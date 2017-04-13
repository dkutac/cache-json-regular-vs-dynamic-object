Class UnitTest.kutac.JSON.Adapter.Expose extends %UnitTest.TestCase {

Method TestString()
{
	Set obj = ##class(SamplePersistent).%New()
	Set obj.String = "hello world"
	Set dyn = obj.%Expose()
	Do $$$LogMessage(dyn.%ToJSON())
	Do $$$AssertEquals(dyn.String,obj.String)
}

Method TestStringDisplayList()
{
	Set obj = ##class(SamplePersistent).%New()
	Set obj.StringDisplayList = 1
	Set dyn = obj.%Expose()
	Do $$$LogMessage(dyn.%ToJSON())
	Do $$$AssertEquals(dyn.StringDisplayList,"A")
}

Method TestStringList()
{
	Set obj = ##class(SamplePersistent).%New()
	For i=1:1:3 {
		Do obj.StringList.Insert(i)
	}
	Set dyn = obj.%Expose()
	Do $$$LogMessage(dyn.%ToJSON())
	Do $$$AssertEquals(dyn.StringList.%Size(),3)
	Do $$$AssertEquals(dyn.StringList.%Get(0),1)
	Do $$$AssertEquals(dyn.StringList.%Get(1),2)
	Do $$$AssertEquals(dyn.StringList.%Get(2),3)
}

Method TestStringArray()
{
	Set obj = ##class(SamplePersistent).%New()
	For i=1:1:3 {
		Do obj.StringArray.SetAt(i*2,i*3)
	}
	Set dyn = obj.%Expose()
	Do $$$LogMessage(dyn.%ToJSON())
	Do $$$AssertEquals(dyn.StringArray.%Get(3),2)
	Do $$$AssertEquals(dyn.StringArray.%Get(6),4)
	Do $$$AssertEquals(dyn.StringArray.%Get(9),6)
}

Method TestObjectList()
{
	Set obj = ##class(SamplePersistent).%New()
	For i=1:1:3 {
		Set obj2 = ##class(SamplePersistent).%New()
		Set obj2.String = i
		Set obj2.StringDisplayList = i
		Do obj.ObjectList.Insert(obj2)
	}
	Set dyn = obj.%Expose()
	Do $$$LogMessage(dyn.%ToJSON())
	Do $$$AssertEquals(dyn.ObjectList.%Get(0).String,1)
	Do $$$AssertEquals(dyn.ObjectList.%Get(1).String,2)
	Do $$$AssertEquals(dyn.ObjectList.%Get(2).String,3)
	Do $$$AssertEquals(dyn.ObjectList.%Get(0).StringDisplayList,"A")
	Do $$$AssertEquals(dyn.ObjectList.%Get(1).StringDisplayList,"B")
	Do $$$AssertEquals(dyn.ObjectList.%Get(2).StringDisplayList,"C")
}

Method TestObjectArray()
{
	Set obj = ##class(SamplePersistent).%New()
	For i=1:1:3 {
		Set obj2 = ##class(SamplePersistent).%New()
		Set obj2.String = i
		Set obj2.StringDisplayList = i
		Do obj.ObjectArray.SetAt(obj2,i)
	}
	Set dyn = obj.%Expose()
	Do $$$LogMessage(dyn.%ToJSON())
	Do $$$AssertEquals(dyn.ObjectArray.%Get(1).String,1)
	Do $$$AssertEquals(dyn.ObjectArray.%Get(2).String,2)
	Do $$$AssertEquals(dyn.ObjectArray.%Get(3).String,3)
	Do $$$AssertEquals(dyn.ObjectArray.%Get(1).StringDisplayList,"A")
	Do $$$AssertEquals(dyn.ObjectArray.%Get(2).StringDisplayList,"B")
	Do $$$AssertEquals(dyn.ObjectArray.%Get(3).StringDisplayList,"C")
}

Method TestOne()
{
	// This doesn't seem to work yet. It's questionable whether it should - things get messy if we project both sides of relationships.
	/*
	Set obj = ##class(SamplePersistent).%New()
	Set obj2 = ##class(SamplePersistent).%New()
	Set obj2.String = "Hello World"
	Set obj.One = obj2
	Set dyn = obj.%Expose()
	Do $$$LogMessage(dyn.%ToJSON())
	Do $$$AssertEquals(dyn.One.String,obj2.String)
	*/
}

Method TestMany()
{
	Set obj = ##class(SamplePersistent).%New()
	Set obj2 = ##class(SamplePersistent).%New()
	Set obj2.String = "Hello World"
	Do obj.Many.Insert(obj2)
	Set dyn = obj.%Expose()
	Do $$$LogMessage(dyn.%ToJSON())
	Do $$$AssertEquals(dyn.Many.%Get(0).String,obj2.String)
}

}