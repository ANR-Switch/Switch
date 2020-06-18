/**
* Name: GenerateGTFSshapefiles
* Based on the internal empty template. 
* Author: Lo�c
* Tags: 
*/
model GenerateGTFSshapefiles

global {
	
	string CSV_directory <- "../Datasets/Toulouse/gtfs_tisseo/";
	string agency_path <- "agency.csv";
	string trips_path <- "trips.csv";
	string stop_times_path <- "stop_times.csv";
	string stops_path <- "stops.csv";
	string routes_path <- "routes.csv";
	string calendar_path <- "calendar.csv";
	string shapes_path <- "shapes.csv";
	
	file agency_csv <- csv_file(""+CSV_directory+agency_path, ",", true);
	file trips_csv <- csv_file(""+CSV_directory+trips_path, ",", true);
	file stop_times_csv <- csv_file(""+CSV_directory+stop_times_path, ",", true);
	file stops_csv <- csv_file(""+CSV_directory+stops_path, ",", true);
	file routes_csv <- csv_file(""+CSV_directory+routes_path, ",", true);
	file calendar_csv <- csv_file(""+CSV_directory+calendar_path, ",", true);
	file shapes_csv <- csv_file(""+CSV_directory+shapes_path, ",", true);
	
	matrix<string> agency_data <- matrix<string>(agency_csv);
	matrix<string> trips_data <- matrix<string>(trips_csv);
	matrix<string> stop_times_data <- matrix<string>(stop_times_csv);
	matrix<string> stops_data <- matrix<string>(stops_csv);
	matrix<string> routes_data <- matrix<string>(routes_csv);
	matrix<string> calendar_data <- matrix<string>(calendar_csv);
	matrix<string> shapes_data <- matrix<string>(shapes_csv);
	
	//key = agence_id
	map<string, list> agency_map <- [];
	
	//key = trip_id
	map<string, list> trips_map <- [];
	
	//key = [trip_id,stop_id,stop_sequence]
	map<list, list> stop_times_map <- [];
	
	//key = stop_id
	map<string, list> stops_map <- [];
	
	//key = route_id
	map<string, list> routes_map <- [];
	
	//key = service_id
	map<string, list> calendar_map <- [];
	
	//key = [shape_id,shape_pt_sequence]
	map<list, list> shapes_map <- [];
	
	init {
		loop line over: rows_list(agency_data){
			agency_map[line[0]]<- copy_between(line,1,length(line));
		}
		write first(agency_map.keys);
		write ""+length(agency_map) +" agency/ies imported";
		
		loop line over: rows_list(stops_data){
			stops_map[line[0]]<- copy_between(line,1,length(line));
		}
		write first(stops_map.keys);
		write ""+length(stops_map) +" stop(s) imported";
		
		loop line over: rows_list(stop_times_data){
			stop_times_map[[line[0],line[1],line[2]]]<- copy_between(line,3,length(line));
		}
		write first(stop_times_map.keys);
		write ""+length(stop_times_map) +" stop_times imported";
		
		loop line over: rows_list(trips_data){
			trips_map[line[0]]<- copy_between(line,1,length(line));
		}
		write first(trips_map.keys);
		write ""+length(trips_map) +" trip(s) imported";
		
		loop line over: rows_list(routes_data){
			routes_map[line[0]]<- copy_between(line,1,length(line));
		}
		write first(routes_map.keys);
		write ""+length(routes_map) +" route(s) imported";
		
		loop line over:rows_list(calendar_data){
			calendar_map[line[0]]<- copy_between(line,1,length(line));
		}
		write first(calendar_map.keys);
		write ""+length(calendar_map) +" trip date service(s) imported";
		
		loop line over: rows_list(shapes_data){
			shapes_map[[line[0],line[3]]]<- copy_between(line,1,length(line)-1);
		}
		write first(shapes_map.keys);
		write ""+length(shapes_map) +" trip shape(s) imported";
		
	}
	
	action createPolyline {
		
	}
	
	point string2point(string lon, string lat){
		return point(to_GAMA_CRS({float(lon),float(lat),0}));
	}

}

species all_in_one{
	string route_id;
	string agency_id;
	string trip_id;
	string service_id;
	string shape_id;
	string stop_id;
	string route_short_name;
	string route_long_name;
	string route_desc;
	string route_type;
	string route_url;
	string route_color;
	string route_text_color;
	string trip_headsign;
	string direction_id;
	string stop_sequence;
	string arrival_time;
	string departure_time;
	string stop_headsign;
	string pickup_type;
	string drop_off_type;
	string shape_dist_traveled;
	string stop_code;
	string stop_name;
	string stop_lat;
	string stop_lon;
	string location_type;
	string parent_station;
	string wheelchair_boarding;
}

species calendar{
	string service_id;
	string monday;
	string tuesday;
	string wednesday;
	string thursday;
	string friday;
	string saturday;
	string sunday;
	string start_date;
	string end_date;
}

species trip_shape{
	string shape_id;
	geometry trip_shape;
}

experiment generateGTFSdata type: gui;