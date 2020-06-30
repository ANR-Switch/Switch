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



species Individual skills: [moving] control:simple_bdi parent:Passenger{
	
	
	list<list<list>> week_agenda <-
	 [agenda_work,
	  agenda_work,
	  agenda_work,
	  agenda_work_then_leisure,
	  agenda_work,
	  agenda_leisure,
	  agenda_leisure];

	predicate current_activity;
	
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
	
	init{
		current_activity <- staying_at_home;
		color <- colors_per_act[current_activity];
		do RegisterTodayAgendaEvent;
	}
	
	bool has_car{
		return not (car_place = nil);
	}
	
	bool has_bike{
		return not (bike_place = nil);
	}
	
	action RegisterTodayAgendaEvent{
		int day_of_week <- world.date2day(current_date);
		loop activity over: week_agenda[day_of_week]{
			float time_diff <- world.hour2date(activity[0]) - current_date;
			//here we generrate a random number of seconds to add or substract to the activity time so
			//the individuals don't start the same activity at the same time
			float time_distribution <- rnd(-3600.0,3600.0);
			ask EventManager{
				do registerEvent(time + time_diff + time_distribution, myself, activity[1]);
			}
		}
	}
	
	action setSignal (float signal_time, string signal_type){
		switch signal_type{
			match "working"{
				current_activity <- working;
				do compute_transport_trip(work_building.location);
				do executeTripPlan;
			}
			match "eating"{
				current_activity <- eating;
				do compute_transport_trip(home_building.location);
				do executeTripPlan;
			}
			match "staying at home"{
				current_activity <- staying_at_home;
				do compute_transport_trip(home_building.location);
				do executeTripPlan;
			}
			match "leisure"{
				current_activity <- leisure;
				do compute_transport_trip(one_of(Building).location);
				do executeTripPlan;
			}
			match "arrived"{
				remove transport_trip[0] from: transport_trip;
				if length(transport_trip) = 0 {
					color <- colors_per_act[current_activity];
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
		switch one_of(["car","bike","bus","walk"]) {
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
		draw circle(5) color: color rotate: heading border: #black;
	}	
		
}