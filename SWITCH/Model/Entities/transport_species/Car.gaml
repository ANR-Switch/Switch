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
		size <- 4.13;//Argus average size
		max_passenger <- 5;
	}
	
	aspect default {
		draw square(1#px) color: #green border: #black depth: 1.0 ;
	}
	
}
