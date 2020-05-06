/***
* Name: Parameters
* Author: Patrick Taillandier
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model SWITCH

global {
	string dataset <- "../Datasets/Castanet Tolosan/"; // default
	
	
	file road_shapefile <- shape_file(dataset+"roads.shp");
	file building_shapefile <- shape_file(dataset+"buildings.shp");
	file node_shapefile <- shape_file(dataset+"nodes.shp");
	
	
	//date (et heure) de début de la simulation : 7/4/2020 à 6h
	date starting_date <- date(2020,4,7,6);
	
	list<string> type_mode <- ["car","bus","bike","feet"];
	list<string> criteria <- ["comfort", "safety", "price","ecology","simplicity","time"];
	//Step value
	float step <- 1 #mn;
	
	float bus_freq <- 7.0;
	float bus_capacity <- 50.0;
		
	float gas_price <- 1.5; //prix au litre
	float subscription_price <- 30.0; //prix par mois
		
	float number_of_users <- 0.0;
	float percentage_of_drivers <- 0.0;
	
	int nb_individuals <- 1000;
	
	bool road_speed_in_km_h <- true;
		
		
}
