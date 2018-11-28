/**
* Name: FIPA
* Author: giulioma
* Description: 
* Tags: Tag1, Tag2, TagN
*/

model FIPA

global {
	
	point auction_location1 <- {25,25};
	point auction_location2 <- {50,50};
	point auction_location3 <- {75,75};
	
	//No challenges: Comment lines -> 22, 24, 30 and 38
	// Challenge 1: Comment lines -> 21, 24, 29 and 38
	//Challenge 2: Comment lines -> 22, 23, 29 and 37
	//Both challenges: Comment lines -> 21, 23, 29 and 37
	
//	list<string> auction_type <- ['CDs'];
	list<string> auction_type <- ['CDs', 'Clothing', 'Books'];
//	list<string> auction_kind <- ['Dutch'];
	list<string> auction_kind <- ['Dutch', 'English', 'Sealed'];
	list<Initiator> InitiatorList <- [];
	
	
	list<list<int>> random_combination <- [[0,2,1],[0,1,2],[2,1,0],[1,2,0]];
//	int combination_key <-  0;
	int combination_key <- rnd(0,3);
	
	int type_assigned <- 0;
	int kind_assigned <- 0;
	
	init {
			create Participant number: 20 ;
//			create Initiator number: 1 ;
			create Initiator number: 3 ;
			create Guard number: 1;
	}
	
	bool creativity <- false;
	int guard_speed <- 1;
	point ExitPoint <- {0,50};
	
}

species Guard skills: [moving]{
	float size <- 2.0 ;
	rgb color <- #black;
	aspect base {
		draw circle(size) color: color ;
	}
	
	list<Participant> targets <- [];
	
	reflex kill when: creativity and length(self.targets)>0{
		point target <- self.targets[0].location;
		Participant badGuy <- self.targets[0];
		do goto target: target speed: guard_speed;
		
		if( self.location distance_to(target) < 2){
			ask (badGuy){
				if(length(myself.targets)>0 and self = badGuy){
					//write "Killed!";
					remove first(myself.targets) from: myself.targets;
					do die;
				}
			}
		}else if( target distance_to(ExitPoint) < 2){
			//write "Guard: That was fast.";
			remove first(targets) from: targets;
		}
	}
}

