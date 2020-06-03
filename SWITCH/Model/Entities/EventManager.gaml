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
			ask signal_target{
			listactions <- listactions + " " + signal_time + " " + signal_type + " has been added \n";
		}
			add [signal_time,signal_target, signal_type] at:0 to: events;
		}else if insert_index= length(events)-1{
			ask signal_target{
			listactions <- listactions + " " + signal_time + " " + signal_type + " has been added \n";
		}
			events << [signal_time,signal_target,signal_type];
		}else{
			ask signal_target{
			listactions <- listactions + " " + signal_time + " " + signal_type + " has been added \n";
		}
			add [signal_time,signal_target,signal_type] at: insert_index+1 to: events;
		}
	}
	
	reflex sendSignal{
		write events;
		ask Car{
			listactions <- listactions + " NEW TIME STEP \n";
		}
		loop while: not empty(events) and getEventTime(0) <= time{
			//write ""+getEventTransport(0)+" " +getEventTime(0) + " " +getEventType(0);
			int eventTime <- getEventTime(0);
			string eventType <- getEventType(0);
			Transport eventTransport <- getEventTransport(0);
			ask eventTransport{
				listactions <- listactions + " " + myself.getEventTime(0) + " " +myself.getEventType(0) + " has been executed \n";
				listEventManager <- listEventManager + " \n "+ myself.getEventTime(0)+":"+myself.getEventType(0);
				do setSignal(eventTime,eventType);
			}
			remove [eventTime,eventTransport,eventType] from: events;
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