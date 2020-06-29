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
import "transport_species/Car.gaml"
import "transport_species/Bike.gaml"


species Individual skills: [moving] control:simple_bdi parent:Passenger{
	
	string sub_area;
	list<map<list<int>, pair<predicate,list<Individual>>>> agenda_week;
	map<list<int>, pair<predicate,list<Individual>>> agenda_d;
	path my_path;
	Building target_building;
	predicate current_activity <- staying_at_home;
	string athletic among: ["no", "a bit", "yes", nil];
	
	map<string,int> grades;//how agent care for differents criteria	
	map<string, float> priority_modes;//priority for each mode
	int n update: n +1;
	float habit_coeff update: ln(n);
	
	string profile_type;
	
	Building work_building;
	Building home_building;
	
	list<Individual> relatives;
	list<Individual> friends;
	list<Individual> colleagues;
	
	map<predicate, map<string,list<Building>>> building_targets;
	
	map<predicate,list<pair<float,float>>> times_to_join_activity <- [];
	map<predicate,list<pair<float,float>>> times_spent_in_activity <- [];
	
	
	
	//the trip the individual has to follow to join the activity
	//transport_trip [[string tp_mode, point start_pos, point target_pos]]
	// tp_mode in [
	list<list> transport_trip;
	int trip_pointer <- 0;
	
	rgb color <-colors_per_act[current_activity];
	
	int age;
	string gender;
	string category <- none;
	// salaire ? catégorie socio ? 
	
	float distance;
	
	float time_bike;
	float time_car;
	float time_bus;
	float time_walk;
	
	float price_car;
	float price_bus;
	float price_bike;
	float price_walk;
	
	action initialization{
		target_building <- home_building;
		car_place <- any_location_in(Road closest_to self);
		bike_place <-location;
		gender<-any(["f","m"]);
		athletic<-any(["no","a bit","yes"]);
		
		
		profile_type<-"fqsdfqs";//changer ici pour le mode
		int m <- 99;//rnd(100);
		if(profile_type = "test"){
				grades["comfort"]<-10;
	  			grades["price"]<-10;
	  			grades["time"]<-10;
	  			grades["security"]<-10;
	  			grades["ecology"]<-10;
	  			grades["simplicity"]<-10;
		}
		
		if(profile_type = "rocci") {//auto qui kiffent
			if(m<16){
				grades["comfort"]<-10;
	  			grades["price"]<-5;
	  			grades["time"]<-7;
	  			grades["security"]<-rnd(10);
	  			grades["ecology"]<-0;
	  			grades["simplicity"]<-8;
			}else if (m >= 16 and m < 32 ){ //auto opposition autre mode
				grades["comfort"]<-10;
	  			grades["price"]<-6;
	  			grades["time"]<-7;
	  			grades["security"]<-rnd(10);
	  			grades["ecology"]<-3;
	  			grades["simplicity"]<-10;
			}else if (m >= 32 and m < 49 ){ //multimodaux
				grades["comfort"]<-8;
	  			grades["price"]<-8;
	  			grades["time"]<-10;
	  			grades["security"]<-rnd(10);
	  			grades["ecology"]<-8;
	  			grades["simplicity"]<-10;
			}else if (m >= 49 and m < 66 ){ //multimodaux opp voiture
				grades["comfort"]<-3;
	  			grades["price"]<-10;
	  			grades["time"]<-6;
	  			grades["security"]<-rnd(10);
	  			grades["ecology"]<-10;
	  			grades["simplicity"]<-8;
			}else if (m >= 66 and m < 83 ){ //alternatif adhérence leur mode
				grades["comfort"]<-2;
	  			grades["price"]<-rnd(10);
	  			grades["time"]<-7;
	  			grades["security"]<-rnd(10);
	  			grades["ecology"]<-10;
	  			grades["simplicity"]<-10;
			}else { //alternatif oppo
				grades["comfort"]<-2;
	  			grades["price"]<-8;
	  			grades["time"]<-4;
	  			grades["security"]<-rnd(10);
	  			grades["ecology"]<-10;
	  			grades["simplicity"]<-rnd(10);
			}
		} else {
			
	  		if (m <= 34){ //automobilistes ouverts à tout mode
	  			grades["comfort"]<-8;
	  			grades["price"]<-8;
	  			grades["time"]<-10;
	  			grades["security"]<-rnd(10);
	  			grades["ecology"]<-4;
	  			grades["simplicity"]<-10;
	  		} else if(m > 34 and m<=61){ //pro indiv
	  			grades["comfort"]<-7;
	  			grades["price"]<-rnd(10);
	  			grades["time"]<-9;
	  			grades["security"]<-rnd(10);
	  			grades["ecology"]<-5;
	  			grades["simplicity"]<-10;
	  		}else if(m > 61 and m<=77){ //automobilistes à contre coeur
	  			grades["comfort"]<-5;
	  			grades["price"]<-rnd(10);
	  			grades["time"]<-8;
	  			grades["security"]<-rnd(10);
	  			grades["ecology"]<-10;
	  			grades["simplicity"]<-9;
	  		}else if(m > 77 and m<=87){ //pro indiv
	  			grades["comfort"]<-10;
	  			grades["price"]<-5;
	  			grades["time"]<-7;
	  			grades["security"]<-rnd(10);
	  			grades["ecology"]<-3;
	  			grades["simplicity"]<-10;
	  		}else {
	  			loop i from: 0 to: length(criteria)-1{
	      		grades[criteria[i]]<- rnd(9);
		  		}
	  		}
		}
	  	
	  	m <- rnd(1);
	  	if (m = 0){
	  		car_place <- nil;
	  	}
	  	
		
		n<-5;//for habit coefficient
		
		
		
		
		//People agents are located anywhere in one of the building
		location <- any_location_in(home_building);
		if (work_building = nil){
			
		}
		if (work_building != nil) {
			distance <- home_building distance_to work_building;
		} else {
			distance <- 10.0;
		}
		time_bike <- distance/bike_speed+0.1;
		time_car <- distance/car_speed+0.1;
		time_bus <- distance/bus_speed+0.1;
		time_walk <- distance/walk_speed+0.1;
		
		price_bus <- subscription_price/(21.8*2)+ 0.1; //21.8 est le nombre moyen de jour "de semaine" par mois
		price_car <- (7.2*distance/100*gas_price)/(21.8*2) +0.1;
		price_bike <- 0.0001;
		price_walk <- 0.0001;
		
		
		
		
		do update_priority(); 
		
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
						
						val <- 1.0 /(price_car/min([price_car,price_bus, price_walk, price_bike]));
					
					}
					match "time" {
						//on considère que la voiture à une allure moyenne de 25km/h
						//write max(time_car,time_bike, time_bus, time_walk);
						val<- 1.0/(time_car/min(time_car,time_bike, time_bus, time_walk));
						
					}
					match "ecology"{
						val <-0.0;
					}
					match "simplicity"{
						val <- 0.8;
					}
					match "safety"{
						val <- 1 - percentage_of_drivers/100;
						
						//eventuellement prendre en compte la capacité de la route ? est-ce une info à la quelle on a accès ?
					}
				}	
			}//end match car
			match "bike" {
				switch criterion {
					match "comfort" {
						//enfants, motif du déplacement
						if weather = "sunny"{
							val <- 1.0;
						} else if (weather = "rainy"){
							val <-0.3;
						} else {
							val <- 0.1;
						}
						
						if athletic = "no"{
							val <- (val + 0.1) /2;
						} else if (athletic = "a bit") {
							val <- (val + 0.6) /2;
						} else {
							val <- (val + 1.0)/2;
						}
					}
					match "price" {
						val <- 1/ (price_bike/min(price_car, price_bus, price_walk, price_bike));
					}
					match "time" {
						val<- 1 / (time_bike/min(time_car,time_bike, time_bus, time_walk));
					
					}
					match "ecology"{
						val <- 2.0;
					}
					match "simplicity"{
						// dans le trajet effectué, voir pourcentage route cyclables + distance au dessus de 20min pas cool (voir papiers socio)
						val <- 0.9;
					}
					match "safety"{
						//dans le trajet effectué pourcentage de route non partagée avec automobilistes
						val <-ratio_cycleway;
					}			
				}
			}//end match bike
			match "bus" {
				switch criterion {
					match "comfort" {
						//selon son heure de départ
						//nb de personnes qu'on peut transporter en 30min - nb actuel de passager
						float val1 <- ((30/bus_freq)* bus_capacity) - number_of_users_per_hour[[current_date.hour,int(floor(current_date.minute/30)*30)]];
						val <- val1/((30/bus_freq)* bus_capacity);
					}
					match "price" {
					 	val <- 1/ (price_bus/min(price_car,price_bus, price_walk, price_bike));
					 
					
					}
					match "time" {
						// On considère qu'un bus se déplace à 10km/h
						val<- 1 / (time_bus/min(time_car,time_bike, time_bus, time_walk));
						
					}
					match "ecology"{
						val <- 0.7;
					}
					match "simplicity"{
						//Dépend du nombre de ligne de bus différentes à prendre; à voir comment faire avec ces data
						val <-0.3;
					}
					match "safety"{
						if (gender = "f"){
							if(current_date.hour>21.0){
								val <- 0.5;
							} else {
								val <- 0.80;
							}
						} else {
							val <- 0.9;
						}
						
					}
				}
				
			}//end match bus
			match "walk"{
				switch criterion {
					match "comfort" { 
						if(distance <1){
							val<-1.0;
						}else if (distance < 3){
							val <- 1 - distance /3.0;
						} else {
							val <- 0.0;
						}
						val <- 0.5;
					}
					match "price" {
						val <- 1 / (price_walk/min(price_car, price_bus, price_walk, price_bike));
						
					}
					match "time" {
						val<- 1 / (time_walk/min(time_car,time_bike, time_bus, time_walk));
					
					}
					match "ecology"{
						val <- 2.0;
					}
					match "simplicity"{
//						if(distance < 2.5){
//							val <- 1.0;
//						}
//						if(distance < 5){
//							val <- 1- distance /3.0;
//						} else {
//							val <- 0.0;
//						}
						val <- 0.5;
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
			val <- exp(grades[criteria[i]])*((compute_value(type,criteria[i])*2)-1);
		}
		n<-0;
		return val/length(criteria) + habit_coeff*priority_modes[type];
		
	}
	
	action update_priority{
		loop i from: 0 to: length(type_mode)-1{
			priority_modes[type_mode[i]]<- compute_priority_mobility_mode(type_mode[i]);
		}
		if(not has_car()){
			priority_modes["car"] <-0;
		}
		//write "max priority = : " + get_max_priority_mode() ;
		
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
	
	string get_max_priority_mode{
		float p <- max(priority_modes);
		switch p{
			match priority_modes["car"]{
				return "car";
			}
			match priority_modes["bike"]{
				return "bike";
			}
			match priority_modes["walk"]{
				return "walk";
			}
			match priority_modes["bus"]{
				return "bus";
			}
		}
		
	}
	
	reflex define_agenda_day when: every(#day) {
		agenda_d <- agenda_week[current_date.day_of_week - 1];
	}
	
	reflex executeAgenda{
		pair act_p <- nil;
		loop activity_time over: agenda_d.keys{
			if activity_time[0] < current_date.hour or (activity_time[0] = current_date.hour and activity_time[1] <= current_date.minute){
				act_p <- agenda_d[activity_time];
			}
		}
		if (act_p.key != nil) {
			current_activity <- act_p.key;
			if (get_current_intention() != nil) {
				do remove_intention(first(intention_base).predicate, true);
			}
			do remove_belief(at_target);
			do add_desire(current_activity);
			ask world {do write_message(myself.name + " - new activity: " + myself.current_activity);}
		}
	}
	
	//compute a trip acording to priority and target
	action compute_transport_trip(point target_){
		// for the moment this function is only returning a car trip
		//
		transport_trip <- [];
		float p <- max(priority_modes);
		switch p {
			match priority_modes["car"]{
				transport_trip << ["walk",location, car_place];
				point target_parking <- any_location_in(Road closest_to target_);
				transport_trip << ["car",car_place,target_parking];
				transport_trip << ["walk",target_parking,target_];
			}
			
			match priority_modes["bike"]{
				transport_trip << ["walk",location, bike_place];
				point target_parking <- any_location_in(Road closest_to target_);
				transport_trip << ["bike",bike_place,target_parking];
				transport_trip << ["walk",target_parking,target_];
			}
			// TODO: Update with real bus
			match priority_modes["bus"]{
				point target_parking <- any_location_in(Road closest_to target_);
				transport_trip << ["car",location,target_parking];
				transport_trip << ["walk",target_parking,target_];
			}
			
			match priority_modes ["walk"]{
				transport_trip << ["walk",location, target_];
			}
			
		}
		trip_pointer <- 0;
		ask world {do write_message(myself.name + " - transport trip: " + myself.transport_trip);}
	}
	
	action prepare_trip (Building target_bd){
		target_building <- target_bd;
		do compute_transport_trip(any_location_in(target_building));
		status <- "go to trip";
		do add_subintention(get_current_intention(),at_target, true);
		do current_intention_on_hold();
	}
	
	string building_type_choice(predicate pred) {
		list<string> possible_building_types <- activities[pred.name];
		if (weight_bd_type_per_age_sex_class = nil ) or empty(weight_bd_type_per_age_sex_class) {
			return any(possible_building_types);
		}
		loop a over: weight_bd_type_per_age_sex_class.keys {
			if (age >= a[0]) and (age <= a[1]) {
				map<string, float> weight_bds <-  weight_bd_type_per_age_sex_class[a][gender];
				list<float> proba_bds <- possible_building_types collect ((each in weight_bds.keys) ? weight_bds[each]:1.0 );
				if (sum(proba_bds) = 0) {return any(possible_building_types);}
				return possible_building_types[rnd_choice(proba_bds)];
			}
		}
		return any(possible_building_types);
		
	}
	
	Building choice_a_target(predicate pred) {
		string type <- building_type_choice(pred);
		list<Building> bds <- building_targets[pred][type];
		if (empty(bds)) {
			return the_outside;
		} else {	
			return one_of(bds);
		}
	}
	
	plan do_work intention: working{
		if (not has_belief(at_target)) {
			do prepare_trip(work_building);
		}
	}
	
	plan do_study intention:studying {
		if (not has_belief(at_target)) {
			do prepare_trip(work_building);	
		}
	}
	
	plan do_stay_at_home intention: staying_at_home{
		if (not has_belief(at_target)) {
			do prepare_trip(home_building);
		}
	}
	
	plan do_shopping intention: shopping{
		if (not has_belief(at_target)) {
			Building bd <- choice_a_target(shopping);
			do prepare_trip(bd);	
		}
	}
	
	plan do_eating_restaurant intention: eating {
		if (not has_belief(at_target)) {
			Building bd <- choice_a_target(eating);
			do prepare_trip(bd);	
		}
	}
	
	plan do_a_leisure_activity intention: leisure {
		if (not has_belief(at_target)) {
			Building bd <- choice_a_target(leisure);
			do prepare_trip(bd);	
		}
	}
	
	plan meet_a_friend intention: visiting_friend priority: rnd(1.0){
		if (not has_belief(at_target)) {
			list<Individual> available_friends <- friends where (each.current_activity != working);
			target_building <- one_of(available_friends collect each.target_building);
			do add_subintention(get_current_intention(),at_target, true);
			do current_intention_on_hold();
		}
	}
	
	plan practice_sport intention: practicing_sport{
		if (not has_belief(at_target)) {
			Building bd <- choice_a_target(practicing_sport);
			do prepare_trip(bd);	
		}
	}
		
	plan do_other_activity intention: shopping{
		if (not has_belief(at_target)) {
			Building bd <- choice_a_target(shopping);
			do prepare_trip(bd);	
		}
	}
	
	plan execute_trip intention: at_target{
		ask world {do write_message(myself.name + " - status: " + myself.status + " trip_pointer: " + myself.trip_pointer);}
		switch status{
			match "go to trip"{
				string mobility_mode <- transport_trip[trip_pointer][0];
				color <-colors_per_mobility_mode[mobility_mode]; 
					
				switch mobility_mode{
					match "walk"{do useWalk([self],transport_trip[trip_pointer][2]);}
					match "car"{do useCar([self],transport_trip[trip_pointer][2]);}
					match "bike"{do useBike([self],transport_trip[trip_pointer][2]);}
					default{write "error execute_trip transport mode switch";}
				}
			}
		
			match "arrived"{
				if trip_pointer = length(transport_trip)-1{
					color <- colors_per_act[current_activity];
					do add_belief(at_target);
				}else{
					//There is transport left to use so the individual join the next departure by foot
					trip_pointer <- trip_pointer + 1;
					status <- "go to trip";
				}
			}
		}
	}

	
	action useCar(list<Individual> passengers_, point pos_target_){
		ask world {do write_message(myself.name + " - drive: location" + myself.location + " target: "+ pos_target_);}
		if (current_car = nil) {
			current_car <- world.createCar(self.location,pos_target_,passengers_, time);
		}
		
	}
	
	action useBike(list<Individual> passengers_, point pos_target_){
		if (current_bike = nil) {
			current_bike <- world.createBike(self.location,pos_target_,passengers_, time);
		}
	}
	
	action useWalk( list<Individual> passengers_, point pos_target_){
		ask world {do write_message(myself.name + " - walk: location" + myself.location + " target: "+ pos_target_);}
		if (current_walk = nil) {
			current_walk <- world.createWalk(self.location,pos_target_,passengers_, time);
		}
	}
	
	aspect default {
		draw circle(5) color: color rotate: heading border: #black;
	}	
		
}