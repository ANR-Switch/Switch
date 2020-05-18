/**
* Part of the SWITCH Project
* Author: Patrick Taillandier
* Tags: gis, OSM data
*/


model Generatepopulation

import "../Model/Constants.gaml"

import "../Model/Entities/network_species/Building.gaml"

import "../Model/Entities/Individual.gaml"


global {
	//define the path to the dataset folder
	string dataset_path <- "../Datasets/Castanet Tolosan/";

	//GIS data
	file shp_buildings <- file_exists(dataset_path+"buildings.shp") ? shape_file(dataset_path+"buildings.shp"):nil;
	geometry shape <- envelope(shp_buildings);
	
	
	
		
	//Population data 
	csv_file csv_parameter_population <- file_exists(dataset_path+"Population parameter.csv") ? csv_file(dataset_path+"Population parameter.csv",",",true):nil;
	csv_file csv_parameter_agenda <- file_exists(dataset_path+"Agenda parameter.csv") ? csv_file(dataset_path+"Agenda parameter.csv",",",true):nil;
	csv_file csv_activity_weights <- file_exists(dataset_path+"Activity weights.csv") ? csv_file(dataset_path+"Activity weights.csv",",",string, false):nil;
	csv_file csv_building_type_weights <- file_exists(dataset_path+"Building type weights.csv") ? csv_file(dataset_path+"Building type weights.csv",",",string, false):nil;
	
	
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
	
	// ------------------------------------------- //
	// SYNTHETIC POPULATION FROM COMOKIT ALGORITHM //
	// ------------------------------------------- //
	
	Outside the_outside;
	
	init {
	 	//Initialization of the building using the shapefile of buildings
		create Building from: building_shapefile;
		
		create Outside {the_outside <- self;}
		list<Building> homes <- Building where (each.type in possible_homes);
		map<string,list<Building>> buildings_per_activity <- Building group_by (each.type);
		
		map<Building,float> working_places;
		loop wp over: possible_workplaces.keys {
			if (wp in buildings_per_activity.keys) {
					working_places <- working_places +  (buildings_per_activity[wp] as_map (each:: (each.shape.area * possible_workplaces[wp])));  
			}
		}
		
		int min_student_age <- retirement_age;
		int max_student_age <- 0;
		map<list<int>,list<Building>> schools;
		loop l over: possible_schools.keys {
			max_student_age <- max(max_student_age, max(l));
			min_student_age <- min(min_student_age, min(l));
			string type <- possible_schools[l];
			schools[l] <- (type in buildings_per_activity.keys) ? buildings_per_activity[type] : list<Building>([]);
		}
		do create_population(working_places, schools, homes, min_student_age, max_student_age);
		do assign_school_working_place(working_places,schools, min_student_age, max_student_age);
		
		do create_social_networks(min_student_age, max_student_age);	
		
		do define_agenda(min_student_age, max_student_age);	

	
		save Individual type: shp to:dataset_path + "individuals.shp" attributes: [
			"age":: age,
			"gender"::gender,
			"category"::category,
			"work_pl":: (work_building = the_outside) ? -1 : int(work_building),
			"work_pl":: int(home_building),
			"relatives"::relatives collect int(self),
			"friends"::friends collect int(self),
			"colleagues"::colleagues collect int(self)
			] ;
	
		save "id, agenda" type:text to:dataset_path + "agenda.csv";
		ask Individual {
			save  ""+int(self) +";"+ agenda_week type:text to:dataset_path + "agenda.csv";
		}
		
	}
	/*
	 * The default algorithm to create a population of agent from simple rules. </p>
	 * 
	 * The <b> arguments </b> includes: </br> 
	 * - min_student_age :: minimum age for lone individual </br>
	 * - max_student_age :: age that makes the separation between adults and children </p>
	 * 
	 * The <b> parameter </b> to adjust the process: </br>
	 * - nb_households :: the number of household per building (can be set using feature 'flat' from the shapefile of buildings) </br>
	 * - proba_active_family :: the probability to build a father+mother classical household rather than a lonely individual </br>
	 * - retirement_age :: the age that makes the separation between active and retired adults (will have a great impact on the agenda) </br>
	 * - number_children_max, number_children_mean, number_children_std :: assign a given number of children between 0 and max using gaussian mean and std </br>
	 * - proba_grandfather, proba_grandmother :: assign grand mother/father to the household
	 * </p>
	 */
	action create_population(map<Building,float> working_places,map<list<int>,list<Building>> schools, list<Building> homes, 
		int min_student_age, int max_student_age
	) {
		
		if (csv_parameter_population != nil) {
			loop i from: 0 to: csv_parameter_population.contents.rows - 1 {
				string parameter_name <- csv_parameter_population.contents[0,i];
				float value <- float(csv_parameter_population.contents[1,i]);
				world.shape.attributes[parameter_name] <- value;
				
			}
		}
		list<list<Individual>> households;
		
		ask homes {
			loop times: nb_households {
				list<Individual> household;
				if flip(proba_active_family) {
				//father
					create Individual {
						age <- rnd(max_student_age + 1,retirement_age);
						gender <- "M";
						home_building <- myself;
						household << self;
					} 
					//mother
					create Individual {
						age <- rnd(max_student_age + 1,retirement_age);
						gender <- "F";
						home_building <- myself;
						household << self;
					
					}
					//children
					int number <- min(number_children_max, round(gauss(number_children_mean,number_children_std)));
					if (number > 0) {
						create Individual number: number {
							//last_activity <-first(staying_home);
							age <- rnd(0,max_student_age);
							gender <- one_of(["M", "F"]);
							home_building <- myself;
							household << self;
						}
					}
					if (flip(proba_grandfather)) {
						create Individual {
							category <- retired;
							age <- rnd(retirement_age + 1, max_age);
							gender <- "M";
							home_building <- myself;
							household << self;
						}
					}	
					if (flip(proba_grandmother)) {
						create Individual {
							category <- retired;
							age <- rnd(retirement_age + 1, max_age);
							gender <- "F";
							home_building <- myself;
							household << self;
						}
					}
				} else {
					create Individual {
						age <- rnd(min_student_age + 1,max_age);
						gender <- one_of(["M", "F"]);
						home_building <- myself;
						household << self;
						category <- age > retirement_age ? retired : worker;
					} 
				}
				
				ask household {
					relatives <- household - self;
				}  
				households << household;
			}
		}
		ask Individual {
			location <- any_location_in(home_building);
		}
		ask Individual where ((each.age >= max_student_age) and (each.age < retirement_age)) {
			category <- flip((gender = "M") ? proba_unemployed_M : proba_unemployed_F) ? unemployed : worker;
		}	
	}
	
	
	//Initialiase social network of the agents (colleagues, friends)
	action initialise_social_network(map<Building,list<Individual>> working_places, map<Building,list<Individual>> schools, map<int,list<Individual>> ind_per_age_cat) {
		
		ask Individual {
			int nb_friends <- max(0,round(gauss(nb_friends_mean,nb_friends_std)));
			loop i over: ind_per_age_cat.keys {
				if age < i {
					friends <- nb_friends among ind_per_age_cat[i];
					friends <- friends - self;
					break;
				}
			}
			
			if (category = worker) {
				int nb_colleagues <- max(0,int(gauss(nb_work_colleagues_mean,nb_work_colleagues_std)));
				if nb_colleagues > 0 {
					colleagues <- nb_colleagues among (working_places[work_building] - self);
				}
			} 
			else if (category = student) {
				int nb_classmates <- max(0,int(gauss(nb_classmates_mean,nb_classmates_std)));
				if nb_classmates > 0 {
					colleagues <- nb_classmates among ((schools[work_building] where ((each.age >= (age -1)) and (each.age <= (age + 1))))- self);
				}
			}
		}
	
 	}
	
	
	// ----------------------------------- //
	// SYNTHETIC POPULATION SOCIAL NETWORK //
	// ----------------------------------- //
	
	/*
	 * The default algorithm to create a the social network (friends and colleagues) of agent from simple rules :</p>
	 *  - choose friends from the same age category  </br> 
	 *  - choose colleagues from agents working at the same place  </br> 
	 * 
	 * The <b> arguments </b> includes: </br> 
	 * - min_student_age :: minimum age for lone individual </br>
	 * - max_student_age :: age that makes the separation between adults and children </p>
	 * 
	 * The <b> parameter </b> to adjust the process: </br>
	 * - min_age_for_evening_act :: the minimum age to have a autonomous activity during evening </br>
	 * - retirement_age :: age of retirement </br>
	 * - nb_friends_mean :: mean number of friends per individual </br>
	 * - nb_friends_std :: standard deviation of the number of friends per individual  </br>
	 * - nb_work_colleagues_mean :: mean number of work colleagues per individual (with who the individual will have strong interactions) </br>
	 * - nb_work_colleagues_std :: standard deviation of the number of work colleagues per individual  </br>
	 * - nb_classmates_mean :: mean number of classmates per individual (with who the individual will have strong interactions)  </br>
	 * - nb_classmates_std :: standard deviation of the number of classmates per individual  </br>
	 * 
	 */
	action create_social_networks(int min_student_age, int max_student_age) {
		map<Building, list<Individual>> WP<- (Individual where (each.category = worker)) group_by each.work_building;
		map<Building, list<Individual>> Sc<- (Individual where (each.category = student)) group_by each.work_building;
		map<int,list<Individual>> ind_per_age_cat;
		ind_per_age_cat[min_age_for_evening_act] <- [];
		ind_per_age_cat[min_student_age] <- [];
		ind_per_age_cat[max_student_age] <- [];
		ind_per_age_cat[retirement_age] <- [];
		ind_per_age_cat[max_age] <- [];
		
		loop p over: Individual {
			loop cat over: ind_per_age_cat.keys {
				if p.age < cat {
					ind_per_age_cat[cat]<<p;
					break;
				}  
			}
		}
		do initialise_social_network(WP, Sc,ind_per_age_cat);
	}
	
	// ------------------------------------------------------- //
	// SYNTHETIC POPULATION SCHOOL / WORK LOCATION ASSIGNEMENT //
	// ------------------------------------------------------- //
	
	// Inputs
	//   working_places : map associating to each Building a weight (= surface * coefficient for this type of building to be a working_place)
	//   schools :  map associating with each school Building its area (as a weight of the number of students that can be in the school)
	//   min_student_age : minimum age to be in a school
	//   max_student_age : maximum age to go to a school
	action assign_school_working_place(map<Building,float> working_places,map<list<int>,list<Building>> schools, int min_student_age, int max_student_age) {
		
		// Assign to each individual a school and working_place depending of its age.
		// in addition, school and working_place can be outside.
		// Individuals too young or too old, do not have any working_place or school 
		ask Individual {
			if (age >= min_student_age) {
				if (age < max_student_age) {
					category <- student;
					loop l over: schools.keys {
						if (age >= min(l) and age <= max(l)) {
							if (flip(proba_go_outside) or empty(schools[l])) {
								work_building <- the_outside;	
							} else {
								switch choice_of_target_mode {
									match random {
										work_building <- one_of(schools[l]);
									}
									match closest {
										work_building <- schools[l] closest_to self;
									}
									match gravity {
										list<float> proba_per_building;
										loop b over: schools[l] {
											float dist <- max(20,b.location distance_to home_building.location);
											proba_per_building << (b.shape.area / dist ^ gravity_power);
										}
										work_building <- schools[l][rnd_choice(proba_per_building)];	
									}
								}
								
							}
						}
					}
				} else if (age < retirement_age) { 
					if flip(proba_work_at_home) {
						work_building <- home_building;
					}
					else if (flip(proba_go_outside) or empty(working_places)) {
						work_building <- the_outside;	
					} else {
						switch choice_of_target_mode {
							match random {
								work_building <- working_places.keys[rnd_choice(working_places.values)];
								
							}
							match closest {
								work_building <- working_places.keys closest_to self;
							}
							match gravity {
								list<float> proba_per_building;
								loop b over: working_places.keys {
									float dist <-  max(20,b.location distance_to home_building.location);
									proba_per_building << (working_places[b]  / (dist ^ gravity_power));
								}
								work_building <- working_places.keys[rnd_choice(proba_per_building)];	
							}
						}
					}
					
				}
			}
		}		
	}
	
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
	action define_agenda(int min_student_age, int max_student_age) {
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
				current_hour <- end_hour + 1;
			}
		}
		current_ind.agenda_week[day-1] <- agenda_day;
	}
		
}

