/**
* Name: Crossroad
* Based on the internal empty template. 
* Author: Lo�c
* Tags: 
*/


model SWITCH

import "Node.gaml"

species Crossroad parent: Node {
	
	//OSM type (highway feature for node: https://wiki.openstreetmap.org/wiki/Key:highway) 
	string type;
	
	//OSM information on crossroad (see https://wiki.openstreetmap.org/wiki/Tag:highway%3Dcrossing)
	string crossing;
	
	
	
	
	aspect default {
		draw square(1#px) color: #white border: #black depth: 1.0 ;
	}
	
}

