/**
* Name: Car
* Based on the internal empty template. 
* Author: Lo�c
* Tags: 
*/


model SWITCH

import "PrivateTransport.gaml"

species Car parent: PrivateTransport {
	
	HubCar target;
	
	init{
		max_speed <- 130.0;
		size <- 4.13;//Argus average size in meters
		max_passenger <- 5;
	}
	
	reflex endTrip when: location = target.location{
		ask target{
			do getOutCar(myself);
		}
	}
	
	aspect default {
		draw square(1#px) color: #red border: #black depth: 1.0 ;
	}
	
}
