/*based on http://www.dms.umontreal.ca/~duchesne/chap12.pdf */
data past;
   keep date sales;
   format date monyy5.;
   lu = 0;
   n = 25;
   do i = -10 to n;
      u = .7 * lu + .2 * rannor(1234);
      lu = u;
      sales = 10 + .10 * i + u;
      date = intnx( 'month', '1jul1991'd, i - n );
      if i > 0 then output;
   end;
run;

proc print data=past;
run;
/*
proc sgplot data=past;
   series x=date y=sales ;
   xaxis values=('1jul89'd to '1jan93'd by qtr);
   refline '15jul91'd / axis=x;
run;
*/
/* forecasting for next 10 months and put everything in the out pred dataset */
proc forecast data=past lead=10 out=pred;
   var sales;
run;

proc print data=pred;
run;
/* interval states what the time is betwen two observations in the data column (id var) */
proc forecast data=past interval=month lead=10 out=pred;
   var sales;
   id date;
run;
/*same as before but with 90% confidence interval*/
proc forecast data=past interval=month lead=10
              out=pred outlimit alpha=0.1;
   var sales;
   id date;
run;

proc print data=pred;
run;
/*not only forecast values, but also forecasted values for past values*/
proc forecast data=past interval=month lead=10
              out=pred outfull;
   id date;
   var sales;
run;
/*plot; _TYPE_ can be actual or forecast */
proc sgplot data=pred;
   series x=date y=sales / group=_type_ lineattrs=(pattern=1);
   xaxis values=('1jan90'd to '1jan93'd by qtr);
   refline '15jul91'd / axis=x;
run;

proc forecast data=past interval=month lead=10
              out=pred outfull outresid;
   id date;
   var sales;
run;

proc sgplot data=pred;
   where _type_='RESIDUAL';
   needle x=date y=sales / markers;
   xaxis values=('1jan89'd to '1oct91'd by qtr);
run;

proc forecast data=past interval=month lead=10
              out=pred outfull outresid
              outest=est outfitstats;
   id date;
   var sales;
run;

proc print data=est;
run;
/*goodness of fit stas with outfitstats option and expo smoothing method*/
proc forecast data=past interval=month lead=10
              method=expo trend=2
              out=pred outfull outresid
              outest=est outfitstats;
   var sales;
   id date;
run;

proc print data=est;
run;
/* generate random noise around constant*/
data for1;
   b0 = 5;
   do time = 1 to 40;
      x = b0 + rannor(54321);
      output;
   end;
run;

proc sgplot data=for1;
   needle x=time y=x / markers markerattrs=(symbol=circlefilled);
run;
/*generate noise around straigth line, ascending with time*/
data for2;
   b0 = 5;
   b1 = 1;
   do time = 1 to 40;
      x = b0 + b1*time + 5*rannor(54321);
      output;
   end;
run;

proc sgplot data=for2;
   needle x=time y=x / markers markerattrs=(symbol=circlefilled);
run;
/*generate data based on previous value*/
data for3;
   xl = 0;
   do time = -10 to 40;
      x  = xl + rannor(54321);
      if time > 0 then output;
      xl = x;
   end;
run;

proc sgplot data=for3;
   /*adds vertical lines to points*/
   needle x=time y=x / markers markerattrs=(symbol=circlefilled);
run;