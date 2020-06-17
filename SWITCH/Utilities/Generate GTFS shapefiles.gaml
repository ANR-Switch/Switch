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
	
	map<string, list> agency_map <- [];
	map<string, list> trips_map <- [];
	map<string, list> stop_times_map <- [];
	map<string, list> stops_map <- [];
	map<string, list> routes_map <- [];
	map<string, list> calendar_map <- [];
	map<string, list> shapes_map <- [];
	
	matrix agency_data <- matrix(csv_file(""+CSV_directory+agency_path, "\n", true));
	matrix trips_data <- matrix(csv_file(""+CSV_directory+trips_path, ",", true));
	matrix stop_times_data <- matrix(csv_file(""+CSV_directory+stop_times_path, ",", true));
	matrix stops_data <- matrix(csv_file(""+CSV_directory+stops_path, ",", true));
	matrix routes_data <- matrix(csv_file(""+CSV_directory+routes_path, ",", true));
	matrix calendar_data <- matrix(csv_file(""+CSV_directory+calendar_path, ",", true));
	matrix shapes_data <- matrix(csv_file(""+CSV_directory+shapes_path, ",", true));

	int nb_attributes_agency <- 6;
	int nb_attributes_trips <- 6;
	int nb_attributes_stop_times <- 9;
	int nb_attributes_stops <- 8;
	int nb_attributes_routes <- 9;
	int nb_attributes_calendar <- 10;
	int nb_attributes_shapes <- 4;

	init {
		loop line over: rows_list(agency_data){
			loop column over: line{
				write column;
			}
		}
	}

}

experiment generateGTFSdata type: gui {
	output {}
}