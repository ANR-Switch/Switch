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
	
	string trip_id;
	string transportLine_id;
	//list<list> = [[date arrival_time, date departure_time, Station station_to_collect]]
	list<list> trip_description <- [];
	
	map<Station,list<Passenger>> passengers <- [];
	int nb_passenger <- 0;
	
	Station station_departure;
	Station station_target;
	
	action start (graph<Crossroad,Road> road_network_, float start_time) {
		station_departure <- Station(trip_description[0][2]);
		location <- station_departure.location;
		station_target <- Station(trip_description[0][2]);
		do collectPassenger(station_target, start_time);
		station_departure <- station_target;
		remove trip_description[0] from: trip_description;
		station_target <- Station(trip_description[0][2]);
		available_graph <- road_network_;
		path the_path <- path_between(available_graph, station_departure.location, station_target.location);
		if (the_path = nil) {
			write "ERROR Public transport "+ trip_id +" teleported from "+station_departure.name+" to "+station_target.name color:#red;
			do endTrip;
		} else {
			path_to_target <- list<Road>(the_path.edges);			
			add nil to: path_to_target at: 0;
			do sendEnterRequest(start_time);
		}
		
	}
	
	action joinNextStation(float start_time){
		float exec_start_time <- machine_time;
		station_departure <- station_target;
		remove trip_description[0] from: trip_description;
		station_target <- Station(trip_description[0][2]);
		path the_path <- path_between(available_graph, location, station_target.location);
		if (the_path = nil) {
			write "ERROR Public transport "+ trip_id +" teleported from "+station_departure.name+" to "+station_target.name color:#red;
			do endTrip;
		} else {
			path_to_target <- list<Road>(the_path.edges);			
			add nil to: path_to_target at: 0;
			do sendEnterRequest(start_time);
		}
	}
	
	action setSignal (float signal_time, string signal_type) {
		invoke setSignal(signal_time,signal_type);
		switch signal_type {
			match "collect"{
				//write "trip "+trip_id+" collecting station "+station_target.name+" at "+date(starting_date + signal_time);
				do collectPassenger(station_target, signal_time);
				do joinNextStation (signal_time);
			}
		}
		
	}
	
	action endTrip(float arrived_time){
		//write " bus "+trip_id+" endtrip";
		location <- station_target.location;
		if passengers[Station(trip_description[0][2])] != nil{
			loop passenger over: passengers[Station(trip_description[0][2])]{
				ask passenger{ do setSignal(arrived_time, "arrived");}
				passenger.location <- location;
				nb_passenger <- nb_passenger -1;
			}
			passengers[Station(trip_description[0][2])] <- [];
		}
		if length(trip_description) <=1 {
			// the transport arrived at the last station and has already drop the passenger
			do registerDataInfo;
			do die;
		}else{
			//there is at least one more station in the trip so we create an event to collect the current station
			//and join the next one
			float collect_time <- date(trip_description[0][1]) - current_date;
			ask EventManager{
				//write "register collect event at " + date(starting_date+time+collect_time);
				do registerEvent(time + collect_time, myself,"collect");
			}
		}
		
	}
	
	action collectPassenger(Station station_target_, float collect_time){
		ask station_target_{
			if waiting_passengers[myself.transportLine_id] != nil{
				list<list> remaining_passenger <- [];
				//write waiting_passengers[myself.transportLine_id];
				loop passenger over: waiting_passengers[myself.transportLine_id]{
					Passenger p  <- Passenger(passenger[0]);
					Station destination <- Station(passenger[1]);
					if myself.nb_passenger < myself.max_passenger {
						if myself.passengers[destination] !=nil {
							myself.passengers[destination] << p;
						}else{
							myself.passengers[destination] <- [p];
						}
						ask p{ do setSignal(collect_time, "passenger");}
						myself.nb_passenger <- myself.nb_passenger + 1;
					}else{
						remaining_passenger << [p,destination];
						ask p{ do setSignal(collect_time, "transport full");}
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

