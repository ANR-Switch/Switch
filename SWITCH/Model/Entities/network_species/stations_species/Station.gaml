/***
* Name: Individual
* Author: admin_ptaillandie
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model SWITCH

import "../../transport_species/Passenger.gaml"
import "../../transport_species/PublicTransport.gaml"
import "../../TransportLine.gaml"

species Station {
	
	string id;
	string name;
	
	//all the transport line that have this station in one of their trip
	list<TransportLine> lines <- [];
	
	//key=TransportLine_id list=[Passenger waiting_passenger :: Station destination]
	map<string, list<list>> waiting_passengers <- [];

	action waitAtStation(Passenger p, string transportLine_id, Station destination){
		if waiting_passengers[transportLine_id] != nil{
			waiting_passengers[transportLine_id] << [p,destination];
		}else{
			waiting_passengers[transportLine_id] <- [[p,destination]];
		}
	}
	
	aspect default {
		draw square(15) color: #white border: #black;
	}
	
}
