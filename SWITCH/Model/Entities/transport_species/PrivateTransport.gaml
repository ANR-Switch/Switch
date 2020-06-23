/**
* Name: PrivateTransport
* Based on the internal empty template. 
* Author: Lo�c
* Tags: 
*/
model SWITCH

import "Transport.gaml"
species PrivateTransport parent: Transport {

	//the target position, final destination of the trip
	point pos_target;
	
	//passengers present in the transport
	// the fisrt passenger of the list is considered as the driver
	list<Passenger> passengers <- [];
	
	action getIn (list<Passenger> passengers_) {
		int nb_passenger <- min([length(passengers_), max_passenger]);
		if nb_passenger > 0 {
			loop i from: 0 to: nb_passenger - 1 {
				passengers << passengers_[i];
				passengers_[i].status <- i = 0 ? "driving" : "passenger";
			}
		}
	}

	action start (point start_location, point end_location,graph<Crossroad,Road> road_network, float start_time) {
		location <- start_location;
		pos_target <- end_location;
		available_graph <- road_network;
		path the_path <- path_between(available_graph, location, pos_target);
		if (the_path = nil) {
			write "PATH NIL //// TELEPORTATION ACTIVEEE !!!!!!";
			do endTrip;
		} else {
			path_to_target <- list<Road>(the_path.edges);			
			add nil to: path_to_target at: 0;
			do sendEnterRequest(start_time);
		}
	}

	action updatePassengerPosition{
		loop passenger over: passengers{
			passenger.location <- getCurrentRoad().start_node.location;
		}	
	}
	
	action endTrip virtual:true;
	
	aspect default {
		draw square(1 #px) color: #green border: #black;
	}

}

