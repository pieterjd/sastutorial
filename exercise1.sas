libname pjan 'E:\PROJECTS\SANDBOX\PIETERJAN';

/*checken of ik aan data kan*/
/**/
/*
proc sort data=pjan.report_summary_kpi;
proc print data=pjan.report_summary_kpi;
run;
proc summary data=pjan.report_summary_kpi;
  var pos;
run;
*/
data ex1;
 /*selecting vars*/
 set pjan.report_summary_kpi (keep=media_issue edition_date issue_desc estimated_received actual_received 
  estimated_sold actual_sold POS ACTUAL_PERCPOSCOMPLETE EDITION_DATE);
  /*downsizing*/
  if pos='ALL' and estimated_sold NE . and ACTUAL_PERCPOSCOMPLETE >= 0.95 and EDITION_DATE>='16JUN2014'd  ;
  /*new vars*/
  delta_sold = estimated_sold - actual_sold;
  delta_received = estimated_received - actual_received;
  if delta_sold = . then sold_overestimate = 'UNKNOWN';
  else if delta_sold>0 then sold_overestimate = 'YES'; 
  else sold_overestimate = 'NO';

run;
/*
proc print data=ex1;
run;
*/
proc sort data=ex1;
by sold_overestimate;
run;
/*
proc means data=ex1 ;
by sold_overestimate;
run;

proc summary data=ex1 nway ;
title "Delta_sold = estimated-actual";
var delta_sold;
class sold_overestimate;
output out=delta_summary median =;

run;
*/
proc sql;
 create table sql_summary as select max(delta_sold) as max,min(delta_sold) as min, mean(delta_sold) as mean,sold_overestimate
 from ex1
 group by sold_overestimate;
 quit;
run;
/*same thing with first and last*/
proc sort data=ex1;
by sold_overestimate delta_sold;
run;
/*summary using first and last*/
/*getting min*/
data fl_summary;
 set ex1 (keep=sold_overestimate delta_sold);
 by sold_overestimate;
 if firST.sold_overestimate or last.sold_overestimate;
 first = first.sold_overestimate;
 last = last.sold_overestimate;
 retain max min;
if first.sold_overestimate=1 then min=delta_sold; else do;
	max=delta_sold;
	output;/*maximum bepaald, dus nu mag een rij ge-output'd worden*/
end;/*end else*/
run;
proc print data=ex1;
run;
/*
-- next part of the exercise
-- joining met simulations en sku_simulation_param tables
*/
data mysims;
 set pjan.simulations;
 where default = 'Y';/*select only simulations with default params*/
run;
/*mysim joinen met ex1 dataset*/
/*!! gene commentaar zetten tussen sql commands. Sas editor kleurt het wel goed in, maar query draait de soep in*/
proc sql;
 create table sqljoin as select ex1.media_issue,estimated_sold,actual_sold,delta_sold,sold_overestimate,simulation_id,sku_simulation_param.distribution_method,sku_simulation_param.forecast_method
 from ex1,pjan.sku_simulation_param,mysims
 where ex1.media_issue=sku_simulation_param.sku_code and sku_simulation_param.simulation_id=mysims.id;
 quit;
run;
/*beteke tabellekes maken*/
title;
proc tabulate data=sqljoin;
 title "sqljoin overview";
 class sold_overestimate distribution_method forecast_method;
 table sold_overestimate,distribution_method,forecast_method;
run;
title;
/*merging met data statement*/
/*na ne hele hoop geklooi cf join-debug program voor meer uitleg*/
/*sas kan gene join van 3 tabellen in 1 keer doen, dus 2 stappen nodig*/

/*eerst sorteren*/

proc sort data=ex1;
by media_issue;
run;
proc sort data=pjan.sku_simulation_param;
 by sku_code;
