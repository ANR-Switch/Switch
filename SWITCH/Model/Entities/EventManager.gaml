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
			events << [signal_time,signal_target,signal_type];
		}else{
			add [signal_time,signal_target,signal_type] at: insert_index+1 to: events;
		}
	}
	
	reflex sendSignal{
		write events;
		loop while: not empty(events) and getEventTime(0) <= time{
			ask getEventTransport(0){do setSignal(myself.getEventTime(0),myself.getEventType(0));}
			remove events[0] from: events;
		}	
	}
	
	Transport getEventTransport(int event_index){
		return Transport(events[event_index][1]);
	}
	
	int getEventTime(int event_index){
		return int(events[event_index][0]);
	}
	
	string getEventType(int event_index){
		return string(events[event_index][2]);
	}
	
	//implementation of iterative dicotomic search
	//return the index i  like events[i][0] <= signal_time and events[i+1][0] > signal_time
	int indexSearch(int signal_time){
		bool found <- false;
		int end_bound <- length(events);
		int start_bound <- 0;
		int index <- -1;
		
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