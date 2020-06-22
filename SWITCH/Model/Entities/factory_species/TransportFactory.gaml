/***
* Name: Individual
* Author: admin_ptaillandie
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model SWITCH

import "../transport_species/Transport.gaml"
import "../transport_species/Bike.gaml"
import "../transport_species/Walk.gaml"
import "../transport_species/Bus.gaml"
import "../transport_species/Tram.gaml"
import "../transport_species/Metro.gaml"
import "../data_structure_species/SortedMap.gaml"
import "../data_structure_species/Queue.gaml"
import "../transport_species/Passenger.gaml"

global{
	
	Car createCar(point start_location, point end_location, list<Passenger> passengers_,graph<Crossroad,Road> road_network, float start_time){
        create Car returns: children{
        	test_mode <- true;
	    	do getIn(passengers_);
            do start(start_location,end_location, road_network, start_time);
        } 
        return children[0];
    }
    
    Bike createBike(point start_location, point end_location, list<Passenger> passengers_,graph<Crossroad,Road> road_network, float start_time){
        create Bike returns: children{
	    	do getIn(passengers_);
            do start(start_location,end_location,road_network, start_time);
        } 
        return children[0];
    }
    
    Walk createWalk(point start_location, point end_location, list<Passenger> passengers_,graph<Crossroad,Road> road_network, float start_time){
        create Walk returns: children{
	    	do getIn(passengers_);
            do start(start_location,end_location,road_network, start_time);
        } 
        return children[0];
    }
    
    Bus createBus(point start_location, string transportLine_id, list<list> trip_description,graph<Crossroad,Road> road_network, float start_time){
    	create Bus returns: children{
    		
        } 
        return children[0];
    }
    
    Metro createMetro(point start_location, string transportLine_id, list<list> trip_description,graph<Crossroad,Road> road_network, float start_time){
    	create Metro returns: children{
    		
        } 
        return children[0];
    }
    
    Tram createTram(point start_location, string transportLine_id, list<list> trip_description,graph<Crossroad,Road> road_network, float start_time){
    	create Tram returns: children{
    		
        } 
        return children[0];
    }
}