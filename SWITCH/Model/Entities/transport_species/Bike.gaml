/**
* Name: Bike
* Based on the internal empty template. 
* Author: Lo�c
* Tags: 
*/


model SWITCH

import "PrivateTransport.gaml"

species Bike parent: PrivateTransport {
	
	string transport_mode <- "bike";
	
	init{
		max_speed <- 20.0;
		size <- 1.0;
		max_passenger <- 1;
	}
	
	float getRoadTravelTime (Road r) {
		float max_speed_formula <- min([self.max_speed, r.max_speed]) #km / #h;
		return r.size / max_speed_formula;
	}	
	
	action endTrip{
		location <- pos_target;
		loop passenger over:passengers{
			// we assumed that the first passenger is always the transport owner
			if passenger = passengers[0]{ passenger.bike_place <- location;}
			passenger.status <- "arrived";
			passenger.location <- location;
			passenger.current_bike <- nil;
		}
		do die;
	}
	
	aspect default {
		draw square(2) color: #green border: #black;
	}
	
}

