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

global { 
	string datasettest <- "../Datasets/Road test/"; // default
	file crossroad_shapefile <- shape_file(datasettest+"roadTest.shp");
	geometry shape <- envelope(crossroad_shapefile);
	float step <- 5 #sec;
	float road_speed <- 50.0;
	list<string> crossroads;
	
	graph<Crossroad,Road> road_network;
	Crossroad A;Crossroad B;Crossroad C;Crossroad D;
	Crossroad E;Crossroad F;Crossroad G;Crossroad H;
	
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
		create Road{type <- "AB"; start_node <- A; end_node <- B; max_speed <- road_speed; shape <- line([A.location,B.location]); do init;}
		create Road{type <- "BC"; start_node <- B; end_node <- C; max_speed <- road_speed; shape <- line([B.location,C.location]); do init;}
		create Road{type <- "CD"; start_node <- C; end_node <- D; max_speed <- road_speed; shape <- line([C.location,D.location]); do init;}
		create Road{type <- "CE"; start_node <- C; end_node <- E; max_speed <- road_speed; shape <- line([C.location,E.location]); do init;}
		create Road{type <- "BF"; start_node <- B; end_node <- F; max_speed <- road_speed; shape <- line([B.location,F.location]); do init;}
		create Road{type <- "FG"; start_node <- F; end_node <- G; max_speed <- road_speed; shape <- line([F.location,G.location]); do init;}
		create Road{type <- "FH"; start_node <- F; end_node <- H; max_speed <- road_speed; shape <- line([F.location,H.location]); do init;}
		road_network <- directed(as_edge_graph(Road,Crossroad));
		create transport_generator;
	}
	
	reflex print_data{
		write the_logger.data_to_string;
		ask the_logger {do reset_data;}
	}
}

species transport_generator {
    

    reflex send_car {
        int nb_transport_sent <- 0;
        int nb_transport_to_send <- 10;
        loop while: nb_transport_sent < nb_transport_to_send {
            create Car {
                location <- A.location;
                Crossroad c <- one_of([D, E, G, H]);
                if flip(0.1){
                	switch c{
                		match D{test_target <- "D";}
                		match E{test_target <- "E";}
                		match G{test_target <- "G";}
                		match H{test_target <- "H";}
                	}
                }
                pos_target <- c.location;
                available_graph <- road_network;
                path_to_target <- list<Road>(path_between(available_graph, location, pos_target).edges);
                nextRoad <- path_to_target[road_pointer];
                if (not nextRoad.canAcceptTransport(self)){
                    nb_transport_sent <- nb_transport_to_send;
                    do die;
                }else{
                    ask nextRoad {
                        do queueInRoad(myself);
                    }
                }
            }
            nb_transport_sent <- nb_transport_sent + 1;
        }
    }

}

experiment RoadTest type: gui {
	float minimum_cycle_duration <- 0.1;
	output {
		layout #split parameters: false navigator: false editors: false consoles: true toolbars: false tray: true tabs: true;	
		display map background: #white type: opengl {
			species Crossroad aspect: roadTest;
			species Road aspect: roadTest;
		}
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
