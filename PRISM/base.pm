// Model type declaration
dtmc

// Stake ratio distribution
const double r1 = 1/3;
const double r2 = 1/3;
const double r3 = 1/3;

// Granularity of each slot
const int g = 1;

// Stake age parameters
const minAge = 3;
const int maxAge = 9;
const int ageLimit = 36;

// Age limit factor increase
const int factor = 1;
//const int ageLimit = 36*factor;

// Increase age by 1 only for each completed slot
formula age_update = mod(step,3*g-2)=0? 1 : 0;

// Agents probability of being elected to produce a block
formula p = r1/g * min(age1+age_update,maxAge)/(maxAge);

// Agents eligibility to stake (e.g., old enough)
formula eligibile = (age1+age_update>=minAge)? true : false;

// Total number of solutions found during a step
formula solutions = solution1+solution2+solution3;

// Total number of agents chosen as block proposer
formula winners = winner1+winner2+winner3;

// Highest coinage from agents with solutions found
formula maxCoinage = max(r1*age1*solution1,r2*age2*solution2,r3*age3*solution3);

// Total number of elible stakers
formula eligible_stakers = (age1+1>=minAge? 1:0)+(age2+1>=minAge? 1:0)+(age3+1>=minAge? 1:0);

module stepper

	step : [1..3*g] init 1;

	[election] mod(step,3)=1 -> (step'=step+1);
	[consensus0] mod(step,3)=2 -> (step'=step+1);
	[consensus1] mod(step,3)=2 -> (step'=step+1);
	[consensus2] mod(step,3)=2 -> (step'=step+1);
	[consensus3] mod(step,3)=2 -> (step'=step+1);
	[reset] mod(step,3)=0 -> (step' = (step=3*g)? 1 : step+1);

endmodule

// Module process for agent 1
module agent1

	age1 : [0..ageLimit] init minAge;
	solution1 : [0..1] init 0;
	winner1 : [0..1] init 0;

	// Solution search
	[election] eligibile -> p:(solution1'=1)&(age1'=min(age1+age_update,ageLimit)) 
			        + 1-p:(age1'=min(age1+age_update,ageLimit));
	[election] !eligibile -> (age1'=age1+age_update);

	// Highest coinage selection rule
	[consensus1] solution1=1&(r1*age1)=maxCoinage -> (solution1'=0)&(winner1'=1);
	[consensus2] solution2=1&(r2*age2)=maxCoinage -> (solution1'=0);
	[consensus3] solution3=1&(r3*age3)=maxCoinage -> (solution1'=0);
	[consensus0] solutions=0 -> (solution1'=0);

	// Reset to prepare for new step
	[reset] winner1=1 -> (winner1'=0)&(age1'=0);
	[reset] winner1=0 -> true;

endmodule

// Agents using agent 1 as a template module
// Module process for agent 2
module agent2=agent1 [
age1=age2,
solution1=solution2,
winner1=winner2,
r1=r2,
age2=age1,
solution2=solution1,
winner2=winner1,
r2=r1,
consensus1=consensus2,
consensus2=consensus1
] endmodule
// Module process for agent 3
module agent3=agent1 [
age1=age3,
solution1=solution3,
winner1=winner3,
r1=r3,
age3=age1,
solution3=solution1,
winner3=winner1,
r3=r1,
consensus1=consensus3,
consensus3=consensus1
] endmodule

// Labels describing
// a state that has solutions
label "solutions" = solutions>0;
// a state that has conflicts
label "conflict" = solutions>1;
// a state that has winners
label "winners" = winners>0;
// a state that has multiple winners
label "failure" = winners>1;

// Reward value of 1 applied to any state
// that has an action label: election
rewards "subslots"
	[election] true : 1; 
endrewards

// Reward value of 1/g applied to any state
// that has an action label: election
rewards "slots"
	[election] true : 1/g; 
endrewards

// Reward value of [1..n] applied to any state
// in which has agents which found solutions
rewards "total_elected"
	solutions > 0 : solutions; 
endrewards

// Reward value of 1 applied to any state
// in which agent 3 found a solution
rewards "A3_elected"
	solution3 = 1 : 1; 
endrewards

// Reward value of 1 applied to any state
// that has multiple solutions found
// ( multiple agents elected)
rewards "conflicts"
	solutions > 1 : 1; 
endrewards

// Reward value of [1..n] applied to any state
// in which winners were chosen
rewards "total_produced"
	winners > 0 : winners; 
endrewards

// Reward value of 1 applied to any state
// in which agent 3 was chosen as winner
rewards "A3_produced"
	winner3 = 1 : 1; 
endrewards

// Reward value of (coinage of winner) applied to any state
// in which winners were chosen
rewards "total_rewards"
	winner1 = 1 : r1*age1;
	winner2 = 1 : r2*age2;
	winner3 = 1 : r3*age3;
endrewards

// Reward value of agent 3's coinage applied to any state
// in which agent 3 was chosen as winner
rewards "A3_rewards"
	winner3 = 1 : r3*age3; 
endrewards

// Reward value of an agents stake age applied to any state
// in which that agent was chosen as winner
rewards "production_age"
	winner1 = 1 : age1;
	winner2 = 1 : age2;
	winner3 = 1 : age3;
endrewards

// Reward value of agent 3's stake age applied to any state
// in which agent 3 was chosen as winner
rewards "A3_production_age"
	winner3 = 1 : age3;
endrewards

// Reward value equal to the number of current
rewards "eligibility"
	mod(step,3)=1 : eligible_stakers;
endrewards
