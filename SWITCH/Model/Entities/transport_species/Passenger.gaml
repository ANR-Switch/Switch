/**
* Name: Passenger
* Based on the internal empty template. 
* Author: Nicolas
* Tags: 
*/


model SWITCH

import "Car.gaml"
/* Insert your model definition here */
species Passenger {
	Car current_car;
	Bike current_bike;
	Walk current_walk;
	
	point car_place;
	point bike_place;
	
	string status among: ["go to trip","passenger","driving","arrived","activity",nil];
}
