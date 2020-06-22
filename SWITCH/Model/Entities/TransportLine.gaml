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

species TransportLine{
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
	//service_id :: [int starting_time, string trip_id, int hub_id]
	map<string, list<list>> starting_times <- [];
	
	action createTrip(string trip_id){
		
	}
}
