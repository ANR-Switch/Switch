/**
* Name: Walk
* Based on the internal empty template. 
* Author: Lo�c
* Tags: 
*/


model SWITCH

import "PrivateTransport.gaml"

species Walk parent: PrivateTransport {
	
	string transport_mode <- "walk";
	
	init{
		max_speed <- 6.0;
		size <- 1.0;
		max_passenger <- 1;
	}
	
	float getRoadTravelTime(Road r){
		return get_freeflow_travel_time(r) with_precision 3;
	}
	
	//There is a specific start action for pedestrians as it is coherent to not have a road to pass for a walk trip
	//so when the path is nil, a leave event is set. When the leave signal will occur, as path_to_target is empty the action endTrip
	//will be called causing the pedestrian to be teleported at his target location
	action start (point start_location, point end_location,graph<Crossroad,Road> road_network_, float start_time) {
		location <- start_location;
		pos_target <- end_location;
		available_graph <- road_network_;
		path the_path <- path_between(available_graph, location, pos_target);
		if (the_path = nil) {
			path_to_target <- [];
			do setLeaveTime(time + (distance_to(start_location,end_location)/self.max_speed));
		} else {
			path_to_target <- list<Road>(the_path.edges);			
			add nil to: path_to_target at: 0;
			do sendEnterRequest(start_time);
		}
	}
	
	action endTrip(float arrived_time){
		do registerDataInfo(arrived_time);
		location <- pos_target;
		loop passenger over:passengers{
			ask passenger{ do setSignal(arrived_time, "arrived");}
			passenger.location <- location;
			passenger.current_walk <- nil;
		}
		do die;
	}
	
	aspect default {
		draw square(2) color: #green border: #black;
	}
	
}

