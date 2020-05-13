/**
* Name: Bike
* Based on the internal empty template. 
* Author: Lo�c
* Tags: 
*/


model SWITCH

import "PrivateTransport.gaml"

species Bike parent: PrivateTransport {
	
	HubBike target;
	
	init{
		max_speed <- 14.0;
		size <- 1.0;
		max_passenger <- 1;
	}
	
	reflex startTrip when: road_pointer < 0{
		location <- path_to_target[0].start_node.location;
		ask path_to_target[0]{ do queueInRoad(myself); }	
	}
	
	reflex endTrip when: location = target.location{
		ask target{
			do leave(myself);
		}
	}
	
	aspect default {
		draw square(2) color: #green border: #black;
	}
	
}

