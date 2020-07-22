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
	//[string hour :: [string tp_mode :: SortedMap [float delay] ]
	map<string, map<string,SortedMap>> late_times_by_transports_modes_during_day;
	//[string hour :: SortedMap [float road_occupation_ratio] ]
	map<string, SortedMap> road_occupations_ratios_during_day;
	
	int nb_data_delays <- 0;
	int nb_data_road <- 0;
	
	init{
		float t <- 0.0;
		date d <- date(2020,1,1,0,0,0);
		loop times: int(24#h / time_step){
			int hour <- (d+t).hour;
			int min <- (d+t).minute;
			string key <- ""+(hour>9?hour:"0"+hour)+"h"+(min>9?min:"0"+min);
			create SortedMap number: 5 returns: sm;
			late_times_by_transports_modes_during_day[key]<-
			[
				"walk"::sm[0],
				"bike"::sm[1],
				"car"::sm[2],
				"bus"::sm[3]
			];
			road_occupations_ratios_during_day[key] <- sm[4];
			t <- t+time_step;
		}	
	}
	
	action addDelayTime(string transport_type,float add_time, float delay){
		float truncated_delay <- delay with_precision 3;
		ask late_times_by_transports_modes_during_day[getKey(add_time)][transport_type]{ do add([truncated_delay]); }
		nb_data_delays <- nb_data_delays +1;
	}
	
	action addOccupationRatio(float add_time,float occup_ratio){
		float truncated_ratio <- occup_ratio with_precision 3;
		ask road_occupations_ratios_during_day[getKey(add_time)]{ do add([truncated_ratio]);}
		nb_data_road <- nb_data_road +1;
	}
	
	reflex getRoadStats when: every(time_step){
		loop r over: Road{
			if  r.occupation_ratio > 0{
				do addOccupationRatio(time,r.occupation_ratio);	
			}
		}
	}
	
	reflex saveDataCSV when: current_date.hour=23 and current_date.minute = 59{
		string delays_buff <- "hour, transport_mode, mean delay, min delay, max delay, nb delay, 1st quartile delay, median delay, third quartile delay";
		string occup_buff <- "hour, mean road occupation, min road occupation, max road occupation, nb road occupation, 1st quartile road occupation, median road occupation, third quartile road occupation";
		write ""+ nb_data_delays+" data entries about delays to save";
		write ""+ nb_data_road+" data entries about road to save";
		list<float> delays <- [];
		float mean_delay;
		float min_delay;
		float max_delay;
		int nb_delay;
		float first_quartile_delay;
		float median_delay;
		float third_quartile_delay;
		
		list<float> road_occupations <- [];
		float mean_road_occupation;
		float min_road_occupation;
		float max_road_occupation;
		int nb_road_occupation;
		float first_quartile_road_occupation;
		float median_road_occupation;
		float third_quartile_road_occupation;
		
		loop hour over:late_times_by_transports_modes_during_day.keys{
			loop transport_mode over: late_times_by_transports_modes_during_day[hour].keys{
				delays <- late_times_by_transports_modes_during_day[hour][transport_mode].data collect each[0];
				nb_delay <- length(delays);
				if nb_delay > 0{
					mean_delay <- mean(delays) with_precision 3;
					min_delay <- min(delays);
					max_delay <- max(delays);
					first_quartile_delay <- delays[int(floor(nb_delay*0.25))];
					median_delay <- delays[int(floor(nb_delay*0.5))];
					third_quartile_delay <- delays[int(floor(nb_delay*0.75))];
					delays_buff <- delays_buff+"\n"+hour+","+transport_mode+","+mean_delay+","+min_delay+","+nb_delay+","+first_quartile_delay+","+median_delay+","+third_quartile_delay;
				}else{
					delays_buff <- delays_buff+"\n"+hour+","+transport_mode+","+0+","+0+","+0+","+0+","+0+","+0;
				}
			}
			road_occupations <- road_occupations_ratios_during_day[hour].data collect each[0];
			nb_road_occupation <- length(road_occupations);
			if nb_road_occupation > 0{
				mean_road_occupation <- mean(road_occupations) with_precision 3;
				min_road_occupation <- min(road_occupations);
				max_road_occupation <- max(road_occupations);
				first_quartile_road_occupation <- road_occupations[int(floor(nb_road_occupation*0.25))];
				median_road_occupation <- road_occupations[int(floor(nb_road_occupation*0.5))];
				third_quartile_road_occupation <- road_occupations[int(floor(nb_road_occupation*0.75))];
				occup_buff <- occup_buff+ "\n"+hour+","+mean_road_occupation+","+min_road_occupation+","+nb_road_occupation+","+first_quartile_road_occupation+","+median_road_occupation+","+third_quartile_road_occupation;
			}else{
				occup_buff <- occup_buff+ "\n"+hour+","+0+","+0+","+0+","+0+","+0+","+0;
			}
		}
		save delays_buff to: dataset+"/output_data/late_times.csv" type:"text";
		save occup_buff to: dataset+"/output_data/road_occupations.csv" type:"text";
	}
	
	string getKey(float add_time){
		int hour <- floor(add_time/3600);
		int min <- floor((add_time - 3600*hour)/(time_step /#sec)) * (time_step /#mn);
		return ""+(hour>9?hour:"0"+hour)+"h"+(min>9?min:"0"+min);
	}
}
