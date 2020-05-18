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
	
	file individual_shapefile <- file_exists(dataset +"individuals.shp") ? shape_file(dataset+"individuals.shp") : nil;
	file agenda_file <- file_exists(dataset +"agenda.csv") ? csv_file(dataset+"agenda.csv", ";", true) : nil;
	
	//date (et heure) de début de la simulation : 7/4/2020 à 6h00 0"
	date starting_date <- date(2020,4,7,8,20,0);
	
	bool debug_mode <- true;
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

	int num_individuals <- 1000;
	
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
	 
	 list<predicate> activity_predicates <- [studying, working, staying_at_home,visiting_friend,leisure,eating,shopping,practicing_sport,doing_other_act];
	
	
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
	
	
	
	//Agenda paramaters
	list<int> non_working_days <- [7]; //list of non working days (1 = monday; 7 = sunday)
	int work_hours_begin_min <- 6; //beginning working hour: min value
	int work_hours_begin_max <- 8; //beginning working hour: max value 
	int work_hours_end_min <- 15; //ending working hour: min value
	int work_hours_end_max <- 18; //ending working hour: max value
	int school_hours_begin_min <- 7; //beginning studying hour: min value
	int school_hours_begin_max <- 9; //beginning studying hour: max value
	int school_hours_end_min <- 15; //ending studying hour: min value
	int school_hours_end_max <- 18; //ending studying hour: max value
	int first_act_hour_non_working_min <- 7; //for non working day, min hour for the beginning of the first activity 
	int first_act_hour_non_working_max <- 10; //for non working day, max hour for the beginning of the first activity 
	int lunch_hours_min <- 11; //min hour for the begining of the lunch time
	int lunch_hours_max <- 13; //max hour for the begining of the lunch time
	int max_duration_lunch <- 2; // max duration (in hour) of the lunch time
	int max_duration_default <- 3; // default duration (in hour) of activities
	int min_age_for_evening_act <- 13; //min age of individual to have an activity after school
	float nb_activity_fellows_mean <- 3.0;
	float nb_activity_fellows_std <- 2.0;

	int max_num_activity_for_non_working_day <- 4; //max number of activity for non working day
	int max_num_activity_for_unemployed <- 3; //max number of activity for a day for unployed individuals
	int max_num_activity_for_old_people <- 3; //max number of activity for a day for old people ([0,max_num_activity_for_old_people])
	float proba_activity_evening <- 0.7; //proba for people (except old ones) to have an activity after work
	float proba_lunch_outside_workplace <- 0.5; //proba to have lunch outside the working place (home or restaurant)
	float proba_lunch_at_home <- 0.5; // if lunch outside the working place, proba of having lunch at home
	
	float proba_work_outside <- 0.0; //proba for an individual to work outside the study area
	float proba_go_outside <- 0.0; //proba for an individual to do an activity outside the study area
	float proba_outside_contamination_per_hour <- 0.0; //proba per hour of being infected for Individual outside the study area 
		
	csv_file csv_parameter_agenda <- file_exists(dataset+"Agenda parameter.csv") ? csv_file(dataset+"Agenda parameter.csv",",",true):nil;
	csv_file csv_activity_weights <- file_exists(dataset+"Activity weights.csv") ? csv_file(dataset+"Activity weights.csv",",",string, false):nil;
	csv_file csv_building_type_weights <- file_exists(dataset+"Building type weights.csv") ? csv_file(dataset+"Building type weights.csv",",",string, false):nil;
	
	
			
	//Population data 
	csv_file csv_parameter_population <- file_exists(dataset+"Population parameter.csv") ? csv_file(dataset+"Population parameter.csv",",",true):nil;
	
	
	// ------ From default Gaml generator
	float proba_active_family <- 0.95;
	float number_children_mean <- 2.0;
	float number_children_std <- 0.5;
	int number_children_max <- 3;
	float proba_grandfather<-  0.2; //rate of grandfathers (individual with age > retirement_age) - num of grandfathers = N_grandfather * num of possible homes
	float proba_grandmother<- 0.3; //rate of grandmothers (individual with age > retirement_age) - num of grandmothers = M_grandmother * num of possible homes
	int retirement_age <- 55; //an individual older than (retirement_age + 1) are not working anymore
	int max_age <- 100; //max age of individual
	float nb_friends_mean <- 5.0; //Mean number of friends living in the considered area
	float nb_friends_std <- 3.0;//Stand deviation of the number of friends living in the considered area
	float nb_classmates_mean <- 10.0; //Mean number of classmates with which an Individual will have close contact
	float nb_classmates_std <- 5.0;//Stand deviation of the number of classmates with which an Individual will have close contact
	float nb_work_colleagues_mean <- 5.0; //Mean number of work colleagures with which an Individual will have close contact
	float nb_work_colleagues_std <- 3.0;//Stand deviation of the number of work colleagures with which an Individual will have close contact
	float proba_work_at_home <- 0.05; //probability to work at home;
	float proba_unemployed_M <- 0.03; // probability for a M individual to be unemployed.
	float proba_unemployed_F <-0.03; // probability for a F individual to be unemployed.
	list<string> possible_homes <- remove_duplicates(OSM_home + ["", "home", "hostel"]);  //building type that will be considered as home
	
	 //building type that will be considered as home - for each type, the coefficient to apply to this type for this choice of working place
	 //weight of a working place = area * this coefficient
	map<string, float> possible_workplaces <- (OSM_work_place as_map (each::2.0)) + map(["office"::3.0, "admin"::2.0, "industry"::1.0, "store"::1.0, "shop"::1.0,"bookstore"::1.0,
		"gamecenter"::1.0, "restaurant"::1.0,"coffeeshop"::1.0,"caphe"::1.0, "caphe-karaoke"::1.0,"farm"::0.1, "repairshop"::1.0,"hostel"::1.0
	]);
	
	// building type that will considered as school (ou university) - for each type, the min and max age to go to this type of school.
	map<list<int>,string> possible_schools <- [[3,18]::"school", [19,23]::"university"]; 
	
	
}
