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
	
	//start crossroad node
	Crossroad start_node;
	
	//end crossroad node
	Crossroad end_node;
	
	//maximum legal speed on this road
	float max_speed;
	
	//number of motorized vehicule lane in this road
	int nb_lanes;
	
	//is the road is oneway or not
	string oneway;
	
	//length of the road (in meters)
	float size <- shape.perimeter;
	
	//maximum space capacity of the road (in meters)
	float max_capacity <- size * nb_lanes;
	
	//actual free space capacity of the road (in meters)
	float current_capacity <- max_capacity;
	
	//has_bike_lane = true if there is a specific lane for bikes in this road
	//				= false if not
	bool has_bike_lane <- false;
	
	//list of current vehicules present in the road
	list<Bike> present_bikes;
	list<Transport> present_transports;
	
	// if there is a bike lane, bikes don't consume road capacity
	action getBikeInRoad(Bike b){
		if not has_bike_lane {
			current_capacity <- current_capacity - b.size;
		}	
		present_bikes << b;
	}
	
	action getInRoad(Transport t){
		current_capacity <- current_capacity - t.size;
		present_transports << t;
		t.speed <- getRoadSpeed(t);
	}
	
	bool canAcceptTransport(Transport t){
		return current_capacity > t.size;
	}
	
	reflex getOutRoad when: not empty(present_transports) and (present_transports[0].location = end_node.location){
		bool nextRoadOk <- present_transports[0].nextRoad.canAcceptTransport(present_transports[0]);
		loop while: not empty(present_transports) and (present_transports[0].location = end_node.location) and nextRoadOk{
			ask present_transports[0].nextRoad { do getInRoad(myself.present_transports[0]); }
			// free leaving transport space in the road
			current_capacity <- current_capacity + present_transports[0].size;
			//remove transport from the road
			present_transports <- copy_between(present_transports, 1,length(present_transports));
			//checking if the next Transport can also join the next road
			nextRoadOk <- present_transports[0].nextRoad.canAcceptTransport(present_transports[0]);
		}
	}
	
	reflex getBikeOutRoad when: present_bikes[0].location = end_node.location{
		loop while: present_bikes[0].location = end_node.location{
			ask present_bikes[0].nextRoad { do getBikeInRoad(myself.present_bikes[0]); }
			//remove transport from the road
			present_bikes <- copy_between(present_bikes, 1,length(present_bikes));
		}
	}
	
	// compute the real speed (km/h) of incoming transports
	// The formula used is BPR equilibrium formula
	float getRoadSpeed(Transport t){
		float formula_speed <- size / (size/(max_speed #m/#s)) * ( 1 + 0.15 * (current_capacity/max_capacity)^4);
		formula_speed <- formula_speed #km/#h;
		return max([t.max_speed, formula_speed]);
	}
	
	
	
	
	aspect default {
		draw shape color: #gray end_arrow: 5;
	} 
}
