/***
* Name: Individual
* Author: admin_ptaillandie
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model SWITCH

import "../../Individual.gaml"

species Hub {
	rgb color;
	
	aspect default {
		draw square(5) color: color border: #black;
	}
	
	action enter(list<Individual> passengers_, Hub targetHub){}
	action leave(Transport t){}
}
