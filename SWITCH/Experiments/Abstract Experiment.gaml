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
			
			overlay position: { 5, 5 } size: { 700 #px, 200 #px }  transparency: 1
            {
           		draw world.name  font: default at: { 20#px, 20#px} anchor: #top_left color:text_color;
           		draw ("Day " + int((current_date - starting_date) /  #day))   font: default at: { 20#px, 50#px} anchor: #top_left color:text_color;
            }
			image file:  file_exists(dataset+"/satellite.png") ? (dataset+"/satellite.png"): dataset_folder+"Default/satellite.png" transparency: 0.5 refresh: false;
			
			species Building;
			species Node;
			species Road;
			species Individual;

		}
		
	}

}