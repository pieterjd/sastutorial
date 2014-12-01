/*
Toy problem: Suppose a farmer has 75 acres on which to plant two crops: wheat and barley. To produce these crops, 
it costs the farmer (for seed, fertilizer, etc.) $120 per acre for the wheat and  $210 per acre for the barley. 
The farmer has $15000 available for expenses. But after the harvest, the farmer must store the crops while awaiting 
favourable market conditions. The farmer has storage space for 4000 bushels. Each acre yields an average of 110 
bushels of wheat or 30 bushels of barley.  If the net profit per bushel of wheat (after all expenses have been 
subtracted) is $1.30 and for barley is $2.00, how should the farmer plant the 75 acres to maximize profit?
*/
/*
SAS Docs: http://support.sas.com/documentation/cdl/en/ormpug/59679/HTML/default/viewer.htm#intromp_sect23.htm
*/
proc optmodel;
/*wheat and barley vars*/
 var wheat, barley;
/*objective*/
 maximize profit=110*1.3*wheat + 30*2*barley;
 /*constraints*/
 /*expense constraint*/
 con expense:120*wheat + 210*barley <= 15000;
 con storage:110*wheat+30*barley <= 4000;
 con area: wheat + barley <= 75;

 solve with lp /solver=primal;

 /*print solution*/
 print wheat barley;
quit;
run;
/*http://www.purplemath.com/modules/linprog3.htm*/
proc optmodel;
 var S,G;
 maximize profit=-2*S+5*G;
 con minimal_demandS:100<=S;
 con maximal_demandS:200>=S;
 con minimal_demandG:80 <=G;
 con maximal_demandG:170>=G;
 con shipping: S+G>=200;

 solve with lp /solver=primal;
 print S G;
 quit;
 run;

 /*transport problem: http://ir.library.oregonstate.edu/xmlui/bitstream/handle/1957/20201/em8779-e.pdf#page=3 */
 /*the usual way*/
 proc optmodel;
  var X11,X12,X13,X21,X22,X23,X31,X32,X33;
  /*minimize transportation cost*/
  minimize cost = 32*X11 + 40*X21 + 120*X31 + 60*X12 + 68*X22 +
 104*X32 + 200*X13 + 80*X23 + 60*X33;
  con c1:X11 + X21 + X31 >= 30;
  con c2:X12 + X22 + X32 >= 35;
  con c3:X13 + X23 + X33 >= 30;
  con c4:X11 + X12 + X13 <= 20;
  con c5:X21 + X22 + X23 <= 30;
  con c6:X31 + X32 + X33 <= 45;
  
  solve with lp /solver=primal;
  print X11 X12 X13 X21 X22 X23 X31 X32 X33;
  quit;
run;

/*transportation way of solving*/
/*http://support.sas.com/documentation/cdl/en/ormpug/59679/HTML/default/viewer.htm#optmodel_sect5.htm*/
proc optmodel;
 set O={'1','2','3'};
 set D={'A','B','C'};
 /*cost matrix*/
 number c{O,D}=[32 60 200
                40 68 80
				120 104 60];
 /**maxload from loggingsite*/
 number a{O} = [20 30 45];
 /*demand for each mill*/
 num b{D} = [30 35 30];
 /*define variables*/
 var X{O,D}>=0;
 min cost = sum{i in O,j in D}c[i,j]*X[i,j];
 constraint maxload{i in O}:sum{j in D}X[i,j]<=a[i];
 constraint mindemand{j in D}:sum{i in O}X[i,j] >=b[j];
 solve;
 print x;
run;
/*another example from http://comp.utm.my/pars/files/2013/04/Optimization-of-Transportation-Problem-with-Computer-Aided-Linear-Programming.pdf */
proc optmodel;
  set O={'Mine1','Mine2'};
  set D={'Plant1','Plant2','Plant3'};
  number c{O,D}=[9.459 16.4415 28.3995
				14.944 29.211 19.101];
 number a{O} = [103.445 197.335]; 
 number r{D} = [71.35 133.498 96.1005];

 var x{O,D} >=0;

 min cost = sum{i in O,j in D}c[i,j]*x[i,j];
 expand cost;
 constraint supply{i in O}:sum{j in D}x[i,j]<=a[i];
 expand supply;
 constraint demand{j in D}:sum{i in O}x[i,j]>=r[j];
expand demand;
 solve with lp /solver=primal;
 print x;
run;
/*previous one unfeasible, now use generated constraints to explicitly define constraints*/
/* ? still infeasible ? */
proc optmodel;
 var X11,X12,X13,X21,X22,X23;
 Minimize cost=9.459*X11 + 16.4415*X12 + 28.3995*X13 + 14.944*X21 + 29.211*X22 + 19.101*x23;                                                                                            
 Constraint s1: X11 + X12 + x13 <= 103.445;                                            
 Constraint s2: X21 + X22 + X23 <= 197.335;
 Constraint d1: X11 + X21 >= 71.35 ;                                                              
 Constraint d2: X12 + X22 >= 133.498;                                                             
 Constraint d3: X13 + X23 >= 96.1005;                                                             

 solve;
 print;
 quit;
run;

/*http://wps.prenhall.com/wps/media/objects/2234/2288589/ModB.pdf*/
/*Example B4*/
proc optmodel;
 /*quantities to manufacture*/
