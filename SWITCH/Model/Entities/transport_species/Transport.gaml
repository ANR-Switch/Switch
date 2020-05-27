/**
* Name: Transport
* Based on the internal empty template. 
* Author: Lo�c
* Tags: 
*/


model SWITCH

import "../../logger.gaml"
import "../../Global.gaml"
import "../../../Experiments/Tests/Road Test.gaml"
import "../network_species/Road.gaml"
import "../Individual.gaml"

species Transport skills: [moving]{
	
	string status <- "starting trip" among: ["starting trip", "waiting space in road", "waiting to enter road", "moving", "waiting to leave road"];
	
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
	point pos_target;
	
	//list of roads that lead to the target
	list<Road> path_to_target;
	
	//indicate the actual road in path_to_target list
	int road_pointer <- 0;
	
	//last entry_time received
	int last_entry_time <- 0;
	
	//last leave_time received
	int last_leave_time<- int(time);
	
	//last road occupation ratio observed by the transport
	float last_occup_ratio <- 0.0;
	
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
	
	action setSignal{
		switch status{
			match "waiting to enter road"{
				if road_pointer > 0 { ask path_to_target[road_pointer]{ do leave(myself,myself.last_leave_time); } }
				road_pointer <- road_pointer +1;
				ask path_to_target[road_pointer]{ 
					do queueInRoad(myself);
					myself.last_occup_ratio <- (max_capacity-current_capacity)/max_capacity;
				}
				status <- "moving";
			}
			match "waiting to leave road"{
				if road_pointer < length(path_to_target)-1 {
					do sendEnterRequest;
				}else{
					//the transport is arrived
					do endTrip;
				}
			}
		}
		
	}
	
	action sendEnterRequest{
		ask path_to_target[road_pointer+1]{ do enterRequest(myself); }
		status <- "waiting space in road";
	}
	
	action setEntryTime(int entry_time){
		ask event_m { do registerEvent(entry_time,myself);}
		status <- "waiting to enter road";
		last_entry_time <- entry_time;
		//we say to the road that a space will be free at entry_time
		ask path_to_target[road_pointer]{ do willLeave(entry_time,myself); }
	}
	
	action setLeaveTime(int leave_time){
		ask event_m { do registerEvent(leave_time,myself);}
		status <- "waiting to leave road";
		last_leave_time <- leave_time;
	}

	action enterRoad{}
	
	action endTrip{}
	
	aspect default {
		draw square(1#px) color: #green border: #black depth: 1.0 ;
	}
	
}

