/***
* Name: Individual
* Author: admin_ptaillandie
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model SWITCH

import "Node.gaml"

species Hub parent: Node {
	
	string name;
	
	aspect default {
		draw square(1#px) color: #magenta border: #black depth: 1.0 ;
	}
}
