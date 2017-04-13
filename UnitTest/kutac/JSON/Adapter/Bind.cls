Class UnitTest.kutac.JSON.Adapter.Bind extends %UnitTest.TestCase {

Method TestString()
{
	Set dyn = {"Many":[],"ObjectArray":{},"ObjectList":[],"String":"hello world","StringArray":{},"StringDisplayList":"","StringList":[],"_id":""}
	Set obj = ##class(SamplePersistent).%Bind(dyn,.tSC)
	Do $$$AssertStatusOK(tSC)
	Do $$$AssertEquals(obj.String,dyn.String)
}

Method TestStringDisplayList()
{
	Set dyn = {"Many":[],"ObjectArray":{},"ObjectList":[],"String":"","StringArray":{},"StringDisplayList":"A","StringList":[],"_id":""}
	Set obj = ##class(SamplePersistent).%Bind(dyn,.tSC)
	Do $$$AssertStatusOK(tSC)
	Do $$$AssertEquals(obj.StringDisplayList,1)
}

Method TestStringList()
{
	Set dyn = {"Many":[],"ObjectArray":{},"ObjectList":[],"String":"","StringArray":{},"StringDisplayList":"","StringList":[1,2,3],"_id":""}
	Set obj = ##class(SamplePersistent).%Bind(dyn,.tSC)
	Do $$$AssertStatusOK(tSC)
	Do $$$AssertEquals(obj.StringList.Count(),3)
	Do $$$AssertEquals(obj.StringList.GetAt(1),1)
	Do $$$AssertEquals(obj.StringList.GetAt(2),2)
	Do $$$AssertEquals(obj.StringList.GetAt(3),3)
}

Method TestStringArray()
{
	Set dyn = {"Many":[],"ObjectArray":{},"ObjectList":[],"String":"","StringArray":{"3":2,"6":4,"9":6},"StringDisplayList":"","StringList":[],"_id":""}
	Set obj = ##class(SamplePersistent).%Bind(dyn,.tSC)
	Do $$$AssertStatusOK(tSC)
	Do $$$AssertEquals(obj.StringArray.GetAt(3),2)
	Do $$$AssertEquals(obj.StringArray.GetAt(6),4)
	Do $$$AssertEquals(obj.StringArray.GetAt(9),6)
}

Method TestObjectList()
{
	Set dyn = {"Many":[],"ObjectArray":{},"ObjectList":[
			{"Many":[],"ObjectArray":{},"ObjectList":[],"String":1,"StringArray":{},"StringDisplayList":"A","StringList":[],"_id":""},
			{"Many":[],"ObjectArray":{},"ObjectList":[],"String":2,"StringArray":{},"StringDisplayList":"B","StringList":[],"_id":""},
			{"Many":[],"ObjectArray":{},"ObjectList":[],"String":3,"StringArray":{},"StringDisplayList":"C","StringList":[],"_id":""}
		],"String":"","StringArray":{},"StringDisplayList":"","StringList":[],"_id":""}
	Set obj = ##class(SamplePersistent).%Bind(dyn,.tSC)
	Do $$$AssertStatusOK(tSC)
	Do $$$AssertEquals(obj.ObjectList.GetAt(1).String,1)
	Do $$$AssertEquals(obj.ObjectList.GetAt(2).String,2)
	Do $$$AssertEquals(obj.ObjectList.GetAt(3).String,3)
	Do $$$AssertEquals(obj.ObjectList.GetAt(1).StringDisplayList,1)
	Do $$$AssertEquals(obj.ObjectList.GetAt(2).StringDisplayList,2)
	Do $$$AssertEquals(obj.ObjectList.GetAt(3).StringDisplayList,3)
}

Method TestObjectArray()
{
	Set dyn = {"Many":[],"ObjectArray":{
			"1":{"Many":[],"ObjectArray":{},"ObjectList":[],"String":1,"StringArray":{},"StringDisplayList":"A","StringList":[],"_id":""},
			"2":{"Many":[],"ObjectArray":{},"ObjectList":[],"String":2,"StringArray":{},"StringDisplayList":"B","StringList":[],"_id":""},
			"3":{"Many":[],"ObjectArray":{},"ObjectList":[],"String":3,"StringArray":{},"StringDisplayList":"C","StringList":[],"_id":""}
		},"ObjectList":[],"String":"","StringArray":{},"StringDisplayList":"","StringList":[],"_id":""}
	Set obj = ##class(SamplePersistent).%Bind(dyn,.tSC)
	Do $$$AssertStatusOK(tSC)
	Do $$$AssertEquals(obj.ObjectArray.GetAt(1).String,1)
	Do $$$AssertEquals(obj.ObjectArray.GetAt(2).String,2)
	Do $$$AssertEquals(obj.ObjectArray.GetAt(3).String,3)
	Do $$$AssertEquals(obj.ObjectArray.GetAt(1).StringDisplayList,1)
	Do $$$AssertEquals(obj.ObjectArray.GetAt(2).StringDisplayList,2)
	Do $$$AssertEquals(obj.ObjectArray.GetAt(3).StringDisplayList,3)
}

Method TestOne()
{
	// TODO: anything with this?
}

Method TestMany()
{
	Set dyn = {"Many":[
			{"Many":[],"ObjectArray":{},"ObjectList":[],"String":"Hello World","StringArray":{},"StringDisplayList":"","StringList":[],"_id":""}
		],"ObjectArray":{},"ObjectList":[],"String":"","StringArray":{},"StringDisplayList":"","StringList":[],"_id":""}
	Set obj = ##class(SamplePersistent).%Bind(dyn,.tSC)
	Do $$$AssertStatusOK(tSC)
	Do $$$AssertEquals(obj.Many.GetNext("").String,"Hello World")
}

}