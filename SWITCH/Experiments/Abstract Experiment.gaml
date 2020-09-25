/***
* ... 
***/
model SWITCH

import "../Model/Global.gaml"
import "../Model/logger.gaml"

global {
	font default <- font("Helvetica", 18, #bold);
	rgb text_color <- world.color.brighter.brighter;
	rgb background <- world.color.darker.darker;
	string dataset_folder <- "../../Datasets"; // Need to be overwritten if the caller is not in a sub-directory
	init {
		do global_init;
	}

}

experiment "Abstract Experiment" virtual: true {
	parameter 'Buildings:' var: isBuildingDisplayed category: 'Display';
	string ask_dataset_path {
		int index <- -1;
		string question <- "Available datasets :\n ";
		list<string> dirs <- gather_dataset_names();
		loop i from: 0 to: length(dirs) - 1 {
			question <- question + (i + 1) + "- " + dirs[i] + " \n ";
		}

		loop while: (index < 0) or (index > length(dirs) - 1) {
			index <- int(user_input(question, [enter("Your choice", 1)])["Your choice"]) - 1;
		}

		return dataset_folder + dirs[index] + "/";
	}

	/*
	 * Gather all the sub-folder of the given dataset_folder
	 */
	list<string> gather_dataset_names (string dataset_fol <- world.dataset_folder) {
		list<string> dirs <- folder(dataset_fol).contents;
		dirs <- dirs where folder_exists(dataset_fol + each);
		return dirs;
	}

	output {
		layout #split parameters: false navigator: false editors: false consoles: true;
		display "Current Distribution" type: java2D background: background {
			chart "Current activity distribution" type: pie style: exploded size:{1,0.5} position: {0, 0} background: background{
				loop acti over: activity_list {
					data acti value: Individual count (each.current_activity.name = acti) color: colors_per_act_string[acti];
					
				}

			}
			chart "Current mode distribution" type: pie style: exploded size:{1,0.5}  position: {0, 0.5} background: background{
				loop mode over: mode_list {
					data mode value: Individual count (each.current_transport_mode = mode) color:colors_per_mobility_mode[mode];
				}

			}
			graphics TimeAndDate {
				draw ("Day " + int((current_date - starting_date) /  #day))   font: default at: { 20#px, 50#px} anchor: #top_left color:text_color;
            	string dispclock <- current_date.hour <10 ? "0"+current_date.hour : ""+current_date.hour;
            	dispclock <- current_date.minute <10 ? dispclock+"h0"+current_date.minute : dispclock +"h"+current_date.minute;
            	draw dispclock font: default at: { 20#px, 80#px} anchor: #top_left color:text_color;
            	draw "step: "+step+" sec" font: default at: { 20#px, 110#px} anchor: #top_left color:text_color;
            	float y <- 170#px;
			}

		}

		display "Map" type: opengl synchronized: false background: background virtual: true draw_env: false {
			overlay position: {0, 0} size: {200 #px, 650 #px} rounded: false transparency:0.5{
				draw ("Day " + int((current_date - starting_date) / #day)) font: default at: {15 #px, 10 #px} anchor: #top_left color: text_color;
				string dispclock <- current_date.hour < 10 ? "0" + current_date.hour : "" + current_date.hour;
				dispclock <- current_date.minute < 10 ? dispclock + "h0" + current_date.minute : dispclock + "h" + current_date.minute;
				draw dispclock font: default at: {15 #px, 50 #px} anchor: #top_left color: text_color;
				draw "step: " + step + " sec" font: default at: {15 #px, 90 #px} anchor: #top_left color: text_color;
				float y <- 130 #px;
				loop type over: colors_per_act.keys {
					draw square(15 #px) at: {20 #px, y} color: colors_per_act[type] border: #white;
					draw type.name at: {40 #px, y + 4 #px} color: #white font: default; //+":"+((Individual count (each.current_activity = type))/num_individuals*100) with_precision 2 +"%" at: { 40#px, y + 4#px } color: # white font: default;
					y <- y + 35 #px;
				}

				loop type over: colors_per_mobility_mode.keys {
					draw square(15 #px) at: {20 #px, y} color: colors_per_mobility_mode[type] border: #white;
					draw type at: {40 #px, y + 4 #px} color: #white font: default; //+":"+((Individual count (each.get_max_priority_mode() = type))/num_individuals*100) with_precision  2+"%" at: { 40#px, y + 4#px } color: # white font: default;
					y <- y + 35 #px;
				}
			}
			//image file:  file_exists(dataset+"/satellite.png") ? (dataset+"/satellite.png"): dataset_folder+"Default/satellite.png" transparency: 0.5 refresh: false;
			species Building;
			species Road aspect: default;
			species Crossroad;
			species StationBus;
			species StationMetro;
			species StationTram;
			species Bus;
			species Individual;
		}
		
		display "How many travels by modes?" type: java2D background: background {
			chart "How many travels by modes every step?" type: histogram style:stack background: background {
				data "car" value: mode_cumulative_stat["car"] accumulate_values: true	color:colors_per_mobility_mode["car"];
				data "bike" value: mode_cumulative_stat["bike"] accumulate_values: true	color:colors_per_mobility_mode["bike"];
				data "bus" value: mode_cumulative_stat["bus"] accumulate_values: true	color:colors_per_mobility_mode["bus"];
				data "walk" value: mode_cumulative_stat["walk"] accumulate_values: true	color:colors_per_mobility_mode["walk"];
			}
		}
		display "How many transports during day" type: java2D background: background {
			chart "How many travels by modes every step?" type: series style:stack background: #white {
				data "car" value: length(Car) color:colors_per_mobility_mode["car"] thickness: 2.5 marker: false; 
				data "bike" value: length(Bike)	color:colors_per_mobility_mode["bike"] thickness: 2.5 marker: false;
				data "bus" value: length(Bus) color:colors_per_mobility_mode["bus"] thickness: 2.5 marker: false;
				data "walk" value: length(Walk)	color:colors_per_mobility_mode["walk"] thickness: 2.5 marker: false;
			}
		}
	}

}