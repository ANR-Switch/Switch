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

species Transport parent: EventListener virtual: true{
	
	string transport_mode <- "transport";
	
	// maximum speed for a transport (km/h)
	float max_speed;

	// transport length (meters)
	float size;

	//passenger capacity 
	int max_passenger;
	
	//the target position, final destination of the trip
	point pos_target;

	//road graph available for the transport
	graph<Crossroad,Road> available_graph;
	
	string lastAction <- "none";

	//list of roads that lead to the target
	list<Road> path_to_target;
	
	//***********metrics about the trip*****************
	float last_entry_time <- 0.0;
	//theoric_trip_time is the cumulated trip time at free flow speed
	float theoric_trip_time <- 0.0;
	//actual_trip_time is the cumulated real trip_time 
	float actual_trip_time <- 0.0;
	//actual_trip_distance is the cumulated distance achieved by this transport 
	float actual_trip_distance <- 0.0;
	// jam_time is the cumulated trip time spend in jammed roads
	float jam_time <- 0.0;
	bool road_was_jammed <- false;
	//*************************************************

	action setSignal (float signal_time, string signal_type) {
		switch signal_type {
			match "enter road" {
				//if we are leaving a road by entering another the transports warns the first road 
				do changeRoad(signal_time);
				do updatePassengerPosition();
			}
			match "First in queue" {
				if hasNextRoad() {
					do sendEnterRequest(signal_time);
				} else {
				//the transport is arrived
					if getCurrentRoad() != nil{
						actual_trip_time <- actual_trip_time + signal_time - last_entry_time;
						actual_trip_distance <- actual_trip_distance + getCurrentRoad().size;
						jam_time <- road_was_jammed ? jam_time + signal_time - last_entry_time : jam_time;
						ask getCurrentRoad() {
							do leave(myself, signal_time);
						}
					}
					do endTrip(signal_time);
				}
			}
		}
	}

	action changeRoad (float signal_time) {
		Road current <- getCurrentRoad();
		Road next <- getNextRoad();
		if current != nil {
			actual_trip_time <- actual_trip_time + signal_time - last_entry_time;
			actual_trip_distance <- actual_trip_distance + current.size;
			ask current {
				do leave(myself, signal_time);
			}
		}
		remove first(path_to_target) from: path_to_target;
		if (next != nil) {
			last_entry_time <- signal_time;
			theoric_trip_time <- theoric_trip_time + get_freeflow_travel_time(next);
			road_was_jammed <- next.is_jammed;
			ask next {
				do queueInRoad(myself, signal_time);
			}
		}
	}

	//the parameter should point toward the next road in path_to_target
	action sendEnterRequest (float request_time) {
		if (hasNextRoad()) {
			ask getNextRoad() {
				do enterRequest(myself, request_time);
			}
		}
	}

	action setEntryTime (float entry_time) {
		ask EventManager {
			do registerEvent(entry_time, myself, "enter road");
		}

	}

	action setLeaveTime (float leave_time) {
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
		if(r != nil){
			float max_freeflow_speed <- min([self.max_speed, r.avg_speed]) #km / #h;
			return r.size / max_freeflow_speed;
		}else{
			return distance_to(location,pos_target)/self.max_speed;
		}
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
	
	action registerDataInfo(float add_time){
		ask logger[0]{
			if myself.actual_trip_time > 0{
				do addDelayTime(myself.transport_mode,add_time,myself.actual_trip_time - myself.theoric_trip_time);
				do addSpeed(myself.transport_mode,add_time,(myself.actual_trip_distance/myself.actual_trip_time)*3.6);
			}
			
		}
	}
	
	action updatePassengerPosition virtual: true;

	action endTrip(float arrived_time) virtual:true;

	aspect default {
		draw square(1 #px) color: #green border: #black depth: 1.0;
	}

}

