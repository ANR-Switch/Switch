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
	
	action getInCar(Individual driver, list<Individual> passengers_, HubCar targetHub){
		current_capacity <- current_capacity + 1;
		create Car{
			passengers << driver;
			driver.status <- "driving";
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
	
	action getOutCar(Car c){
		current_capacity <- current_capacity - 1;
		c.passengers[0].car_place <- self;
		loop passenger over: c.passengers{
			passenger.location <- location;
			passenger.status <- "arrived";
		}
		ask c{do die;}
	}
}
