/***
* Name: Individual
* Author: admin_ptaillandie
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model SWITCH

import "../../Global.gaml"

import "../transport_species/Transport.gaml"
import "../transport_species/Bike.gaml"
import "../transport_species/Walk.gaml"
import "../transport_species/Bus.gaml"
import "../transport_species/Tram.gaml"
import "../transport_species/Metro.gaml"
import "../../Constants.gaml"
import "../data_structure_species/SortedMap.gaml"
import "../data_structure_species/Queue.gaml"
import "../transport_species/Passenger.gaml"

global{
	
	Car createCar(point start_location, point end_location, list<Passenger> passengers_, float start_time){
        create Car returns: children{
	    	do getIn(passengers_);
            do start(start_location,end_location, road_network, start_time);
        } 
        mode_cumulative_stat["car"]<- mode_cumulative_stat["car"]+1;
        return children[0];
    }
    
    Bike createBike(point start_location, point end_location, list<Passenger> passengers_, float start_time){
        create Bike returns: children{
	    	do getIn(passengers_);
            do start(start_location,end_location,road_network, start_time);
        } 
        mode_cumulative_stat["bike"]<- mode_cumulative_stat["bike"]+1;
        return children[0];
    }
    
    Walk createWalk(point start_location, point end_location, list<Passenger> passengers_, float start_time){
        create Walk returns: children{
	    	do getIn(passengers_);
            do start(start_location,end_location,road_network, start_time);
        } 
        mode_cumulative_stat["walk"]<- mode_cumulative_stat["walk"]+1;
        return children[0];
    }
    
    Bus createBus(string trip_id_, string transportLine_id_ , list<list> trip_description_, float start_time){
    	create Bus returns: children{
    		trip_id <- trip_id_;
    		transportLine_id <- transportLine_id_;
    		trip_description <- trip_description_;
    		do start(road_network, start_time);
        }
        mode_cumulative_stat["bus"]<- mode_cumulative_stat["bus"]+1;
        return children[0];
    }
    
    Metro createMetro(string trip_id_, string transportLine_id_ , list<list> trip_description_, float start_time){
    	create Metro returns: children{
    		trip_id <- trip_id_;
    		transportLine_id <- transportLine_id_;
    		trip_description <- trip_description_;
    		do start(road_network, start_time);
        } 
        mode_cumulative_stat["metro"]<- mode_cumulative_stat["metro"]+1;
        return children[0];
    }
    
    Tram createTram(string trip_id_, string transportLine_id_ , list<list> trip_description_, float start_time){
    	create Tram returns: children{
    		trip_id <- trip_id_;
    		transportLine_id <- transportLine_id_;
    		trip_description <- trip_description_;
    		do start(road_network, start_time);
        } 
        mode_cumulative_stat["tram"]<- mode_cumulative_stat["tram"]+1;
        return children[0];
    }
    
    reflex resetState{
		loop acti over: activity_list {
			add acti::0 to: activity_cumulative_stat;
		}

		write mode_cumulative_stat;
		loop mode over: mode_list {
			add mode::0 to: mode_cumulative_stat;
		}
	}
}