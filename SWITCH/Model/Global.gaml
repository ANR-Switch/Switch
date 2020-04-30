/***
* Name: Global
* Author: Patrick Taillandier
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model SWITCH

import "Parameters.gaml"

import "Entities/Road.gaml"

import "Entities/Individual.gaml"

import "Entities/Building.gaml"

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
	
	//simplicity
	
	


	
	
	geometry shape <- envelope(road_shapefile);
	//Graph of the road network
	graph road_network;
	
	action global_init  {
		//Initialization of the building using the shapefile of buildings
		create Building from: building_shapefile;
		//Initialization of the road using the shapefile of roads
		create Road from: road_shapefile;
		
		//Creation of the people agents
		create Individual number: 10 with: [home_building::one_of(Building), work_building::one_of(Building) ];
      	road_network <- as_edge_graph(Road);
      	
	}
}