species Initiator skills: [fipa] {

	string type;
	string kind;
	rgb color;
	point location;
	bool initialized <- false;
	
	int init_offer;
	int original_offer;
	bool auction_alive <- false;
	list<Participant> people_attending <- [];
	int auction_time <- 0;
	bool next <- false;
	bool auction_ended <-false;
	
	int price_sold <- -1;
	
	int dutch_auction_minimum <- 100;
	int sealed_auction_minimum <- rnd(90,120);
	
	aspect base {
		if !self.initialized{
			add self to: InitiatorList;
			
			// Assigning Type
			self.type <- auction_type[type_assigned];
			if self.type = 'CDs'{
				self.color <- #red;
				self.location <- auction_location1;
			}
			
			else if self.type = 'Clothing'{
				self.color <- #yellow;
				self.location <- auction_location2;
			}
			
			else if self.type = 'Books'{
				self.color <- #blue;
				self.location <- auction_location3;
			}
			type_assigned <- type_assigned +1;
			
			// Assigning Kind
//			self.kind <- auction_kind[kind_assigned];
			self.kind <- auction_kind[random_combination[combination_key][kind_assigned]];
			if self.kind = 'Dutch'{
				self.init_offer <- rnd(400, 500);
			}
					
			else if self.kind = 'English'{
				self.init_offer <- rnd(50, 100);
			}
			
			else if self.kind = 'Sealed'{
				self.init_offer <- 0;
			}
			kind_assigned <- kind_assigned +1;
			
			//Assigning init_offer
			original_offer <- self.init_offer;
			
			//Let them know you initialized
			self.initialized <- true;
		
		}
		
		//Make shape based on kind
		if self.kind = 'Dutch'{
			draw box(2,2,2) at: self.location color: self.color;
		}
				
		else if self.kind = 'English'{
			draw box(2,2,2) at: self.location color: self.color;
		}
				
		else if self.kind = 'Sealed'{
			draw box(2,2,2) at: self.location color: self.color;
		}
		
	}
	
	reflex startAuction when: length(self.people_attending) > 3 and !self.auction_alive and !self.auction_ended	{
		self.auction_alive <- true;
		next <- true;
		//write self.kind + " auction selling " + self.type + " is open with an initial offer of " + self.init_offer;
		loop a over: self.people_attending {
			do start_conversation (to :: [a], protocol :: 'fipa-request', performative :: 'inform', contents :: ["Get ready"]);
		}
	}
	
	reflex decrement_offer when: self.auction_alive and self.kind = 'Dutch'{
		int decrement <- rnd(40,50);
		self.init_offer <- self.init_offer - decrement; 
		//write "New Offer: " + self.init_offer + " by " + self.type;
	}
	
	reflex send_request when: self.auction_alive and next {
		
		//write self.kind + " auction selling " + self.type + " now has " + length(self.people_attending) + " participants";
		loop r over: self.people_attending {
//			//write 'Send message';
			do start_conversation (to :: [r], protocol :: 'fipa-request', performative :: 'cfp', contents :: [init_offer]);
		}
		self.auction_time <- self.auction_time + 1;
		
		next <- false;
	}
	
	reflex read_reply_message when: (!(empty(proposes))) and self.auction_alive{
		Participant winner;
		loop a over: proposes {
			//write 'Agree message with content: ' + string(a.contents);
			do accept_proposal with: [ message :: a, contents :: ['Interesting proposal'] ];
			int offer <- int(a.contents at 0);
			
			if self.kind = 'Dutch'{
				if self.init_offer < self.dutch_auction_minimum{
					self.auction_alive <- false;
					self.price_sold <- 0;
					self.people_attending <- [];
					winner <- nil;
				}
				else if offer > self.init_offer and offer > self.price_sold{
					self.auction_alive <- false;
					self.price_sold <- offer;
					self.people_attending <- [];
					winner <- a.sender;
				}
			}
			
			else if self.kind = 'English'{
				if offer > self.init_offer and offer > self.price_sold{
					self.price_sold <- offer;
					winner <- a.sender;
				}
				else{
					remove a.sender from: self.people_attending;
				}
				
				if length(self.people_attending) <= 1{
					self.auction_alive <- false;
					self.people_attending <- [];
					
					if self.original_offer > self.init_offer{
						self.init_offer <- 0;
						self.price_sold <- 0;
						winner <- nil;
					}
					
				}else{
					self.init_offer <- self.price_sold;
				}
			}
			
			else if self.kind = 'Sealed'{
				if offer > self.price_sold{
					self.auction_alive <- false;
					self.price_sold <- offer;
					winner <- a.sender;
					self.people_attending <- [];
				}
			}
			
		} 
		
		if !self.auction_alive{
			//write 'ENDED! ' + self.kind + " auction sold " + self.type + " for " + self.price_sold;
			self.auction_ended <- true;
			
			if winner != nil{
				do start_conversation (to :: [winner], protocol :: 'fipa-request', performative :: 'inform', contents :: ["You Won!", self.price_sold]);
				
				if self.kind = 'Dutch'{
					write "Dutch auction had profit: " + 100.0*float(self.price_sold)/float(self.dutch_auction_minimum) + "%";
				} else if self.kind = 'English'{
					write "English auction had profit: " + 100.0*float(self.price_sold)/float(self.original_offer) + "%";
				} else if self.kind = 'Sealed'{
					write "Sealed auction had profit: " + 100.0*float(self.price_sold)/float(self.sealed_auction_minimum) + "%";
				}	
			}
			
		} else{
			next <- true;	
		}
	}
	
	reflex getInformed when: !empty(informs){
		message infomsg <- informs at 0;
		if infomsg.contents at 0 != "ok!"{
			if infomsg.contents at 0 = 0{
				ask(Guard){
					add infomsg.sender to: self.targets;
					//write "Winner didn't pay. Call the cops!";
				}
			} else {
				//write "Payment Received";
			}
		}
	}
}

