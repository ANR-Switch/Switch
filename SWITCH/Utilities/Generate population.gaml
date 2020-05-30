/**
* Part of the SWITCH Project
* Author: Patrick Taillandier
* Tags: gis, OSM data
*/


model Generatepopulation


import "../Model/Entities/network_species/Building.gaml"

import "../Model/Entities/Individual.gaml" 


global {
		//GIS data
	list<file> shp_buildings <- define_shapefiles("buildings");
	geometry shape <- envelope(union(shp_buildings collect envelope(each)));
		
	bool parallel <- true;
	
	// ------------------------------------------- //
	// SYNTHETIC POPULATION FROM COMOKIT ALGORITHM //
	// ------------------------------------------- //
	
	Outside the_outside;
	
	init {
	 	//Initialization of the building using the shapefile of buildings
	 	loop shp_building over:shp_buildings {
			create Building from: shp_building with: [types::(string(get("types")) split_with ",")];
		}
		
		create Outside {the_outside <- self;}
		list<Building> homes <- Building where not empty(each.types inter possible_homes);
		map<string,list<Building>> buildings_per_activity ;
		list<string> tps <- remove_duplicates(Building accumulate each.types) ;
		loop t over: tps {
			buildings_per_activity[t] <- [];
		}
		ask Building {
			loop t over: types {
				buildings_per_activity[t] << self;
			}
		}
		
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
		write "Individual created";
		do assign_school_working_place(working_places,schools, min_student_age, max_student_age);
		write "Working placed assigned";
		
		do create_social_networks(min_student_age, max_student_age);	
		write "social network created";
		map<string,list<Individual>> inds <- Individual group_by each.sub_area;
		loop sa over: inds.keys {
			save inds[sa] type: shp to:dataset+ sa  + "/individuals.shp" attributes: [
			"sub_area"::sub_area,
			"age":: age,
			"gender"::gender,
			"category"::category,
			"work_pl":: work_building = nil ? -2 :((work_building = the_outside) ? -1 : work_building.id),
			"home_pl":: home_building.id,
			"rels"::string(relatives collect int(each)),
			"frs"::string(friends collect int(each)),
			"colls"::string(colleagues collect int(each))
			] ;
	
		}
		
	/*	save "id, agenda" type:text to:dataset_path + "agenda.csv";
		ask Individual {
			string ag <- "";
			loop i from:0 to: 6 {
				map<list<int>, pair<predicate,list<Individual>>> ag_day <- agenda_week[i];
				loop ti over: ag_day.keys {
					ag <- ag + ti[0] + ","+ ti[1] + ",";
					pair<predicate,list<Individual>> pred <- ag_day[ti];
					ag <- ag + pred.key.name + ":"+  (pred.value collect int(each)) + "$";
										
				}
				ag <- ag + "&";
			}
			save  ""+int(self) +";"+ ag type:text to:dataset_path + "agenda.csv" rewrite: false;
		}  */
		
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
						sub_area <- myself.sub_area;
					} 
					//mother
					create Individual {
						age <- rnd(max_student_age + 1,retirement_age);
						gender <- "F";
						home_building <- myself;
						household << self;
						sub_area <- myself.sub_area;
					
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
							sub_area <- myself.sub_area;
						}
					}
					if (flip(proba_grandfather)) {
						create Individual {
							category <- retired;
							age <- rnd(retirement_age + 1, max_age);
							gender <- "M";
							home_building <- myself;
							household << self;
							sub_area <- myself.sub_area;
						}
					}	
					if (flip(proba_grandmother)) {
						create Individual {
							category <- retired;
							age <- rnd(retirement_age + 1, max_age);
							gender <- "F";
							home_building <- myself;
							household << self;
							sub_area <- myself.sub_area;
						}
					}
				} else {
					create Individual {
						age <- rnd(min_student_age + 1,max_age);
						gender <- one_of(["M", "F"]);
						home_building <- myself;
						household << self;
						category <- age > retirement_age ? retired : none;
						sub_area <- myself.sub_area;
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
		
		ask Individual parallel:parallel {
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
		ask Individual parallel: true{
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

}



experiment generate_population type: gui {

	
	output {
		display map {
			species Building;
			species Individual;
		}
	}
}