set months = {1..6};
 var X{months}>=0;
 /*selling quantities*/
 set sales={1..6};
 var Y{sales}>=0;
 constraint y1:Y[1]=0;/*do not sell anything in month 1*/
 constraint x6:X[6]=0;/*do not manufacture anything in last month*/
 /*inventory variables*/
 set inventory = {1..6};
 var I{inventory} >=0;
 constraint inv1:I[1]=X[1];
 expand inv1;
 constraint inv25{k in 2..5}:I[k]=I[k-1]-Y[k]+X[k];
 expand inv25;
 constraint inv6:I[6]=I[5]-Y[6];/*everything must be sold out, so no inventory at the end of month 6*/
 expand inv6;
 constraint maxinv{k in 1..6}:I[k]<=100;
 expand maxinv;
 /*prices*/
 number prices{sales}=[0 80 60 70 80 90];
 /*costs*/
 number costs{months}=[60 60 50 60 70 0];
 maximize profit=sum{k in sales}prices[k]*Y[k] - sum{k in months}costs[k]*X[k];
 expand profit;

 solve with lp /solver=primal;
 print X Y I;
 quit;
run;
/*Other inventory problem with guide is sas
http://www.mwsug.org/proceedings/2009/tutorials/MWSUG-2009-T11.pdf
*/
proc optmodel;
 set<num> periods;
 number price{periods};
 number demand{periods};
 number inventorycost{periods};
 /*fill them up with values*/
 periods=1..2;
 price[1]=1;price[2]=1;
 demand[1]=10;demand[2]= 11;
 inventorycost[1] = 0.1;inventorycost[2] = 0.1;
 /*variables*/
 var buy{periods} >= 0;
 var usefrominventory{periods} >= 0;
 var inventory{periods} >= 0;
 /*constraints*/
 constraint meetDemands{t in periods}:buy[t]+usefrominventory[t] >= demand[t];
 /*inventory constraint: first one for t=1, second for all other t*/
 constraint inventoryBalance1{t in periods: t=1}:inventory[t] = buy[t] -demand[t];
 constraint inventoryBalance2{t in periods: t>1}:inventory[t] = inventory[t-1] + buy[t] -demand[t];
 /*objective*/
 min cost = sum{t in periods}(price[t]*buy[t]+inventorycost[t]*inventory[t]);
 expand;
 solve;
 print price demand;
 print buy usefrominventory inventory;
 print cost;
 quit;
run;








/*same problem as before thingie*/
/*still unfeasible :( */

proc optmodel;
 set<num> months;
 number salePrice{months};
 number costPrice{months};
 
 /*fill them up with values*/
 months=1..6;
 salePrice[1]=0;salePrice[2]=80;salePrice[3]=60;salePrice[4]=70;salePrice[5]=80;salePrice[6]=90;
 costPrice[1]=60;costPrice[2]=60;costPrice[3]=50;costPrice[4]=60;costPrice[5]=70;costPrice[6]=0;

 /*variables*/
 var manufactured{months} >= 0;
 var sold{months} >= 0;
 var inventory{months} >= 0;
 /*constraints*/

 /*inventory constraint: first one for t=1, second for all other t*/
 constraint inventoryBalance1{t in months: t=1}:inventory[t] = manufactured[t];
 constraint inventoryBalance2{t in months: t>1}:inventory[t] = inventory[t-1] + manufactured[t] -sold[t];
 /*objective*/
 
 max profit = sum{t in months} (salePrice[t]*sold[t]-costPrice[t]*manufactured[t]);
 expand;
 solve;
 print manufactured sold inventory;

 print profit;
 quit;
run;

/*problem B.16 school bus problem*/
proc optmodel;
 set O={'A','B','C','D','E'};
 set D={'D','C','E'};
 number miles{O,D} = [5 8 6
                      0 4 12
					  4 0 7
					  7 2 5
					  12 7 0];
 number nrStudents{O}=[700 500 100 800 400];
 number maxCapacity{D}=[900 900 900];
 var x{O,D}>=0;
 /*objective function*/
 min studentMiles = sum{i in O,j in D} miles[i,j]*x[i,j];
 /*constraints*/
 constraint allStudentsToSchool{i in O}:sum{j in D}x[i,j]>=nrStudents[i];
 constraint schoolMaxCapacity{j in D}:sum{i in O}x[i,j]<=maxCapacity[j];
 expand;
 solve;
 print x;
 quit;
run;

/*problem B18 scheduling workers*/
proc optmodel;
 set periods={'1','2','3','4','5','6'};
 number required{periods} = [3 12 16 9 11 4];
 var x{periods} >=0;
 min totalWorkers=sum{i in periods}x[i];
 
 constraint requiredWorkers1{t in periods:t=1}:x[1]+x[6]>=required[1];
 constraint requiredWorkers2{t in periods:t>1}:x[t]+x[t-1]>=required[t];
 
 expand;
 solve;
 print x;
 quit;
run;
/*test on conditional constraint on first toy problem*/

proc optmodel;
 /*wheat and barley vars*/
 var wheat, barley;
/*objective*/
 maximize profit=110*1.3*wheat + 30*2*barley;
 /*constraints*/
 /*expense constraint*/
 con expense:120*wheat + 210*barley <= 15000;
 con storage:110*wheat+30*barley <= 4000;
 con area: wheat + barley <= 75;
 /*binary variable is 1 if wheat != barley else 0*/
 var y binary;
 constraint equality:wheat - 10000000*y = barley;
 solve with milp;
 /*print solution*/
 print wheat barley y;
quit;
run;
 





















































