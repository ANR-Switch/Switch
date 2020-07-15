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
	
	
	list<list<list>> week_agenda <-
	 [copy(agenda_work),
	  copy(agenda_work),
	  copy(agenda_work),
	  copy(agenda_work_then_leisure),
	  copy(agenda_work),
	  copy(agenda_leisure),
	  copy(agenda_leisure)];
	list<list> day_agenda;

	predicate current_activity;
	predicate waiting_activity;
	
	bool joining_activity;
	
	Building work_building;
	Building home_building;
	
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
		do FillTodayAgenda;
		do registerNextActivity;
		switch rnd(1.0){
			match_between [0.0,0.8]{prefered_transport_mode <- "car";}
			//match_between [0.6,0.8]{prefered_transport_mode <- "bus";}
			match_between [0.8,0.9]{prefered_transport_mode <- "bike";}
			match_between [0.9,1.0]{prefered_transport_mode <- "walk";}
		}
	}
	
	bool has_car{
		return not (car_place = nil);
	}
	
	bool has_bike{
		return not (bike_place = nil);
	}
	
	/*action RegisterTodayAgendaEvent{
		int day_of_week <- world.date2day(current_date);
		loop activity over: week_agenda[day_of_week]{
			float time_diff <- world.hour2date(activity[0]) - current_date;
			//here we generate a random number of seconds to add or substract to the activity time so
			//the individuals don't start the same activity at the same time
			float time_distribution <- rnd(-1200.0,1200.0);
			ask EventManager{
				do registerEvent(time + time_diff + time_distribution, myself, activity[1]);
			}
		}
	}*/
	
	action FillTodayAgenda{
		int day_of_week <- world.date2day(current_date);
		day_agenda <- week_agenda[day_of_week];
	}
	
	action registerNextActivity{
		if length(day_agenda) > 0{
			float time_diff <- world.hour2date(day_agenda[0][0]) - current_date;
			//here we generate a random number of seconds to add or substract to the activity time so
			//the individuals don't start the activities at the same time
			float time_distribution <- rnd(-1800.0,1800.0);
			ask EventManager{
				do registerEvent(time + time_diff + time_distribution, myself, myself.day_agenda[0][1]);
			}	
		}
	}
	
	action setSignal (float signal_time, string signal_type){
		switch signal_type{
			match "working"{
				if not joining_activity{
					current_activity <- working;
					do compute_transport_trip(any_location_in(work_building.location));
					last_start_time <- signal_time;
					do executeTripPlan;
				}else{
					waiting_activity <- working;
				}
			}
			match "eating"{
				if not joining_activity{
					current_activity <- eating;
					do compute_transport_trip(any_location_in(home_building.location));
					do executeTripPlan;
				}else{
					waiting_activity <- eating;
				}
			}
			match "staying at home"{
				if not joining_activity{
					current_activity <- staying_at_home;
					do compute_transport_trip(any_location_in(home_building.location));
					do executeTripPlan;
				}else{
					waiting_activity <- staying_at_home;
				}
			}
			match "leisure"{
				if not joining_activity{
					current_activity <- leisure;
					do compute_transport_trip(one_of(Building).location);
					do executeTripPlan;
				}else{
					waiting_activity <- leisure;
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
					do executeTripPlan;
				}
			}
			match "passenger"{}
			match "transport full"{}
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

	action executeTripPlan{
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