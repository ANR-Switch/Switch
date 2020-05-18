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
	
	aspect default {
		draw square(2) color: #green border: #black;
	}
	
}

