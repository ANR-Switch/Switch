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


	
	aspect default {
		draw square(1#px) color: #green border: #black;
	}
	
}

