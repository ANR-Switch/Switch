/***
* Name: Individual
* Author: admin_ptaillandie
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model SWITCH

species Building {
	
	string type <- "default";
	float size <- shape.perimeter;
	
	aspect default {
		switch type{
			match "home"{color <- #grey;}
			match "work"{color <- #red;}
			match "parking"{color <- #blue;}
			default {color <- #grey;}
		}
		draw shape color: color border: #black;
	}
}
