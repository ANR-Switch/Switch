/***
* Name: Individual
* Author: admin_ptaillandie
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model SWITCH

import "../../transport_species/Passenger.gaml"

species Station {
	rgb color;
	string name;
	
	aspect default {
		draw square(5) color: color border: #black;
	}
	
	action enter(list<Passenger> passengers_, Station targetHub){}
	action leave(Transport t){}
}
