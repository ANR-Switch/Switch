/**
* Name: logger
* Based on the internal empty template. 
* Author: admin_ptaillandie
* Tags: 
*/

model logger

import "Entities/transport_species/Transport.gaml"

species logger {
	float time_step <- 10 #mn;
	//[string transport_mode :: list[float late_time]]
	map<string, map<string,list<float>>> late_times_by_transports_modes_during_day;
	
	init{
		float t <- 0.0;
		date d <- date(2020,1,1,0,0,0);
		loop times: int(24#h / time_step){
			int hour <- (d+t).hour;
			int min <- (d+t).minute;
			string key <- ""+(hour>9?hour:"0"+hour)+"h"+(min>9?min:"0"+min);
			late_times_by_transports_modes_during_day[key]<-
			[
				"walk"::[],
				"bike"::[],
				"car"::[],
				"bus"::[]
			];
			t <- t+time_step;
		}	
	}
	
	
	/*map<string, list<float>> exec_times <- [];
	map<string, rgb> color_exec_times;
	
	init{
		exec_times["compute trip"]<-[];
		exec_times["execute trip"]<-[];
		exec_times["collect"]<-[];
		exec_times["start transport"]<-[];
		exec_times["compute travel time"]<-[];
		exec_times["insert event"]<-[];
		
		color_exec_times["insert event"]<- #magenta;
		color_exec_times["compute trip"]<- #green;
		color_exec_times["execute trip"]<-#red;
		color_exec_times["collect"]<- #yellow;
		color_exec_times["start transport"]<-#black;
		color_exec_times["compute travel time"]<-#blue;
	}*/
	
	action addDelayTime(string transport_type,float delay){
		int hour <- current_date.hour;
		int min <- floor(current_date.minute / (time_step /#mn)) * (time_step /#mn);
		string key <- ""+(hour>9?hour:"0"+hour)+"h"+(min>9?min:"0"+min);
		late_times_by_transports_modes_during_day[key][transport_type]<<delay;
	}
	
	reflex saveDataCSV when: every(11#h){
		list<string> data2save <- [];
		loop hour over:late_times_by_transports_modes_during_day.keys{
			loop transport_mode over: late_times_by_transports_modes_during_day[hour].keys{
				loop delay over: late_times_by_transports_modes_during_day[hour][transport_mode]{
					data2save << ""+hour+","+transport_mode+","+delay;
				}
			}
		}
		save data:data2save to: dataset+"/output_data/late_times.csv" type:"csv";
	}
}
