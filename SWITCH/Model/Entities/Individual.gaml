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
import "network_species/Building.gaml"
import "network_species/Hub_subspecies/HubCar.gaml"
import "network_species/Hub_subspecies/HubBike.gaml"

species Individual skills: [moving] control:simple_bdi{
	
	list<map<list<int>, predicate>> agenda_week;
	point target;
	path my_path;
	Building target_building;
	string status among: ["go to trip","passenger","driving","trip finished",nil];
	
	map<string,int> grades;//how agent care for differents criteria	
	map<string, float> priority_modes;//priority for each mode
	
	Building work_building;
	Building home_building;
	
	HubCar car_place;
	HubBike bike_place;
	
	//the trip the individual has to follow to join the activity
	list<Hub> transport_trip;
	
	rgb color <-#red;
	
	int age;
	string gender;
	// salaire ? catégorie socio ? 
	
	float distance;
	
	float time_bike;
	float time_car;
	float time_bus;
	float time_walk;
	
	float price_car;
	float price_bus;
	
	init{
		
		loop i from: 0 to: length(criteria)-1{
      		grades[criteria[i]]<- rnd(9);
	  	}
		
		
		loop i from: 0 to: length(type_mode)-1{
			priority_modes[type_mode[i]]<- compute_priority_mobility_mode(type_mode[i]);
		}
		
		
		
		
		//People agents are located anywhere in one of the building
		location <- any_location_in(home_building);
		distance <- home_building distance_to work_building;
		time_bike <- distance/bike_speed;
		time_car <- distance/car_speed;
		time_bus <- distance/bus_speed;
		time_walk <- distance/walk_speed;
		
		price_bus <- subscription_price/(21.8*2); //21.8 est le nombre moyen de jour "de semaine" par mois
		price_car <- (7.2*distance/100*gas_price)/(21.8*2);
		price_bus<- 0.68;
		price_car <- 0.8;
		
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
						val <- 0.5;
						//val <- 1- (price_car/max([price_car,price_bus]));
					}
					match "time" {
						//on considère que la voiture à une allure moyenne de 25km/h
						time_car <- distance/25.0;
						//val<- time_car/max([time_car,time_bike, time_bus, time_walk]);
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
						//val<-time_bike/max([time_car,time_bike, time_bus, time_walk]);
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
					 	val <-0.5;
					 	//val <- price_bus/max(price_car,price_bus);
					}
					match "time" {
						// On considère qu'un bus se déplace à 10km/h
						//val<-time_bus/max(time_car,time_bike, time_bus, time_walk);
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
			match "walk"{
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
						//val<-time_walk/max(time_car,time_bike, time_bus, time_walk);
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
			}//end match walk
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
	
	bool has_car{
		return not (car_place = nil);
	}
	
	bool has_bike{
		return not (bike_place = nil);
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
	
	//compute a trip acording to priority and target
	action compute_transport_trip(point target_){
		// for the moment this function is only returning a car trip
		return [car_place, HubCar closest_to target_];
	}
	
	plan do_work intention: working{
		if (not has_belief(at_target)) {
			//target <- any_location_in(work_building);
			target_building <- work_building;
			do add_subintention(get_current_intention(),at_target, true);
			status <- "go to trip";
			do current_intention_on_hold();
		}
		//color <- #blue;
	}
	
	plan do_stay_at_home intention: staying_at_home{
		if (not has_belief(at_target)) {
			target_building <- home_building;
			do add_subintention(get_current_intention(),at_target, true);
			do current_intention_on_hold();
		}
		//color <- #red;
	}
	
	plan do_eating_at_home intention: eating priority: rnd(1.0){
		if (not has_belief(at_target)) {
			target_building <- home_building;
			do add_subintention(get_current_intention(),at_target, true);
			do current_intention_on_hold();
		}
		//color <- #yellow;
	}
	
	plan do_eating_restaurant intention: eating priority: rnd(1.0){
		if (not has_belief(at_target)) {
			target_building <- any_location_in(one_of(Building));
			do add_subintention(get_current_intention(),at_target, true);
			do current_intention_on_hold();
		}
		//color <- #green;
	}
	
	plan see_a_movie intention: leisure priority: rnd(1.0){
		if (not has_belief(at_target)) {
			target_building <- any_location_in(one_of(Building));
			do add_subintention(get_current_intention(),at_target, true);
			do current_intention_on_hold();
		}
		//color <- #magenta;
	}
	
	plan meet_a_friend intention: leisure priority: rnd(1.0){
		if (not has_belief(at_target)) {
			target_building <- any_location_in(one_of(Building));
			do add_subintention(get_current_intention(),at_target, true);
			do current_intention_on_hold();
		}
		//color <- #blue;
	}

		
	//normal move plan
	/*plan driving intention: at_target  finished_when: target = location priority: compute_priority_mobility_mode("car"){
		if (my_path = nil) {
			my_path <- road_network path_between (location, target);
		}
		do follow path: my_path speed: car_speed #km/#h return_path: true;
		if (target = location) {
			do add_belief(at_target);
			my_path <- nil;
		}
		color <- #red;
	}*/
	
	aspect default {
		draw circle(20) color: #magenta rotate: heading border: #black;
	}	
		
}