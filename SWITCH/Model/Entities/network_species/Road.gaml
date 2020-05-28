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
	string urban_context <- "urban" among: ["urban","interurban", nil];
	
	//is roundabout or not (OSM information)
	string junction;
	
	//start crossroad node
	Crossroad start_node;
	
	//end crossroad node
	Crossroad end_node;
	
	//maximum legal speed on this road
	float max_speed;
	
	//average speed on this road
	float avg_speed <- road_speed.keys contains [type,urban_context,weather] ? road_speed[[type,urban_context,weather]]*road_speed_avg_coef[type] : 50;
	
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
	
	//the minimal timestamp when the next transport can leave the road (transcription of maximal output capacity)
	int min_leave_time <- 0;
	
	//has_bike_lane = true if there is a specific lane for bikes in this road
	//				= false if not
	bool has_bike_lane <- false;
	
	//list of current vehicules present in the road [[time_to_leave,Transport]]
	//Note that target.location store the location of car target if this road is the last road
	//if this road is not the trip car last road then target.location = nil
	list<Bike> present_bikes <- [];
    list<Transport> present_transports <- [];
    
    //This list store all the incoming transports requests
    //waiting_transports = [[int time_request, Transport t]]
    list<list> waiting_transports <- [];
    
    action init{
    	size <- shape.perimeter;
    	max_capacity <- size * nb_lanes;
    	current_capacity <- max_capacity;
    }
    
	// if there is a bike lane, bikes don't consume road capacity
	action queueInRoad(Bike b){
		present_bikes << b;
	}
	
	action queueInRoad(Transport t,int entry_time){
		present_transports << t;
		int leave_time <- int(floor(max([min_leave_time, entry_time + getRoadTravelTime(t)])));
		ask t{ do setLeaveTime(leave_time); }
	}
	
	action enterRequest(Transport t, int time_request){
		if current_capacity > t.size{
			do queueInRoad(t,time_request);
		}else{
			waiting_transports << [time_request, t];
		}
	}
	
	action acceptTransport(int entry_time){
		Transport t <- waiting_transports[0][1];
		loop while: current_capacity > t.size and not empty(waiting_transports){
			ask t { do setEntryTime(entry_time); }
			remove t from: waiting_transports;
			current_capacity <- current_capacity - t.size;
			if not empty(waiting_transports){ t <- waiting_transports[0][1]; }
		}
	}
	
	//action called by transport when they know the time they'll enter the next road
	action willLeave(int leave_time, Transport t){
		current_capacity <- current_capacity + t.size;
		do acceptTransport(leave_time + getRoadTravelTime(t));
	}
	
	//action called by a transport when it leaves the road
	action leave(Transport t,int t_leave_time){
		remove present_transports[0] from: present_transports;
		//the time spend by transport t to leave the road is computed based on its size and the avg speed on this road 
		min_leave_time <- int(floor(t_leave_time + avg_speed #km/#h * t.size));
	}
	
	// compute the travel of incoming transports
	// The formula used is BPR equilibrium formula
	int getRoadTravelTime(Transport t){
		float max_speed_formula <- max([t.speed,max_speed]) #km/#h;
		float free_flow_travel_time <- size/max_speed_formula;
		float travel_time <- free_flow_travel_time *  (1.0 + 0.15 * ((max_capacity-current_capacity)/max_capacity)^4);
		return int(floor(travel_time));
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
                Transport trans <- present_transports[i];
                float dt <- (i * trans.size) + i * spacing;
                float t <- dt / d;
                float xt <- ((1 - t) * x0 + t * x1);
                float yt <- ((1 - t) * y0 + t * y1);
                float time_to_leave <- 0.0; // NOT CORRECT DUE TO CHANGES ON ROAD BEHAVIOUR 
                
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
