/**
* Name: SWITCH
* Based on the internal skeleton template. 
* Author: Lo�c
* Tags: 
*/

model SWITCH

import "../Model/Entities/network_species/Road.gaml"
import "../Model/Entities/network_species/Crossroad.gaml"
import "../Model/Entities/transport_species/Car.gaml"

global {
	string datasettest <- "../Datasets/Road test/"; // default
	file crossroad_shapefile <- shape_file(datasettest+"roadTest.shp");
	geometry shape <- envelope(crossroad_shapefile);
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
		create Road{type <- "AB"; start_node <- A; end_node <- B; max_speed <- road_speed; shape <- line([A.location,B.location]);}
		create Road{type <- "BC"; start_node <- B; end_node <- C; max_speed <- road_speed; shape <- line([B.location,C.location]);}
		create Road{type <- "CD"; start_node <- C; end_node <- D; max_speed <- road_speed; shape <- line([C.location,D.location]);}
		create Road{type <- "CE"; start_node <- C; end_node <- E; max_speed <- road_speed; shape <- line([C.location,E.location]);}
		create Road{type <- "BF"; start_node <- B; end_node <- F; max_speed <- road_speed; shape <- line([B.location,F.location]);}
		create Road{type <- "FG"; start_node <- F; end_node <- G; max_speed <- road_speed; shape <- line([F.location,G.location]);}
		create Road{type <- "FH"; start_node <- F; end_node <- H; max_speed <- road_speed; shape <- line([F.location,H.location]);}
		road_network <- directed(as_edge_graph(Road,Crossroad));
	}
}

species transport_generator{
	
	int nb_transport_sent <- 0;
	int nb_transport_to_send <- 10;
	
	reflex send_car{
		bool next_road_ok;
		create Car returns: created_car {posTarget <- one_of([D,E,G,H]).location;}
		loop while: next_road_ok {
			create Car returns: created_car {}
		}
	}
	
}

experiment RoadTest type: gui {
	output {
		layout #split parameters: false navigator: false editors: false consoles: true toolbars: false tray: false tabs: true;	
		display map background: #white type: opengl {
			species Crossroad aspect: roadTest;
			species Road aspect: roadTest;
		}
	}
}
