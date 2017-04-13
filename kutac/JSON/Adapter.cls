Class kutac.JSON.Adapter [ Abstract ]
{

Parameter VERSION = 0.6;

/// bind a <class>%DynamicObject</class> to a given "regular" Cache class.
/// a new instance of the Cache class is created, or existing instance is opened and its properties are set from the model
/// whether a new instance is created or existing one is opened is determined by searching for Extent index, by the name
/// of property that defines extent index coming along with model data.<p>
/// If such property is not found, implicit Id is expected and new instance is created.<br/>
/// Also, if property that defines Extent index is present but empty, a new instance is created..
ClassMethod %Bind(pModel As %DynamicObject, Output pSC As %Status = {$$$OK}) As %RegisteredObject
{
	#dim e as %Exception.AbstractException
	#dim tObject=$$$NULLOREF
	try {
		// find Extent index definition
		set tCls=##class(%Dictionary.CompiledClass).%OpenId(..%ClassName(1))
		#dim tIdx as %Dictionary.CompiledIndex
		#dim key=""
		#dim tIdKey
		for {
			set tIdx=tCls.Indices.GetNext(.key) q:key=""
			if tIdx.IdKey {
				set tIdKey("name")=tIdx.Name,tIdKey("props")=tIdx.Properties	// get list of properties constructing ID
				quit	
			} 
		}	
		if $d(tIdKey) {
			if tIdKey("props")="" {
				set tObject=$$$NULLOREF
				set:pModel.%IsDefined("_id") tObject=$classmethod(..%ClassName(1),"%OpenId",pModel.%Get("_id"))
				set:tObject=$$$NULLOREF tObject=..%New()
			} else {
				#dim tOpenMethod=tIdKey("name")_"Open"
				#dim len=$l(tIdKey("props"),",")
				set:len=1 tObject=$classmethod(..%ClassName(1),tOpenMethod,pModel.%Get($p(tIdKey("props"),",",1)))
				set:len=2 tObject=$classmethod(..%ClassName(1),tOpenMethod,pModel.%Get($p(tIdKey("props"),",",1)),pModel.%Get($p(tIdKey("props"),",",2)))
				set:len=3 tObject=$classmethod(..%ClassName(1),tOpenMethod,pModel.%Get($p(tIdKey("props"),",",1)),pModel.%Get($p(tIdKey("props"),",",2)),pModel.%Get($p(tIdKey("props"),",",3)))
				if len>3 throw $$$ERROR($$$GeneralError,"UNIMPLEMENTED")
			}
		} else {
		 	set tObject=..%New()
		}
		
		// traverse incoming data and assign them to corresponding classes in the regular Cache object instance
		#dim tProp as %Dictionary.CompiledProperty
		#dim tIterator=pModel.%GetIterator()
		#dim tKey,tValue
		#dim aKey,aValue
		while tIterator.%GetNext(.tKey,.tValue) {
			#dim tType=pModel.%GetTypeOf(tKey)
			if tKey="_id" continue
			// find true Cache data type
			set tProp=##class(%Dictionary.CompiledProperty).%OpenId(..%ClassName(1)_"||"_tKey)
			set tPropDefType=##class(%Dictionary.CompiledClass).%OpenId(tProp.Type)
			//w !,tKey,":",tType,":",tProp.Type
			if tType="string" {
				// literals
				set $property(tObject,tKey)=$method(tObject,tKey_"DisplayToLogical",tValue)
			} elseif tType="array" {
				// is it a Cache list or array?
				if tProp.Collection="list" {
					if tPropDefType.ClassType="datatype" {
						do $method($property(tObject,tKey),"Clear")
						kill aKey,aValue
						#dim aIterator=tValue.%GetIterator()
						while aIterator.%GetNext(.aKey,.aValue) {
							do $method($property(tObject,tKey),"Insert",aValue)
						}
					} else {
						// object
						do $method($property(tObject,tKey),"Clear")
						kill aKey,aValue
						set aIterator=tValue.%GetIterator()
						while aIterator.%GetNext(.aKey,.aValue) {
							do $method($property(tObject,tKey),"SetAt",$classmethod(tProp.Type,"%Bind",aValue,.pSC),aKey)
						}
					}
				} elseif tProp.Collection="array" {
					if tProp.RuntimeType="%Library.RelationshipObject" {
						// relationship = special case of array of objects
						do $method($property(tObject,tKey),"Clear")
						kill aKey,aValue
						set aIterator=tValue.%GetIterator()
						while aIterator.%GetNext(.aKey,.aValue) {
							do $method($property(tObject,tKey),"Insert",$classmethod(tProp.Type,"%Bind",aValue,.pSC))
						}
					} else {
						// ordinary array
						if tPropDefType.ClassType="datatype" {
							do $method($property(tObject,tKey),"Clear")
							kill aKey,aValue
							set aIterator=tValue.%GetIterator()
							while aIterator.%GetNext(.aKey,.aValue) {
								do $method($property(tObject,tKey),"SetAt",aKey,aValue)
							}
						} else {
							// object
							do $method($property(tObject,tKey),"Clear")
							kill aKey,aValue
							set aIterator=tValue.%GetIterator()
							while aIterator.%GetNext(.aKey,.aValue) {
								do $method($property(tObject,tKey),"SetAt",$classmethod(tProp.Type,"%Bind",aValue,.pSC),aKey)
							}
						}
					}
				}
			} elseif tType="object" {
				set $property(tObject,tKey)=$classmethod(tProp.Type,"%Bind",tValue)
			} else {
				throw $$$ERROR($$$GeneralError,"UNIMPLEMENTED")
			}
		}
	} catch (e) {
		w !,"ERROR:" b
		set pSC=e.AsStatus()
	}
	return tObject
}

/// expose a "regular" Cache object to <class>%DynamicObject</class> for further JSON operations 
/// (most likely to serialize by calling %ToJSON() method)
Method %Expose(pSystem As %Boolean) As %DynamicObject [ CodeMode = objectgenerator ]
{
	do %code.WriteLine("	set tModel={}")
	set tCls=##class(%Dictionary.CompiledClass).%OpenId(%class.Name)
	#dim tProp as %Dictionary.CompiledProperty
	#dim key=""
	for {
		s tProp=tCls.Properties.GetNext(.key) q:key=""
		if tProp.Private continue
		if tProp.Internal continue
		if tProp.Cardinality="one" continue
		if tProp.Cardinality="parent" continue
		set tPropDefType=##class(%Dictionary.CompiledClass).%OpenId(tProp.Type)	
		if tPropDefType=$$$NULLOREF continue	// pri kompilaci jeste nemusi byt k dispozici
		d %code.WriteLine("	// "_tProp.Name_": type = "_tProp.Type) 
		if tProp.Collection="array" {
			if tProp.RuntimeType="%Library.RelationshipObject" {
				// relationship
				do %code.WriteLine("	set tArr=[],sArr=.."_tProp.Name)
				do %code.WriteLine("	set key="""" for {")
				do %code.WriteLine("		set sArrMember=sArr.GetNext(.key) q:key=""""")
				do %code.WriteLine("		do tArr.%Push(sArrMember.%Expose())")
				do %code.WriteLine("	}")
				do %code.WriteLine("	set tModel."_tProp.Name_"=tArr")				
			} else {
				// ordinary array
				if tPropDefType.ClassType="datatype" {
					do %code.WriteLine("	set tArr=[],sArr=.."_tProp.Name)				
					do %code.WriteLine("	s key="""" for  {")
					do %code.WriteLine("		s sArrMember=sArr.GetNext(.key) q:key=""""")
					do %code.WriteLine("		d tArr.%Push(sArrMember)")
					do %code.WriteLine("	}")
					do %code.WriteLine("	set tModel."_tProp.Name_"=tArr")
				} else {
					// object
					do %code.WriteLine("	set tArr=[],sArr=.."_tProp.Name)
					do %code.WriteLine("	set key="""" for {")
					do %code.WriteLine("		set sArrMember=sArr.GetNext(.key) q:key=""""")
					do %code.WriteLine("		do tArr.%Push(sArrMember.%Expose())")
					do %code.WriteLine("	}")
					do %code.WriteLine("	set tModel."_tProp.Name_"=tArr")
				}				
			}
		} elseif tProp.Collection="list" {
			if tPropDefType.ClassType="datatype" {
				do %code.WriteLine("	set tList=[],sList=.."_tProp.Name)				
				do %code.WriteLine("	for i=1:1:sList.Count() {")
				do %code.WriteLine("		d tList.%Push(sList.GetAt(i))")
				do %code.WriteLine("	}")
				do %code.WriteLine("	set tModel."_tProp.Name_"=tList")
			} else {
				// object
				do %code.WriteLine("	set tList=[],sList=.."_tProp.Name)				
				do %code.WriteLine("	for i=1:1:sList.Count() {")
				do %code.WriteLine("		d tList.%Push(sList.GetAt(i).%Expose())")
				do %code.WriteLine("	}")
				do %code.WriteLine("	set tModel."_tProp.Name_"=tList")			
			}	
		} else { 
			if tPropDefType.ClassType="datatype" {
				do %code.WriteLine("	set tModel."_tProp.Name_"=.."_tProp.Name_"LogicalToDisplay(.."_tProp.Name_")")
			} else {
				// object
				do %code.WriteLine("	set:.."_tProp.Name_"'=$$$NULLOREF tModel."_tProp.Name_"=.."_tProp.Name_".%Expose()")				
			}
		}
	}
	if tCls.ClassType="persistent" {
		set key=""
		#dim tIdKey
		for {
			set tIdx=tCls.Indices.GetNext(.key) q:key=""
			if tIdx.IdKey {
				set tIdKey("name")=tIdx.Name,tIdKey("props")=tIdx.Properties	// get list of properties constructing ID
				quit	
			} 
		}
		if $d(tIdKey) {
			if tIdKey("props")="" {
				do %code.WriteLine("	set tModel.""_id""=..%Id()")
			}
		}
		
	}
	do %code.WriteLine("	return tModel")
	return $$$OK
}

}
