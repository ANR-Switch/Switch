/***
* Name: Global
* Author: Patrick Taillandier
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model SWITCH


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
	
	action global_init  {
		//Initialization of the building using the shapefile of buildings
		create Building from: building_shapefile;
		
		ask Building{
			switch size{
				match_between [0.0,50.0]{}
				match_between [50.0,125.0]{type <-"home";}
				match_between [125.0,250.0]{type <- rnd(1.0)<0.5 ? "parking" : "work";}
				default {type <- "work";}
			}
		}
		
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
		
		
		//Creation of the people agents
		create Individual number: nb_individuals {
			home_building <- one_of(Building where (each.type = "home"));
			work_building <- one_of(Building where (each.type = "work"));
			car_place <- home_building.location;
			bike_place <- home_building.location;
			location <- any_location_in(home_building);
		}
		
		if (choice_of_target_mode = gravity) {
			map<string, list<Building>> buildings <- Building group_by (each.type);
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
      	road_network <- directed(as_edge_graph(Road,Crossroad));
      	ask Road {
      		start_node <- road_network source_of self;
      		end_node <- road_network target_of self;
      	}
	}
}
