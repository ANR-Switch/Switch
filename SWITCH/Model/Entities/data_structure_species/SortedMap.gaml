/**
* Name: SortedMap
* Based on the internal empty template. 
* Author: Lo�c
* Tags: 
*/


model SWITCH

species SortedMap {
	//Registered data list like data = [[float sorted_number, ..., ..., ...]]
	//Note that this list should always be sorted by the first element of each list then the first element must be a float
	//The sort method used is the insertion sort
	list<list> data <- [];
	
	action add(list list_to_add){
		//Dichotomic search of the insertion index
		int insert_index <- indexSearch(float(list_to_add[0]));
		if insert_index = -1{
			add list_to_add at:0 to: data;
		}else if insert_index= length(data)-1{
			data << list_to_add;
		}else{
			add list_to_add at: insert_index+1 to: data;
		}
	}
	
	list get(int index){
		return data[index];
	}
	
	action remove(list list_to_remove){
		remove list_to_remove from: data;
	}
	
	bool isEmpty{
		return length(data) = 0;
	}
	
	//implementation of iterative dicotomic search
	//return the index i  like data[i][0] <= sorted_number and data[i+1][0] > sorted_number
	int indexSearch(float sorted_number){
		bool found <- false;
		int end_bound <- length(data);
		int start_bound <- 0;
		int index <- -1;
		
		loop while: start_bound < end_bound{
			index <- int(floor((start_bound + end_bound)/2));
			if int(data[index][0]) > sorted_number {
				if index = 0 {
					return -1;	
				}else{
					end_bound <- index;
				}
			}else if int(data[index][0]) <= sorted_number {
				if index = length(data)-1{
					return index;
				}else if int(data[index+1][0]) > sorted_number{
					return index;
				}else{
					start_bound <- index;
				}
			}
		}
		return index;
	}
}
	
	