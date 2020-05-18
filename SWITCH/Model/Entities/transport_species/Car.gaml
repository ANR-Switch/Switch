/**
* Name: Car
* Based on the internal empty template. 
* Author: Lo�c
* Tags: 
*/


model SWITCH

import "PrivateTransport.gaml"

species Car parent: PrivateTransport {
	
	init{
		max_speed <- 130.0;
		size <- 4.13;// Argus average size in meters
		max_passenger <- 5;
	}
	
	action endTrip{
		location <- pos_target;
		loop passenger over:passengers{
			// we assumed that the first passenger is always the transport owner
			if passenger = passengers[0]{ passenger.car_place <- location;}
			passenger.status <- "arrived";
			passenger.location <- location;
		}
		do die;
	}
	
	aspect default {
		draw square(5) color: #red border: #black;
	}
	
}
