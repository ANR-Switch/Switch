/**
* Name: logger
* Based on the internal empty template. 
* Author: admin_ptaillandie
* Tags: 
*/

model logger

import "Entities/transport_species/Transport.gaml"

species logger { 
	
	
	// data = [Transport t :: [list<float> x_series :: list<float> y_series]]
	map<Transport, pair<list<float>,list<float>>> data;
	
	action add_transport_data(Transport t, float x, float y) {
		if data.keys contains t {
			data[t]<- data[t].key + [x] :: data[t].value + [y] ;
		}
	}
	
	action remove_transport_data(Transport t){
		remove index:t from: data;
	}
	
	string data_to_string{
		string res <- "default";
		return res;
	}
	
	action reset_data {
		data <- [];
	}
	
}
