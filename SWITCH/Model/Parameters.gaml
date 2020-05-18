/***
* Name: Parameters
* Author: Patrick Taillandier
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model SWITCH
import "Constants.gaml"

global {
	string dataset <- "../Datasets/Castanet Tolosan/"; // default
	
	
	file road_shapefile <- shape_file(dataset+"roads.shp");
	file building_shapefile <- shape_file(dataset+"buildings.shp");
	file node_shapefile <- shape_file(dataset+"nodes.shp");
	
	
	//date (et heure) de début de la simulation : 7/4/2020 à 6h00 0"
	date starting_date <- date(2020,4,7,8,20,0);
	
	list<string> type_mode <- ["car","bus","bike","walk"];
	list<string> criteria <- ["comfort", "safety", "price","ecology","simplicity","time"];
	//Step value
	float step <- 15 #sec;
	
	float bus_freq <- 7.0;
	float bus_capacity <- 50.0;
		
	float gas_price <- 1.5; //prix au litre
	float subscription_price <- 30.0; //prix par mois
		
	float number_of_users <- 0.0;
	float percentage_of_drivers <- 0.0;
	

	//speed
	float car_speed <- 20.0;
	float bus_speed <- 10.0;
	float bike_speed <- 8.0;
	float walk_speed <- 3.0;

	int nb_individuals <- 1000;
	
	bool road_speed_in_km_h <- true;
	
	//Acvitity parameters 
	string choice_of_target_mode <- gravity among: ["random", "gravity","closest"]; // model used for the choice of building for an activity 
	int nb_candidates <- 4; // number of building considered for the choice of building for a particular activity
	float gravity_power <- 0.5;  // power used for the gravity model: weight_of_building <- area of the building / (distance to it)^gravity_power
	
	
	//list of activities, and for each activity type, the list of possible building type
	map<string, list<string>> activities <- [
		act_shopping::remove_duplicates(OSM_shop), 
		act_eating::remove_duplicates(OSM_eat),
		act_leisure::remove_duplicates(OSM_leisure), 
		act_sport::remove_duplicates(OSM_sport),
	 	act_other::remove_duplicates(OSM_other_activity)
	 ];
	
	
	//for each category of age, and for each sex, the weight of the different activities
	map<list<int>,map<string,map<string,float>>> weight_activity_per_age_sex_class <- [
		 [0,10] :: 
		["M"::[act_friend::1.0, act_eating::0.5, act_shopping::0.5,act_leisure::1.0,act_sport::1.0,act_other::0.1 ], 
		"F"::[act_friend::1.0, act_eating::0.5, act_shopping::0.5,act_leisure::1.0,act_sport::1.0,act_other::0.1 ]],
	
		[11,18] :: 
		["M"::[act_friend::0.5, act_eating::2.0, act_shopping::1.0,act_leisure::3.0,act_sport::3.0,act_other::0.5 ], 
		"F"::[act_friend::0.5, act_eating::2.0, act_shopping::1.0,act_leisure::3.0,act_sport::1.0,act_other::0.5 ]],
	
		[19,60] :: 
		["M"::[act_friend::1.0, act_eating::1.0, act_shopping::1.0,act_leisure::1.0,act_sport::1.0,act_other::1.0 ], 
		"F"::[act_friend::2.0, act_eating::0.2, act_shopping::3.0,act_leisure::0.5,act_sport::0.5,act_other::1.0 ]],
	
		[61,120] :: 
		["M"::[act_friend::2.0, act_eating::0.5, act_shopping::0.5,act_leisure::0.5,act_sport::0.2,act_other::2.0 ], 
		"F"::[act_friend::2.0, act_eating::0.1, act_shopping::1.0,act_leisure::0.2,act_sport::0.1,act_other::2.0 ]]
	
	];
	
	//for each category of age, and for each sex, the weight of the different type of buildings
	map<list<int>,map<string,map<string,float>>> weight_bd_type_per_age_sex_class <- [
		[0,10] :: 
		["M"::["playground"::5.0, "park"::3.0], 
		"F"::["playground"::5.0, "park"::3.0]],
	
		[11,18] :: 
		["M"::["playground"::2.0, "park"::2.0], 
		"F"::["playground"::2.0, "park"::2.0,"cinema"::3.0]],
	
		[19,60] :: 
		["M"::["playground"::0.5, "park"::2.0], 
		"F"::["playground"::5.0, "park"::3.0]],
	
		[61,120] :: 
		["M"::["playground"::0.0, "park"::3.0, "place_of_worship"::2.0, "cinema"::2.0], 
		"F"::["playground"::0.0, "park"::3.0, "place_of_worship"::3.0,"cinema"::2.0]]
	
	];
		
}
