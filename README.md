#Cache JSON two way biding between regular and dynamic objects
==========================

This project has been developed for one of partners during a workshop where they needed to bind 'regular' Cache objects (registered, persistent classes)
to dynamic object in order to exchange data effectively by means of REST API. The adapter allows to bridge the existing gap in Cache JSON implementation.
With the adapter, is is easy to extend regular Cache classes by adding the adapter class into the base classes list.

How to use:
add the kutac.JSON.Adapter into the base class list

in your code, when you need to expose regular class as a dynamic one, call instance method %Expose() like this:
set x=##class(myregularclass).%New() / or %OpenId(id).%Expose()
now you have a dynamic object so you can call directly .%ToJSON() to show serialized data

when you need to bind incoming JSON string/stream, just do following:
set x=##class(myregularclass).%Bind({}.%FromJSON(jsonstring),.sc)

this is a relatively simple intrface, tested on a limited set of classes, but shall support literal attributes as well as reference attributes and collections as well as relatinships.

Further, when binding to a persistent class, the adapter is using definition of an IdKey index (defautl or custom) to identify existing instance of a persistent class so it not only creates new instacne but mofifies existing instance when appropriate. 
