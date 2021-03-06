/// this class is a simple implementation of binding between 'regular' Cache classes and dynamic objects.</p>
/// How it works: <br/>
/// use %Bind() method to convert dynamic object to a regular (persistent, registered, serial) Cache class<br/>
/// use %Expose() method to convert regular Cache class to a dynamic object<p/>
/// Collections implementation notes:<br/>
/// Cache lists are exposed as JSON arrays - using [] notation<br/>
/// Cache arrays are exposed as JSON objects - using {} notation - with first key equal to a key identifying Cache array elements, the second key equal to a Cache array node value<p/>
/// Cache streams are IGNORED!<br/> The reason is following. JSON is typically payload of RESTful services.
/// As such, streams are best handled as form/multi-part requests. Updates to streams shall thus be implemented
/// as separate methods and targeted directly to 'regular' objects.
Class kutac.JSON.Adapter [ Abstract ]
{

Parameter VERSION = 0.91;

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
		set tCls=##class(%Dictionary.CompiledClass).%OpenId(..%ClassName(1),,.tSC)
		$$$ThrowOnError(tSC)
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
				if (pModel.%Get("_id") '= "") {
					set tObject=$classmethod(..%ClassName(1),"%OpenId",pModel.%Get("_id"),,.tSC)
					$$$ThrowOnError(tSC)
				} else {
					set tObject=..%New()
				}
			} else {
				#dim tOpenMethod=tIdKey("name")_"Open"
				#dim len=$l(tIdKey("props"),",")
				
				// TODO: convert to args... syntax to allow any number of idkey properties.
				set:len=1 tObject=$classmethod(..%ClassName(1),tOpenMethod,pModel.%Get($p(tIdKey("props"),",",1)))
				set:len=2 tObject=$classmethod(..%ClassName(1),tOpenMethod,pModel.%Get($p(tIdKey("props"),",",1)),pModel.%Get($p(tIdKey("props"),",",2)))
				set:len=3 tObject=$classmethod(..%ClassName(1),tOpenMethod,pModel.%Get($p(tIdKey("props"),",",1)),pModel.%Get($p(tIdKey("props"),",",2)),pModel.%Get($p(tIdKey("props"),",",3)))
				if len>3 $$$ThrowStatus($$$ERROR($$$NotImplemented))
				// DK: v 0.7 - 2017-04-20, if no object instance found then create a new one 
				if tObject=$$$NULLOREF set tObject=..%New()
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
			//w !,tKey,":",tType
			if tKey="_id" continue
			// find true Cache data type
			set tProp=##class(%Dictionary.CompiledProperty).%OpenId(..%ClassName(1)_"||"_tKey,,.tSC)
			// DK v 0.8 - 2017-04-20, ignore unknown keys
			if $$$ISERR(tSC) continue	// $$$ThrowOnError(tSC)
			set tPropDefType=##class(%Dictionary.CompiledClass).%OpenId(tProp.Type,,.tSC)
			$$$ThrowOnError(tSC)
			//w ":",tProp.Type	
			if (tType="string") || (tType="number") {
				// literals
				// DK 0.91: handle correctly I/O translations - use XML format preferably
				try {
					// there is no runnable method XSDToLogical generated for the regular object's literal properties
					set $property(tObject,tKey)=$classmethod(tProp.Type,"XSDToLogical",tValue)
				} catch (ie) {
					set $property(tObject,tKey)=$method(tObject,tKey_"DisplayToLogical",tValue)					
				}
			} elseif tType="array" {
				// is it a Cache array?
				if tProp.Collection="array" {
					if tProp.RuntimeType="%Library.RelationshipObject" {
						// relationship = special case of array of objects
						do $method($property(tObject,tKey),"Clear")
						kill aKey,aValue
						set aIterator=tValue.%GetIterator()
						while aIterator.%GetNext(.aKey,.aValue) {
							do $method($property(tObject,tKey),"Insert",$classmethod(tProp.Type,"%Bind",aValue,.pSC))
							$$$ThrowOnError(pSC)
						}
					}
					// Cache list?
				} elseif tProp.Collection="list" {
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
							do $method($property(tObject,tKey),"Insert",$classmethod(tProp.Type,"%Bind",aValue,.pSC))
							$$$ThrowOnError(pSC)
						}
					}
				}
			} elseif tType="object" {
				if tProp.Collection="array" {
					if tProp.RuntimeType="%Library.RelationshipObject" {
						// no action					
					} else {
						// ordinary array
						if tPropDefType.ClassType="datatype" {
							do $method($property(tObject,tKey),"Clear")
							kill aKey,aValue
							set aIterator=tValue.%GetIterator()
							while aIterator.%GetNext(.aKey,.aValue) {
								do $method($property(tObject,tKey),"SetAt",aValue,aKey)
							}
						} elseif tPropDefType.ClassType="stream" {
							// ignore streams
						} else {
							// object
							do $method($property(tObject,tKey),"Clear")
							kill aKey,aValue
							set aIterator=tValue.%GetIterator()
							while aIterator.%GetNext(.aKey,.aValue) {
								s %type = tProp.Type
								do $method($property(tObject,tKey),"SetAt",$classmethod(tProp.Type,"%Bind",aValue,.pSC),aKey)
								$$$ThrowOnError(pSC)
							}
						}
					}
				} elseif tPropDefType.ClassType="stream" {
					// ignore streams					
				} else {
					// object
					set $property(tObject,tKey)=$classmethod(tProp.Type,"%Bind",tValue)
				}
			} else {
				$$$ThrowStatus($$$ERROR($$$NotImplemented))
			}
		}
	} catch (e) {
		set pSC=e.AsStatus()
	}
	return tObject
}

