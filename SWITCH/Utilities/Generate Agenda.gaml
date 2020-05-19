/**
* Name: GenerateAgenda
* Based on the internal empty template. 
* Author: admin_ptaillandie
* Tags: 
*/

 
model GenerateAgenda

import "../Model/Parameters.gaml"

import "../Model/Constants.gaml"

import "../Model/Entities/network_species/Building.gaml"

import "../Model/Entities/Individual.gaml"

global {
	// ----------------- //
	// SYNTHETIC AGENDAS //
	// ----------------- //
	
	
	// Inputs
	//   min_student_age : minimum age to be in a school
	//   max_student_age : maximum age to go to a school
	// 
	// Principles: each individual has a week agenda composed by 7 daily agendas (maps of hour::Activity).
	//             The agenda depends on the age (students/workers, retired and young children).
	//             Students and workers have an agenda with 6 working days and one leisure days.
	//             Retired have an agenda full of leisure days.
	action define_agenda {
		int min_student_age <- retirement_age;
		int max_student_age <- 0;
		map<list<int>,list<Building>> schools;
		loop l over: possible_schools.keys {
			max_student_age <- max(max_student_age, max(l));
			min_student_age <- min(min_student_age, min(l));
		}
		if (csv_parameter_agenda != nil) {
			loop i from: 0 to: csv_parameter_agenda.contents.rows - 1 {
				string parameter_name <- csv_parameter_agenda.contents[0,i];
				if (parameter_name in world.shape.attributes.keys) {
					if (parameter_name = "non_working_days" ) {
						non_working_days <- [];
						loop j from: 1 to: csv_parameter_agenda.contents.columns - 1 {
							int value <- int(csv_parameter_agenda.contents[j,i]);
							if (value >= 1 and value <= 7 and not(value in non_working_days)) {
								non_working_days << value;
							}
						}
					}
					else {
						float value <- float(csv_parameter_agenda.contents[1,i]);
						world.shape.attributes[parameter_name] <- value;
					}
				} 
			}
		}
		if (csv_activity_weights != nil) {
			matrix data <- matrix(csv_activity_weights);
			weight_activity_per_age_sex_class <- [];
			list<string> act_type;
			loop i from: 3 to: data.columns - 1 {
				act_type <<string(data[i,0]);
			}
			loop i from: 1 to: data.rows - 1 {
				list<int> cat <- [ int(data[0,i]),int(data[1,i])];
				map<string,map<string, float>> weights <- (cat in weight_activity_per_age_sex_class.keys) ? weight_activity_per_age_sex_class[cat] : map([]);
				string sex <- string(data[2,i]);
				map<string, float> weights_sex;
				loop j from: 0 to: length(act_type) - 1 {
					weights_sex[act_type[j]] <- float(data[j+3,i]); 
				}
				
				weights[sex] <- weights_sex;
				weight_activity_per_age_sex_class[cat] <- weights;
			}
		}	
		list<predicate> possible_activities_tot <- [visiting_friend,eating, shopping, practicing_sport, leisure, doing_other_act];
		list<predicate> possible_activities_without_rel <- possible_activities_tot - visiting_friend;
		ask Individual {
			loop times: 7 {agenda_week<<[];}
		}
		// Initialization for students or workers
		ask Individual where ((each.age < retirement_age) and (each.age >= min_student_age))  {
			// Students and workers have an agenda similar for 6 days of the week ...
			if (category = unemployed) {
				loop i from:1 to: 7 {
					ask myself {do manag_day_off(myself,i,possible_activities_without_rel,possible_activities_tot);}
				} 
			} else {
				loop i over: ([1,2,3,4,5,6,7] - non_working_days) {
					map<list<int>,pair<predicate,list<Individual>>> agenda_day <- agenda_week[i - 1];
					list<predicate> possible_activities <- empty(friends) ? possible_activities_without_rel : possible_activities_tot;
					int current_hour;
					if (age < max_student_age) {
						current_hour <- rnd(school_hours_begin_min,school_hours_begin_max);
						agenda_day[[current_hour, rnd(60)]] <- studying::[];
					} else {
						current_hour <-rnd(work_hours_begin_min,work_hours_begin_max);
						agenda_day[[current_hour, rnd(60)]] <- working::[];
					}
					bool already <- false;
					loop h from: lunch_hours_min to: lunch_hours_max {
						if (h in (agenda_day.keys collect each[0])){
							already <- true; 
							break;
						}
					}
					if not already {
						if (flip(proba_lunch_outside_workplace)) {
							current_hour <- rnd(lunch_hours_min,lunch_hours_max);
							int dur <- rnd(1,2);
							if (not flip(proba_lunch_at_home)) {
								list<Individual> inds <- max(0,gauss(nb_activity_fellows_mean,nb_activity_fellows_std)) among colleagues;
								loop ind over: inds {
									map<list<int>,pair<predicate,list<Individual>>> agenda_day_ind <- ind.agenda_week[i - 1];
									agenda_day_ind[[current_hour, rnd(60)]] <- eating::(inds - ind + self);
									if (ind.age < max_student_age) {
										agenda_day_ind[[current_hour + dur,rnd(60)]] <- studying::[];
									} else {
										agenda_day_ind[[current_hour + dur, rnd(60)]] <- working::[];
									}
								}
								agenda_day[[current_hour, rnd(60)]] <- eating::inds ;
							} else {
								agenda_day[[current_hour, rnd(60)]] <- staying_at_home::[];
							}
							current_hour <- current_hour + dur;
							if (age < max_student_age) {
								agenda_day[[current_hour, rnd(60)]] <- studying::[];
							} else {
								agenda_day[[current_hour, rnd(60)]] <- working::[];
							}
						}
					}
					if (age < max_student_age) {
						current_hour <- rnd(school_hours_end_min,school_hours_end_max);
					} else {
						current_hour <-rnd(work_hours_end_min,work_hours_end_max);
					}
					agenda_day[[current_hour, rnd(60)]] <- staying_at_home::[];
					
					already <- false;
					loop h2 from: current_hour to: 23 {
						if (h2 in agenda_day.keys) {
							already <- true;
							break;
						}
					}
					if not already and (age >= min_age_for_evening_act) and flip(proba_activity_evening) {
						current_hour <- current_hour + rnd(1,max_duration_lunch);
						predicate act <- myself.activity_choice(self, possible_activities);
						int current_hour <- min(23,current_hour + rnd(1,max_duration_default));
						int end_hour <- min(23,current_hour + rnd(1,max_duration_default));
						if not(act in [visiting_friend]) {
							list<Individual> cands <- friends where not(current_hour in (each.agenda_week[i - 1].keys collect first(each)));
							list<Individual> inds <- max(0,gauss(nb_activity_fellows_mean,nb_activity_fellows_std)) among cands;
							loop ind over: inds {
								map<list<int>,pair<predicate,list<Individual>>> agenda_day_ind <- ind.agenda_week[i - 1];
								agenda_day_ind[[current_hour, rnd(60)]] <- act::(inds - ind + self);
								int max_hour <- (agenda_day_ind.keys max_of each[0]);
								bool return_home <- agenda_day_ind[agenda_day_ind.keys first_with (each[0] = max_hour)].key = staying_at_home;
								if (return_home) {agenda_day_ind[[end_hour, rnd(60)]] <- staying_at_home::[];}
								
							}
							agenda_day[[current_hour, rnd(60)]] <- act::inds;
						} else {
							agenda_day[[current_hour, rnd(60)]] <- act::[];
						}
						agenda_day[[end_hour, rnd(60)]] <- staying_at_home::[];
					}
					agenda_week[i-1] <- agenda_day;
				}
				
				// ... but it is diferent for non working days : they will pick activities among the ones that are not working, studying or staying home.
				loop i over: non_working_days {
					ask myself {do manag_day_off(myself,i,possible_activities_without_rel,possible_activities_tot);}
				}
			}
		}
		
		// Initialization for retired individuals
		loop ind over: Individual where (each.age >= retirement_age) {
			loop i from:1 to: 7 {
				do manag_day_off(ind,i,possible_activities_without_rel,possible_activities_tot);
			}
		}
		
		ask Individual {
			loop i from: 0 to: 6 {
				if (not empty(agenda_week[i])) {
					
					map<list<int>,pair<predicate,list<Individual>>> agenda_day_ind <- agenda_week[i];
					int last_act <- (agenda_day_ind.keys) max_of first(each);
								
					if (agenda_day_ind[agenda_day_ind.keys first_with (each[0] = last_act)].key != staying_at_home) {
						int h <- last_act = 23 ? 23 : min(23, last_act + rnd(1,max_duration_default));
						agenda_week[i][[h, rnd(60)]] <- (staying_at_home)::[];
					}
				}
			}
		}
		
		
		
		
	}
	
	predicate activity_choice(Individual ind, list<predicate> possible_activities) {
		if (weight_activity_per_age_sex_class = nil ) or empty(weight_activity_per_age_sex_class) {
			return any(possible_activities);
		}
		loop a over: weight_activity_per_age_sex_class.keys {
			if (ind.age >= a[0]) and (ind.age <= a[1]) {
				map<string, float> weight_act <-  weight_activity_per_age_sex_class[a][ind.gender];
				list<float> proba_activity <- possible_activities collect ((each.name in weight_act.keys) ? weight_act[each.name]:1.0 );
				if (sum(proba_activity) = 0) {return any(possible_activities);}
				return possible_activities[rnd_choice(proba_activity)];
			}
		}
		return any(possible_activities);
		
	}
	
	
	
	//specific construction of a "day off" (without work or school)
	action manag_day_off(Individual current_ind, int day, list<predicate> possible_activities_without_rel, list<predicate> possible_activities_tot) {
		map<list<int>,pair<predicate,list<Individual>>> agenda_day <- current_ind.agenda_week[day - 1];
		list<predicate> possible_activities <- empty(current_ind.friends) ? possible_activities_without_rel : possible_activities_tot;
		int max_act <- (current_ind.age >= retirement_age) ? max_num_activity_for_old_people :(current_ind.category = unemployed ? max_num_activity_for_unemployed : max_num_activity_for_non_working_day);
		int num_activity <- rnd(0,max_act) - length(agenda_day);
		if (num_activity > 0) {
			list<int> forbiden_hours;
			bool act_beg <- false;
			int beg_act <- 0;
			loop h over: (agenda_day.keys collect (first(each)))sort_by each {
				if not (act_beg) {
					act_beg <- true;
					beg_act <- h;
				} else {
					act_beg <- false;
					loop i from: beg_act to:h {
						forbiden_hours <<i;
					}
				}
			}
			int current_hour <- rnd(first_act_hour_non_working_min,first_act_hour_non_working_max);
			loop times: num_activity {
				if (current_hour in forbiden_hours) {
					current_hour <- current_hour + 1;
					if (current_hour > 22) {
						break;
					} 
				}
				
				int end_hour <- min(23,current_hour + rnd(1,max_duration_default));
				if (end_hour in forbiden_hours) {
					end_hour <- forbiden_hours first_with (each > current_hour) - 1;
				}
				if (current_hour >= end_hour) {
					break;
				}
				predicate act <-activity_choice(current_ind, possible_activities);
				if not(act in [visiting_friend, staying_at_home, working, studying] ) {
				
					list<Individual> cands <- current_ind.friends where not(current_hour in (each.agenda_week[day - 1].keys collect first(each)));
					list<Individual> inds <- max(0,gauss(nb_activity_fellows_mean,nb_activity_fellows_std)) among cands;
					
					loop ind over: inds {
						map<list<int>,pair<predicate,list<Individual>>> agenda_day_ind <- ind.agenda_week[day - 1];
							agenda_day_ind[[current_hour, rnd(60)]] <- act::(inds - ind + current_ind);
							int max_hour <- (agenda_day_ind.keys max_of each[0]);
							bool return_home <- agenda_day_ind[agenda_day_ind.keys first_with (each[0] = max_hour)].key = staying_at_home;
							if (return_home) {agenda_day_ind[[end_hour, rnd(60)]] <- staying_at_home::[];}
							
						
					}
					agenda_day[[current_hour, rnd(60)]] <- act::inds;
				} else {
					agenda_day[[current_hour, rnd(60)]] <- act::[];
				}
				agenda_day[[end_hour, rnd(60)]] <- staying_at_home::[];
				current_hour <- end_hour + 1;
			}
		}
		current_ind.agenda_week[day-1] <- agenda_day;
	}	
}
		