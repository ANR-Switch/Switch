/**
* Name: SWITCH
* Based on the internal skeleton template. 
* Author: Lo�c
* Tags: 
*/

model SWITCH

import "../Model/Entities/network_species/Road.gaml"
import "../Model/Entities/network_species/Crossroad.gaml"
import "../Model/Entities/transport_species/Transport.gaml"
import "../Model/Entities/transport_species/PrivateTransport.gaml"
import "../Model/Entities/transport_species/Car.gaml"

global {
	string datasettest <- "../Datasets/Road test/"; // default
	file crossroad_shapefile <- shape_file(datasettest+"roadTest.shp");
	geometry shape <- envelope(crossroad_shapefile);
	float step <- 5 #sec;
	float road_speed <- 50.0;
	graph<Crossroad,Road> road_network;
	Crossroad A;Crossroad B;Crossroad C;Crossroad D;
	Crossroad E;Crossroad F;Crossroad G;Crossroad H;
	
	init{
		create Crossroad from: crossroad_shapefile with:[
			type::string(get("name"))
		];
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
		create Car returns: created_car{
			location <- A.location; 
			posTarget <- one_of([D,E,G,H]).location; 
			available_graph <- road_network;
			path_to_target <- list<Road>(path_between(available_graph,location,posTarget).edges);
			nextRoad <- path_to_target[road_pointer];
		}
		write ""+created_car[0]+"'s path ="+created_car[0].path_to_target;
		ask created_car[0].nextRoad{do queueInRoad(created_car[0]);}
	}
}

species transport_generator{
	
	int nb_transport_sent <- 0;
	int nb_transport_to_send <- 10;
	bool next_road_ok;
	
	reflex send_car{
		create Car returns: created_car {
			location <- A.location; 
			posTarget <- one_of([D,E,G,H]).location; 
			available_graph <- road_network;
			path_to_target <- list<Road>(path_between(available_graph,location,posTarget).edges);
			nextRoad <- path_to_target[road_pointer];
		}
		nb_transport_sent <- 1;
		next_road_ok <- created_car[0].nextRoad.canAcceptTransport(created_car[0]);
		loop while: next_road_ok and nb_transport_sent < nb_transport_to_send{
			write ""+created_car[0]+"'s path ="+created_car[0].path_to_target;
			write created_car[0].nextRoad;
			ask created_car[0].nextRoad{do queueInRoad(created_car[0]);}
			create Car returns: created_car {
				location <- A.location; 
				posTarget <- one_of([D,E,G,H]).location; 
				available_graph <- road_network;
				path_to_target <- list<Road>(path_between(available_graph,location,posTarget).edges);
				nextRoad <- path_to_target[road_pointer];
			}
			next_road_ok <- created_car[0].nextRoad.canAcceptTransport(created_car[0]);
			nb_transport_sent <- nb_transport_sent + 1;
		}
		write "end step nb car created: "+nb_transport_sent;
	}
	
}

experiment RoadTest type: gui {
	float minimum_cycle_duration <- 0.7;
	output {
		layout #split parameters: false navigator: false editors: false consoles: true toolbars: false tray: true tabs: true;	
		display map background: #white type: opengl {
			species Crossroad aspect: roadTest;
			species Road aspect: roadTest;
		}
	}
}
