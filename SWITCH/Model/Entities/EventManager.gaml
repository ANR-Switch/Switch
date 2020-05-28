/**
* Name: EventManager
* Based on the internal empty template. 
* Author: Lo�c
* Tags: 
*/


model SWITCH

import "transport_species/Transport.gaml"

species EventManager {
	
	//Registered events list events = [[int signal_time, Transport signal_target, string signal_type]]
	//Note that this list should always be sorted, 
	//an intuitive method to sort the list is to use the insertion sort
	list<list> events;
	
	action registerEvent(int signal_time, Transport signal_target, string signal_type){
		//Dichotomic search of the insertion index
		int insert_index <- indexSearch(signal_time);
		if insert_index = -1{
			add [signal_time,signal_target, signal_type] at:0 to: events;
		}else if insert_index= length(events)-1{
			events << [signal_time,signal_target];
		}else{
			add [signal_time,signal_target, signal_type] at: insert_index+1 to: events;
		}
	}
	
	reflex sendSignal{
		loop while: not empty(events) and int(events[0][0]) <= time{
			ask Transport(events[0][1]){do setSignal;}
			remove events[0] from: events;
		}	
	}
	
	//implementation of iterative dicotomic search
	//return the index i  like events[i][0] <= signal_time and events[i+1][0] > signal_time
	int indexSearch(int signal_time){
		bool found <- false;
		int end_bound <- length(events);
		int start_bound <- 0;
		int index <- 0;
		
		loop while: start_bound < end_bound{
			index <- int(floor((start_bound + end_bound)/2));
			if int(events[index][0]) > signal_time {
				if index = 0 {
					return -1;	
				}else{
					end_bound <- index;
				}
			}else if int(events[index][0]) <= signal_time {
				if index = length(events)-1{
					return index;
				}else if int(events[index+1][0]) > signal_time{
					return index;
				}else{
					start_bound <- index;
				}
			}
		}
		return index;
	}
	
}