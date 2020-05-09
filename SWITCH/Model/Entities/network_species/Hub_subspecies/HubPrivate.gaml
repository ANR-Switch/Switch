/**
* Name: HubPrivate
* Based on the internal empty template. 
* Author: Lo�c
* Tags: 
*/


model HubPrivate

import "Hub.gaml"

// the purpose of this species is not to intanciate Hub that are private to some Individual
// but Hub that manage private transport, basically parkings
species HubPrivate parent: Hub {
	
	// Hub capacity (number of transports parkable) 
	int max_capacity;
	
	int current_capacity <- 0 min:0;
	
	bool canPark{
		return max_capacity > current_capacity;
	}

}

