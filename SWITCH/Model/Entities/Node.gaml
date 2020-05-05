/***
* Name: Individual
* Author: admin_ptaillandie
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model SWITCH


species Node {
	string type;
	string crossing;
	
	aspect default { 
		if (type = "traffic_signals") {
			draw circle(1#px) color: #green border: #black depth: 1.0;
		} else {
			draw square(1#px) color: #magenta border: #black depth: 1.0 ;
		}
		
	}
}
