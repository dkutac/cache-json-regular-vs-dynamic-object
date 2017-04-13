Class UnitTest.kutac.JSON.Adapter.SamplePersistent Extends (%Persistent, kutac.JSON.Adapter) {

Property String As %String;

Property StringDisplayList As %String(VALUELIST=",1,2,3", DISPLAYLIST=",A,B,C");

Property StringList As list of %String;

Property StringArray As array of %String;

Property ObjectList As list of UnitTest.kutac.JSON.Adapter.SamplePersistent;

Property ObjectArray As array of UnitTest.kutac.JSON.Adapter.SamplePersistent;

Relationship One As UnitTest.kutac.JSON.Adapter.SamplePersistent [ Cardinality = one, Inverse = Many ];

Relationship Many As UnitTest.kutac.JSON.Adapter.SamplePersistent [ Cardinality = many, Inverse = One ];

Storage Default
{
<Data name="ObjectArray">
<Attribute>ObjectArray</Attribute>
<Structure>subnode</Structure>
<Subscript>"ObjectArray"</Subscript>
</Data>
<Data name="SamplePersistentDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>String</Value>
</Value>
<Value name="3">
<Value>StringDisplayList</Value>
</Value>
<Value name="4">
<Value>StringList</Value>
</Value>
<Value name="5">
<Value>ObjectList</Value>
</Value>
<Value name="6">
<Value>One</Value>
</Value>
</Data>
<Data name="StringArray">
<Attribute>StringArray</Attribute>
<Structure>subnode</Structure>
<Subscript>"StringArray"</Subscript>
</Data>
<DataLocation>^UnitTest.k9986.SamplePersi560AD</DataLocation>
<DefaultData>SamplePersistentDefaultData</DefaultData>
<IdLocation>^UnitTest.k9986.SamplePersi560AD</IdLocation>
<IndexLocation>^UnitTest.k9986.SamplePersi560AI</IndexLocation>
<StreamLocation>^UnitTest.k9986.SamplePersi560AS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}