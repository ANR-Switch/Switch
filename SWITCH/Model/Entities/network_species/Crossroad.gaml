/**
* Name: Crossroad
* Based on the internal empty template. 
* Author: Lo�c
* Tags: 
*/


model SWITCH

species Crossroad{
	
	//OSM type (highway feature for node: https://wiki.openstreetmap.org/wiki/Key:highway) 
	string type;
	
	//OSM information on crossroad (see https://wiki.openstreetmap.org/wiki/Tag:highway%3Dcrossing)
	string crossing;
	
	list<string> sub_areas;
	aspect default {
		draw circle(3) color: #grey border: #black;
	}
	
	aspect roadTest{
		draw circle(10) color: #grey border: #black;
		draw type at: location+point([15,-5]) size:10 color:#black;
	}
	
}

