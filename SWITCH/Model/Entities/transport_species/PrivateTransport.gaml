/**
* Name: PrivateTransport
* Based on the internal empty template. 
* Author: Lo�c
* Tags: 
*/


model SWITCH

import "Transport.gaml"

species PrivateTransport parent: Transport {
	
	action getIn(list<Individual> passengers_){
		int nb_passenger <- min (length(passengers_), max_passenger);
		loop i from: 0 to: nb_passenger-1{
			passengers << passengers_[i];
			passengers_[i].status <- i = 0 ? "driving" : "passenger";
		}
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
		draw square(1#px) color: #green border: #black;
	}
	
}

