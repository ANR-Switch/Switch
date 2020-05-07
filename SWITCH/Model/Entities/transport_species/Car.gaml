/**
* Name: Car
* Based on the internal empty template. 
* Author: Lo�c
* Tags: 
*/


model SWITCH

import "PrivateTransport.gaml"

species Car parent: PrivateTransport {
	
	aspect default {
		draw square(1#px) color: #green border: #black depth: 1.0 ;
	}
	
}
