/**
* Name: HubPublic
* Based on the internal empty template. 
* Author: Lo�c
* Tags: 
*/


model SWITCH

import "HubPrivate.gaml"
import "../../Individual.gaml"
import "../../../Global.gaml"

species HubBike parent: HubPrivate {
	
	init{
		color <- #green;
	}
	
	action enter(list<Individual> passengers_, HubBike targetHub){
		current_capacity <- current_capacity + 1;
		create Bike{
			//As a bike can only have one person on it, only the first person on the list is taken in
			passengers << passengers_[0];
			passengers_[0].status <- "driving";
			available_graph <- road_network;
			target <- targetHub;
			path_to_target <- path_between(available_graph,myself,target).vertices;
		}
	}
	
	action leave(Bike t){
		current_capacity <- current_capacity - 1;
		t.passengers[0].location <- location;
		t.passengers[0].bike_place <- self;
		t.passengers[0].status <- "arrived";
		ask t{do die;}
	}
}