species Participant skills: [fipa, moving] {
	
	string type <- auction_type[rnd(0,2)];
	string auction_kind;
	rgb color;
	point target;
	bool initialized <- false;
	bool attending <- false;
	int part_offer <- rnd(100, 400);
	float english_bid <- part_offer/rnd(2,6);
	float english_offer <- english_bid;
	bool run <- false;
	float running_speed <- rnd(0.5,1.5);
	
	float size <- 1.0 ;
	aspect base {
		if !self.initialized{
			if self.type = 'CDs'{
				self.color <- #red;
				self.target <- auction_location1;
			}
			
			else if self.type = 'Clothing'{
				self.color <- #yellow;
				self.target <- auction_location2;
			}
			
			else if self.type = 'Books'{
				self.color <- #blue;
				self.target <- auction_location3;
			}
			
			self.initialized <- true;
		
		}
		
		draw circle(self.size) color: self.color ;
	}
	
	reflex gotoauction when: !self.attending{
		do goto target: target speed: 1.0;
	
		if(location distance_to(target) < 2) {
			loop ini over: InitiatorList{
				ask ini {
					if self.type = myself.type{
						add myself to: self.people_attending;
						myself.attending <- true;
						myself.auction_kind <- self.kind;
						break;
					}
				}
			}
		}
	}
	
	reflex runForYourLife when: run{
		do goto target:ExitPoint speed: self.running_speed;
		if( location distance_to(ExitPoint) < 2){
			//write "Thief: I Got Away!";
			run <- false;
		}
	}
	
	reflex getInformed when: !empty(informs){
		message infomsg <- informs at 0;
		
		if infomsg.contents at 0 = "You Won!"{
			//There is 70% chance the winner participant might panic and not pay
			if rnd(1,100) > 30 and creativity{
				do inform with: (message: infomsg, contents: [0]);
				run <- true;
			} else{
				int toPay <- int(infomsg.contents at 1);
				self.part_offer <- self.part_offer - toPay;
				do inform with: (message: infomsg, contents: [toPay]);
			}
		}
		else{
			do inform with: (message: infomsg, contents: ["ok!"]);	
		}
	}
	
	reflex reply_message when: (!empty(cfps)) {
		message requestFromInitiator <- (cfps at 0);
//		if requestFromInitiator.performative != 'cfp'{
		int offer <- int(requestFromInitiator.contents at 0);
		
		if self.auction_kind = 'Dutch'
		{
			if offer < self.part_offer {
				do propose with: (message: requestFromInitiator, contents: [self.part_offer]);
//				do refuse with: (message: requestFromInitiator, contents: [false]);
			}
			else {
//				//write 'Inform the initiator of the failure';
				do propose with: (message: requestFromInitiator, contents: [false]);
//				do refuse with: (message: requestFromInitiator, contents: [false]);
			}
		}
		
		else if self.auction_kind = 'English'
		{
			if self.english_offer < self.part_offer {
				do propose with: (message: requestFromInitiator, contents: [self.english_offer]);
//				do refuse with: (message: requestFromInitiator, contents: [false]);
				
				self.english_offer <- self.english_offer + self.english_bid;
			}
			else {
//				//write 'Inform the initiator of the failure';
				do propose with: (message: requestFromInitiator, contents: [false]);
//				do refuse with: (message: requestFromInitiator, contents: [false]);
			}
		}
		
		else if self.auction_kind = 'Sealed'
		{
			do propose with: (message: requestFromInitiator, contents: [self.part_offer]);
//			do refuse with: (message: requestFromInitiator, contents: [false]);
		}
//	}
	
	}
}

experiment auction_info type: gui repeat: 1{
	output {
		display main_display {
			species Participant aspect: base ;
			species Initiator aspect: base ;
			species Guard aspect: base;
			
			graphics 'exitpoint'{
				draw box(4,4,4) color: #purple at: ExitPoint;
			}
		}
	}	
}
 
