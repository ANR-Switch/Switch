/***
* Name: Individual
* Author: admin_ptaillandie
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model SWITCH

import "Hub_subspecies/HubPrivate.gaml"


species Building {
	
	string type;
	
	list<HubPrivate> parkings;
	
	aspect default {
		draw shape color: #gray border: #black;
	}
}
