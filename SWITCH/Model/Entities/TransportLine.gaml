/**
* Name: TransportLine
* Based on the internal empty template. 
* Author: Lo�c
* Tags: 
*/


model TransportLine

import "network_species/stations_species/Station.gaml"
import "network_species/stations_species/StationTram.gaml"
import "network_species/stations_species/StationBus.gaml"
import "network_species/stations_species/StationMetro.gaml"
import "factory_species/TransportFactory.gaml"
import "../../Utilities/import GTFS.gaml"
import "EventManager.gaml"

species TransportLine parent: EventListener{
	string id;
	string short_name;
	string long_name;
	
	//3=bus 0=tram 1=metro
	int transport_type;
	
	//store all the geometry corresponding to trips made by this line
	map<string, geometry> line_shapes <- [];
	
	//store the correspondance between a trip_id the shape_id it has to follow
	map<string,string> trip_shapes <- [];
	
	rgb line_color <- #black;
	
	//store the trips info
	// key = trip_id list<list> = [[int arrival_time, int departure_time, Station station_to_collect]]
	map<string, list<list>> trips;
	
	// this is the map of trip departure, the map's keys are service_id so when we start a new day, 
	// we load every starting event in the event manager
	//service_id :: [string starting_time, string trip_id, Station first_station]
	map<string, list<list>> starting_times <- [];
	
	action RegisterTodayDepartures{
		list<string> today_service_ids <- world.getServiceIdsFromDate(current_date);
		loop service_id over: starting_times.keys{
			if today_service_ids contains service_id{
				loop departure over:starting_times[service_id]{
					date target_date <- hour2date(departure[0]);
					float time_diff <- target_date - current_date;
					ask EventManager{
						//we register a signal with the trip_id as the signal type so when we receive the signal
						//we know that we have to start this trip
						do registerEvent(time + time_diff, myself, departure[1]);
					}
				}
			}
		}
	}
	
	action setSignal (float signal_time, string signal_type) {
		switch signal_type {
			default{
				list<list> trip_description <- trips[signal_type];
				loop trip_step over: trip_description{
					trip_step[0] <- hour2date(trip_step[0]);
					trip_step[1] <- hour2date(trip_step[1]);
				}
				switch transport_type{
					match 0{
						Tram t <- world.createTram(id,trip_description,signal_time);
					}
					match 1{
						Metro m <- world.createMetro(id,trip_description,signal_time);
					}
					match 3{
						Bus b <- world.createBus(id,trip_description,signal_time);
					}
				}
			}
		}
	}
	
	//convert a time from GTFS format string (HH:mm:ss) to a GAMA date type
	// /!\ the returned date has the year, month and day from the current_date
	//     if the computed date is before current_date then the hour corresponds
	//     to the next day so we add a day to the returned date
	date hour2date(string time_){
		date target_date <- date(time_,"HH:mm:ss");
		target_date <- date(current_date.year,current_date.month,current_date.day, target_date.hour, target_date.minute, target_date.second);
		if target_date before current_date{
			target_date <- target_date add_days 1;
		}
		return target_date;
	}
}
