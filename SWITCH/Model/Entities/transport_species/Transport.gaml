/**
* Name: Transport
* Based on the internal empty template. 
* Author: Lo�c
* Tags: 
*/


model SWITCH

import "../../logger.gaml"

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
	
	//the target position, final destination of the trip
	Hub target; 
	//same as target but it is a point (for test purpose)
	point posTarget;
	
	//list of roads that lead to the target
	list<Road> path_to_target;
	
	//indicate the actual road in path_to_target list
	int road_pointer <- 0;
	bool startedTrip <- false;
	
	//Next road to travel on
	Road nextRoad;
	
	//******* /!\ TESTING ATTRIBUTES and ACTION **********
	string test_target;
	bool already_reached_end_road <- false;
	float traveled_dist <- 0.0;
	
	
	action addPointReachedEndRoad{
		traveled_dist <- traveled_dist + path_to_target[road_pointer].size;
		if (the_logger != nil) {
			ask the_logger {do add_data(myself.test_target, myself.name, myself.traveled_dist);}
		}
	}
	action addPointEnterRoad{
		already_reached_end_road <- false;
		if (the_logger != nil) {
			ask the_logger {do add_data(myself.test_target, myself.name, myself.traveled_dist);}
		}
	}
	//****************************************************
	
	
	// this action is called by road accepting this transport
	action enterRoad(Road r){
		road_pointer <- startedTrip ? road_pointer + 1 : 0;	
		startedTrip <- true;
		//****** Metrics purpose *************	
		if (test_target != nil) {do addPointEnterRoad();}
		//************************************
		if road_pointer = length(path_to_target)-1{
			//if the current road is the last road of the trip then the transport can join the target
			nextRoad <- nil;
		}else{
			nextRoad <- path_to_target[road_pointer+1];
		}
	}
	
	action endTrip{}
	
	aspect default {
		draw square(1#px) color: #green border: #black depth: 1.0 ;
	}
	
}