/// expose a "regular" Cache object to <class>%DynamicObject</class> for further JSON operations 
/// (most likely to serialize by calling %ToJSON() method)
Method %Expose(pSystem As %Boolean = 1, pIgnoreStreams As %Boolean = 1) As %DynamicObject [ CodeMode = objectgenerator ]
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
		if tPropDefType=$$$NULLOREF continue	// may not be available at the compilation time
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
					do %code.WriteLine("	set tArr={},sArr=.."_tProp.Name)				
					do %code.WriteLine("	s key="""" for  {")
					do %code.WriteLine("		s sArrMember=sArr.GetNext(.key) q:key=""""")
					do %code.WriteLine("		d tArr.%Set(key,sArrMember)")
					do %code.WriteLine("	}")
					do %code.WriteLine("	set tModel."_tProp.Name_"=tArr")
				} elseif tPropDefType.ClassType="stream" {
					// not supported
				} else {
					// object
					do %code.WriteLine("	set tArr={},sArr=.."_tProp.Name)
					do %code.WriteLine("	set key="""" for {")
					do %code.WriteLine("		set sArrMember=sArr.GetNext(.key) q:key=""""")
					do %code.WriteLine("		do tArr.%Set(key,sArrMember.%Expose())")
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
			} elseif tPropDefType.ClassType="stream" {
				// not supported
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
				// DK 0.91: handle correctly I/O translations (use XML format where possible)
				do %code.WriteLine("	try {")
				do %code.WriteLine("		set tModel."_tProp.Name_"=##class("_tProp.Type_").LogicalToXSD(.."_tProp.Name_")")
				do %code.WriteLine("	} catch (ie) {")
				do %code.WriteLine("		set tModel."_tProp.Name_"=.."_tProp.Name_"LogicalToDisplay(.."_tProp.Name_")")
				do %code.WriteLine("	}")
			} elseif tPropDefType.ClassType="stream" {
				// not supported
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
				do %code.WriteLine("	set:pSystem tModel.""_id""=..%Id()")
			}
		}
		
	}
	do %code.WriteLine("	return tModel")
	return $$$OK
}

}
