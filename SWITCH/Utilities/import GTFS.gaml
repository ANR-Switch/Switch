/**
* Name: GenerateGTFSshapefiles
* Based on the internal empty template. 
* Author: Lo�c
* Tags: 
*/
model importGTFS

import "../Model/Entities/network_species/stations_species/Station.gaml"
import "../Model/Entities/network_species/stations_species/StationTram.gaml"
import "../Model/Entities/network_species/stations_species/StationBus.gaml"
import "../Model/Entities/network_species/stations_species/StationMetro.gaml"
import "../Model/Entities/TransportLine.gaml"

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
	map<string, Station> station_map <- [];
	
	//key = route_id
	map<string, list<string>> routes_map <- [];
	
	//key = service_id
	map<string, list<string>> calendar_map <- [];
	
	//key = shape_id
	map<string, list<list<string>>> shapes_map <- [];
	map<string,geometry> polyline_shape_map <- [];
	
	action readCSVfiles{
		
		//**********************READING DATA FROM CSV*********************
		int nb_elem;
		 
		loop line over: rows_list(agency_data){
			agency_map[line[0]]<- line;
		}
		write ""+length(agency_map) +" agency/ies read";
		
		loop line over: rows_list(stops_data){
			stops_map[line[0]]<- line;
		}
		write ""+length(stops_map) +" stop(s) read";
		
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
		write ""+nb_elem +" stop_times read";
		
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
		write ""+nb_elem +" trip(s) read";
		
		loop line over: rows_list(routes_data){
			routes_map[line[0]]<- line;
		}
		write ""+length(routes_map) +" route(s) read";
		
		loop line over:rows_list(calendar_data){
			calendar_map[line[0]]<- line;
		}
		write ""+length(calendar_map) +" trip date service(s) read";
		
		loop line over: rows_list(shapes_data){
			if shapes_map[line[0]] != nil{
				shapes_map[line[0]]<< line;
			}else{
				shapes_map[line[0]]<- [line];
			}
		}
		write ""+length(shapes_map) +" trip shape(s) read";
	}
	
	action createTransportLineAndStations{
		write "reading CSV GTFS files";
		do readCSVfiles();
		do createShapes();
		write "creating TransportLines and Stations";
		loop routes over: routes_map.keys{
			create TransportLine{
				id <- routes_map[routes][0];
				short_name <- routes_map[routes][2];
				long_name <- routes_map[routes][3];
				transport_type <- int(routes_map[routes][5]);
				line_color <- myself.hex2rgb(routes_map[routes][7]);
				
				loop trip over: trips_map[routes]{
					if line_shapes[trip[5]] != nil{
						line_shapes[trip[5]] <- polyline_shape_map[trip[5]];
					}
					trip_shapes[trip[0]]<-trip[5];
					stop_times_map[trip[0]] <- stop_times_map[trip[0]] sort_by int(each[2]);
					loop stop_times over: stop_times_map[trip[0]]{
						list<string> stop <- stops_map[stop_times[1]];
						if station_map[stop[0]] = nil{
							//we only import stations data covered by the simulation area
							point stop_location <- myself.string2point(stop[4],stop[3]);
							if world.shape overlaps stop_location{
								switch transport_type{
									match 0{
										create StationTram{
											id <- stop[0];
											name <- stop[2];
											location <- stop_location;
											station_map[stop[0]]<-self;
										}
									}
									match 1{
										create StationMetro{
											id <- stop[0];
											name <- stop[2];
											location <- stop_location;
											station_map[stop[0]]<-self;
										}
									}
									match 3{
										create StationBus{
											id <- stop[0];
											name <- stop[2];
											location <- stop_location;
											station_map[stop[0]]<-self;
										}
									}
								}
							}
						}
						//we check a second times if the stop is present in the map because it might not be added (outside the simulation area)
						if station_map[stop[0]] != nil {
							if trips[trip[0]]!=nil{
								trips[trip[0]]<<[stop_times[3],stop_times[4],station_map[stop[0]]];
							}else{
								trips[trip[0]]<-[stop_times[3],stop_times[4],station_map[stop[0]]];
							}
							//we add the transport line in a station attribute so the station is aware of wich lines collect it
							ask station_map[stop[0]]{ if not (lines contains myself){lines<<myself;} }
							//if this is the first stop_times for this trip we add it in starting_times list
							if length(trips[trip[0]]) =1{
								if starting_times[trip[1]] != nil{
									starting_times[trip[1]] << [stop_times[3],trip[0],station_map[stop[0]]];
								}else{
									starting_times[trip[1]] <- [stop_times[3],trip[0],station_map[stop[0]]];
								}
							}
						}
					}
				}
			}
		}
		//if the transportLine has no trips planned the we kill it
		//if the trips map isn't empty then the transportLine can register all the departure events for the day
		ask TransportLine{
			if length(trips.keys) = 0 {
				do die;
			}else{
				do RegisterTodayDepartures;
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
			polyline_shape_map[shape_] <- polyline(shape_compo);
			shape_compo <- [];
		}
	}
	
	// return a list of service_ids for a specific day, it's used by transport lines 
	// to only create active trips for a given date  
	list<string> getServiceIdsFromDate(date today){
		list<string> service_ids_for_today <- [];
		int day_of_the_week <- date2day(today);
		loop services_date over: calendar_map.keys{
			if int(calendar_map[services_date][day_of_the_week])=1{
				date start_date_ <- string2date(calendar_map[services_date][8]);
				date end_date_ <- string2date(calendar_map[services_date][9]);
				if (today after start_date_) and (today before end_date_){
					service_ids_for_today << services_date;
				}
			}
		}
		return service_ids_for_today;
	}
	
	// convert a date from GTFS format string (yyyymmdd) to GAMA date type
	date string2date(string date_){
		int year <- int(copy_between(date_,0,4));
		int month <- int(copy_between(date_,4,6));
		int day <- int(copy_between(date_,6,8));
		return date([year,month,day]);
	}
	
	//return an int corresponding to the day of week for a given date (used to compute the service_id list for a specific day)
	int date2day(date date_){
		int day_code <- date_.day;
		int year_num <- date_.year mod 100;
		float year_code <- year_num + floor(year_num /4);
		int month_code;
		switch date_.month{
			match 1{ if (year_num mod 4)=0 {month_code <- 5;}else{ month_code <- 6;} }
			match 2{ if (year_num mod 4)=0 {month_code <- 1;}else{ month_code <- 2;} }
			match 3{month_code <- 2;}
			match 4{month_code <- 5;}
			match 5{month_code <- 0;}
			match 6{month_code <- 3;}
			match 7{month_code <- 5;}
			match 8{month_code <- 1;}
			match 9{month_code <- 4;}
			match 10{month_code <- 6;}
			match 11{month_code <- 2;}
			match 12{month_code <- 4;}
		}
		return ((day_code mod 7) + (year_code mod 7) + month_code) mod 7;
		/*int day_num <- int(((day_code mod 7) + (year_code mod 7) + month_code) mod 7);
		switch day_num{
			match 1 {return "monday";}
			match 2 {return "tuesday";}
			match 3 {return "wednesday";}
			match 4 {return "thursday";}
			match 5 {return "friday";}
			match 6 {return "saturday";}
			match 7 {return "sunday";}
		}*/
	}
	
	point string2point(string lon, string lat){
		return point(to_GAMA_CRS({float(lon),float(lat),0}));
	}
	
	int hex2int(string hex){
		switch hex{
			match "a"{return 10;}
			match "b"{return 11;}
			match "c"{return 12;}
			match "d"{return 13;}
			match "e"{return 14;}
			match "f"{return 15;}
			default{return int(hex);}
		}
	}
	
	rgb hex2rgb(string hex){
		if length(hex) != 6{return #black;}
		hex <- lower_case(hex);
		int r <- hex2int(at(hex,0))*16 + hex2int(at(hex,1));
		int g <- hex2int(at(hex,2))*16 + hex2int(at(hex,3));
		int b <- hex2int(at(hex,4))*16 + hex2int(at(hex,5));
		return rgb(r,g,b);
	}

}