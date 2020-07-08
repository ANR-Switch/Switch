/**
* Name: EventManager
* Based on the internal empty template. 
* Author: Lo�c
* Tags: 
*/


model SWITCH

import "transport_species/Transport.gaml"
import "data_structure_species/SortedMap.gaml"
import "EventListener.gaml"

species EventManager {
	
	//Registered events list events = [[float signal_time, EventListener signal_target, string signal_type]]
	//Note that this list should always be sorted, 
	//an intuitive method to sort the list is to use the insertion sort
	SortedMap events_map;
	init{
		create SortedMap{myself.events_map <- self;}
		
	}
	
	action registerEvent(float signal_time, EventListener signal_target, string signal_type){
		ask events_map{
			do add([signal_time,signal_target,signal_type]);
		}
	}
	
	reflex sendSignal when: not events_map.isEmpty() {
		loop while: not events_map.isEmpty() and getEventTime(0) <= time{
			float event_time <- getEventTime(0);
			string event_type <- getEventType(0);
			EventListener event_target <- getEventTarget(0);
			float start_time;
			float exec_time;
			ask events_map{
				do remove(0);
			}
			//start_time <- machine_time;
			ask event_target{
				do setSignal(event_time,event_type);
			}
			/*exec_time <- machine_time - start_time;
			if execution_times_by_event_type[event_type] = nil{
				if ["working","eating","staying at home","leisure"] contains event_type {
					execution_times_by_event_type["individuals activities"] << exec_time;
				}else{
					execution_times_by_event_type["creation public transport"] << exec_time;
				}
			}else{
				execution_times_by_event_type[event_type] << exec_time;
			}*/
		}
	}
	
	EventListener getEventTarget(int event_index){
		return EventListener(events_map.get(event_index)[1]);
	}
	
	float getEventTime(int event_index){
		return float(events_map.get(event_index)[0]);
	}
	
	string getEventType(int event_index){
		return string(events_map.get(event_index)[2]);
	}
}