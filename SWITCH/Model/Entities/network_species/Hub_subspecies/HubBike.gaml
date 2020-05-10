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
	
	action getInBike(Individual driver, HubBike targetHub){
		current_capacity <- current_capacity + 1;
		create Bike{
			passengers << driver;
			driver.status <- "driving";
			available_graph <- road_network;
			target <- targetHub;
			path_to_target <- path_between(available_graph,myself,target).vertices;
		}
	}
	
	action getOutBike(Bike b){
		current_capacity <- current_capacity - 1;
		b.passengers[0].location <- location;
		b.passengers[0].bike_place <- self;
		b.passengers[0].status <- "arrived";
		ask b{do die;}
	}
}
