/**
* Name: SWITCH
* Based on the internal skeleton template. 
* Author: Lo�c
* Tags: 
*/

model SWITCH

import "../../Model/logger.gaml"
import "../../Model/Entities/network_species/Road.gaml"
import "../../Model/Entities/network_species/Crossroad.gaml"
import "../../Model/Entities/transport_species/Transport.gaml"
import "../../Model/Entities/transport_species/PrivateTransport.gaml"
import "../../Model/Entities/transport_species/Car.gaml"
import "../../Model/Entities/EventManager.gaml"

global { 
	string datasettest <- "../Datasets/Road test/"; // default
	file crossroad_shapefile <- shape_file(datasettest+"roadTest.shp");
	geometry shape <- envelope(crossroad_shapefile);
	float step <- 5 #sec;
	float param_road_speed <- 50.0;
	list<string> crossroads;
	
	graph<Crossroad,Road> road_network;
	Crossroad A;Crossroad B;Crossroad C;Crossroad D;
	Crossroad E;Crossroad F;Crossroad G;Crossroad H;
	
	float speed_AB <- param_road_speed;
	float speed_BC <- param_road_speed;
	float speed_CD <- param_road_speed;
	float speed_CE <- param_road_speed;
	float speed_BF <- param_road_speed;
	float speed_FG <- param_road_speed;
	float speed_FH <- param_road_speed;
	
	int vehicule_in_A <- 10;
	
	init{
		create logger with: [store_individual_dest::true]{the_logger <- self;}
		//logger.data["D"] <- []; logger.data["E"] <- []; logger.data["G"] <- []; logger.data["H"] <- [];
		
		create Crossroad from: crossroad_shapefile with:[
			type::string(get("name"))
		];
		crossroads <- remove_duplicates(Crossroad collect each.type);
		A <- Crossroad first_with (each.type = "A");
		B <- Crossroad first_with (each.type = "B");
		C <- Crossroad first_with (each.type = "C");
		D <- Crossroad first_with (each.type = "D");
		E <- Crossroad first_with (each.type = "E");
		F <- Crossroad first_with (each.type = "F");
		G <- Crossroad first_with (each.type = "G");
		H <- Crossroad first_with (each.type = "H");
		create Road{type <- "AB"; start_node <- A; end_node <- B; max_speed <- speed_AB; shape <- line([A.location,B.location]); do init;}
		create Road{type <- "BC"; start_node <- B; end_node <- C; max_speed <- speed_BC; shape <- line([B.location,C.location]); do init;}
		create Road{type <- "CD"; start_node <- C; end_node <- D; max_speed <- speed_CD; shape <- line([C.location,D.location]); do init;}
		create Road{type <- "CE"; start_node <- C; end_node <- E; max_speed <- speed_CE; shape <- line([C.location,E.location]); do init;}
		create Road{type <- "BF"; start_node <- B; end_node <- F; max_speed <- speed_BF; shape <- line([B.location,F.location]); do init;}
		create Road{type <- "FG"; start_node <- F; end_node <- G; max_speed <- speed_FG; shape <- line([F.location,G.location]); do init;}
		create Road{type <- "FH"; start_node <- F; end_node <- H; max_speed <- speed_FH; shape <- line([F.location,H.location]); do init;}
		road_network <- directed(as_edge_graph(Road,Crossroad));
		create transport_generator;
		create EventManager;
		event_m <- first(EventManager);
	}
	
	reflex manage_step when: every(#h) {}
	
	reflex print_time{
		write "***********"+timestamp(time)+"*****************" color:#red;
	}
	
	//this function return a convenient string corresponding to a time (in second)
	string timestamp (int time_to_print){
		int nb_heure <- floor(time_to_print/3600);
      	int nb_min <- floor((time_to_print-nb_heure*3600)/60);
      	int nb_sec <- floor(time_to_print-nb_heure*3600-nb_min*60);
      	string buff <- "";
      	if nb_heure < 10 {buff <- buff +"0";}
      	buff <- buff + nb_heure + "h";
      	if nb_min < 10 {buff <- buff +"0";}
      	buff <- buff + nb_min + "m";
      	if nb_sec < 10 {buff <- buff + "0";}
      	return buff + nb_sec +"s";
	}
}

species transport_generator {
    

    reflex send_car when: every(5.0){
        int nb_transport_sent <- 0;
        int nb_transport_to_send <- vehicule_in_A;
        int delay <-0;
        loop while: nb_transport_sent < nb_transport_to_send{
            create Car {
                location <- A.location;
                Crossroad c <- one_of([D, E, G, H]);
                pos_target <- c.location;
                available_graph <- road_network;
                path_to_target <- list<Road>(path_between(available_graph, location, pos_target).edges);
                add nil to:path_to_target at:0;
                do sendEnterRequest(int(time+delay));
                delay <- delay+1;
            }
            nb_transport_sent <- nb_transport_sent + 1;
        }
    }

}

experiment RoadTest type: gui {
	float minimum_cycle_duration <- 0.7;
	
	parameter "AB speed limit " var: speed_AB min: 0.0 max: 130.0 category: "Speed" ;
	parameter "BC speed limit " var: speed_BC min: 0.0 max: 130.0 category: "Speed" ;
	parameter "CD speed limit " var: speed_CD min: 0.0 max: 130.0 category: "Speed" ;
	parameter "CE speed limit " var: speed_CE min: 0.0 max: 130.0 category: "Speed" ;
	parameter "BF speed limit " var: speed_BF min: 0.0 max: 130.0 category: "Speed" ;
	parameter "FG speed limit " var: speed_FG min: 0.0 max: 130.0 category: "Speed" ;
	parameter "FH speed limit " var: speed_FH min: 0.0 max: 130.0 category: "Speed" ;
	
	parameter "vehicule arriving in A each cyle " var: vehicule_in_A min: 0 max: 100 category: "Flow" ;
	
	output {	
		display map background: #white type: opengl {
			species Crossroad aspect: roadTest;
			species Road aspect: advanced;
		}
//		display chart_D {
//            chart "traveled distance by car going to D" type: series {
//                datalist legend:(list(Car) collect each.name) value: (list(Car) collect each.traveled_dist);
//              }
//          }
		/*display chart_D refresh: every (5 #cycles){
			chart "traveled distance by car going to D" type: series{
				write "test";
				loop data_point over: data["D"]{
					data data_point.key value: data_point.value style: line color: rnd_color(255);
				}
      		}
      	}
      	display chart_E refresh: every (5 #cycles){
			chart "traveled distance by car going to E" type: series{
				loop data_point over: data["E"]{
					data data_point.key value: data_point.value style: line color: rnd_color(255);
				}
      		}
      	}
      	display chart_G refresh: every (5 #cycles){
			chart "traveled distance by car going to G" type: series{
				loop data_point over: data["G"]{
					data data_point.key value: data_point.value style: line color: rnd_color(255);
				}
			}
      	}
      	display chart_H refresh: every (5 #cycles){
			chart "traveled distance by car going to H" type: series{
				loop data_point over: data["H"]{
					data data_point.key value: data_point.value style: line color: rnd_color(255);
				}
			}
      	}*/
	}
}
