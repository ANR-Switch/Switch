/**
* Name: HubPublic
* Based on the internal empty template. 
* Author: Lo�c
* Tags: 
*/


model SWITCH

import "Hub.gaml"
import "../../Individual.gaml"

species HubPublic parent: Hub {
	
	string name;
	
	list<Individual> waiting_people;
	
}
