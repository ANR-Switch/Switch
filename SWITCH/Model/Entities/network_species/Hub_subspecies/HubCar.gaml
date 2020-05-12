/**
* Name: HubPublic
* Based on the internal empty template. 
* Author: Lo�c
* Tags: 
*/


model SWITCH

import "HubPrivate.gaml"
import "../../Individual.gaml"
import "../../transport_species/Car.gaml"
import "../../../Global.gaml"

species HubCar parent: HubPrivate {
	
	init{
		color <- #red;
	}
	
	action enter(list<Individual> passengers_, HubCar targetHub){
		current_capacity <- current_capacity + 1;
		create Car{
			passengers_[0].status <- "driving";
			int nb_passenger <- min (length(passengers_), max_passenger);
			loop i from: 0 to: nb_passenger-1{
				passengers << passengers_[i];
				passengers_[i].status <- "passenger";
			}
			available_graph <- road_network;
			target <- targetHub;
			path_to_target <- path_between(available_graph,myself,target).vertices;
		}
	}
	
	action leave(Car t){
		current_capacity <- current_capacity - 1;
		t.passengers[0].car_place <- self;
		loop passenger over: t.passengers{
			passenger.location <- location;
			passenger.status <- "trip finished";
		}
		ask t{do die;}
	}
}
