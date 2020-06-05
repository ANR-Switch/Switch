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
species Transport skills: [moving] {

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
	string lastAction <- "none";

	//list of roads that lead to the target
	list<Road> path_to_target;
	string listactions <- "";
	
	string listEvent <-"";
	
	string listEventManager <-"";

	//******* /!\ TESTING ATTRIBUTES and ACTION **********
	string test_target;
	bool already_reached_end_road <- false;
	float traveled_dist <- 0.0;

	action addPointReachedEndRoad {
		traveled_dist <- traveled_dist + getCurrentRoad().size;
		if (the_logger != nil) {
			ask the_logger {
				do add_data(myself.test_target, myself.name, myself.traveled_dist);
			}

		}

	}

	action addPointEnterRoad {
		already_reached_end_road <- false;
		if (the_logger != nil) {
			ask the_logger {
				do add_data(myself.test_target, myself.name, myself.traveled_dist);
			}

		}

	}
	//****************************************************
	action setSignal (float signal_time, string signal_type) {
		switch signal_type {
			match "enter road" {
				//if we are leaving a road by entering another the transports averts the first road 
				do changeRoad(signal_time);
			}

			match "First in queue" {
				listactions <- listactions + " " + signal_time + " First in Queue " + hasNextRoad() + " (" + path_to_target + ")\n";
				if hasNextRoad() {
					do sendEnterRequest(signal_time);
				} else {
					//the transport is arrived
					listactions <- listactions + " " + signal_time + " There is no next road (" + path_to_target + ")\n";
					ask getCurrentRoad() {
						do leave(myself, signal_time);
					}
					do endTrip;
				}
				lastAction <- "First in queue";
			}
		}
	}

	action changeRoad (float signal_time) {
		Road current <- getCurrentRoad();
		Road next <- getNextRoad();
		if current != nil {
			listactions <- listactions + " " + signal_time + " Leaving " + current.name + "(" + path_to_target + ")\n";
			ask current {
				do leave(myself, signal_time);
			}
			traveled_dist <- traveled_dist + getCurrentRoad().size;
		}
		remove first(path_to_target) from: path_to_target;
		if (next != nil) {
			listactions <- listactions + " " + signal_time + " Queing " + next.name + " TravelTime:" + getRoadTravelTime(next) + " (" + path_to_target + ")\n";
			ask next {
				do queueInRoad(myself, signal_time);
			}

		} else {
			listactions <- listactions + " " + signal_time + " Queing " + next.name + " End of the road " + " (" + path_to_target + ")\n";
		}

	}

	//the parameter should point toward the next road in path_to_target
	action sendEnterRequest (float request_time) {
		if (hasNextRoad()) {
			listactions <- listactions + " " + request_time + " Enter request " + getNextRoad().name + "(" + path_to_target + ")\n";
			ask getNextRoad() {
				do enterRequest(myself, request_time);
			}
		}

	}

	action setEntryTime (float entry_time) {
		listEvent <- listEvent + " " + entry_time + " Enter road/ ";
		ask event_m {
			do registerEvent(entry_time, myself, "enter road");
		}

	}

	action setLeaveTime (float leave_time) {
		listEvent <- listEvent + " " + leave_time + " First In queue/ ";
		ask event_m {
			do registerEvent(leave_time, myself, "First in queue");
		}

	}

	// compute the travel of incoming transports
	// The formula used is BPR equilibrium formula
	float getRoadTravelTime(Road r){
		float max_speed_formula <- max([speed,r.max_speed]) #km/#h;
		float free_flow_travel_time <- r.size/max_speed_formula;
		float travel_time <- free_flow_travel_time *  (1.0 + 0.15 * ((r.max_capacity-r.current_capacity)/r.max_capacity)^4);
		return travel_time with_precision 3;
	}

	bool hasNextRoad {
		return length(path_to_target) > 1;
	}

	Road getNextRoad {
		if (hasNextRoad()) {
			return path_to_target[1];
		} else {
			return nil;
		}
	}

	Road getCurrentRoad {
		return path_to_target[0];
	}

	//this function return a convenient string corresponding to a time (in second)
	string timestamp (float time_to_print) {
		int nb_heure <- floor(time_to_print / 3600);
		int nb_min <- floor((time_to_print - nb_heure * 3600) / 60);
		int nb_sec <- floor(time_to_print - nb_heure * 3600 - nb_min * 60);
		string buff <- "";
		if nb_heure < 10 {
			buff <- buff + "0";
		}

		buff <- buff + nb_heure + "h";
		if nb_min < 10 {
			buff <- buff + "0";
		}

		buff <- buff + nb_min + "m";
		if nb_sec < 10 {
			buff <- buff + "0";
		}

		return buff + nb_sec + "s";
	}

	action endTrip {}

	aspect default {
		draw square(1 #px) color: #green border: #black depth: 1.0;
	}

}

