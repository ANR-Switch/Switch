/***
* Name: Individual
* Author: admin_ptaillandie
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model SWITCH


species Road {
	string type;
	string oneway;
	string junction;
	float maxspeed;
	int lanes;
	
	aspect default {
		draw shape color: #gray end_arrow: 5;
	} 
}
