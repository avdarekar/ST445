*
Programmed by: Ayesha Darekar
Course and section: ST 445 Section 1
Programmed on: 9/3/2021
Programmed to: create a pdf file on Ipums2005Basic dataset

Modified by: Ayesha Darekar
Modified on: 9/8/2021
Modified to: continued to work and finish assignment

Jenner bundle note: the original OS-shell and libname setup lines (course
network drives) are replaced by the InputDS/HW1 libnames and mock
InputDS.Ipums2005Basic dataset below (the real IPUMS extract is
course-proprietary and excluded from the repo by .gitignore). Everything
from "close all destinations" onward is unmodified from the source
script.
;

libname InputDS "%sysfunc(pathname(work))";
libname HW1 "%sysfunc(pathname(work))";

/* mock InputDS.Ipums2005Basic -- reproduces the columns
   hw1/Ipums2005BasicDataset.sas actually reads: ownership, state,
   metro, city, hh_income, home_value, mortgage_payment, citypop */
data InputDS.Ipums2005Basic;
  length ownership 8 state $20 metro 8 city $40;
  input ownership state & $20. metro city $40. hh_income home_value mortgage_payment citypop;
  datalines;
1 North Carolina        2 Raleigh                                 168000 210000 1450 4635
1 North Carolina        4 Charlotte                                171000 340000 1610 8746
2 North Carolina        2 Raleigh                                 166500 95500 890 4635
1 South Carolina        2 Columbia                                169900 180000 1320 1336
2 South Carolina        4 Charleston                               173200 410000 1980 1503
1 South Carolina        2 Greenville                               165500 92000 780 703
1 North Carolina        4 Durham                                   174800 375000 1720 2789
2 South Carolina        2 Columbia                                167000 150000 1050 1336
1 North Carolina        2 Raleigh                                 172500 265000 1580 4635
2 North Carolina        4 Charlotte                                170200 990000 2450 8746
1 South Carolina        4 Charleston                               165000 88000 700 1503
2 South Carolina        2 Greenville                               174000 305000 1690 703
1 North Carolina        2 Durham                                   168800 240000 1390 2789
2 North Carolina        4 Charlotte                                173900 60000 610 8746
1 South Carolina        4 Columbia                                166200 155000 1120 1336
;
run;

*close all destinations and create pdf destination;
ods _all_ close;
ods pdf file = 'HW1 Darekar IPUMS Report.pdf' style = plateau;

*get rid of date and proc titles on pdf;
options nodate;
ods noproctitle;

*output proc contents except for enginehost to pdf;
title 'Descriptor Information Before Sorting';
ods exclude enginehost;
proc contents data = InputDS.Ipums2005Basic varnum;
run;
title;

*sort dataset by ownership, state, metro and city;
proc sort data = InputDS.Ipums2005Basic
          out = HW1.Ipums2005sort;
  by descending ownership state metro city;
run;

*output proc contents (again, exclude enginehost);
title 'Descriptor Information After Sorting';
ods exclude enginehost;
proc contents data = HW1.Ipums2005sort varnum;
run;
title;

*create formats for home_value and city;
proc format;
  value homeval(fuzz = 0) low - 95000 = 'Tier 1'
                          95000 <- 162500 = 'Tier 2'
                          162500 <- 350000 = 'Tier 3'
                          350000 <- 1000000 = 'Tier 4'
                          9999999 = 'NA';

  value $cityval           'Not in identifiable city (or size group)' = 'N/A';
run;

*title and footnotes;
title 'Listing of Payments, Income, and Home Value';
title2 height = 8pt 'Including Ownership and State within Ownership Totals';
footnote1 j = left 'Only for North and South Carolina';
footnote2 j = left 'Only for Metro values of 2 and 4';
footnote3 j = left 'Only for households with income between $165,000 and $175,000 (inclusive)';
footnote4 j = left 'Tier 1 = Up to $95,000, Tier 2 = Up to $162,500, Tier 3 = Up to $350,000, Tier 4 = Up to $1,000,000,';
footnote5 j = left 'NA = $9,999,999';

*output data to pdf;
proc print data = HW1.Ipums2005sort label;
  *group by ownership, state, metro, and city and create separate pages for unique metro values;
  by descending ownership state metro city;
  pageby metro;

  *show hh_income and mortgage_payment subtotals for state variable;
  sumby state;
  sum hh_income mortgage_payment;

  *select variables to print and select variables to print at the beginning of each row;
  var hh_income home_value mortgage_payment;
  id ownership state metro city;

  *subset data;
  where (state = 'North Carolina' or state = 'South Carolina')
        and (metro = 2 or metro = 4)
        and (hh_income >= 165000 and hh_income <=175000);

  *add appropriate formats to variables;
  format home_value homeval. city $cityval17. hh_income dollar11. mortgage_payment dollar8.;

  *labels for variables;
  label ownership = 'Ownership Category'
        state = 'State Name'
        metro = 'Metro Code'
        city = 'City Name'
        hh_income = "Household's Income"
        home_value = 'Home Value'
        mortgage_payment = 'Mortgage Payment';
run;
title;
footnote;

*titles and footnotes;
title 'Selected Numerical Summaries of US Census IPUMS Data';
title2 height = 8pt 'by Ownership and Home Value Classification';
footnote j = left 'Excluding Alaska and Hawaii';
footnote2 j = left 'Tier 1 = Up to $95,000, Tier 2 = Up to $162,500, Tier 3 = Up to $350,000, Tier 4 = Up to $1,000,000,';
footnote3 j = left 'NA = $9,999,999';

*print statistics for some numerical variables;
proc means data = HW1.Ipums2005sort n min q1 median q3 max nonobs;
  *subset data and select variables;
  where state ne 'Alaska' and state ne 'Hawaii';
  var hh_income mortgage_payment;

  *apply format to home_value and group by ownership and home_value;
  format home_value homeval.;
  class ownership home_value;

  *labels for variables;
  label ownership = 'Ownership Category'
        hh_income = "Household's Income"
        home_value = 'Home Value'
        mortgage_payment = 'Mortgage Payment';
run;
title;

*print frequencies of variables;
title 'Total Population by Ownership and Ownership by Metro';
title2 'and Ownership by Home Value Classification';
proc freq data = HW1.Ipums2005sort;
  *subset data, weight frequencies by citypop, and apply formats;
  where state ne 'Alaska' and state ne 'Hawaii';
  weight citypop;
  format home_value homeval.;

  *create three tables;
  table ownership;
  table ownership*metro / format = comma13.;
  table ownership*home_value / nocol norow format = comma13.;

  *labes for variables;
  label ownership = 'Ownership Category'
        home_value = 'Home Value'
        metro = 'Metro Code';
run;
title;
footnote;

*close pdf destination and reopen listing destination;
ods pdf close;
ods listing;

quit;
