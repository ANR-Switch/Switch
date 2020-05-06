/***
* Name: Individual
* Author: admin_ptaillandie
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model SWITCH

import "../Global.gaml"
import "../Parameters.gaml"
import "../Constants.gaml"
import "../Entities/network_species/Building.gaml"

species Individual skills: [moving] control:simple_bdi{
	list<map<list<int>, predicate>> agenda_week;
	point target;
	path my_path;
	Building target_building;
	
	map<string,int> grades;//how agent care for differents criteria	
	map<string, float> priority_modes;//priority for each mode
	
	Building work_building;
	Building home_building;
	
	rgb color <-#red;
	
	float distance;
	
	
	
	
	init{
		
		loop i from: 0 to: length(criteria)-1{
      		grades[criteria[i]]<- rnd(9);
	  	}
		
		
		loop i from: 0 to: length(type_mode)-1{
			priority_modes[type_mode[i]]<- compute_priority_mobility_mode(type_mode[i]);
		}
		
		
		
		//People agents are located anywhere in one of the building
		location <- home_building.location;
		distance <- home_building distance_to work_building;
		
		
		//0 = lundi; 6 = dimanche
		loop i from: 0 to: 6 {
			// ce que je fais durant la journee
			
			map<list<int>,predicate> agenda_day;
			if (i < 5) {
				agenda_day[[8,30]] <- working;
				agenda_day[[12,0]] <- eating;
				agenda_day[[13,30]] <- working; 
				agenda_day[[17,30]] <- staying_at_home; 
			} else {
				agenda_day[[12,0]] <- eating;
				agenda_day[[15,0]] <- leisure;
			}
			agenda_week << agenda_day;
		}
		do add_desire(staying_at_home);
		
	}
	
	
	//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
	// Maj var agent
	//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
	float compute_value(string type, string criterion){ //compute contextual value according to mode and criteria
		float val;
		switch type {
			match "car" {
				switch criterion {
					match "comfort" {
						val <- 1.0;
					}
					match "price" {
						//on considère qu'une voiture dépense 7,2 litres pour 100 km(moyenne sur 2019)
						float abs_price <- 7.2*distance/100*gas_price;
						//voir comment normaliser
						val <-0.5;
					}
					match "time" {
						//on considère que la voiture à une allure moyenne de 25km/h
						float abs_time <- distance/25.0;
						//pareil, normaliser en comparant avec les autres ?
						val <-0.5;
					}
					match "ecology"{
						val <-0.0;
					}
					match "simplicity"{
						val <- 1.0;
					}
					match "safety"{
						val <- percentage_of_drivers/100;
						
						//eventuellement prendre en compte la capacité de la route ? est-ce une info à la quelle on a accès ?
					}
				}	
			}//end match car
			match "bike" {
				switch criterion {
					match "comfort" {
						//enfants, motif du déplacement
						val <-0.5;
					}
					match "price" {
						val <- 1.0;
					}
					match "time" {
						//on considère que les vélos se déplacent en moyenne à 10km/h
						float abs_time <- distance/10.0;
						val <-0.5;
					}
					match "ecology"{
						val <- 1.0;
					}
					match "simplicity"{
						// dans le trajet effectué, voir pourcentage route cyclables + distance au dessus de 20min pas cool (voir papiers socio)
						val <-0.5;
					}
					match "safety"{
						//dans le trajet effectué pourcentage de route non partagée avec automobilistes
						val <-0.5;
					}			
				}
			}//end match bike
			match "bus" {
				switch criterion {
					match "comfort" {
						//selon son heure de départ
						//nb de personnes qu'on peut transporter en 30min - nb actuel de passager
						float val1 <- ((30/bus_freq)* bus_capacity) - number_of_users_per_hour[[int(current_date.hour,floor(current_date.minute/30)*30)]];
						val <- val1/((30/bus_freq)* bus_capacity);
					}
					match "price" {
					 	float abs_price <- subscription_price;
						val <-0.5;
					}
					match "time" {
						// On considère qu'un bus se déplace à 10km/h
						float abs_time <- distance/10.0;
						val <-0.5;
					}
					match "ecology"{
						val <- 0.75;
					}
					match "simplicity"{
						//Dépend du nombre de ligne de bus différentes à prendre; à voir comment faire avec ces data
						val <-0.5;
					}
					match "safety"{
						if(current_date.hour>21.0){
							val <- 0.5;
						} else {
							val <- 0.90;
						}
					}
				}
				
			}//end match bus
			match "feet"{
				switch criterion {
					match "comfort" { 
						if(distance < 3){
							val <- 1- distance /3.0;
						} else {
							val <- 0.0;
						}
					}
					match "price" {
						val <- 1.0;
					}
					match "time" {
						float abs_time <- distance/5;
						val <-0.5;
					}
					match "ecology"{
						val <- 1.0;
					}
					match "simplicity"{
						if(distance < 3){
							val <- 1- distance /3.0;
						} else {
							val <- 0.0;
						}
					}
					match "safety"{
						if(current_date.hour > 21 or current_date.hour<5){
							val <- 0.2;
						} else {
							val <- 1.0;
						}
					}			
					
				}//end match criterion
			}//end match feet
		}//end switch
		
		return val;
	}

	
	float compute_priority_mobility_mode(string type) {
		float val <- 0.0;
		loop i from: 0 to: length(criteria)-1{
			val <- grades[criteria[i]]*compute_value(type,criteria[i]);
		}
	
		return val/length(criteria);
	}
	
	
	
	bool is_time(int hour, int minute) {
		return current_date.hour = hour and current_date.minute = minute;
	}
	
	reflex executeAgenda {
		predicate act <- agenda_week[current_date.day_of_week - 1][[current_date.hour,current_date.minute]];
		if (act != nil) {
			if (get_current_intention() != nil) {
				do remove_intention(first(intention_base).predicate, true);
			}
			
			do remove_belief(at_target);
			do add_desire(act);
		}
	}
	
	plan do_work intention: working{
		if (not has_belief(at_target)) {
			target <- any_location_in(work_building);
			do add_subintention(get_current_intention(),at_target, true);
			do current_intention_on_hold();
		}
		//color <- #blue;
	}
	
	
	plan do_stay_at_home intention: staying_at_home{
		if (not has_belief(at_target)) {
			target <- any_location_in(home_building);
			do add_subintention(get_current_intention(),at_target, true);
			do current_intention_on_hold();
		}
		//color <- #red;
	}
	
	plan do_eating_at_home intention: eating priority: rnd(1.0){
		if (not has_belief(at_target)) {
			target <- any_location_in(home_building);
			do add_subintention(get_current_intention(),at_target, true);
			do current_intention_on_hold();
		}
		//color <- #yellow;
	}
	
	plan do_eating_restaurant intention: eating priority: rnd(1.0){
		if (not has_belief(at_target)) {
			target <- any_location_in(one_of(Building));
			do add_subintention(get_current_intention(),at_target, true);
			do current_intention_on_hold();
		}
		//color <- #green;
	}
	
	plan see_a_movie intention: leisure priority: rnd(1.0){
		if (not has_belief(at_target)) {
			target <- any_location_in(one_of(Building));
			do add_subintention(get_current_intention(),at_target, true);
			do current_intention_on_hold();
		}
		//color <- #magenta;
	}
	
	plan meet_a_friend intention: leisure priority: rnd(1.0){
		if (not has_belief(at_target)) {
			target <- any_location_in(one_of(Building));
			do add_subintention(get_current_intention(),at_target, true);
			do current_intention_on_hold();
		}
		//color <- #blue;
	}
	
	
	
	
		
	//normal move plan
	plan driving intention: at_target  finished_when: target = location priority: compute_priority_mobility_mode("car"){
		if (my_path = nil) {
			my_path <- road_network path_between (location, target);
		}
		do follow path: my_path speed: 20 #km/#h return_path: true;
		if (target = location) {
			do add_belief(at_target);
			my_path <- nil;
		}
		color <- #red;
	}
	
	plan cycling intention: at_target  finished_when: target = location priority: compute_priority_mobility_mode("bike"){
		if (my_path = nil) {
			my_path <- road_network path_between (location, target);
		}
		do follow path: my_path speed: 8 #km/#h return_path: true;
		if (target = location) {
			do add_belief(at_target);
			my_path <- nil;
		}
		color <- #green;
	}
	
	plan walking intention: at_target  finished_when: target = location priority: compute_priority_mobility_mode("feet"){
		if (my_path = nil) {
			my_path <- road_network path_between (location, target);
		}
		do follow path: my_path speed: 3 #km/#h return_path: true;
		if (target = location) {
			do add_belief(at_target);
			my_path <- nil;
		}
		color <- #yellow;
	}
	
	plan taking_bus intention: at_target  finished_when: target = location priority: compute_priority_mobility_mode("bus"){
		if (my_path = nil) {
			my_path <- road_network path_between (location, target);
		}
		do follow path: my_path speed: 10 #km/#h return_path: true;
		if (target = location) {
			do add_belief(at_target);
			my_path <- nil;
		}
		color <- #blue;
	}
	
	aspect default {
		draw triangle(30) color: color rotate: heading border: #black depth: 1.0;
	}	
		
}