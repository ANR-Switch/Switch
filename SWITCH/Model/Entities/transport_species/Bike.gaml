/**
* Name: Bike
* Based on the internal empty template. 
* Author: Lo�c
* Tags: 
*/


model SWITCH

import "PrivateTransport.gaml"

species Bike parent: PrivateTransport {
	
	init{
		max_speed <- 20.0;
		size <- 1.0;
		max_passenger <- 1;
	}
	
	reflex startTrip when: roadPointer < 0{
		location <- path_to_target[0].start_node.location;
		ask path_to_target[0]{ do getBikeInRoad(myself); }	
	}
	
	aspect default {
		draw square(1#px) color: #green border: #black depth: 1.0 ;
	}
	
}

