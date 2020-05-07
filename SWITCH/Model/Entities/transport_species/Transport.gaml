/**
* Name: Transport
* Based on the internal empty template. 
* Author: Lo�c
* Tags: 
*/


model SWITCH


species Transport {
	
	// maximum speed for a transport (km/h)
	float max_speed;
	
	// transport length (meters)
	float size;
	
	//passenger capacity 
	int max_passenger;
	
	aspect default {
		draw square(1#px) color: #green border: #black depth: 1.0 ;
	}
	
}

