/**
* Name: Queue
* Based on the internal empty template. 
* Author: Lo�c
* Tags: 
*/


model SWITCH

// implementation of FIFO queue
species Queue{
	
	list<list> queue <- [];
	
	// as a FIFO queue, adding an element put it at the end of the queue
	action add(list list_to_add){
		queue << list_to_add;
	}
	
	// as a FIFO queue, element return the head of the queue
	list element{
		return queue[0];
	}
	
	// as a FIFO queue, it is only possible to remove the head of the queue
	action remove{
		remove queue[0] from: queue;
	}
	
	bool isEmpty{
		return length(queue)=0;
	}
}

