/***
* Name: Individual
* Author: admin_ptaillandie
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model SWITCH

import "Crossroad.gaml"
import "../transport_species/Transport.gaml"
import "../transport_species/Bike.gaml"

species Road {
	
	//type of road (the OpenStreetMap highway feature: https://wiki.openstreetmap.org/wiki/Map_Features)
	string type;
	
	//is roundabout or not (OSM information)
	string junction;
	
	//start crossroad node
	Crossroad start_node;
	
	//end crossroad node
	Crossroad end_node;
	
	//maximum legal speed on this road
	float max_speed;
	
	//number of motorized vehicule lane in this road
	int nb_lanes <- 1;
	
	//is the road is oneway or not
	string oneway;
	
	//length of the road (in meters)
	float size <- shape.perimeter;
	
	//maximum space capacity of the road (in meters)
	float max_capacity <- size * nb_lanes min: 10.0;
	
	//actual free space capacity of the road (in meters)
	float current_capacity <- max_capacity;
	
	//has_bike_lane = true if there is a specific lane for bikes in this road
	//				= false if not
	bool has_bike_lane <- false;
	
	//list of current vehicules present in the road [[time_to_leave,Transport]]
	list<list> present_bikes;
	list<list> present_transports;
	
	// if there is a bike lane, bikes don't consume road capacity
	action queueInRoad(Bike b){
		if not has_bike_lane {
			current_capacity <- current_capacity - b.size;
		}
		present_bikes << [time+getRoadTravelTime(b),b];
		ask b{ road_pointer <- road_pointer +1; }
	}
	
	action queueInRoad(Transport t){
		write "entering a road";
		current_capacity <- current_capacity - t.size;
		present_transports << [time+getRoadTravelTime(t),t];
		ask t{ road_pointer <- road_pointer +1; }
	}
	
	bool canAcceptTransport(Transport t){
		return current_capacity > t.size;
	}
	
	reflex dequeueFromRoad when: not empty(present_transports) and (float(present_transports[0][0]) <= time){
		write "leaving a road";
		Transport t <- Transport(present_transports[0][1]);
		float time_to_leave <- float(present_transports[0][0]);
		bool nextRoadOk <- t.nextRoad.canAcceptTransport(t);
		// this loop help to free space easily if more than one transport could arrived at the end of the road
		// during the time step
		loop while: not empty(present_transports) and (time_to_leave<=time) and nextRoadOk{
			ask t.nextRoad { do queueInRoad(t); }
			// free leaving transport space in the road
			current_capacity <- current_capacity + t.size;
			//remove transport from the road
			present_transports <- copy_between(present_transports, 1,length(present_transports));
			//checking if the next Transport can also join the next road
			t <- Transport(present_transports[0][1]);
			time_to_leave <- float(present_transports[0][0]);
			nextRoadOk <- t.nextRoad.canAcceptTransport(t);
		}
	}
	
	reflex dequeueBikeFromRoad when: not empty(present_bikes) and (float(present_bikes[0][0]) <= time){
		// here we're not checking nextRoad capacity because we assume that even if there is jam (max capacity reached)
		// bikes can find a way in the road
		Bike b <- Bike(present_bikes[0][1]);
		float time_to_leave <- float(present_bikes[0][0]);
		loop while: not empty(present_bikes) and (time_to_leave <= time){
			ask b.nextRoad { do queueInRoad(b); }
			if not has_bike_lane {
				current_capacity <- current_capacity + b.size;
			}
			//remove transport from the road
			present_bikes <- copy_between(present_bikes, 1,length(present_bikes));
		}
	}
	
	// compute the travel of incoming transports
	// The formula used is BPR equilibrium formula
	float getRoadTravelTime(Transport t){
		float max_speed_formula <- max([t.speed,max_speed]) #m/#sec;
		float free_flow_travel_time <- size/max_speed_formula;
		// here the capacity is in meters so the traffic flow is defined by the quantity of vehicule
		// (in meters) that can pass trough the road in a step duration
		float vehicule_flow <- max_speed_formula * (step #sec);
		float capacity_ratio <- current_capacity / max_capacity;
		float travel_time <- free_flow_travel_time *  (1.0 + 0.15 * (vehicule_flow/capacity_ratio)^4);
		return travel_time;
	}
	
	aspect default {
		rgb road_color <- #gray;
		if current_capacity != max_capacity {road_color <- #red; }
		draw shape color: road_color end_arrow: 5;
	} 
	
	aspect roadTest {
		
		// Color of the road is determined according to current road occupation
		rgb color <- rgb(105,105,105,current_capacity/max_capacity);
		geometry geom_display <- (shape + (2.5));
		
		draw geom_display border:  #gray  color: color;
		
		draw ""+type+" - "+length(present_transports)+" PCU"  at: location+point([15,-5]) size:10 color:#black;
		
		// Display each vehicle in the queue according to their size and colored according to their time_to_leave
		// Warning : Their are currently display next to the starting node. They need to be drafted along the road.
		loop i from: 0 to: length (present_transports) - 1 { 
			Transport t <- Transport(present_transports[0][1]);
			float time_to_leave <- float(present_transports[0][0]);
			draw box(t.size, 1.5,1.5) at: location-(i*t.size)  color: rgb(time_to_leave);
		}
	} 
}
