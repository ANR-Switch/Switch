/***
* Name: Constants
* Author: Patrick Taillandier
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model SWITCH



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
	string act_other <- "other activity";
	
	
	predicate studying <- new_predicate(act_studying);
	predicate working <- new_predicate(act_working);
	predicate staying_at_home <- new_predicate(act_home);
	predicate visiting_friend <- new_predicate(act_friend);
	predicate leisure <- new_predicate(act_leisure);
	predicate eating <- new_predicate(act_eating);
	predicate shopping <- new_predicate(act_shopping);
	predicate practicing_sport <- new_predicate(act_sport);
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
	
	//Type of model for building choice during activity
	string random <- "random";
	string gravity <- "gravity";
	string closest <- "closest";
	
	
		
	string worker <- "worker" const: true;
	string retired <- "retired" const: true;
	string student <- "student" const: true;
	string unemployed <- "unemployed" const: true;
	string none <- "none" const: true;
}
