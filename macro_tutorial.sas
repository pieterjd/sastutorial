libname pjan 'E:\PROJECTS\SANDBOX\PIETERJAN';
/*Macro program file from http://www.ats.ucla.edu/stat/sas/seminars/sas_macros_introduction/*/
options nodate nonumber nocenter formdlim="-";
data hsb2;
  input  id female race ses prog
         read write math science socst;
datalines;
 70 0 4 1 1 57 52 41 47 57
121 1 4 2 3 68 59 53 63 61
 86 0 4 3 1 44 33 54 58 31
141 0 4 3 3 63 44 47 53 56
172 0 4 2 2 47 52 57 53 61
113 1 4 2 2 44 52 51 63 61
 50 0 3 2 1 50 59 42 53 61
 11 0 1 2 2 34 46 45 39 36
 84 0 4 2 1 63 57 54 51 63
 48 1 3 2 2 57 55 52 50 51
 75 1 4 2 3 60 46 51 53 61
 60 1 4 2 2 57 65 51 63 61
 95 0 4 3 2 73 60 71 61 71
104 0 4 3 2 54 63 57 55 46
 38 0 3 1 2 45 57 50 31 56
115 0 4 1 1 42 49 43 50 56
 76 0 4 3 2 47 52 51 50 56
195 0 4 2 1 57 57 60 56 52
;
run;
/*Some basic shit*/
proc means data = hsb2;
  var write math female socst;
run;
proc reg data = hsb2;
  model read = write math female socst;
run;
/*I don't wanna repeat the same variables, macros to the rescue :)*/
%let indvars = write math female socst;
%put vars are &vars;
/*add title with today's date*/
title "Today is &SYSDATE9, time is definately wrong, &SYSTIME";
proc means data = hsb2;
  var &indvars;
run;
/*clear title*/
title;
%put _automatic_;
run;
/*Let's do some string actions*/
%let newind = %upcase(&indvars);
%put &newind;
%let secondWord = %Scan(&indvars,2);
%put &secondWord;
run;
/*Some math and logic, woehoe!*/
%let k=1;
%let tot = %eval(&k +1);
%put total is &tot;
/*some floating stuff*/
%let btwinc = %sysevalf(1.21*&tot);
%put btw inc is &btwinc;
run;
/*symput and symget*/
/*Passing information between data steps*/
proc means data = hsb2 n;
  var write;
  /*only rows with write variable at least 55*/
  where write>=55;
  output out=w55 n=n;
run;
proc print data = w55;
run;
/*get data from w55 and put it in macro variable n55*/
data _null_;
  set w55;
  call symput('n55', n);
run;
%put &n55 Observations have write >=55;
data hsb2_55;
/*read data from hsb2*/
  set hsb2;
  w55 = symget('n55');/*remember, variables are all strings*/
  w55_bis = symget('n55') + 0;/*by adding zero, string is changed to numeric*/
run;
proc print data = hsb2_55;
  /*strings are left aligned, numericals are right aligned*/	
  var write w55  w55_bis;
run;
/*proc sql, nothing new here*/
proc sql;
 select count(id) as count,female
 from hsb2
 group by female;
quit;
/*let's do some proc-sql shit; same shit as before getting the nr of students with a write score of at least 55 */
proc sql;
  select sum(write>=55) into :w55sql
  from hsb2;
quit;
%put sql w55 is &w55sql;
run;
/*means by sessions*/
proc sql;
  select mean(write) as mean into :mean1 - :mean3
  from hsb2
	group by ses;
quit;
%put means are &mean1, &mean2 and &mean3;
run;
/*creating some macros myself*/
data file1 file2 file3 file4;
  input a @@;
  if _n_ <= 3 then output file1;
  if 3 < _n_<=  6 then output file2;
  if 6 < _n_ <= 9 then output file3;
  if 9 < _n_ <=12 then output file4;
cards;
1 2 3 4 5 6 7 8 9 10 11 12
;
run;
/*first without macros*/
data all;
 set
  file1
  file2
  file3
  file4;
run;
proc print data=all;
%macro combine;
data all_comb;
  set
  %do i=1 %to 4;
	file&i
  %end;	
  ;
  run;
%mend;
/*let's call this shit, turn on macro printing to see the result of the macro call*/
options mprint;
%combine
/*macro with parameters*/
%macro combine2(num);
%let tablename = all_comb&num;
data &tablename;
  set
  %do i=1 %to &num;
	file&i
  %end;	
  ;
  run;
  title "&tablename";
  proc print data=&tablename;
  run;
  title;
%mend;
/*let's call this shit, turn on macro printing to see the result of the macro call*/
options mprint;
%combine2(4);
%combine2(3);
run;
proc print data=allcomb4,allcomb3;
run;
/*logistic model example*/
data xxx;
  input v1-v5 ind1 ind2;
  cards;
1 0 1 1 0 34 23
0 0 1 0 1 22 32
1 1 1 0 0 12 10
0 1 0 1 1 56 90
0 1 0 1 1 26 80
1 1 0 0 0 46 45
0 0 0 1 1 57 53
1 1 0 0 0 22 77
0 1 0 1 1 44 45
1 1 0 0 0 41 72
;
run;
proc logistic data=xxx descending;
 model v1=ind1 ind2;
run;
/*do logistic for each v variable*/
/*turn on options for easier debugging*/
options mlogic mprint;
%macro mylogit(num);
%do i=1 %to &num;
  title "logit for v&i";
  proc logistic data=xxx descending;
   model v&i=ind1 ind2;
  run;
%end;
%mend;
/*run the damn thing*/
%mylogit(3);
run;
/*sam shit, but now argument is list of dependent vars*/
%macro mylogit2(vars);
%let k=1;
%let curvar=%SCAN(&vars,&k);
%do %while ("&curvar" NE "");
  title "logit for curvar &curvar";
  proc logistic data=xxx descending;
   model &curvar=ind1 ind2;
  run;
  %let k=%eval(&k+1);
  %let curvar=%SCAN(&vars,&k);
%end;
%mend;
%mylogit2(v1 v2);
/*we doen ne keer zot, niet in volgorde :)*/
%mylogit2(v2 v5 v1);/*moehaha*/
run;
/*same stufff, now storing results in dataset*/
options  mprint mlogic;
%macro mylogit3(vars,outest);
%let k=1;
%let curvar=%SCAN(&vars,&k);
%do %while ("&curvar" NE "");
  title "logit3 for curvar &curvar";
  proc logistic data=xxx descending outest=_est&k;
   model &curvar=ind1 ind2;
  run;
  %let k=%eval(&k+1);
  %let curvar=%SCAN(&vars,&k);
%end;
/*check if outest parameter is supplied*/
%if "&outest" NE "" %then
%do;
  data &outest;
  set
  %do i=1 %to &k-1;
   _est&i 
  %end;/*do loop*/
  ; 
  run;
  /*clean up temp datasets*/
  %let k = %eval(&k - 1);
  proc datasets;
   delete _est1 - _est&k;
  run;
%end;/*end then part*/
%else %do;/*else part*/
  %put "no dataset provided, estimates not combined.";
%end;/*end else part*/
%mend;
%mylogit3(v1 v2);
/*we doen ne keer zot, niet in volgorde :)*/
%mylogit3(v2 v5 v1,a);/*moehaha*/
run;