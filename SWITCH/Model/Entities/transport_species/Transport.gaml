/**
* Name: Transport
* Based on the internal empty template. 
* Author: Lo�c
* Tags: 
*/


model SWITCH

import "../network_species/Road.gaml"
import "../network_species/Hub.gaml"

species Transport {
	
	// maximum speed for a transport (km/h)
	float max_speed;
	
	// actual speed
	float speed;
	
	// transport length (meters)
	float size;
	
	//passenger capacity 
	int max_passenger;
	
	//road graph available for the transport
	graph available_graph;
	
	//the target Hub, final destination of the trip
	Hub target; 
	
	//Next road to travel on
	Road nextRoad;
	
	aspect default {
		draw square(1#px) color: #green border: #black depth: 1.0 ;
	}
	
}

