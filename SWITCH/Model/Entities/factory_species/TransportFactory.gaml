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
import "../data_structure_species/SortedMap.gaml"
import "../data_structure_species/Queue.gaml"

global{
	
	Car createCar(point start_location, point end_location, list<Individual> passengers_){
        create Car returns: children{
	    	do getIn(passengers_);
            do start(start_location,end_location);
        } 
        return children[0];
    }
    
    Bike createBike(point start_location, point end_location, list<Individual> passengers_){
        create Bike returns: children{
	    	do getIn(passengers_);
            do start(start_location,end_location);
        } 
        return children[0];
    }
    
    Walk createWalk(point start_location, point end_location, list<Individual> passengers_){
        create Walk returns: children{
	    	do getIn(passengers_);
            do start(start_location,end_location);
        } 
        return children[0];
    }
}