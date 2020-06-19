/***
* Name: Individual
* Author: admin_ptaillandie
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model SWITCH

import "../../transport_species/Passenger.gaml"
import "../../TransportLine.gaml"

species Station {
	
	string id;
	string name;
	
	//all the transport line that have this station in one of their trip
	list<TransportLine> lines <- [];
	
	aspect default {
		draw square(5) color: color border: #black;
	}
	
}
