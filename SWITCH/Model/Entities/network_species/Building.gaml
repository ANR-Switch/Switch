/***
* Name: Individual
* Author: admin_ptaillandie
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model SWITCH

import "Node.gaml"

species Building parent: Node {
	
	string type;
	
	aspect default {
		draw shape color: #gray border: #black;
	}
}
