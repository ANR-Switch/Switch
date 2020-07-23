/***
* Name: Individual
* Author: admin_ptaillandie
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model SWITCH

import "../Global.gaml"
import "../Parameters.gaml"
import "../Constants.gaml"
import "network_species/Building.gaml"
import "transport_species/Car.gaml"
import "transport_species/Bike.gaml"
import "network_species/stations_species/StationBus.gaml"



species Individual parent:Passenger{
	
	
	list<list> day_agenda;

	predicate current_activity;
	predicate waiting_activity;
	
	bool joining_activity;
	
	point work_place;
	point home_place;
	point school_place;
	point shopping_place;
	point leisure_place;
	
	map<predicate,list<pair<float,float>>> times_to_join_activity <- [];
	map<predicate,list<pair<float,float>>> times_spent_in_activity <- [];
	
	//the trip the individual has to follow to join the activity
	//transport_trip [[string tp_mode, point start_pos, point target_pos]]
	// tp_mode in [
	list<list> transport_trip;
	int trip_pointer <- 0;
	
	rgb color;
	
	string prefered_transport_mode;
	
	init{
		current_activity <- staying_at_home;
		color <- colors_per_act[current_activity];
	}
	
	bool has_car{
		return not (car_place = nil);
	}
	
	bool has_bike{
		return not (bike_place = nil);
	}
	
	action registerNextActivity{
		if length(day_agenda) > 0{
			ask EventManager{
				do registerEvent(float(myself.day_agenda[0][1]), myself, myself.day_agenda[0][0]);
			}	
		}
	}
	
	action setSignal (float signal_time, string signal_type){
		switch signal_type{
			match "working"{
				if not joining_activity{
					current_activity <- working;
					do compute_transport_trip(work_place);
					last_start_time <- signal_time;
					do executeTripPlan(signal_time);
				}else{
					waiting_activity <- working;
				}
			}
			match "eating"{
				if not joining_activity{
					current_activity <- eating;
					do compute_transport_trip(home_place);
					do executeTripPlan(signal_time);
				}else{
					waiting_activity <- eating;
				}
			}
			match "staying at home"{
				if not joining_activity{
					current_activity <- staying_at_home;
					do compute_transport_trip(home_place);
					do executeTripPlan(signal_time);
				}else{
					waiting_activity <- staying_at_home;
				}
			}
			match "leisure"{
				if not joining_activity{
					current_activity <- leisure;
					do compute_transport_trip(leisure_place);
					do executeTripPlan(signal_time);
				}else{
					waiting_activity <- leisure;
				}
			}
			match "studying"{
				if not joining_activity{
					current_activity <- studying;
					do compute_transport_trip(school_place);
					do executeTripPlan(signal_time);
				}else{
					waiting_activity <- studying;
				}
			}
			match "manage kid"{
				if not joining_activity{
					current_activity <- manage_kid;
					do compute_transport_trip(school_place);
					do executeTripPlan(signal_time);
				}else{
					waiting_activity <- manage_kid;
				}
			}
			match "shopping"{
				if not joining_activity{
					current_activity <- shopping;
					do compute_transport_trip(shopping_place);
					do executeTripPlan(signal_time);
				}else{
					waiting_activity <- shopping;
				}
			}
			match "arrived"{
				remove transport_trip[0] from: transport_trip;
				if length(transport_trip) = 0 {
					color <- colors_per_act[current_activity];
					remove day_agenda[0] from: day_agenda;
					if waiting_activity != nil{
						waiting_activity <- nil;
						joining_activity <- false;
						do setSignal(signal_time, waiting_activity.name);
					}else{
						do registerNextActivity;
					}
				}else{
					do executeTripPlan(signal_time);
				}
			}
			match "passenger"{
				if time_start_waiting_at_station > 0 {
					ask logger[0]{
						do addStationWaiting(signal_time,time-myself.time_start_waiting_at_station);
					}
					time_start_waiting_at_station <- -1.0;
				}
			}
			match "transport full"{
				write "transport full";
				if time_start_waiting_at_station > 0 {
					ask logger[0]{
						do addStationWaiting(signal_time,time-myself.time_start_waiting_at_station);
					}
					time_start_waiting_at_station <- time;
				}
			}
		}
	}
	
	//compute a trip acording to priority and target
	action compute_transport_trip(point target_){
		transport_trip <- [];
		switch prefered_transport_mode {
			match "car"{
				transport_trip << ["walk",location, car_place];
				point target_parking <- any_location_in(Road closest_to target_);
				transport_trip << ["car",car_place,target_parking];
				transport_trip << ["walk",target_parking,target_];
			}
			
			match "bike"{
				transport_trip << ["walk",location, bike_place];
				point target_parking <- any_location_in(Road closest_to target_);
				transport_trip << ["bike",bike_place,target_parking];
				transport_trip << ["walk",target_parking,target_];
			}
			
			match "bus"{
				StationBus end_station <- closest_to(StationBus,target_);
				list<TransportLine> tp_lines <- end_station.lines;
				list<StationBus> linked_stations <- [];
				loop line over: tp_lines{
					linked_stations <- linked_stations union list<StationBus>(line.served_stations);
				}
				StationBus start_station <- closest_to(linked_stations,location);
				transport_trip << ["walk",location, start_station.location];
				transport_trip << ["bus",start_station, end_station];
				transport_trip << ["walk",end_station.location, target_];
			}
			
			match "walk"{
				transport_trip << ["walk",location, target_];
			}
			
		}
		trip_pointer <- 0;
		ask world {do write_message(myself.name + " - transport trip: " + myself.transport_trip);}
	}

	action executeTripPlan(float excution_time){
		color <- colors_per_mobility_mode[string(transport_trip[0][0])];
		joining_activity <- false;
		switch transport_trip[0][0]{
			match "car"{
				do useCar([self], transport_trip[0][2]);
			}
			
			match "bike"{
				do useBike([self], transport_trip[0][2]);
			}
			
			match "bus"{
				time_start_waiting_at_station <- excution_time;
				ask StationBus(transport_trip[0][1]){
					StationBus destination <- StationBus(myself.transport_trip[0][2]);
					TransportLine line <- inter(self.lines, destination.lines)[0];
					do waitAtStation(myself,line.id,destination);
				}
			}
			
			match "walk"{
				do useWalk([self], transport_trip[0][2]);
			}
		}
	}

	
	action useCar(list<Individual> passengers_, point pos_target_){
		ask world {do write_message(myself.name + " - drive: location" + myself.location + " target: "+ pos_target_);}
		if (current_car = nil) {
			current_car <- world.createCar(self.location,pos_target_,passengers_, time);
		}
	}
	
	action useBike(list<Individual> passengers_, point pos_target_){
		if (current_bike = nil) {
			current_bike <- world.createBike(self.location,pos_target_,passengers_, time);
		}
	}
	
	action useWalk( list<Individual> passengers_, point pos_target_){
		if (current_walk = nil) {
			current_walk <- world.createWalk(self.location,pos_target_,passengers_, time);
		}
	}
	
	aspect default {
		draw circle(5) color: color border: #black;
	}	
		
}