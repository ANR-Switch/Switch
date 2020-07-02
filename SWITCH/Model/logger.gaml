/**
* Name: logger
* Based on the internal empty template. 
* Author: admin_ptaillandie
* Tags: 
*/

model logger

import "Entities/transport_species/Transport.gaml"

species logger { 
	int nb_road;
	
	// data = [Transport t :: [list<float> x_series :: list<float> y_series]]
	map<int, pair<list<float>,list<float>>> data;
	int nbTransportToMonitor <- 100;
	int cIndex <- 0;
	map<Transport, int> transportIndex <- [];
	
	
	
	action add_transport_data(Transport t, float x, float y) {
		if data.keys contains t {
			data[transportIndex[t]]<- data[transportIndex[t]].key + [x] :: data[transportIndex[t]].value + [y] ;
		}else{
			if (cIndex < nbTransportToMonitor) {
				transportIndex  <+ t::cIndex;
				data[transportIndex[t]] <- [x]::[y];
				cIndex <- cIndex + 1;
			}
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
