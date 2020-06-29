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
		location <- Station(trip_description[0][2]).location;
		station_target <- Station(trip_description[0][2]);
		do collectPassenger(station_target);
		station_departure <- station_target;
		remove trip_description[0] from: trip_description;
		station_target <- Station(trip_description[0][2]);
		available_graph <- road_network_;
		path the_path <- path_between(available_graph, location, station_target.location);
		if (the_path = nil) {
			write "ERROR Public transport "+ trip_id +" teleported from "+station_departure.name+" to "+station_target.name color:#red;
			do endTrip;
		} else {
			path_to_target <- list<Road>(the_path.edges);			
			add nil to: path_to_target at: 0;
			write "send enter request start";
			do sendEnterRequest(start_time);
		}
	}
	
	action joinNextStation(float start_time){
		write "join next station";
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
			match "collect"{
				write "trip "+trip_id+" collecting station "+station_target.name+" à "+date(starting_date + signal_time);
				do collectPassenger(station_target);
				do joinNextStation (signal_time);
			}
		}
		
	}
	
	action endTrip{
		write " bus "+trip_id+" endtrip";
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
			write "die";
			do die;
		}else{
			//there is at least one more station in the trip so we create an event to collect the current station
			//and join the next one
			float collect_time <- date(trip_description[0][1]) - current_date;
			ask EventManager{
				write "register collect event at " + date(starting_date+time+collect_time);
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

