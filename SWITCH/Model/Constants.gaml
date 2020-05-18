/***
* Name: Constants
* Author: Patrick Taillandier
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model SWITCH

global {
	
	
	/*=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-= */ 
	/*										Predicates								 */
	/*=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-= */ 
	
	
	predicate working <- new_predicate("working");
	predicate staying_at_home <- new_predicate("staying_at_home");
	predicate leisure <- new_predicate("leisure");
	predicate eating <- new_predicate("eating");
	predicate at_target <- new_predicate("at target");
	predicate at_subtarget <- new_predicate("at_subtarget");
	
	string worker <- "worker" const: true;
	string retired <- "retired" const: true;
	string student <- "student" const: true;
	string unemployed <- "unemployed" const: true;
	string none <- "none" const: true;
}
