/*http://www.cse.iitd.ernet.in/~naveen/courses/CSL866/TutorialSP.pdf */

proc optmodel;

 set<num> scenarios=1..2;
 number d{scenarios} = [20 80];
 var x>=0;
 /*second stage variables*/
 var t{scenarios};

 number p{scenarios} = [0.5 0.5];
 constraint c1{k in scenarios}:(1-1.5)*x-t[k]<=-1.5*d[k];
 constraint c2{k in scenarios}:(1+0.1)*x-t[k]<=0.1*d[k];
 min discomfort = sum{k in scenarios}p[k]*t[k];
 solve;
 print p t x;
 run;
















/*
Checking out https://www.me.utexas.edu/~jensen/ORMM/computation/unit/stoch_program/simple_example.html
Idea: find the optimal product mix, but the available resources are unknown at this time.
Steps:
* Put together a product mix
* when resource availability is known, see if the product mix is feasible. 
  If not, take action eg hire additional workers and minimize the additional costs.
*/

/*now the resources are available, minimize the additional costs*/
/*
* probs: probability of each scenario
* carpet: available carpet for each scenario
* finish: available finishing for each scenario
each lists of the same length
*/

 proc optmodel;
 set<num> products=1..4;
 /*production quantities*/
 var X{products} >= 0;
 number unit_profit{products} = [15 25 21 31];
 number carpetReq{products} = [4 9 7 10];
 var carpetTotalReq >=0;
 constraint carpetTotalReqDefinition: carpetTotalReq = sum{i in products}carpetReq[i]*X[i];
 number finishReq{products} = [3 1 3 4];
 var finishTotalReq >= 0;
 constraint finishTotalReqDefinition: finishTotalReq =sum{i in products}finishReq[i]*X[i];
 /*fixed resource availability based on expected values - see notes on website*/
/* constraint carpetAvail: carpetTotalReq <= 5625;*/
/* constraint finishAvail: finishTotalReq <= 4000;*/
 /*step 2 requirements*/
 /*explicit definition*/
 set<num> scenarios=1..4;
 
 number probabilities{scenarios} = [0.25 0.25 0.25 0.25];
 number carpet_avail{scenarios} = [4800 5500 6050 6150];
 var y_carpet{scenarios}>=0;
 constraint y_carpetDef{i in scenarios}: y_carpet[i] = sum{j in products}carpetReq[j]*X[j] - carpet_avail[i];
 number finish_avail{scenarios} = [3936 3984 4016 4064];
 var y_finish{scenarios}>=0 ;
 constraint y_finishDef{i in scenarios}: y_finish[i] = sum{j in products}finishReq[j]*X[j] - finish_avail[i];
 var Q{scenarios};
 constraint QDef{i in scenarios}:Q[i] = y_carpet[i]* 5 + y_finish[i]*10;
 var EQ;
 constraint EQDef:EQ = sum{i in scenarios}probabilities[i] * Q[i];
 /*  profit */
 var profit{scenarios};
 constraint profitDef{k in scenarios}:profit[k]=sum{i in products}unit_profit[i]*x[i] - Q[k];
 max trouble=sum{i in products}unit_profit[i]*x[i] - sum{k in scenarios}Q[k];
 expand;
solve;
/* dump optimal solution in production dataset*/
create data production from [solns]=products X;
print x;
print y_carpet Y_finish carpet_avail finish_avail Q profit carpetTotalReq finishTotalReq;
run;