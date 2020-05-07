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
	float maxspeed;
	
	//number of motorized vehicule lane in this road
	int nb_lanes;
	
	//is the road is oneway or not
	string oneway;
	
	//maximum space capacity of the road (in meters)
	float max_capacity <- shape.perimeter * nb_lanes;
	
	//actual free space capacity of the road (in meters)
	float current_capacity <- max_capacity;
	
	//has_bike_lane = true if there is a specific lane for bikes in this road
	//				= false if not
	bool has_bike_lane <- false;
	
	//list of current vehicules present in the road
	list<Bike> present_bikes;
	list<Transport> present_transports;
	
	action getBikeInRoad(Bike b){
		if not has_bike_lane {
			current_capacity <- current_capacity - b.size;
		}	
		present_bikes <- present_bikes + [b];
	}
	
	action getInRoad(Transport t){
		current_capacity <- current_capacity - t.size;
		present_transports <- present_transports + [t];
	}
	
	
	aspect default {
		draw shape color: #gray end_arrow: 5;
	} 
}
