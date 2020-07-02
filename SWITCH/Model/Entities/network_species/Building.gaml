/***
* Name: Individual
* Author: admin_ptaillandie
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model SWITCH

species Building {
	int id;
	string type <- "default";
	string sub_area;
	list<string> types <- [];
	//Number of households in the building
	int nb_households <- 1;
	float size <- shape.perimeter;
	
	
	aspect default {
		switch type{
			match "home"{color <- #grey;}
			match "work"{color <- #red;}
			match "parking"{color <- #blue;}
			default {color <- #grey;}
		}
		draw shape color: #grey border: #black;
	}
}

species Outside parent: Building ;
