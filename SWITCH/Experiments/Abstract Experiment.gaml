/***
* ... 
***/

model SWITCH

import "../Model/Global.gaml"

global {
	font default <- font("Helvetica", 18, #bold);
	rgb text_color <- world.color.brighter.brighter;
	rgb background <- world.color.darker.darker;
	string dataset_folder <- "../../Datasets/"; // Need to be overwritten if the caller is not in a sub-directory

	init { 
		do global_init;
	}

}


experiment "Abstract Experiment" virtual:true{

	string ask_dataset_path {
		int index <- -1;
		string question <- "Available datasets :\n ";
		list<string> dirs <- gather_dataset_names();
		loop i from: 0 to: length(dirs) - 1 {
			question <- question + (i+1) + "- " + dirs[i] + " \n ";
		}

		loop while: (index < 0) or (index > length(dirs) - 1) {
			index <- int(user_input(question, [enter("Your choice",1)])["Your choice"]) -1;
		}
		return dataset_folder + dirs[index] + "/";
	}
	
	/*
	 * Gather all the sub-folder of the given dataset_folder
	 */
	list<string> gather_dataset_names(string dataset_fol <- world.dataset_folder) {
		list<string> dirs <- folder(dataset_fol).contents  ;
		dirs <- dirs where folder_exists(dataset_fol + each);
		return dirs;
	}
	
	
	
	output {
		display "default_display" synchronized: false type: opengl background: background virtual: true draw_env: false {
			
			overlay position: { 5, 5 } size: { 400 #px, 600 #px }  transparency: 0.5
            {
           		//draw world.name  font: default at: { 20#px, 20#px} anchor: #top_left color:text_color;
           		draw ("Day " + int((current_date - starting_date) /  #day))   font: default at: { 20#px, 50#px} anchor: #top_left color:text_color;
            	string dispclock <- current_date.hour <10 ? "0"+current_date.hour : ""+current_date.hour;
            	dispclock <- current_date.minute <10 ? dispclock+"h0"+current_date.minute : dispclock +"h"+current_date.minute;
            	draw dispclock font: default at: { 20#px, 80#px} anchor: #top_left color:text_color;
            	
            	float y <- 170#px;
                loop type over: colors_per_act.keys 
                {
                    draw square(15#px) at: { 20#px, y } color: colors_per_act[type] border: #white;
                    draw type.name at: { 40#px, y + 4#px } color: # white font: default;
                    y <- y + 35#px;
                }
                loop type over: colors_per_mobility_mode.keys
                {
                    draw square(15#px) at: { 20#px, y } color: colors_per_mobility_mode[type] border: #white;
                    draw type at: { 40#px, y + 4#px } color: # white font: default;
                    y <- y + 35#px;
                }
            }
			image file:  file_exists(dataset+"/satellite.png") ? (dataset+"/satellite.png"): dataset_folder+"Default/satellite.png" transparency: 0.5 refresh: false;
			
			species Building;
			species Road aspect: advanced;
			species Crossroad;
			species Individual;
		}
		
		display activity_charts refresh: every(15 #mn) {
			chart "activities during week"  size: {1.0,0.5} background: #darkgray{
				loop act over: colors_per_act.keys {
					data act.name color: colors_per_act[act] value: Individual count (each.current_activity = act);
				}
			}
			chart "activities" type: pie size: {1.0,0.5} position: {0.0,0.5} background: #darkgray {
				loop act over: colors_per_act.keys {
					data act.name color: colors_per_act[act] value: Individual count (each.current_activity = act);
				}
			}
		}
		
	}

}