run;
data sasjoin1(keep=sku_code estimated_sold actual_sold delta_sold sold_overestimate simulation_id distribution_method forecast_method name default);
 merge ex1(rename=(media_issue=sku_code)) pjan.sku_simulation_param;
 by sku_code;
 if actual_sold NE .;
 if simulation_id NE .;/*blijkbaar zijn er rows met een unknown simulation id. sql skipt die automatisch, sas natuurlijk niet, dus hier zelf uitfilteren*/
 name = "sasjoin1";/*for compare dataset*/
run;

/*stap 2 van de join*/
/*weer eerst sorteren*/


proc sort data=sasjoin1;
 by simulation_id;
 run;
 /*
proc print data=sasjoin1;
run;
 */
proc sort data=mysims;
 by id;

data sasjoin2;
 merge mysims(rename=(id=simulation_id)) sasjoin1;
 by simulation_id;
 /*d'er zitten blijkbaar lege sku_codes tussen, da ka nie!*/
 if sku_code NE '';
 /*d'er zitten ook lege default in, dan kan niet*/
 if default EQ 'Y';
 name="sasjoin2";
run;
/*tabellekes*/

proc tabulate data=sasjoin2;
 title "sasjoin2 overview";
 class sold_overestimate distribution_method forecast_method;
 table sold_overestimate,distribution_method,forecast_method;
run;
title;
run;

/*sql like join using in statement in data step*/

/*eerst sorteren*/

proc sort data=ex1;
by media_issue;
run;
proc sort data=pjan.sku_simulation_param;
 by sku_code;
run;
data sasjoin1in(keep=sku_code estimated_sold actual_sold delta_sold sold_overestimate simulation_id distribution_method forecast_method name default);
merge ex1(rename=(media_issue=sku_code) in=InEx1) pjan.sku_simulation_param(in=InSimParam);
if InEx1 and InSimParam;
 by sku_code;
run;

/*weer eerst sorteren*/


proc sort data=sasjoin1in;
 by simulation_id;
 run;
 /*
proc print data=sasjoin1;
run;
 */
proc sort data=mysims;
 by id;
run;

data sasjoin2in;
 merge mysims(rename=(id=simulation_id) in=InMySim) sasjoin1in(in=InSJ1);
 by simulation_id;
 if InMySim and InSJ1;
run;
/*tabellekes*/

proc tabulate data=sasjoin2in;
 title "sasjoin2in overview";
 class sold_overestimate distribution_method forecast_method;
 table sold_overestimate,distribution_method,forecast_method;
run;
title;
run;

/*lookup table*/
/*
sql join in other representation
table:   ex1                      sku_sim_param                mysim
condition: |_ media_issue=sku_code_|         |_simulation_id=id_|

*/
proc sort data=pjan.sku_simulation_param;
 by simulation_id;
proc sort data=mysims;
 by id;
run;
data all_hashies;
 if _N_ = 0 then
  set ex1( keep=media_issue estimated_sold actual_sold delta_sold sold_overestimate);
 if _N_ = 1 then do; 
   
   declare hash ex1hash(dataset: "ex1");
   ex1hash.defineKey("media_issue");
   ex1hash.defineData("estimated_sold","actual_sold","delta_sold","sold_overestimate");
   ex1hash.definedone();
 end; 

 merge pjan.sku_simulation_param(in=ssp keep=sku_code simulation_id distribution_method forecast_method) mysims(rename=(id=simulation_id) in=ms); 
 by simulation_id;
 if ssp and ms;
 /*data uit hashmap halen*/
 rc = ex1hash.find(key:sku_code);
 if rc=0;
 rcStatus = rc;
 if rc EQ 0 then estimated_sold2=estimated_sold;
run;

/*tabellekes*/
data nekes;
 set ex1;
 n2 = _N_;
 if _N_ = 0 then put "n is nul";
run;
proc tabulate data=all_hashies;
 title "allhashies overview";
 class sold_overestimate distribution_method forecast_method;
 table sold_overestimate,distribution_method,forecast_method;
run;
title;
run;
   