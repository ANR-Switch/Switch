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
	
	//[string hour :: [string tp_mode :: SortedMap [float speed] ]
	map<string, map<string,SortedMap>> speed_by_transports_modes_during_day;

	//[string hour :: SortedMap [float road_occupation_ratio] ]
	map<string, SortedMap> road_occupations_ratios_during_day;
	
	//[string hour :: SortedMap [float waiting_time] ]
	map<string, SortedMap> bus_waiting_during_day;
	
	init{
		float t <- 0.0;
		date d <- date(2020,1,1,0,0,0);
		loop times: int(24#h / time_step){
			int hour <- (d+t).hour;
			int min <- (d+t).minute;
			string key <- ""+(hour>9?hour:"0"+hour)+"h"+(min>9?min:"0"+min);
			create SortedMap number: 10 returns: sm;
			late_times_by_transports_modes_during_day[key]<-
			[
				"walk"::sm[0],
				"bike"::sm[1],
				"car"::sm[2],
				"bus"::sm[3]
			];
			speed_by_transports_modes_during_day[key]<-
			[
				"walk"::sm[4],
				"bike"::sm[5],
				"car"::sm[6],
				"bus"::sm[7]
			];
			road_occupations_ratios_during_day[key] <- sm[8];
			bus_waiting_during_day[key] <- sm[9];
			t <- t+time_step;
		}	
	}
	
	action addDelayTime(string transport_type,float add_time, float delay){
		float truncated_delay <- delay with_precision 3;
		ask late_times_by_transports_modes_during_day[getKey(add_time)][transport_type]{ do add([truncated_delay]); }
	}
	
	action addSpeed(string transport_type,float add_time, float speed){
		float truncated_speed <- speed with_precision 3;
		ask speed_by_transports_modes_during_day[getKey(add_time)][transport_type]{ do add([truncated_speed]); }
	}
	
	action addOccupationRatio(float add_time,float occup_ratio){
		float truncated_ratio <- occup_ratio with_precision 3;
		ask road_occupations_ratios_during_day[getKey(add_time)]{ do add([truncated_ratio]);}
	}
	
	action addStationWaiting(float add_time,float waiting_time){
		float truncated_time <- waiting_time with_precision 3;
		ask bus_waiting_during_day[getKey(add_time)]{ do add([truncated_time]);}
	}
	
	reflex getRoadStats when: every(time_step){
		loop r over: Road{
			if  r.occupation_ratio > 0{
				do addOccupationRatio(time,r.occupation_ratio);	
			}
		}
	}
	
	reflex saveDataCSV when: current_date.hour=23 and current_date.minute = 59{
		write "********** SAVING DATA IN "+dataset+"/output_data/ ***************";
		string delays_buff <- "hour, transport_mode, mean delay, variance delay, min delay, max delay, nb delay, 1st quartile delay, median delay, third quartile delay";
		string speeds_buff <- "hour, transport_mode, mean speed, variance speed, min speed, max speed, nb speed, 1st quartile v, median speed, third quartile speed";
		string occup_buff <- "hour, mean road occupation, variance road occupation, min road occupation, max road occupation, nb road occupation, 1st quartile road occupation, median road occupation, third quartile road occupation";
		string waiting_buff <- "hour, mean waiting station time, variance waiting station time, min waiting station time, max waiting station time, nb waiting station time, 1st quartile waiting station time, median waiting station time, third quartile waiting station time";
		list<float> delays <- [];
		list<float> speeds <- [];
		list<float> road_occupations <- [];
		list<float> station_waiting_times <- [];
		
		loop hour over:late_times_by_transports_modes_during_day.keys{
			loop transport_mode over: late_times_by_transports_modes_during_day[hour].keys{
				delays <- late_times_by_transports_modes_during_day[hour][transport_mode].data collect each[0];
				delays_buff <- delays_buff+"\n"+hour+","+transport_mode+","+ getStatsBuff(delays);
				
				speeds <- speed_by_transports_modes_during_day[hour][transport_mode].data collect each[0];
				speeds_buff <- speeds_buff+"\n"+hour+","+transport_mode+","+ getStatsBuff(speeds);
			}
			road_occupations <- road_occupations_ratios_during_day[hour].data collect each[0];
			occup_buff <- occup_buff+ "\n"+hour+","+ getStatsBuff(road_occupations);
			
			station_waiting_times <- bus_waiting_during_day[hour].data collect each[0];
			waiting_buff <- waiting_buff+ "\n"+hour+","+ getStatsBuff(station_waiting_times);
		}
		save delays_buff to: dataset+"/output_data/late_times.csv" type:"text";
		save occup_buff to: dataset+"/output_data/road_occupations.csv" type:"text";
		save speeds_buff to: dataset+"/output_data/speeds.csv" type:"text";
		save waiting_buff to: dataset+"/output_data/station_waiting_times.csv" type:"text";
	}
	
	string getStatsBuff(list<float> data_list){
		string buff <- "";
		float mean;
		float variance;
		float min;
		float max;
		int nb_data;
		float first_quartile;
		float median;
		float third_quartile;
		nb_data <- length(data_list);
		if nb_data > 0{
			mean <- mean(data_list) with_precision 3;
			variance <- variance(data_list) with_precision 3;
			min <- min(data_list) with_precision 3;
			max <- max(data_list) with_precision 3;
			first_quartile <- data_list[int(floor(nb_data*0.25))]with_precision 3;
			median <- data_list[int(floor(nb_data*0.5))] with_precision 3;
			third_quartile <- data_list[int(floor(nb_data*0.75))] with_precision 3;
			buff <- ""+mean+","+variance+","+min+","+max+","+nb_data+","+first_quartile+","+median+","+third_quartile;
		}else{
			buff <- ""+0.0+","+0.0+","+0.0+","+0.0+","+0.0+","+0.0+","+0.0+","+0.0;
		}
		return buff;
	}
	
	string getKey(float add_time){
		int hour <- floor(add_time/3600);
		int min <- floor((add_time - 3600*hour)/(time_step /#sec)) * (time_step /#mn);
		return ""+(hour>9?hour:"0"+hour)+"h"+(min>9?min:"0"+min);
	}
}
