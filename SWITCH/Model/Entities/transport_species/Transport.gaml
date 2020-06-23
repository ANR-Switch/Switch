/**
* Name: Transport
* Based on the internal empty template. 
* Author: Lo�c
* Tags: 
*/
model SWITCH

import "../../logger.gaml"
import "Passenger.gaml"
import "../network_species/Road.gaml"
import "../EventManager.gaml"
import "../EventListener.gaml"

species Transport parent: EventListener{

	string transport_mode <- "transport";
	
	// maximum speed for a transport (km/h)
	float max_speed;

	// transport length (meters)
	float size;

	//passenger capacity 
	int max_passenger;

	//road graph available for the transport
	graph<Crossroad,Road> available_graph;
	
	string lastAction <- "none";

	//list of roads that lead to the target
	list<Road> path_to_target;
	string listactions <- "";
	string listEvent <- "";
	string listEventManager <- "";

	bool jammed_road <- false;
	float last_entering_road <- time;
	float time_in_jams <- 0.0;
	float practical_trip_time <- 0.0;
	float theoric_trip_time <- 0.0;
	
	//******* /!\ TESTING ATTRIBUTES and ACTION **********
	bool test_mode <- false;
	float traveled_dist <- 0.0;

	action addPointReachedEndRoad(float time_){
		traveled_dist <- traveled_dist + getCurrentRoad().size;
		if (length(logger) >0) {
			ask logger {
				do add_transport_data(myself, time_, myself.traveled_dist);
			}
		}
	}

	action addPointEnterRoad(float time_){
		if (length(logger) >0) {
			ask logger {
				do add_transport_data(myself, time_, myself.traveled_dist);
			}
		}
	}
	//****************************************************

	action setSignal (float signal_time, string signal_type) {
		switch signal_type {
			match "enter road" {
			//if we are leaving a road by entering another the transports averts the first road 
				if test_mode { do addPointEnterRoad(signal_time); }
				do changeRoad(signal_time);
				do updatePassengerPosition();
			}
			match "First in queue" {
				listactions <- listactions + " " + signal_time + " First in Queue " + hasNextRoad() + " (" + path_to_target + ")\n";
				if hasNextRoad() {
					do sendEnterRequest(signal_time);
				} else {
				//the transport is arrived
					listactions <- listactions + " " + signal_time + " There is no next road (" + path_to_target + ")\n";
					if jammed_road {
						time_in_jams <- time_in_jams + (signal_time - last_entering_road);
					}
					practical_trip_time <- practical_trip_time + (signal_time - last_entering_road);
					theoric_trip_time <- theoric_trip_time + get_freeflow_travel_time(getCurrentRoad());
					if getCurrentRoad() != nil{
						ask getCurrentRoad() {
							do leave(myself, signal_time);
						}
					}
					do endTrip();
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
			if jammed_road {
				time_in_jams <- time_in_jams + (signal_time - last_entering_road);
			}
			practical_trip_time <- practical_trip_time + (signal_time - last_entering_road);
			theoric_trip_time <- theoric_trip_time + get_freeflow_travel_time(current);
			ask current {
				do leave(myself, signal_time);
			}
			traveled_dist <- traveled_dist + getCurrentRoad().size;
		}
		remove first(path_to_target) from: path_to_target;
		if (next != nil) {
			listactions <- listactions + " " + signal_time + " Queing " + next.name + " TravelTime:" + getRoadTravelTime(next) + " (" + path_to_target + ")\n";
			last_entering_road <- signal_time;
			jammed_road <- next.isJammed();
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
		ask EventManager {
			do registerEvent(entry_time, myself, "enter road");
		}

	}

	action setLeaveTime (float leave_time) {
		if test_mode { do addPointReachedEndRoad; }
		listEvent <- listEvent + " " + leave_time + " First In queue/ ";
		ask EventManager {
			do registerEvent(leave_time, myself, "First in queue");
		}

	}

	// compute the travel of incoming transports
	// The formula used is BPR equilibrium formula
	float getRoadTravelTime (Road r) {
		float free_flow_travel_time <- get_freeflow_travel_time(r);
		float travel_time <- free_flow_travel_time * (1.0 + 0.15 * r.occupation_ratio ^ 4);
		return travel_time with_precision 3;
	}
	
	//compute the free_flow travel time depending on the max speed allowed on the road and the max speed of the transport
	float get_freeflow_travel_time(Road r){
		float max_freeflow_speed <- min([self.max_speed, r.avg_speed]) #km / #h;
		return r.size / max_freeflow_speed;
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
		if length(path_to_target)>0{
			return path_to_target[0];
		}else{
			return nil;
		}
	}

	action updatePassengerPosition{}
	
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

	action endTrip {
	//need to be redefined in each concrete transports
	}

	aspect default {
		draw square(1 #px) color: #green border: #black depth: 1.0;
	}

}

