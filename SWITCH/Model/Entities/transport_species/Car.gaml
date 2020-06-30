/**
* Name: Car
* Based on the internal empty template. 
* Author: Lo�c
* Tags: 
*/


model SWITCH

import "PrivateTransport.gaml"

species Car parent: PrivateTransport {
	
	string transport_mode <- "car";
	
	init{
		max_speed <- 130.0;
		size <- 4.13;// Argus average size in meters
		max_passenger <- 5;
	}
	
	action endTrip(float arrived_time){
		location <- pos_target;
		loop passenger over:passengers{
			// we assumed that the first passenger is always the transport owner
			if passenger = passengers[0]{ passenger.car_place <- location;}
			ask passenger{ do setSignal(arrived_time, "arrived");}
			passenger.location <- location;
			passenger.current_car <- nil;
			ask passenger {
				do addTimeSpentInJams(myself.time_in_jams);
				do addTransportTravelTime(myself, myself.practical_trip_time with_precision 3, myself.theoric_trip_time with_precision 3);
			}
		}
		do die;
	}
	
	aspect default {
		draw square(5) color: #red border: #black;
	}
	
}
