*
Programmed by: Ayesha Darekar
Course and section: ST 445 Section 1
Programmed on: 10/20/21
Programmed to: combine multiple datasets and produce a report  

Modified by: Ayesha Darekar
Modified on: 10/25/21 
Modified to: continued to work and finish assignment
;

*associate filerefs and libraries using relative paths;
x 'cd L:\st445\Data';
filename RawData '.';
libname InputDS '.';

x 'cd L:\st445\Results'; 
libname Results '.';

x 'cd S:\'; 
libname HW6 '.'; 

*create macro variable; 
%let CompOpts = outbase
                noprint
                outcompare
                outdif
                outnoequal
                method = absolute
                criterion = 1e-15;

*read in cities.txt; 
data HW6.cities(drop = _:); 
  attrib city length = $40; 
  infile RawData("Cities.txt") 
         dlm = '09'x 
         firstobs = 2; 
  input _city : $40. citypop : comma6.;  
  city = tranwrd(_city, '/', '-');
run;

*read in states.txt; 
data HW6.states; 
  infile RawData("States.txt") 
         dlm = '09'x
         dsd 
         firstobs = 2;
  input serial 
        state $20. 
        +5 city $40.; 
 run;

 *read in contract.txt;
 data HW6.contract; 
  infile RawData("Contract.txt")
         dlm = '09'x
         firstobs = 2;
  input Serial 
        Metro 
        CountyFIPS : $3. 
        MortPay : dollar6. 
        HHI : dollar10. 
        HomeVal : dollar10.;
run;

*read in mortgaged.txt; 
data HW6.mortgaged; 
  infile RawData("Mortgaged.txt")
         dlm = '09'x
         firstobs = 2
         missover; 
  input Serial 
        Metro 
        CountyFIPS : $3. 
        MortPay : dollar6. 
        HHI : dollar10. 
        HomeVal : dollar10.;
run;

*concatenate data sets; 
data HW6.concatenate; 
  set HW6.contract(in = inC) 
      HW6.mortgaged(in = inM) 
      InputDS.freeclear(in = inFC)  
      InputDS.renters(rename = (FIPS = CountyFIPS) in = inR);
  
  if inM = 1 then MortStat = "Yes, mortgaged/ deed of trust or similar debt"; 
    else if inC =1 then MortStat = "Yes, contract to purchase";
    else if inFC = 1 then MortStat = "No, owned free and clear"; 
    else MortStat = "N/A"; 

  if inR = 1 and homeval = 9999999 then homeval = .R;
  if inR = 0 and homeval = . then homeval = .M;

  if inR = 1 then Ownership = 'Rented';
    else Ownership = 'Owned'; 
run; 

*sort data; 
proc sort data = HW6.states
          out = HW6.states_sort; 
  by city; 
run;

proc sort data = HW6.cities
          out = HW6.cities_sort;
  by city; 
run;

*merge data sets; 
data HW6.merge; 
  merge HW6.states_sort HW6.cities_sort; 
  by city; 
run; 

*sort data; 
proc sort data = HW6.merge
          out = hW6.merge_sort;
  by serial; 
run;

proc sort data = HW6.concatenate
          out = hW6.concatenate_sort;
  by serial; 
run;

*create format for metrodesc;
proc format lib = hw6;
  value metrodesc 0 = 'Indeterminable'    
                  1 = 'Not in a Metro Area'
                  2 = 'In Central/Principal City'
                  3 = 'Not in Central/Principal City'
                  4 = 'Central/Principal Indeterminable';
run;

*search for formats in hw6; 
options fmtsearch = (HW6); 

*combine data sets via merge;
data HW6.HW6DarekarIpums2005;
  attrib Serial label = 'Household Serial Number'
         CountyFIPS length = $3 label = 'County FIPS Code'
         Metro label = 'Metro Status Code'
         MetroDesc length = $32 label = 'Metro Status Description'
         CityPop format = comma6. label = 'City Population (in 100s)'
         MortPay format = dollar6. label = 'Monthly Mortgage Payment'
         HHI format = dollar10. label = 'Household Income'
         HomeVal format = dollar10. label = 'Home Value'
         State length = $20 label = 'State, District, or Territory'
         City length = $40 label = 'City Name'
         MortStat length = $45 label = 'Mortgage Status'
         Ownership length = $6 label = 'Ownership Status';
  merge HW6.concatenate_sort(in = inC) HW6.merge_sort(in = inM);
  by serial;
  if inC = 1 and inM = 1;
  metrodesc = put(metro, metrodesc.);
run;

*compare content portion;
proc compare base = Results.hw6dugginsipums2005
             compare = HW6.hw6darekaripums2005
             out = HW6.contentdiffs
             &CompOpts;
run;

*close listing destination;
ods listing close;
 
*output contents; 
ods output position = hw6.hw6darekardesc(drop = member);
proc contents data = hw6.hw6darekaripums2005 varnum;
run;

*compare descriptor portion;
proc compare base = Results.hw6dugginsdesc
             compare = HW6.hw6darekardesc
             out = HW6.descdiffs
             &CompOpts;
run;

*open pdf destination; 
ods pdf file = "HW6 Darekar IPUMS Report.pdf" dpi = 300 startpage = never; 
ods graphics / reset width = 5.5in; 

*set options; 
options nodate; 

*output data;
title 'Listing of Households in NC with Incomes Over $500,000';  
proc report data = HW6.hw6darekaripums2005;
  columns city metro mortstat hhi homeval; 
  where state = 'North Carolina' and hhi > 500000;
run;
title;

*get statistics on data and create citypop distribution graph; 
ods select Univariate.CityPop.BasicMeasures
           Univariate.CityPop.Quantiles
           Univariate.CityPop.Histogram.Histogram
           Univariate.MortPay.Quantiles
           Univariate.HHI.BasicMeasures
           Univariate.HHI.ExtremeObs
           Univariate.HomeVal.BasicMeasures
           Univariate.HomeVal.ExtremeObs
           Univariate.HomeVal.MissingValues;
proc univariate data = HW6.hw6darekaripums2005; 
  var citypop mortpay hhi homeval;
  histogram citypop / kernel(c = 0.79);
run; 

*insert page break;
ods pdf startpage = now;

*create citypop distribution graph; 
title 'Distribution of City Population'; 
title2 '(For Households in a Recognized City)'; 
footnote j = left 'Recognized cities have a non-zero value for City Population'; 
proc sgplot data = HW6.hw6darekaripums2005;
  histogram citypop / scale = proportion;
  where citypop ne 0; 
  density citypop / type = kernel lineattrs=(color = 'red' thickness = 3); 
  keylegend / position = topright location = inside; 
  yaxis display = (nolabel) valuesformat = percent.; 
run;
title;
footnote; 

*create panel graph; 
title 'Distribution of Household Income Stratified by Mortgage Status';
footnote 'Kernel estimate parameters were determined automatically.';
proc sgpanel data = HW6.hw6darekaripums2005 noautolegend;
  panelby mortstat / novarname;
  histogram hhi / scale = proportion;
  density hhi / type = kernel lineattrs=(color = 'red');
  rowaxis display = (nolabel) valuesformat = percent.;
run;
title;
footnote;

*close pdf destination;
ods pdf close;

quit;
 
