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
	float avg_speed <- road_speed.keys contains [type,urban_context,weather] ? road_speed[[type,urban_context,weather]]*road_speed_avg_coef[type] : 50.0;
	
	//number of motorized vehicule lane in this road
	int nb_lanes <- 1;
	
	//is the road is oneway or not
	string oneway;
	
	//length of the road (in meters)
	float size <- shape.perimeter;
	
	// the minimal time between two vehicules leaving the road (in second)
	float output_flow_capacity <- output_flow.keys contains type ? output_flow[type]: 2.4;
	
	//maximum space capacity of the road (in meters)
	float max_capacity <- size * nb_lanes min: 10.0;
	
	//actual free space capacity of the road (in meters)
	float current_capacity <- max_capacity min:0.0 max:max_capacity;
	
	//the minimal timestamp when the next transport can leave the road (transcription of maximal output capacity)
	int min_leave_time <- 0;
	
	//has_bike_lane = true if there is a specific lane for bikes in this road
	//				= false if not
	bool has_bike_lane <- false;
	
	//list of current vehicules present in the road 
	//list = [[float time_to_leave, Transport t]]
	list<list> present_bikes <- [];
    list<list> present_transports <- [];
    
    //This list store all the incoming transports requests
    //waiting_transports = [[float time_request, Transport t]]
    list<list> waiting_bikes <- [];
    list<list> waiting_transports <- [];
    
    action init{
    	size <- shape.perimeter;
    	max_capacity <- size * nb_lanes;
    	current_capacity <- max_capacity;
    }
    
    float getPresentTransportLeaveTime(int index){
    	return float(present_transports[index][0]);
    }
    
    Transport getPresentTransport(int index){
    	return Transport(present_transports[index][1]);
    }

    float getWaitingTimeRequest(int index){
    	return float(waiting_transports[index][0]);
    }
    
    Transport getWaitingTransport(int index){
    	return Transport(waiting_transports[index][1]);
    }
    
	// if there is a bike lane, bikes don't consume road capacity
	action queueInRoad(Bike b){
		present_bikes << b;
	}
	
	action queueInRoad(Transport t,float entry_time){
		float leave_time <- floor(entry_time + getRoadTravelTime(t));
		//write t.name + " : " + leave_time;
		ask t{
			listactions <- listactions  + " " + entry_time + " Will leave at " + leave_time + "(" + path_to_target +")\n";
		}
		present_transports << [leave_time,t];
		if length(present_transports) = 1{
			ask t{
				listactions <- listactions  + " " + entry_time + " I'm alone, so i'll leave at " + leave_time + "(" + path_to_target +")\n";
			}
			ask getPresentTransport(0){ do setLeaveTime(leave_time); }
		}
	}
	
	action enterRequest(Transport t, float request_time){
		if hasCapacity(t.size){
			ask t { 
				listactions <- listactions  + " " + request_time + " I'll be entering at " + request_time + "(" + path_to_target +")\n";
				myself.current_capacity <- myself.current_capacity - t.size;
				do setEntryTime(request_time);
			}
		}else{
			waiting_transports << [request_time, t];
		}
	}
	
	bool hasCapacity(float capacity){
		return current_capacity > capacity;
	}
	
	action acceptTransport(float entry_time){
		if not empty(waiting_transports){
			Transport t <- getWaitingTransport(0);
			int delay <- 0;
			loop while: hasCapacity(t.size) and not empty(waiting_transports){
				ask t { 
					listactions <- listactions  + " " + entry_time + " AcceptTransport " + entry_time+delay + "(" + path_to_target +")\n";
					myself.current_capacity <- myself.current_capacity - t.size;
					do setEntryTime(entry_time+delay);
				}
				remove waiting_transports[0]  from: waiting_transports;
				
				if not empty(waiting_transports){ 
					t <- getWaitingTransport(0);
				}
				delay <- delay +1;
			}
		}
	}
	
	
	//action called by a transport when it leaves the road
	action leave(float signal_time){
		float gainedCapacity <- getPresentTransport(0).size;
		current_capacity <- current_capacity + gainedCapacity;
		remove present_transports[0] from: present_transports;
		do acceptTransport(signal_time);
		if not empty(present_transports){
			ask getPresentTransport(0){ 
				listactions <- listactions  + " " + signal_time + " The car in front of me has left the road. Will leave the road at " + (signal_time+1) + ", I'll be in front of the road at "+ max(myself.getPresentTransportLeaveTime(0),signal_time+1) +"(" + path_to_target +")\n";
				do setLeaveTime(max(myself.getPresentTransportLeaveTime(0),signal_time+myself.output_flow_capacity));
			}
		}
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
        draw "" + type + " - " + length(present_transports) + " PCU" at: location + point([15, -5]) size: 10 color: #black;
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
