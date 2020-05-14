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
	float max_capacity <- size * nb_lanes min: 10;
	
	//actual free space capacity of the road (in meters)
	float current_capacity <- max_capacity;
	
	//has_bike_lane = true if there is a specific lane for bikes in this road
	//				= false if not
	bool has_bike_lane <- false;
	
	//list of current vehicules present in the road [[time_to_leave,Transport,target.location]]
	//Note that target.location store the location of car target if this road is the last road
	//if this road is not the trip car last road then target.location = nil
	list<list> present_bikes <- [];
    list<list> present_transports <- [];
    
    action init{
    	size <- shape.perimeter;
    	max_capacity <- size * nb_lanes;
    	current_capacity <- max_capacity;
    }
	
	// if there is a bike lane, bikes don't consume road capacity
	action queueInRoad(Bike b){
		if not has_bike_lane {
			current_capacity <- current_capacity - b.size;
		}
		present_bikes << [time+getRoadTravelTime(b),b];
		ask b{ road_pointer <- road_pointer +1; }
		point transport_target;
		ask b{ 
			do enterRoad(myself);
		}
		
		present_bikes << [time+getRoadTravelTime(b),b];
	}
	
	action queueInRoad(Transport t){
		current_capacity <- current_capacity - t.size;
		point transport_target;
		ask t{ 
			do enterRoad(myself);
		}
		present_transports << [time+getRoadTravelTime(t),t];
	}
	
	bool canAcceptTransport(Transport t){
		return current_capacity > t.size;
	}
	
	reflex dequeueFromRoad when: not empty(present_transports) and (float(present_transports[0][0]) <= time){
		do dequeue(present_transports);
	}
	
	reflex dequeueBikeFromRoad when: not empty(present_bikes) and (float(present_bikes[0][0]) <= time){
		do dequeue(present_bikes);
	}
	
	action dequeue(list<list> transportList){
		int count <- 0;
		float time_to_leave <- float(transportList[count][0]);
		Transport t <- Transport(transportList[count][1]);
		loop while: not empty(transportList) and (time_to_leave<=time){
			if t.nextRoad != nil{
				//the transport isn't on its last road so we check if its next road can accept it 
				if t.nextRoad.canAcceptTransport(t){
					//if the next road is ok then it takes the transport in charge
					ask t.nextRoad { do queueInRoad(t); }
					//this road can free space in its queue
					current_capacity <- current_capacity + t.size;
					remove [time_to_leave,t] from: transportList;
				}
			}else{
				//this road can free space in its queue
				current_capacity <- current_capacity + t.size;
				remove [time_to_leave,t]  from: transportList;
				ask t{ do endTrip; }
			}
			time_to_leave <- float(transportList[count][0]);
			t <- Transport(transportList[count][1]);
		}
	}
	
	// compute the travel of incoming transports
	// The formula used is BPR equilibrium formula
	float getRoadTravelTime(Transport t){
		float max_speed_formula <- max([t.speed,max_speed]) #km/#h;
		float free_flow_travel_time <- size/max_speed_formula;
		float travel_time <- free_flow_travel_time *  (1.0 + 0.15 * ((max_capacity-current_capacity)/max_capacity)^4);
		return travel_time;
	}
	
	//this function is called when the transport want to reach its target and not pass the road.
	//the function also use BPR formula but the free flow travel time is computed using 
	//start_node to transport's target distance instead of road size
	float getTargetTravelTime(Transport t, point target){
		float max_speed_formula <- max([t.speed,max_speed]) #m/#sec;
		float free_flow_travel_time <- (start_node distance_to target)/max_speed_formula;
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
        rgb color <- rgb(150,255 * (current_capacity / max_capacity),0);
        geometry geom_display <- (shape + (2.5));
        draw geom_display border: #gray color: color;
        draw "" + type + " - " + length(present_transports) + " PCU" at: location + point([15, -5]) size: 10 color: #black;

        // Display each vehicle in the queue according to their size and colored according to their time_to_leave
        // Vehicles at the top of FIFO are the closet of the end_node.
        if (length(present_transports) > 0) {
            float spacing <- 0.0;
            float x1 <- start_node.location.x;
            float y1 <- start_node.location.y;
            float x0 <- end_node.location.x;
            float y0 <- end_node.location.y;
            float d <- sqrt(((x1 - x0) * (x1 - x0)) + ((y1 - y0) * (y1 - y0)));
            loop i from: 0 to: length(present_transports) - 1 {
                Transport trans <- Transport(present_transports[0][1]);
                float dt <- (i * trans.size) + i * spacing;
                float t <- dt / d;
                float xt <- ((1 - t) * x0 + t * x1);
                float yt <- ((1 - t) * y0 + t * y1);
                float time_to_leave <- float(present_transports[0][0]);
                draw box(trans.size, 1.5, 1.5) at: point([xt, yt]) color: rgb(int(time_to_leave - time));
            }
        }
    }
}
