%let base_dir = E:\PROJECTS\BLADCENTRALEN\SIMULATIONS\;
%let firstweek = 12;
%let lastweek = 37;
%let year = 2013;
options mprint;
/* clear work library*/
proc datasets library=WORK;
 delete _all_;
 run;

/*import macro*/
/*delete the outputset to make sure multiple runs of this macro are ok*/
proc datasets library= WORK;
 delete &outputset;
 run;
%macro import(year,firstweek,lastweek,magazine,outputset);

 %let base_dir = E:\PROJECTS\BLADCENTRALEN\SIMULATIONS\;
 %do week= &firstweek %to &lastweek;
  /*construct file name*/
  /*dot after &week is required as underscore can be part of a macrovariable name*/
  %let filename = &base_dir.SIM&week.\sqp_&magazine&year&week._1.sas7bdat;
/*  %put "week &week";*/
  %put &filename;
  /*check if file exists*/
  %if %sysfunc(fileexist(&filename)) %then %do;
   %put "&filename is alive!!";
   /*name of the temporary dataset*/
   %let tempset = temp&magazine&year&week;
   /*delete previous content in temp dataset*/

   proc datasets library=WORK NOLIST;
    delete &tempset;
   run;

   /*reading file in temp dataset*/
   data &tempset;
    set "&filename";
   run;
   /*append temp data set to master set*/
   proc append base=&outputset data=&tempset;
   run;
  %end;/*end if file exists*/

 %end;/*week loop*/
%mend;
/*delete the outputset to make sure multiple runs of this macro are ok*/
proc datasets library= WORK;
 delete &outputset;
 run;
%import(2013,12,37,tara,testos);
%import(2013,12,32,seoghor,testos);
%import(2013,12,32,hjemmet,testos);

data sales_history;
 set"E:\PROJECTS\BLADCENTRALEN\MASTER\sales_history.sas7bdat";
 /*convert outledid to character type*/
 outledidtxt = trim(put(outledid,6.));
 /*renaming of vars*/
 orig_sales = sales;
 orig_q = draw;
 orig_oos = sales >= draw;
run;
proc sort data=sales_history;
 by media_issue;
run;
proc summary data=sales_history print sum;
 var draw;
 by media_issue;
run;
proc sort data=temphjemmet201316;
 by sku_code;
run;
proc summary data=temphjemmet201316 print sum;
 var q;
by sku_code;
run;
/*proc print data=sales_history;*/
/*run;*/
/*proc sort data=testos;*/
/*by inv_code;*/
run;
/*orig_* comes from sales_history*/
proc sql;
 create table sales_data as select inv_code,sku_code,orig_sales,orig_q,orig_oos, q as sim_q,media_product
 from sales_history,testos
 where sales_history.outledidtxt = testos.inv_code and sales_history.media_issue = testos.sku_code;
 quit;
run;

proc sort data=sales_data;
 by sku_code;
run;
proc summary data=sales_data print sum;
 var sim_q;
by sku_code;
run;

/*look at total delivery per issue, based on numbers by provideor and bc*/
proc sort data=sales_data;
 by sku_code;
run;
proc summary data=sales_data sum print;
var orig_q sim_q;
by sku_code;
run;

/*sales_data prepping for analysis*/
/*calculate retour  for each title for both original data and new data*/
 
data sales_analysis;
  set sales_data;
  if orig_oos and sim_q > orig_sales then do;
   key = "H100";
   new_sales = min(sim_q,orig_q + max(0,(sim_q-orig_q)*1));
   new_oos = new_sales >= sim_q;
   orig_retour = orig_q - orig_sales;
   new_retour = sim_q - new_sales;
   output;
   key = "H75";
   new_sales = min(sim_q,orig_q + max(0,(sim_q-orig_q)*0.75));
   new_oos = new_sales >= sim_q;
   orig_retour = orig_q - orig_sales;
   new_retour = sim_q - new_sales;
   output;
   key = "H50";
   new_sales = min(sim_q,orig_q + max(0,(sim_q-orig_q)*0.5));
   new_oos = new_sales >= sim_q;
   orig_retour = orig_q - orig_sales;
   new_retour = sim_q - new_sales;
   output;
   key = "H25";
   new_sales = min(sim_q,orig_q + max(0,(sim_q-orig_q)*0.25));
   new_oos = new_sales >= sim_q;
   orig_retour = orig_q - orig_sales;
   new_retour = sim_q - new_sales;
   output;
   key = "H0";
   new_sales = min(sim_q,orig_q + max(0,(sim_q-orig_q)*0));
   new_oos = new_sales >= sim_q;
   orig_retour = orig_q - orig_sales;
   new_retour = sim_q - new_sales;
   output;
 end;
 else do;
 /*orig_oos is false dus new_sales is het minimum van hun sales en de sim_q*/
   key = "H100";
   new_sales = min(sim_q,orig_sales);
   new_oos = new_sales >= sim_q;
   orig_retour = orig_q - orig_sales;
   new_retour = sim_q - new_sales;
   output;
   key = "H75";
   new_sales = min(sim_q,orig_sales);
   new_oos = new_sales >= sim_q;
   orig_retour = orig_q - orig_sales;
   new_retour = sim_q - new_sales;
   output;
   key = "H50";
   new_sales = min(sim_q,orig_sales);
   new_oos = new_sales >= sim_q;
   orig_retour = orig_q - orig_sales;
   new_retour = sim_q - new_sales;
   output;
   key = "H25";
   new_sales = min(sim_q,orig_sales);
   new_oos = new_sales >= sim_q;
   orig_retour = orig_q - orig_sales;
   new_retour = sim_q - new_sales;
   output;
   key = "H0";
   new_sales = min(sim_q,orig_sales);
   new_oos = new_sales >= sim_q;
   orig_retour = orig_q - orig_sales;
   new_retour = sim_q - new_sales;
   output;
 end;
