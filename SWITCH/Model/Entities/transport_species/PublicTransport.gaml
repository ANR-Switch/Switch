/**
* Name: PublicTransport
* Based on the internal empty template. 
* Author: Lo�c
* Tags: 
*/


model SWITCH

import "Transport.gaml"
import "../network_species/stations_species/Station.gaml"

species PublicTransport parent: Transport {
	
	string transportLine_id;
	//list<list> = [[int arrival_time, int departure_time, Station station_to_collect]]
	list<list> trip_description <- [];
	
	map<Station,list<Passenger>> passengers <- [];
	int nb_passenger <- 0;
	
	Station station_target;
	
	action start (point start_location, graph<Crossroad,Road> road_network_, float start_time) {
		location <- start_location;
		station_target <- Station(trip_description[0][2]);
		available_graph <- road_network_;
		path the_path <- path_between(available_graph, location, station_target.location);
		if (the_path = nil) {
			write "ERROR Public transport teleported" color:#red;
			do endTrip;
		} else {
			path_to_target <- list<Road>(the_path.edges);			
			add nil to: path_to_target at: 0;
			do sendEnterRequest(start_time);
		}
	}
	
	action setSignal (float signal_time, string signal_type) {
		invoke setSignal(signal_time, signal_type);
		switch signal_type{
			match "collect"{
				do collectPassenger(station_target);
				remove trip_description[0] from: trip_description;
				do start(location, available_graph, signal_time);
			}
		}
		
	}
	
	action endTrip{
		location <- station_target.location;
		if passengers[Station(trip_description[0][2])] != nil{
			loop passenger over: passengers[Station(trip_description[0][2])]{
				passenger.status <- "arrived";
				passenger.location <- location;
				nb_passenger <- nb_passenger -1;
			}
			passengers[Station(trip_description[0][2])] <- [];
		}
		if length(trip_description) <=1 {
			// the transport arrived at the last station and has already drop the passenger
			do die;
		}else{
			//there is at least one more station in the trip so we create an event to collect the current station
			//and join the next one
			float collect_time <- date(trip_description[0][1]) - current_date;
			ask EventManager{
				do registerEvent(time + collect_time, myself,"collect");
			}
		}
	}
	
	action collectPassenger(Station station_target_){
		ask station_target_{
			if waiting_passengers[myself.transportLine_id] != nil{
				list<pair<Passenger,Station>> remaining_passenger <- [];
				loop passenger over: waiting_passengers[myself.transportLine_id]{
					Passenger p  <- passenger.key;
					Station destination <- passenger.value;
					if myself.nb_passenger < myself.max_passenger {
						if myself.passengers[destination] !=nil {
							myself.passengers[destination] << p;
						}else{
							myself.passengers[destination] <- [p];
						}
						p.status <- "passenger";
						myself.nb_passenger <- myself.nb_passenger + 1;
					}else{
						remaining_passenger << p::destination;
						p.status <- "transport full";
					}
				}
				waiting_passengers[myself.transportLine_id] <- remaining_passenger;
			}	
		}
	}
	
	action updatePassengerPosition{
		location <- getCurrentRoad().start_node.location;
		loop station over: passengers.keys{
			loop passenger over: passengers[station]{
				passenger.location <- getCurrentRoad().start_node.location;
			}
		}	
	}
	
	aspect default {
		draw square(15) color: #red border: #black;
	}
	
}

