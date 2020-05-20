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
	string urban_context <- "urban" among: ["urban","interurban","sunny", nil];
	
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
	float current_capacity <- max_capacity min:0.0 max:max_capacity;
	
	//the out flow capacity, number of transports that can leave the road in a second (in meters)
	float max_output_capacity <- road_speed.keys contains [type,urban_context,weather] ? road_speed[[type,urban_context,weather]]*road_speed_avg_coef[type]  #km/#h : 50 #km/#h;
	//actual free out flow
	float current_output_capacity <- max_output_capacity min: 0.0 max: max_output_capacity * step;
	
	
	//has_bike_lane = true if there is a specific lane for bikes in this road
	//				= false if not
	bool has_bike_lane <- false;
	
	//list of current vehicules present in the road [[time_to_leave,Transport]]
	//Note that target.location store the location of car target if this road is the last road
	//if this road is not the trip car last road then target.location = nil
	list<list> present_bikes <- [];
    list<list> present_transports <- [];
    
    action init{
    	size <- shape.perimeter;
    	max_capacity <- size * nb_lanes;
    	current_capacity <- max_capacity;
    }
	
	/*action queueInRoad(Transport t, float time_left){
		current_capacity <- current_capacity - t.size;
		ask t{ do enterRoad(myself); }
		float travel_time <- getRoadTravelTime(t);
		if travel_time < time_left {
			list<list> temp_list <- [[time+time_left,t]];
			do dequeue(temp_list);
			if not empty(temp_list){present_transports << [time+travel_time-time_left,t];}
		}else{
			present_transports << [time+travel_time-time_left,t];	
		}
	}*/
	// if there is a bike lane, bikes don't consume road capacity
	action queueInRoad(Bike b){
		if not has_bike_lane { current_capacity <- current_capacity - b.size; }
		ask b{ do enterRoad(myself); }
		float travel_time <- getRoadTravelTime(b);
		present_bikes << [time+travel_time,b];
	}
	
	action queueInRoad(Transport t){
		current_capacity <- current_capacity - t.size;
		ask t{ do enterRoad(myself); }
		float travel_time <- getRoadTravelTime(t);
		present_transports << [time+travel_time,t];
	}
	
	
	bool canAcceptTransport(Transport t){
		return current_capacity > t.size;
	}
	
	reflex dequeueFromRoad when: not empty(present_transports) and (float(present_transports[0][0]) <= time){
		current_output_capacity <- max_output_capacity * step;
		do dequeue(present_transports);
	}
	
	reflex dequeueBikeFromRoad when: not empty(present_bikes) and (float(present_bikes[0][0]) <= time){
		do dequeue(present_bikes);
	}
	
	action dequeue(list<list> transportList){
		//road_locked = true if the head transport can't access its next road
		bool road_locked <- false;
		Transport t;
		float time_to_leave;
		loop while: not empty(transportList) and (float(transportList[0][0])<=time) and (not road_locked) and (Transport(transportList[0][1]).size < current_output_capacity){
			Transport t <- Transport(transportList[0][1]);
			time_to_leave <- float(transportList[0][0]);
			if t.nextRoad != nil{
				//the transport isn't on its last road so we check if its next road can accept it 
				if t.nextRoad.canAcceptTransport(t){
					//if the next road is ok then it takes the transport in charge
					ask t.nextRoad { do queueInRoad(t); }
					//this road can free space in its queue
					current_capacity <- current_capacity + t.size;
					current_output_capacity <- current_output_capacity - t.size;
					remove transportList[0] from: transportList;
				}else{
					road_locked <- true;
				}
			}else{
				//this road can free space in its queue
				current_capacity <- current_capacity + t.size;
				remove transportList[0] from: transportList;
				ask t{ do endTrip; }
			}
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
	
	aspect advanced {
        geometry geom_display <- (shape + (2.0));
        draw geom_display border: #gray color: rgb(255*(max_capacity-current_capacity)/max_capacity,0,0);
    }
	
	aspect roadTest {
    // Color of the road is determined according to current road occupation
        //rgb color <- rgb(150,255 * (current_capacity / max_capacity),0);
        geometry geom_display <- (shape + (2.5));
        draw geom_display border: #gray color: #black;
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
                Transport trans <- Transport(present_transports[i][1]);
                float dt <- (i * trans.size) + i * spacing;
                float t <- dt / d;
                float xt <- ((1 - t) * x0 + t * x1);
                float yt <- ((1 - t) * y0 + t * y1);
                float time_to_leave <- float(present_transports[i][0]);
                
                int nbStepToLeave <- round(int(time_to_leave - time)*step);
                
                rgb carColor;
                
                if (nbStepToLeave > 0){
                    carColor <- rgb(0,255 - min(255,nbStepToLeave),0);
                }else{
                    carColor <- rgb(255 - min(255,abs(nbStepToLeave)),0,0);
                }
                
                draw box(trans.size, 1.5, 1.5) at: point([xt, yt]) color: carColor rotate:angle_between({x0,y0},{x1,y0},{x1,y1});
            }
        }
    }
}
