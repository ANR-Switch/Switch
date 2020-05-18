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
		max_speed <- 14.0;
		size <- 1.0;
		max_passenger <- 1;
	}
	
	action endTrip{
		location <- pos_target;
		loop passenger over:passengers{
			// we assumed that the first passenger is always the transport owner
			if passenger = passengers[0]{ passenger.bike_place <- location;}
			passenger.status <- "arrived";
			passenger.location <- location;
		}
		do die;
	}
	
	aspect default {
		draw square(2) color: #green border: #black;
	}
	
}

