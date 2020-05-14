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
		size <- 4.13;// Argus average size in meters
		max_passenger <- 5;
	}
	
	action endTrip{
		location <- posTarget;
		loop passenger over:passengers{
			// we assumed that the first passenger is the car owner
			if passenger = passengers[0]{ passenger.car_place <- location;}
			passenger.status <- "arrived";
			passenger.location <- location;
		}
		write "car arrived at destination";
		do die;
	}
	
	aspect default {
		draw square(5) color: #red border: #black;
	}
	
}
