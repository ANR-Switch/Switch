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
			if ["home","parking","work"] contains type{
				create HubCar returns: created_HubCar{
					location <- any_location_in(myself);
				}
				create HubBike returns: created_HubBike{
					location <- any_location_in(myself);
				}
				parkings <- parkings + [created_HubCar][0] + [created_HubBike][0];
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
			car_place <- HubCar(home_building.parkings[0]);
			write home_building.parkings[0];
			bike_place <- HubBike(home_building.parkings[1]);
			write home_building.parkings[1];
			location <- any_location_in(home_building);
		}
      	road_network <- directed(as_edge_graph(Road,Crossroad));
      	ask Road {
      		start_node <- road_network source_of self;
      		end_node <- road_network target_of self;
      	}
	}
}
