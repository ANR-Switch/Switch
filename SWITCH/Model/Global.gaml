/***
* Name: Global
* Author: Patrick Taillandier
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model SWITCH

//import "../Utilities/Generate Agenda.gaml"
import "../Utilities/import GTFS.gaml"
import "../Utilities/stochastic population generation.gaml"
import "Parameters.gaml"
import "Entities/network_species/Building.gaml"
import "Entities/network_species/Crossroad.gaml"
import "Entities/network_species/Road.gaml"
import "Entities/Individual.gaml"
import "Entities/EventManager.gaml"
import "Entities/factory_species/TransportFactory.gaml"

global {
	float seed <- 12358.0;

	//price
	float gas_price;
	float subscription_price;

	//safety 
	float percentage_of_drivers;
	float number_of_users;
	map<list<int>, int> number_of_users_per_hour;
	//routes & pistes cyclables collées à voir
	float ratio_cycleway;

	//ecology
	float air_pollution;

	//comfort
	//use of number of users car si c'est bondé c'est moins confortable
	float bus_capacity; //capacity of one bus


	//time
	float bus_freq; //intervalle en minute
	logger the_logger;
	EventManager the_event_manager;
	list<file> shp_roads <- define_shapefiles("roads");
	geometry shape <- envelope(union(shp_roads collect envelope(each)));
	string optimizer_type <- "NBAStar" among: ["NBAStar", "NBAStarApprox", "Dijkstra", "AStar", "BellmannFord", "FloydWarshall"];
	bool memorize_shortest_paths <- true; //true by default
	Outside the_outside;
	list<int> first_activity_h;
	bool is_fast_step <- false;
	list<Road> road_near_work <- [];
	list<Building> work_buildings;
	list<Building> home_buildings;
	list<Building> shop_buildings;
	list<Building> school_buildings;
	list<Building> leisure_buildings;

	reflex end_simulation when: current_date = end_date {
		do pause;
	}

	reflex manage_step when: every(#h) {
		float next_event_time <- (first(EventManager).getEventTime(0));
		if (not is_fast_step and (time < next_event_time)) {
			step <- fast_step;
			is_fast_step <- true;
		}

		if (is_fast_step and (time >= next_event_time)) {
			step <- normal_step;
			is_fast_step <- false;
		}

	}

	action global_init {
		create EventManager {
			myself.the_event_manager <- self;
		}

		create logger {
			myself.the_logger <- self;
		}
		//Initialization of the building using the shapefile of buildings
		list<file> shp_buildings <- define_shapefiles("buildings");
		loop shp_building over: shp_buildings {
			create Building from: shp_building with: [types::list("types")];
		}

		create Outside {
			the_outside <- self;
		}

		weather <- "sunny";
		ratio_cycleway <- 0.8;
		do write_message("Building created");

		//Initialization of the road using the shapefile of roads
		loop shp_road over: shp_roads {
			create Road from: shp_road with:
			[type:: string(get("type")), oneway::string(get("oneway")), junction::string(get("junction")), nb_lanes::int(get("lanes")), max_speed::float(get("maxspeed")) * (road_speed_in_km_h
			? #km / #h : 1.0)];
		}

		do write_message("Road created");
		list<file> shp_nodes <- define_shapefiles("nodes");

		//Initialization of the nodes using the shapefile of nodes
		loop shp_node over: shp_nodes {
			create Crossroad from: shp_node with: [type:: string(get("type")), crossing::string(get("crossing")), sub_areas::string(get("sub_areas")) split_with ","];
		}

		do write_message("Nodes created");
		map<point, list<Crossroad>> crossRs;
		ask Crossroad where (length(each.sub_areas) > 1) {
			if not (location in crossRs.keys) {
				crossRs[location] <- [self];
			} else {
				crossRs[location] << self;
			}

		}

		loop cr over: crossRs.values {
			if (length(cr) > 1) {
				loop i from: 1 to: length(cr) - 1 {
					ask cr[i] {
						do die;
					}

				}

			}

		}

		do write_message("Nodes filtered");
		ask Building {
			switch size {
				match_between [50.0, 125.0] {
					type <- "home";
					home_buildings << self;
				}

				match_between [125.0, 200.0] {
					type <- "leisure";
					leisure_buildings << self;
				}

				match_between [250.0, 300.0] {
					type <- "shop";
					shop_buildings << self;
				}

				match_between [300.0, 340.0] {
					type <- "leisure";
					leisure_buildings << self;
				}

				match_between [340.0, 350.0] {
					type <- "school";
					school_buildings << self;
				}

				match_between [350.0, 1000.0] {
					type <- "work";
					work_buildings << self;
				}

			}

		}

		if file_exists(population_dataset) {
		} else {
			do generate_population();
		}

		road_network <- directed(as_edge_graph(Road, Crossroad));
		do write_message("Shortest path cache computation");

		//allows to choose the type of algorithm to use compute the shortest paths
		road_network <- road_network with_optimizer_type optimizer_type;

		//allows to define if the shortest paths computed should be memorized (in a cache) or not
		road_network <- road_network use_cache memorize_shortest_paths;

		//		string shortest_paths_file <- define_shapefiles("shortest_path");
		//		 if not file_exists(shortest_paths_file){ 
		//		 	matrix ssp <- all_pairs_shortest_path(road_network);
		//			save ssp type:"text" to:shortest_paths_file;
		//		 }
		//      	road_network <- road_network load_shortest_paths  matrix(file(shortest_paths_file));


		//do write_message("Shortest path loaded");
		ask Road {
			start_node <- road_network source_of self;
			end_node <- road_network target_of self;
			if length(work_buildings at_distance 100.0) > 0 {
				myself.road_near_work << self;
			}
			//don't know why some roads have a nil start...
			if(start_node = nil or end_node = nil ){
				do die;
			}
			point A <- start_node.location;
			point B <- end_node.location;
			if (A = B) {
				trans <- {0, 0};
			} else {
				point u <- {-(B.y - A.y) / (B.x - A.x), 1};
				float angle <- angle_between(A, B, A + u);
				// write sample(int(angle));
				// write sample(norm(u));
				if (angle < 150) {
					trans <- u / norm(u);
				} else {
					trans <- -u / norm(u);
				}

			}

		}

		do createTransportLineAndStations();
	}

	action write_message (string mess) {
		if (debug_mode) {
			write mess;
		}

	}

	reflex print_time {
		write current_date;
	}

	Building get_living_place (int id_bd, map<int, Building> bds) {
		return bds[id_bd];
	}

	Building get_working_place (int id_bd, map<int, Building> bds) {
		if (id_bd = -2) {
			return nil;
		}

		Building bd <- bds[id_bd];
		if (bd = nil) {
			return the_outside;
		}

		return bd;
	}

	action update_weather {
		int t <- rnd(3);
		if (t = 0) {
			weather <- "sunny";
		} else if (t = 1) {
			weather <- "rainy";
		} else {
			weather <- "stormy";
		}

	}

	action update_number_of_users_per_hour {
		loop i from: 5 to: 23 {
			number_of_users_per_hour[[i, 0]] <- 30;
			number_of_users_per_hour[[i, 30]] <- 30;
		}

	}

	list<Individual> manage_list_int (string val) {
		val <- val replace ("[", "") replace ("]", "");
		list<string> vs <- val split_with ",";
		list<Individual> ind <- [];
		loop v over: vs {
			int vint <- int(v);
			if vint < length(Individual) {
				ind << Individual(vint);
			}

		}

		return ind;
	}

	list<file> define_shapefiles (string file_name) {
		list<file> f;
		list<string> sa;
		if empty(sub_areas) {
			sa <- gather_dataset_names(dataset);
		} else {
			sa <- sub_areas;
		}

		loop fd over: sa {
			string p <- dataset + fd + "/" + file_name + ".shp";
			if (file_exists(p)) {
				f << file(p);
			} else {
				int i <- 1;
				loop while: true {
					string p <- dataset + fd + "/" + file_name + "_" + i + ".shp";
					if (file_exists(p)) {
						f << file(p);
						i <- i + 1;
					} else {
						break;
					}

				}

			}

		}

		return f;
	}

	list<string> gather_dataset_names (string _datasets_folder_path) {
		string dfp <- with_path_termination(_datasets_folder_path);
		if not (folder_exists(dfp)) {
			error "Datasets folder does not exist : " + dfp;
		}

		list<string> dirs <- folder(dfp).contents;
		dirs <- dirs where folder_exists(dfp + each);
		return dirs;
	}

	string with_path_termination (string p) {
		return last(p) = "/" ? p : p + "/";
	}

}