run;
proc sort data=sales_analysis;
 by sku_code;
run;


/*calculate percentage retour and oos for each title*/
/*first short shit according to both sku_code and key*/
proc sort data=sales_analysis;
 by sku_code key;
run;

/*calculate some stats*/

proc means data=sales_analysis sum N;
var orig_q orig_sales  orig_retour orig_oos sim_q new_sales new_retour new_oos;
/*no need for media_product for means, but later on for the regression*/
by sku_code key media_product;
output out=sales_means sum=sum_orig_q sum_orig_sales  sum_orig_retour sum_orig_oos 
 sum_sim_q sum_new_sales sum_new_retour sum_new_oos n=n media_product;
run;
data sales_percentages;
  set sales_means;
  orig_perc_retour = sum_orig_retour / sum_orig_q;
  orig_perc_oos = sum_orig_oos /n;
  orig_log_perc_oos = log(orig_perc_oos);
  new_perc_retour = sum_new_retour / sum_sim_q;
  new_perc_oos = sum_new_oos /n;
  new_log_perc_oos = log(new_perc_oos);
run;

/*regression on each magazine, so in this case 3 regression models*/
/*dataset prepareren*/
options mprint;

%macro run_reg(magazine);
 %let magazine=%upcase(&magazine);
data reg_&magazine;
 set sales_percentages;
 /*! contains is case sensitive*/
where media_product contains "&magazine" and key EQ 'H0';
/*only interested in H0 key*/

run;

proc reg data=reg_&magazine outest=est_&magazine noprint;
title "Regression for &magazine";
 model orig_perc_retour = orig_log_perc_oos;
 /*inspired by http://www.ats.ucla.edu/stat/sas/webbooks/reg/chapter1/sasreg1.htm */
/* plot orig_perc_retour * orig_log_perc_oos;*/
run;
title;

/*data set with all hypothesis*/
/*what retour percentage do you get when you fill in new_log_perc_oos in the regression model?*/
data score_&magazine;
 /*need to rename new_log_perc_oos to match the variable name in the regression model
   in order to compute the values according to regression model using proc score*/
 set sales_percentages (drop=orig_log_perc_oos _type_) ;
 where media_product contains "&magazine";
 orig_log_perc_oos = new_log_perc_oos;
run;
/*compute the model results*/
proc score data=score_&magazine score=est_&magazine type=parms out=compute_&magazine;
 var orig_log_perc_oos;
run;

/*compute difference between the model prediction and what provideor predicted*/
data comparison_&magazine;
 set compute_&magazine;
 delta_prediction = model1 - new_perc_retour;
run;


/*check if model estimates are in sensible range*/
/*check if model estimates are in sensible range*/

/*determine min and max of orig_log_perc_oos*/

proc summary data=sales_percentages min max ;
var orig_log_perc_oos ;
by media_product;
output out=sales_percentage_range min=min max=max;
run;
/*join range data with comparison data and a 'in range' boolean*/
proc sql;
 create table comparison_&magazine as select comparison_&magazine..*,sales_percentage_range.min as range_min,sales_percentage_range.max as range_max,
  case when sales_percentage_range.min<= new_log_perc_oos and new_log_perc_oos <= sales_percentage_range.max then 1 else 0 end as new_log_perc_oos_in_range
 from comparison_&magazine,sales_percentage_range
 where comparison_&magazine..media_product = sales_percentage_range.media_product;
 quit;
run;

/*summary info on delta_prediction*/
proc sort data=comparison_&magazine;
 by key new_log_perc_oos_in_range;
run;
proc summary data=comparison_&magazine print;
 title "summary for comparison between model prediction and provideor prediction for &magazine";
 title2 "E(model.prediction-provideor.prediction)";
 var delta_prediction;
 by key new_log_perc_oos_in_range;
run;
title;

%mend;



%run_reg(hjemmet);
%run_reg(tara);
%run_reg(seoghor);



