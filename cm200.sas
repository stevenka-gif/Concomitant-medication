*******************************************************************;
*Program Name       : cm203.sas
*Type               : SDTM
*Description        : producing a previous treatment status count and perce
*Author             : Stephen Kangu
*
*Date created       : 11th nov 2024
*Input datasets     : adcm adsl
**
*******************************************************************;
*
*Change History     :
*Reason for change  :
*Date changed       :
*
*******************************************************************;
*manual setting up library;
libname adam '/home/u62493533/stephenone/mydata/SDTM' access=readonly;

*clear log and output area;
dm 'log;clear;output;clear';
run;quit;

*calculating the big N;
data adsl;
  set adam.adsl;
  output;
  trt01pn=3;
  output;
run;

proc sql;
  select trt01pn , count(distinct(usubjid))
  into: trt1- , :n1-
  from adsl
  where fasfl="Y"
  group by trt01pn;
quit;

%put &trt1. &n1. &trt2. &n2. &trt3. &n3.;

*getting obs for total values to be counted;
data cm1;
  set adam.adcm;
  where fasfl="Y";
  output;
  trt01pn=3;
  output;
run;

*for unique obs;
proc sort data=cm1 out=cmc1 nodupkey;
  by usubjid cmscat trt01pn;
  where cmscat ne "";
run;

*counting treatments against previous treatmenst;
proc freq data=cmc1;
  tables cmscat*trt01pn/out=cmc2(drop=percent);
run;

proc sort data=cmc2 out=cmc3;
  by cmscat;
run;

*transposition of dataset to get treatmentsas columns;
proc transpose data=cmc3 out=cmc4 prefix=_;
  by cmscat ;
  var count;
  id trt01pn;
run;

proc sort data=cm1 out=cmx1 nodupkey;
  by usubjid cmscat cxtrtst trt01pn;
  where cmscat ne "";
run;

*counting treatments against previous treatmenst;

proc freq data=cmx1;
  tables cmscat*cxtrtst*trt01pn/out=cmx2(drop=percent);
run;

proc sort data=cmx2 out=cmx3;
  by cmscat cxtrtst;
run;

*transposition of dataset to get treatmentsas columns;

proc transpose data=cmx3 out=cmx4 prefix=_;
  by cmscat cxtrtst;
  var count;
  id trt01pn;
run;

data com1;
  length col1 col2 col3 col4 $200;
  set cmc4(in=a) cmx4(in=b);*combining the datasets;
  if a then col1=propcase(cmscat);
  else col1="  "||propcase(cxtrtst);
  
  *setting missing values to 0;
  if _1 eq . then _1=0;
  if _2 eq . then _2=0;
  if _3 eq . then _3=0;
  
  *calculating percentages;
  if _1 ne 0 then col2= put(_1,3.0)||' (' ||put(_1/&n3.*100,4.1)||')';
  else if _1 =0 then col2=put(_1,3.0);
  if _2 ne 0 then col3= put(_2,3.0)||' (' ||put(_2/&n2.*100,4.1)||')';
  else if _2 =0 then col3=put(_2,3.0);
  if _3 ne 0 then col4= put(_3,3.0)||' (' ||put(_3/&n1.*100,4.1)||')';
  else if _3 =0 then col4=put(_3,3.0);   
run;

proc sort data=com1 out=com2(keep=col: cmscat);
  by cmscat cxtrtst;
run;

*producing the report;
ods listing close;
ods pdf file="/home/u62493533/stephenone/mydata/cm200.pdf";

title1 "D933IC00003";
title2 "Table 14.1.3.1 Previous disease related treatment modalities (Full analysis set)";

proc report data= com2 headline headskip nowd split="^"
  style(report)={asis=on frame=hsides}
  style(header)={borderbottomcolor=black asis=on just=l};
  columns cmscat col1 ("_Number (%) of subjects_" col2 col3 col4);
  define col1 / "Previous treatment modalities"  style(column)={asis=on cellwidth=39%};
  define col2 / "Durva + Olaparib^(N=&n1.)" style(column)={asis=on cellwidth=20%};
  define col3 / "Durva + Placebo^(N=&n2.)" style(column)={asis=on cellwidth=20%};
  define col4 / "Total^(N=&n3.)" style(column)={asis=on cellwidth=20%};
  define cmscat /   order noprint;
  compute after cmscat;
    line " ";
  endcomp;
run;

ods listing;

%checklog;