/**
* Name: Bus
* Based on the internal empty template. 
* Author: Lo�c
* Tags: 
*/


model SWITCH

import "PublicTransport.gaml"

species Bus parent: PublicTransport {
	
	string transport_mode <- "bus";
	
	init{
		max_speed <- 70.0;
		size <- 12.00; // https://fr.wikipedia.org/wiki/Autobus#:~:text=Leur%20longueur%20oscille%20entre%208,ville%20historique%2C%20etc.).
		max_passenger <- 1000;
	}
	
	aspect default {
		draw square(15) color: #red border: #black;
	}
	
}

