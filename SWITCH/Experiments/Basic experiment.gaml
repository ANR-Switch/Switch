/***
...
***/

model SWITCH

import "Abstract Experiment.gaml"


experiment "Basic experiment" parent: "Abstract Experiment" {
	output {
		display "Main" parent: default_display {
		}
		display transports_charts {
			chart "evolution of traveled distance by time"  size: {1.0,0.5} background: #darkgray{
				write the_logger.data;
				loop tp over:the_logger.data.keys{
					data legend: ""+tp.name value: rows_list(matrix([the_logger.data[tp].key,the_logger.data[tp].value]));
				}
			}
		}
	}
}