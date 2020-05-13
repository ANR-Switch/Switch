/**
* Name: Transport
* Based on the internal empty template. 
* Author: Lo�c
* Tags: 
*/


model SWITCH

import "../network_species/Road.gaml"
import "../network_species/Hub_subspecies/Hub.gaml"
import "../Individual.gaml"

species Transport skills: [moving]{
	
	// maximum speed for a transport (km/h)
	float max_speed;
	
	// transport length (meters)
	float size;
	
	//passenger capacity 
	int max_passenger;
	
	//passengers present in the transport
	// the fisrt passenger of the list is considered as the driver
	list<Individual> passengers <- [];
	
	//road graph available for the transport
	graph available_graph;
	
	//the target Hub, final destination of the trip
	Hub target; 
	
	//list of roads that lead to the target
	list<Road> path_to_target;
	
	//indicate the actual road in path_to_target list
	int roadPointer <- -1;
	
	//Next road to travel on
	Road nextRoad;
	
	
	reflex startTrip when: roadPointer < 0{
		write "start";
		location <- path_to_target[0].start_node.location;
		if path_to_target[0].canAcceptTransport(self){
			ask path_to_target[0]{ do queueInRoad(myself); }	
		}
	}
	
	reflex updateNextRoad when: nextRoad = path_to_target[roadPointer]{
		if roadPointer = length(path_to_target)-1{
			//if the current road is the last road of the trip then the transport can join the target
			do goto target: target;
			nextRoad <- nil;
		}else{
			nextRoad <- path_to_target[roadPointer+1];
		}
	}
	
	reflex endTrip when: location = target.location{}
	
	aspect default {
		draw square(1#px) color: #green border: #black depth: 1.0 ;
	}
	
}

