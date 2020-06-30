/***
...
***/

model SWITCH

import "Abstract Experiment.gaml"


experiment "Basic experiment" parent: "Abstract Experiment" {
	output {
		display "Main" parent: default_display{
		}
	}
}