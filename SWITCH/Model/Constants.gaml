/***
* Name: Constants
* Author: Patrick Taillandier
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model SWITCH

import "Entities/network_species/Road.gaml"
import "Entities/network_species/Crossroad.gaml"

global {
	
	
	//The list of activities
	string act_studying <- "studying";
	string act_working <- "working";
	string act_home <- "staying at home";
	string act_friend <- "visiting friend";
	string act_eating <- "eating";
	string act_shopping <- "shopping";
	string act_leisure <- "leisure";
	string act_sport <- "sport";
	string act_manage_kid <- "manage kid";
	string act_other <- "other activity";
	list<string> activity_list <- [act_studying,act_working,act_home,act_friend,act_eating,act_shopping,act_leisure,act_sport,act_manage_kid,act_other];
	list<string> mode_list <- ["car","bike","bus","walk","none"];
	
	predicate studying <- new_predicate(act_studying);
	predicate working <- new_predicate(act_working);
	predicate staying_at_home <- new_predicate(act_home);
	predicate visiting_friend <- new_predicate(act_friend);
	predicate leisure <- new_predicate(act_leisure);
	predicate eating <- new_predicate(act_eating);
	predicate shopping <- new_predicate(act_shopping);
	predicate practicing_sport <- new_predicate(act_sport);
	predicate manage_kid <- new_predicate(act_manage_kid);
	predicate doing_other_act <- new_predicate(act_other);
	
	predicate at_target <- new_predicate("at target");
	predicate at_subtarget <- new_predicate("at_subtarget");
	
	
	// OSM Constant (type of building) // A REMPLIR 
	list<string> OSM_eat <- ["restaurant","bakery"];
	list<string> OSM_home <- ["yes","house", "manor","apartments",'chocolate','shoes',"caravan"];
	list<string> OSM_shop <- ['commercial','supermarket',"bakery","frozen_food","alcohol","retail","furniture","bicycle"];
	list<string> OSM_leisure <- ["playground", "park", "cinema"];
	list<string> OSM_sport <- ['tennis','multi','basketball','soccer','rugby_league','swimming','cycling','pelota','boules','skateboard','beachvolleyball','athletics'];
	list<string> OSM_other_activity <- ['car_repair','garages','church','hairdresser',"chapel","memorial","ruins"];
	list<string> OSM_work_place <- ['office',"estate_agent","public","civic","government","manufacture","company"];
	list<string> OSM_school <- ["school"];
	
	//****************************************************
	
	// color constants
	map<predicate,rgb> colors_per_act <- [staying_at_home::#blue, working::#red, studying:: #cyan, leisure::#magenta, visiting_friend::#pink, eating::#darkorange, shopping::#gold, practicing_sport::#cyan, manage_kid::#grey, doing_other_act::#gray];
	
	map<string,rgb> colors_per_act_string <- [(staying_at_home.name)::#blue, (working.name)::#red, (studying.name):: #cyan, (leisure.name)::#magenta, (visiting_friend.name)::#pink, (eating.name)::#darkorange, (shopping.name)::#gold, (practicing_sport.name)::#cyan, (manage_kid.name)::#grey, (doing_other_act.name)::#gray];
	
	
	map<string,rgb> colors_per_mobility_mode <- ["car"::#olivedrab, "bike"::#maroon, "bus"::#palegreen, "walk"::#blueviolet,"none"::#gray];

	// ************Traffic Constants**********************
	//Graph of the road network
	graph<Crossroad,Road> road_network;
	
	
	// this map give a speed limit for a specific type of road with an urban and weather context
	map<list<string>,int> road_speed <- 
				  [["motorway","interurban","sunny"]::130,
				   ["motorway","urban","sunny"]::90,
				   ["motorway","interurban","rainy"]::110,
				   ["motorway","urban","rainy"]::80,
				   ["motorway","interurban","stormy"]::80,
				   ["motorway","urban","stormy"]::50,
				   ["trunk","interurban","sunny"]::110,
				   ["trunk","urban","sunny"]::110,
				   ["trunk","interurban","rainy"]::100,
				   ["trunk","urban","rainy"]::100,
				   ["trunk","interurban","stormy"]::80,
				   ["trunk","urban","stormy"]::80,
				   ["primary","interurban","sunny"]::90,
				   ["primary","urban","sunny"]::50,
				   ["primary","interurban","rainy"]::80,
				   ["primary","urban","rainy"]::50,
				   ["primary","interurban","stormy"]::50,
				   ["primary","urban","stormy"]::30,
				   ["secondary","interurban","sunny"]::90,
				   ["secondary","urban","sunny"]::50,
				   ["secondary","interurban","rainy"]::80,
				   ["secondary","urban","rainy"]::50,
				   ["secondary","interurban","stormy"]::50,
				   ["secondary","urban","stormy"]::30,
				   ["tertiary","interurban","sunny"]::90,
				   ["tertiary","urban","sunny"]::50,
				   ["tertiary","interurban","rainy"]::80,
				   ["tertiary","urban","rainy"]::50,
				   ["tertiary","interurban","stormy"]::50,
				   ["tertiary","urban","stormy"]::30,
				   ["residential","interurban","sunny"]::50,
				   ["residential","urban","sunny"]::50,
				   ["residential","interurban","rainy"]::50,
				   ["residential","urban","rainy"]::50,
				   ["residential","interurban","stormy"]::30,
				   ["residential","urban","stormy"]::30,
				   ["living_street","interurban","sunny"]::20,
				   ["living_street","urban","sunny"]::20,
				   ["living_street","interurban","rainy"]::20,
				   ["living_street","urban","rainy"]::20,
				   ["living_street","interurban","stormy"]::20,
				   ["living_street","urban","stormy"]::20
				  ];
	// this map give for a specific road type a coefficient like:
	// average_speed = coefficient * speed_limit
	map<string,float> road_speed_avg_coef <- 
			       ["motorway"::1.2,
			        "trunk"::0.5,
			        "primary"::0.5,
			        "secondary"::0.5,
			        "tertiary"::0.8,
			        "residential"::0.6,
			        "living_street"::1.0
			       ];
			       
	//those numbers represent the minimal time between two vehicules leaving the road (in second)
	//depending on the road type
	map<string,float> output_flow <- 
			       ["motorway"::1.8,
			        "trunk"::2.4,
			        "primary"::2.4,
			        "secondary"::2.4,
			        "tertiary"::6.0,
			        "residential"::6.0,
			        "living_street"::12.0
			       ];
	
	//***********************************************************
	
	//Type of model for building choice during activity
	string random <- "random";
	string gravity <- "gravity";
	string closest <- "closest";
	
	
		
	string worker <- "worker" const: true;
	string retired <- "retired" const: true;
	string student <- "student" const: true;
	string unemployed <- "unemployed" const: true;
	string none <- "none" const: true;
	
	//**********************************************************
	
	//Basic agendas for test purpose
	
	list<list<string>> agenda_work <- 
			       [["08:00:00","working"],
			        ["12:00:00","eating"],
			        ["14:00:00","working"],
			        ["18:00:00","staying_at_home"]
			       ];
	list<list<string>> agenda_work_then_leisure <- 
			       [["08:00:00","working"],
			        ["12:00:00","eating"],
			        ["14:00:00","working"],
			        ["18:00:00","staying_at_home"],
			        ["20:00:00","leisure"],
			        ["23:00:00","staying_at_home"]
			       ];
	list<list<string>> agenda_leisure <- 
			       [["14:00:00","leisure"],
			        ["19:00:00","staying_at_home"]
			       ];
	list<list<string>> agenda_couch_potato <- 
			       [
			       ];
			       
	
	list<string> retired_classic <- ["eating midday","stay at home afternoon"];
	list<string> retired_leisure1 <- ["leisure morning","eating midday","leisure afternoon","stay at home evening"];
	list<string> retired_leisure2 <- ["eating midday","leisure afternoon","stay at home evening"];
	list<string> retired_leisure3 <- ["leisure morning","eating midday","stay at home afternoon"];
	list<string> retired_shopping1 <- ["shopping morning","eating midday","stay at home afternoon"];
	list<string> retired_shopping2 <- ["eating midday","shopping afternoon","stay at home evening"];
	
	list<string> student_classic <- ["studying morning","eating midday","studying afternoon","stay at home evening"];
	list<string> student_sleep_bonus <- ["eating midday","studying afternoon","stay at home evening"];
	list<string> student_leisure <- ["studying morning","eating midday","leisure afternoon","stay at home afternoon"];
	list<string> student_classic_leisure <- ["studying morning","eating midday","studying afternoon","leisure evening","stay at home night"];
	
	list<string> active_nokid_classic <- ["working morning","eating midday","working afternoon","stay at home evening"];
	list<string> active_nokid_with_leisure <- ["working morning","eating midday","working afternoon","leisure evening","stay at home night"];
	list<string> active_nokid_with_shopping <- ["working morning","eating midday","working afternoon","shopping evening","stay at home night"];
	
	list<string> active_with_kid_classic <- ["manage kid morning","working morning","eating midday","working afternoon","manage kid evening","stay at home evening"];
	
	map<string,list<list<string>>> activity_chains_by_social_class <-
		[
			"retired"::[retired_classic,retired_leisure1,retired_leisure2,retired_leisure3,retired_shopping1,retired_shopping2],
			"student"::[student_classic,student_sleep_bonus,student_leisure,student_classic_leisure],
			"active"::[active_nokid_classic,active_nokid_with_leisure,active_nokid_with_shopping],
			"active with kid"::[active_with_kid_classic]
		];
}
