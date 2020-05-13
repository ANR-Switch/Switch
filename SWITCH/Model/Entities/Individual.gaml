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
	point subtarget;
	path my_path;
	Building target_building;
	string status among: ["go to trip","passenger","driving","arrived",nil];
	
	map<string,int> grades;//how agent care for differents criteria	
	map<string, float> priority_modes;//priority for each mode
	
	Building work_building;
	Building home_building;
	
	HubCar car_place;
	HubBike bike_place;
	
	//the trip the individual has to follow to join the activity
	//the trip is modelized as a Hub pair list:
	//the first Hub of the pair is the entry Hub and the second is the exit one
	//the individual need to make the trip between those pair by foot
	list<pair<Hub,Hub>> transport_trip;
	int trip_pointer <- 0;
	
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
				agenda_day[[8,30,0]] <- working;
				//agenda_day[[12,0,0]] <- eating;
				//agenda_day[[13,30,0]] <- working; 
				agenda_day[[17,30,0]] <- staying_at_home; 
			} else {
				/*agenda_day[[12,0,0]] <- eating;
				agenda_day[[15,0,0]] <- leisure;
				agenda_day[[17,30,0]] <- staying_at_home;*/
				agenda_day[[8,30,0]] <- working;
				agenda_day[[17,30,0]] <- staying_at_home; 
			}
			agenda_week << agenda_day;
		}
		do add_belief(at_target);
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
		predicate act <- agenda_week[current_date.day_of_week - 1][[current_date.hour,current_date.minute,current_date.second]];
		if (act != nil) {
			if (get_current_intention() != nil) {
				do remove_intention(first(intention_base).predicate, true);
			}
			write "start activity: "+act;
			do remove_belief(at_target);
			do add_desire(act);
		}
	}
	
	//compute a trip acording to priority and target
	action compute_transport_trip(point target_){
		// for the moment this function is only returning a car trip
		transport_trip << car_place :: HubCar closest_to target_;
		trip_pointer <- 0;
	}
	
	plan do_work intention: working{
		if (not has_belief(at_target)) {
			write "go to work";
			target_building <- work_building;
			do compute_transport_trip(target_building.location);
			status <- "go to trip";
			do add_subintention(get_current_intention(),at_target, true);
			do current_intention_on_hold();
		}
	}
	
	plan do_stay_at_home intention: staying_at_home{
		if (not has_belief(at_target)) {
			write "go to home";
			target_building <- home_building;
			do add_subintention(get_current_intention(),at_target, true);
			do current_intention_on_hold();
		}
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
			target_building <- one_of(Building);
			do add_subintention(get_current_intention(),at_target, true);
			do current_intention_on_hold();
		}
		//color <- #green;
	}
	
	plan see_a_movie intention: leisure priority: rnd(1.0){
		if (not has_belief(at_target)) {
			target_building <- one_of(Building);
			do add_subintention(get_current_intention(),at_target, true);
			do current_intention_on_hold();
		}
		//color <- #magenta;
	}
	
	plan meet_a_friend intention: leisure priority: rnd(1.0){
		if (not has_belief(at_target)) {
			target_building <- one_of(Building);
			do add_subintention(get_current_intention(),at_target, true);
			do current_intention_on_hold();
		}
		//color <- #blue;
	}

		
	//normal move plan
	
	plan execute_trip intention: at_target  finished_when: location = target_building.location priority: 10{
		do compute_transport_trip(target_building.location);
		//boucle sur les hubs par pas de 2 (alterne marche/transport)
		loop i from:0 to: length(transport_trip)-2 step: 2 {
			subtarget <- transport_trip[i].location;//marche jusqu'au hub
			do add_subintention(get_current_intention(),at_subtarget,true); 
			do current_intention_on_hold();
			write "ask hub: "+transport_trip[i]+" to go to hub: "+transport_trip[i+1];
			ask transport_trip[i]{
				do enter([myself],myself.transport_trip[i+1]);
			}
			
			do remove_belief(at_subtarget);
		}
		//fin : marcher jusqu'a la target finale du trajet
		subtarget <- target_building.location;
		if(not has_belief(at_subtarget)){
			do add_subintention(get_current_intention(),at_subtarget,true);
		}
		if (location = target_building.location) { 
			do add_belief(at_target);
		}
	}
	
	plan execute_trip intention: at_target{
		switch status{
			match "go to trip"{
				do add_subintention(get_current_intention(),at_subtarget,true); 
				do current_intention_on_hold();
				write "ask hub: "+transport_trip[trip_pointer].key+" to go to hub: "+transport_trip[trip_pointer].value;
				ask transport_trip[trip_pointer].key{
					do enter([myself],myself.transport_trip[myself.trip_pointer].value);
				}
			}
			match_one ["driving","passenger"]{ do remove_belief(at_subtarget); }
			match "arrived"{
				
			}
		}
	}
	
	plan walk_to_subtarget intention: at_subtarget{
		
		do goto(subtarget,walk_speed,road_network);
		if(location = subtarget){
			do add_belief(at_subtarget);
		}
	}
	
	aspect default {
		switch status{
			match "driving"{ color <- #yellow; }
			match "passenger"{ color <- #cyan; }
			match "trip finished"{ color <- #green; }
			default { color <- #magenta; }
		}
		 
		draw circle(40) color: color rotate: heading border: #black;
	}	
		
}