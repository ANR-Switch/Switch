/**
* Name: GenerateGTFSshapefiles
* Based on the internal empty template. 
* Author: Lo�c
* Tags: 
*/
model GenerateGTFSshapefiles

global {
	
	bool csv_has_header <- true;
	
	string save_directory<- "../Datasets/Toulouse/";
	string CSV_directory <- save_directory+"gtfs_tisseo/";
	string agency_path <- "agency.csv";
	string trips_path <- "trips.csv";
	string stop_times_path <- "stop_times.csv";
	string stops_path <- "stops.csv";
	string routes_path <- "routes.csv";
	string calendar_path <- "calendar.csv";
	string shapes_path <- "shapes.csv";
	
	
	//more info about gtfs file format -> https://developers.google.com/transit/gtfs/reference
	file agency_csv <- csv_file(""+CSV_directory+agency_path, ",", string, csv_has_header);
	file trips_csv <- csv_file(""+CSV_directory+trips_path, ",", string, csv_has_header);
	file stop_times_csv <- csv_file(""+CSV_directory+stop_times_path, ",", string, csv_has_header);
	file stops_csv <- csv_file(""+CSV_directory+stops_path, ",", string, csv_has_header);
	file routes_csv <- csv_file(""+CSV_directory+routes_path, ",", string, csv_has_header);
	file calendar_csv <- csv_file(""+CSV_directory+calendar_path, ",", string, csv_has_header);
	file shapes_csv <- csv_file(""+CSV_directory+shapes_path, ",", string, csv_has_header);
	
	matrix agency_data <- matrix(agency_csv);
	matrix trips_data <- matrix(trips_csv);
	matrix stop_times_data <- matrix(stop_times_csv);
	matrix stops_data <- matrix(stops_csv);
	matrix routes_data <- matrix(routes_csv);
	matrix calendar_data <- matrix(calendar_csv);
	matrix shapes_data <- matrix(shapes_csv);
	
	//key = agence_id
	map<string, list<string>> agency_map <- [];
	
	//key = route_id value=all the trips for the specific routes
	map<string, list<list<string>>> trips_map <- [];
	
	//key=trip_id value=all the stop_times for the specific trip
	map<string, list<list<string>>> stop_times_map <- [];
	
	//key = stop_id
	map<string, list<string>> stops_map <- [];
	
	//key = route_id
	map<string, list<string>> routes_map <- [];
	
	//key = service_id
	map<string, list<string>> calendar_map <- [];
	
	//key = shape_id
	map<string, list<list<string>>> shapes_map <- [];
	
	init {
		
		//**********************IMPORT DATA FROM CSV*********************
		int nb_elem;
		 
		loop line over: rows_list(agency_data){
			agency_map[line[0]]<- line;
		}
		write ""+length(agency_map) +" agency/ies imported";
		
		loop line over: rows_list(stops_data){
			stops_map[line[0]]<- line;
		}
		write ""+length(stops_map) +" stop(s) imported";
		
		nb_elem <- 0;
		loop line over: rows_list(stop_times_data){
			if stop_times_map[line[0]] != nil{
				stop_times_map[line[0]]<< line;
				nb_elem <- nb_elem +1;
			}else{
				stop_times_map[line[0]]<- [line];
				nb_elem <- nb_elem +1;
			}
		}
		write ""+nb_elem +" stop_times imported";
		
		nb_elem <- 0;
		loop line over: rows_list(trips_data){
			if trips_map[line[2]] != nil{
				trips_map[line[2]]<< line;
				nb_elem <- nb_elem +1;
			}else{
				trips_map[line[2]]<- [line];
				nb_elem <- nb_elem +1;
			}
		}
		write ""+nb_elem +" trip(s) imported";
		
		loop line over: rows_list(routes_data){
			routes_map[line[0]]<- line;
		}
		write ""+length(routes_map) +" route(s) imported";
		
		loop line over:rows_list(calendar_data){
			calendar_map[line[0]]<- line;
		}
		write ""+length(calendar_map) +" trip date service(s) imported";
		
		loop line over: rows_list(shapes_data){
			if shapes_map[line[0]] != nil{
				shapes_map[line[0]]<< line;
			}else{
				shapes_map[line[0]]<- [line];
			}
		}
		write ""+length(shapes_map) +" trip shape(s) imported";
		//***************************************************************

		//*****************CREATING shapefile species********************
		do createShapes();
		do createCalendars();
		do createAllInOne();
		//***************************************************************
		
		//*****************CREATING shapefiles***************************
		save trip_shape to: save_directory+"trip_shape.shp" type: shp attributes: ["shape_id"::shape_id,"polyline_shape"::polyline_shape];
		save calendar to: save_directory+"calendar.shp" type: shp attributes: [
			"service_id"::service_id,
			"monday"::monday,
			"tuesday"::tuesday,
			"wednesday"::wednesday,
			"thursday"::thursday,
			"friday"::friday,
			"saturday"::saturday,
			"sunday"::sunday,
			"start_date"::start_date,
			"end_date"::end_date
		];
		save all_in_one to: save_directory+"all_in_one.shp" type: shp attributes: [
			"route_id"::route_id,
			"trip_id"::trip_id,
			"service_id"::service_id,
			"shape_id"::shape_id,
			"stop_id"::stop_id,
			"route_short_name"::route_short_name,
			"route_long_name"::route_long_name,
			"route_desc"::route_desc,
			"route_type"::route_type,
			"route_url"::route_url,
			"route_color"::route_color,
			"route_text_color"::route_text_color,
			"trip_headsign"::trip_headsign,
			"direction_id"::direction_id,
			"stop_sequence"::stop_sequence,
			"arrival_time"::arrival_time,
			"departure_time"::departure_time,
			"stop_headsign"::stop_headsign,
			"pickup_type"::pickup_type,
			"drop_off_type"::drop_off_type,
			"shape_dist_traveled"::shape_dist_traveled,
			"stop_code"::stop_code,
			"stop_name"::stop_name,
			"stop_lat"::stop_lat,
			"stop_lon"::stop_lon,
			"location_type"::location_type,
			"parent_station"::parent_station,
			"wheelchair_boarding"::wheelchair_boarding
		];
		//***************************************************************
	}
	
	action createAllInOne{
		loop routes over: routes_map.keys{
			loop trips over: trips_map[routes]{
				stop_times_map[trips[0]] <- stop_times_map[trips[0]] sort_by int(each[2]);
				loop stop_times over: stop_times_map[trips[0]]{
					list<string> stop <- stops_map[stop_times[1]];
					create all_in_one{
						route_id <- routes;
						trip_id <- trips[0];
						service_id <- trips[1];
						shape_id <- trips[5];
						stop_id <- stop[0];
						route_short_name <- routes_map[routes][2];
						route_long_name <- routes_map[routes][3];
						route_desc <- routes_map[routes][4];
						route_type <- routes_map[routes][5];
						route_url <- routes_map[routes][6];
						route_color <- routes_map[routes][7];
						route_text_color <- routes_map[routes][8];
						trip_headsign <- trips[3];
						direction_id <- trips[4];
						stop_sequence <- stop_times[2];
						arrival_time <- stop_times[3];
						departure_time <- stop_times[4];
						stop_headsign <- stop_times[5];
						pickup_type <- stop_times[6];
						drop_off_type <- stop_times[7];
						shape_dist_traveled <- stop_times[8];
						stop_code <- stop[1];
						stop_name <- stop[2];
						stop_lat <- stop[3];
						stop_lon <- stop[4];
						location_type <- stop[5];
						parent_station <- stop[6];
						wheelchair_boarding <- stop[7];
					}
				}
			}
		}
	}
	
	action createCalendars{
		loop c over: calendar_map.keys{
			create calendar{
				service_id <- calendar_map[c][0];
				monday <- calendar_map[c][1];
				tuesday <- calendar_map[c][2];
				wednesday <- calendar_map[c][3];
				thursday <- calendar_map[c][4];
				friday <- calendar_map[c][5];
				saturday <- calendar_map[c][6];
				sunday <- calendar_map[c][7];
				start_date <- calendar_map[c][8];
				end_date <- calendar_map[c][9];
			}
		}
	}
	
	action createShapes{
		
		list<point> shape_compo <- [];
		
		loop shape_ over: shapes_map.keys{
			shapes_map[shape_] <- shapes_map[shape_] sort_by int(each[3]);
			loop pt over: shapes_map[shape_]{
				shape_compo << string2point(pt[2],pt[1]);
			}
			create trip_shape{
				shape_id <- shape_;
				polyline_shape <- polyline(shape_compo);
			}
			shape_compo <- [];
		}
	}
	
	point string2point(string lon, string lat){
		return point(to_GAMA_CRS({float(lon),float(lat),0}));
	}

}

species all_in_one{
	string route_id;
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
	geometry polyline_shape;
	
	aspect default {
		draw polyline_shape color: #black;
	}
}

experiment generateGTFSdata type: gui{
	output{
		display map background: #white type: opengl{
			species trip_shape aspect: default;
		}
	}
}