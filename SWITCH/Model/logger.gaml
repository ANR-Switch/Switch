/**
* Name: logger
* Based on the internal empty template. 
* Author: admin_ptaillandie
* Tags: 
*/


model logger

species logger { 
	
	bool store_individual_dest <- false;
	// data = [string destination :: [string car_name :: float dist_traveled]]
	map<string,list<pair<string,float>>> data;
	
	action add_data(string dest, string id, float dist) {
		if (store_individual_dest) {
			if not(dest in data) {
				data[dest] <-[];
			} 
			data[dest] << (id::dist);
		}
	}
	
	string data_to_string{
		string res;
		loop k over: data.keys{
			loop v over: data[k]{
				res <- res + ""+k+"   "+v.key+"   "+v.value + "\n";
			}
		}
		res <- res + "-----------------------------\n";
		return res;
	}
	
	action reset_data {
		data <- [];
	}
	
}
