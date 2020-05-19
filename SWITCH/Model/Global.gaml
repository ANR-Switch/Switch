/***
* Name: Global
* Author: Patrick Taillandier
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model SWITCH

import "../Utilities/Generate Agenda.gaml"

import "Parameters.gaml"

import "Entities/network_species/Building.gaml"
import "Entities/network_species/Crossroad.gaml"
import "Entities/network_species/Road.gaml"



import "Entities/Individual.gaml"
 
global {
		//variables environement de transport :
	//map<string, map<string,float>> info_mode_env; //<mode, <critère,valeur>>
	
	//price
	float gas_price;
	float subscription_price;
	
	//safety 
	float percentage_of_drivers;
	float number_of_users;
	map<list<int>, int> number_of_users_per_hour;
	//routes & pistes cyclables collées à voir
	
	//ecology
	float air_pollution;
	
	//comfort
	//use of number of users car si c'est bondé c'est moins confortable
	float bus_capacity;//capacity of one bus
	
	
	//time
	float bus_freq; //intervalle en minute
	
	logger the_logger;
	
	
	geometry shape <- envelope(road_shapefile);
	//Graph of the road network
	graph<Crossroad,Road> road_network;
	
	Outside the_outside;
	
	
	action global_init  {
		//Initialization of the building using the shapefile of buildings
		create Building from: building_shapefile;
		create Outside {the_outside <- self;}
		
		do write_message("Building created");
		
		//Initialization of the road using the shapefile of roads
		create Road from: road_shapefile with: [
			type::string(get("type")),
			oneway::string(get("oneway")),
			junction::string(get("junction")),
			nb_lanes::int(get("lanes")),
			max_speed:: float(get("maxspeed")) * (road_speed_in_km_h ? #km/#h : 1.0)
		];
		
		//Initialization of the nodes using the shapefile of nodes
		create Crossroad from: node_shapefile  with:[
			type::string(get("type")),
			crossing::string(get("crossing"))
		];
		
		
		do write_message("Road created");
		
		if (individual_shapefile != nil) {
			create Individual from: individual_shapefile with: [
				age:: int(get("age")),
				gender::string(get("gender")),
				category::string(get("category")),
				work_building::int(get("work_pl")) = -1 ? the_outside : (int(get("work_pl")) = 0 ? nil : Building[int(get("work_pl"))]),
				home_building::Building[int(get("home_pl"))]
				
			];
			if (num_individuals > -1.0 and (num_individuals < length(Individual))) {
				ask (length(Individual) - num_individuals) among Individual{
					do die;
				}
			}
			ask Individual {
				relatives <- world.manage_list_int(string(shape get "rels")) where (not dead(each));
				friends <- world.manage_list_int(string(shape get "frs"))  where (not dead(each));
				colleagues <- world.manage_list_int(string(shape get "colls"))  where (not dead(each));
			}
		} else {
			ask Building{
				switch size{
					match_between [0.0,50.0]{}
					match_between [50.0,125.0]{type <-"home";}
					match_between [125.0,250.0]{type <- rnd(1.0)<0.5 ? "parking" : "work";}
					default {type <- "work";}
				}
			}
	
			//Creation of the people agents
			create Individual number: num_individuals {
				home_building <- one_of(Building where (each.type = "home"));
				work_building <- one_of(Building where (each.type = "work"));
				car_place <- home_building.location;
				bike_place <- home_building.location;
				location <- any_location_in(home_building);
			}
		}
		
		do write_message("Individual created");
		
		do define_agenda();
		
		do write_message("Agenda generated");
		
		ask Individual {
			do initialization;
		}
		
		map<string, list<Building>> buildings <- Building group_by (each.type);
				
		switch choice_of_target_mode {
			match random {
				ask Individual {
					list<predicate> acts <- remove_duplicates((agenda_week accumulate each.values) collect each.key) - [staying_at_home, working, studying, visiting_friend] ;
					loop act over: acts {
						map<string, list<Building>> bds;
						loop type over: activities[act.name] {
							list<Building> buildings <- buildings[type];
							bds[type] <- nb_candidates among buildings;
								
						}
						building_targets[act] <- bds;
					}
				}
			}
			match closest {
				ask Individual {
					list<predicate> acts <- remove_duplicates((agenda_week accumulate each.values) collect each.key) - [staying_at_home, working, studying, visiting_friend] ;
					loop act over: acts {
						map<string, list<Building>> bds;
						loop type over: activities[act.name] {
							list<Building> buildings <- buildings[type];
							bds[type] <- [buildings closest_to home_building.location];
								
						}
						building_targets[act] <- bds;
					}
				}
			}
			match gravity {
				ask Individual {
					list<predicate> acts <- remove_duplicates((agenda_week accumulate each.values) collect each.key) - [staying_at_home, working, studying, visiting_friend] ;
					loop act over: acts {
						map<string, list<Building>> bds;
						loop type over: activities[act.name] {
							list<Building> buildings <- buildings[type];
							if length(buildings) <= nb_candidates {
								bds[type] <- buildings;
							} else {
								list<Building> bds_;
								list<float> proba_per_building;
								loop b over: buildings {
									float dist <- max(20,b.location distance_to home_building.location);
									proba_per_building << (b.shape.area / dist ^ gravity_power);
								}
								loop while: length(bds_) < nb_candidates {
									bds_<< buildings[rnd_choice(proba_per_building)];
									bds_ <- remove_duplicates(bds_);
								}
								bds[type] <- bds_;
							}
							building_targets[act] <- bds;
						}
					}
				}
			}
		}
      	road_network <- directed(as_edge_graph(Road,Crossroad));
      	ask Road {
      		start_node <- road_network source_of self;
      		end_node <- road_network target_of self;
      	}
	}
	
	action write_message(string mess) {
		if (debug_mode) {
			write mess;
		}
	}
	
	list<Individual> manage_list_int(string val) {
		val <- val replace("[","") replace("]","");
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
}

