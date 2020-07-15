/**
* Name: Passenger
* Based on the internal empty template. 
* Author: Nicolas
* Tags: 
*/


model SWITCH

import "Car.gaml"
import "../EventListener.gaml"
/* Insert your model definition here */
species Passenger parent: EventListener{
	Car current_car;
	Bike current_bike;
	Walk current_walk;
	
	point car_place;
	point bike_place;
	
	string status among: ["go to trip","passenger","driving","arrived","activity",nil];
	
	list<float> times_spent_in_jammed_roads <- [];
	
	list<float> times_spent_waiting_at_stations <- [];
	
	float last_start_time <- 0.0;
	float last_theoric_trip_time <- 0.0;
	float last_late_time <- 0.0;
	
	//times_in_transport =[string transport_type :: [float practical_travel_time :: float theoric_travel_time]]
	map<string,list<pair<float,float>>> times_in_transport <- [];
	
	action addTimeSpentInJams(float time_in_jams){
		times_spent_in_jammed_roads << time_in_jams;
	}
	
	action addStationWaitingTimes(float time_at_station){
		times_spent_waiting_at_stations << time_at_station;
	}
	
	action addTransportTravelTime(Transport t, float practical_travel_time, float theoric_travel_time){
		//write ""+ t +" executed its trip in " + practical_travel_time +"seconds instead of "+ theoric_travel_time+" seconds";
		if times_in_transport.keys contains t.transport_mode{
			times_in_transport[t.transport_mode] << practical_travel_time::theoric_travel_time;
		}else{
			times_in_transport[t.transport_mode] <- [practical_travel_time::theoric_travel_time];
		}
	}
	
	action setSignal (float signal_time, string signal_type) virtual:true;
}
