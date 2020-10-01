/**
* Name: GenerateGTFSshapefiles
* Based on the internal empty template. 
* Author: Lo�c
* Tags: 
*/
model stochastic_pop_gen

import "../Model/Entities/Individual.gaml"
import "../Model/Parameters.gaml"
import "../Model/Constants.gaml"
import "../Model/Global.gaml"

global {

	action generate_population {
		
		create Individual number: num_individuals {
			home_place <- any_location_in(one_of(home_buildings));
			work_place <- any_location_in(one_of(work_buildings));
			location <- home_place;
			car_place <- any_location_in(Road closest_to self);
			bike_place <- location;
			work_place <- any_location_in(one_of(work_buildings));
			school_place <- any_location_in(one_of(school_buildings));
			shopping_place <- any_location_in(one_of(shop_buildings));
			leisure_place <- any_location_in(one_of(leisure_buildings));
			prefered_transport_mode <- myself.pickPreferedTpMode();
			day_agenda <- myself.getAgenda();
			do registerNextActivity;
		}
	}

	string pickPreferedTpMode {
		float rand <- rnd(1.0);
		float cumul_prob <- 0.0;
		loop tp_mode_name over: prefered_tp_mode_proba.keys {
			cumul_prob <- cumul_prob + prefered_tp_mode_proba[tp_mode_name];
			if rand <= cumul_prob {
				return tp_mode_name;
			}
		}
		return "car";
	}
	
	// return an agenda like [[string activity, float starting_time]...]
	list<list> getAgenda{
		string social_class <- pickSocialClass();
		list<string> activity_chain <- one_of(activity_chains_by_social_class[social_class]);
		
		list<list> agenda <- [];
		float last_start <- 0.0;
		loop activity over:activity_chain{
			float act_start_time <- gauss(activity_start_distrib[activity].key,activity_start_distrib[activity].value);
			if (length(agenda) > 0) and (float(last(agenda)[1]) > act_start_time){
				act_start_time <- float(last(agenda)[1]) +1800.0;
			}
			agenda << [refactorActivityName(activity),act_start_time];
		}
		return agenda;
	}

	string pickSocialClass {
		float rand <- rnd(1.0);
		float cumul_prob <- 0.0;
		loop sc_name over: social_class_distrib.keys {
			cumul_prob <- cumul_prob + social_class_distrib[sc_name];
			if rand <= cumul_prob {
				return sc_name;
			}
		}
		return "retired";
	}
	
	string refactorActivityName(string activity_name){
		switch activity_name{
			match_one ["eating midday"]{return "eating";}
			match_one ["stay at home morning","stay at home afternoon","stay at home evening","stay at home night"]{return "staying at home";}
			match_one ["leisure morning","leisure afternoon","leisure evening","leisure night"]{return "leisure";}
			match_one ["shopping morning","shopping afternoon","shopping evening","shopping night"]{return "shopping";}
			match_one ["studying morning","studying afternoon","studying evening","studying night"]{return "studying";}
			match_one ["working morning","working afternoon","working evening","working night"]{return "working";}
			match_one ["manage kid morning","manage kid afternoon","manage kid evening","manage kid night"]{return "manage kid";}
		}
	}
}