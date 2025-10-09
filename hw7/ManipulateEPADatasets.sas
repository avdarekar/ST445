*
Programmed by: Ayesha Darekar
Course and section: ST 445 Section 1
Programmed on: 11/3/21
Programmed to: reading in and manipulating data sets from EPA  

Modified by: Ayesha Darekar
Modified on: 11/10/21 
Modified to: continued to work and finish assignment 
;

*use relative paths to create libraries and filerefs;
x 'cd L:/st445/Data'; 
libname InputDS '.';
filename RawData '.'; 

x 'cd L:/st445/Results';
libname Results '.';

x 'cd S:/';
libname HW7 '.'; 

*create macro variable; 
%let CompOpts = outbase
                noprint
                outcompare
                outdif
                outnoequal
                method = absolute
                criterion = 1e-9;

*read in EPA Data.csv and do data cleaning;
data HW7.EPAData(drop = _:);
  infile RawData("EPA Data.csv") 
         firstobs = 7
         dlm = ',';
  input siteid 
        aqscode 
        poc 
        / _date $
        / _max $ 
        / _aqi $ 
        / _count $;
  
  date = intnx('day', '31DEC2018'd, input(compress(_date, , 'a'), 3.));
  aqs = input(compress(_max, , 'a'), 4.0); 
  aqi = input(compress(_aqi, , 'a'), 1.); 
  count = input(compress(_count, , 'a'), 2.); 
run;

*read in EPA Data (1).csv; 
data HW7.EPAData1; 
  infile RawData("EPA Data (1).csv")
         firstobs = 2
         dlm = ',';
  input date : mmddyy8. siteid poc aqs aqi count aqscode;      
run;

*read in EPA Data (2).csv; 
data HW7.EPAData2; 
  infile RawData("EPA Data (2).csv")
         firstobs = 6
         dsd;
  input siteid aqscode poc @; 

  do i = 1 to 244;
    input aqs aqi count @; 
    day = i;
    date = intnx('day', '31DEC2018'd, i);
    output;
  end; 

  drop i; 
run;

*transpose pm10 dataset;
proc transpose data = InputDS.pm10
               name = _day
               out = HW7.pm10(rename = (mean = aqs)); 
  by siteid aqscode poc;
  var day1-day140 day145-day247 day250-day273 day141-day144;
  id metric;
run;

*concatenate concentration datasets;
data HW7.concat;
  set HW7.epadata2 HW7.epadata HW7.epadata1 HW7.pm10(in = inpm10);

  stCode = input(substr(put(siteid, 9.), 1, 2), 2.);
  CountyCode = input(substr(put(siteid, 9.), 3, 3), 3.);
  sitenum = input(substr(put(siteid, 9.), 8), 2.);

  where aqs ne . and count ne . and aqi ne .;
  if inpm10 then date = intnx('day', '31DEC2018'd, input(compress(_day, , 'a'), 3.));
run;

*sort data sets; 
proc sort data = InputDS.aqssites
          out = hw7.aqssites_sort;
  by stcode countycode sitenum;  
run;

proc sort data = hw7.concat
          out = hw7.concat_sort;
  by stcode countycode sitenum; 
run;

*merge concat_sort with aqssites_sort dataset;
data HW7.merge_aqs; 
  merge hw7.concat_sort(in = inC) hw7.aqssites_sort;
  by stcode countycode sitenum; 

  if inC then output; 
run;

*sort data sets; 
proc sort data = InputDS.methods
          out = hw7.methods_sort; 
  by aqscode;
run;

proc sort data = hw7.merge_aqs
          out = hw7.merge_aqs_sort; 
  by aqscode; 
run;

*search for formats; 
options fmtsearch = (InputDS);

*merge merge_aqs_sort with methods_sort; 
data HW7.HW7DarekarFinal(drop = day stcode countycode sitenum cbsaname) 
     HW7.HW7DarekarFinal100(drop = cbsaname); 
  attrib date format = yymmdd10. label = 'Observation Date'
         siteid label = 'Site ID'
         poc label = 'Parameter Occurance Code (Instrument Number within Site and Parameter)'
         aqscode label = 'AQS Parameter Code'
         parameter length = $50 label = 'AQS Parameter Name'
         aqsabb length = $4 label = 'AQS Parameter Abbreviation'
         aqsdesc length = $40 label = 'AQS Measurement Description'
         aqs label = 'AQS Observed Value'
         aqi label = 'Daily Air Quality Index Value' 
         aqidesc label = 'Daily AQI Category'
         count label = 'Daily AQS Observations'
         percent label = 'Percent of AQS Observations (100*Observed/24)'
         mode length = $50 label = 'Measurement Mode' 
         collectdescr length = $50 label = 'Description of Collection Process'
         analysis length = $50 label = 'Analysis Technique'
         mdl label = 'Federal Method Detection Limit'
         localName length = $50 label = 'Site Name' 
         lat label = 'Site Latitude'
         long label = 'Site Longitude'
         stabbrev length = $50 label = 'State Abbreviation'
         countyname length = $50 label = 'County Name' 
         cityname length = $50 label = 'City Name'
         estabdate format = yymmdd10. label = 'Site Established Date'
         closedate format = yymmdd10. label = 'Site Closed Date';

  merge hw7.merge_aqs_sort(in = inMsort) hw7.methods_sort; 
  by aqscode; 
  
  *data cleaning;
  collectdescr = propcase(collectdescr);
  analysis = propcase(analysis);
  
  if parameter = 'Carbon monoxide' then do; 
    aqsabb = 'CO'; 
    aqsdesc = 'Daily Max 8-hour CO Concentration';
  end;
  else if parameter = 'Sulfur dioxide' then do;
    aqsabb = 'SO2'; 
    aqsdesc = 'Daily Max 1-hour SO2 Concentration';
  end;
  else if parameter = 'Ozone' then do;
    aqsabb = 'O3'; 
    aqsdesc = 'Daily Max 8-hour Ozone Concentration';
  end;
  else if parameter = 'PM10 Total 0-10um STP' then do;
    aqsabb = 'PM10'; 
    aqsdesc = 'Daily Mean PM10 Concentration';
  end;

  aqidesc = put(aqi, aqicat.);
  
  if not missing(count) then percent = round((100*count)/24);

  cityname = scan(cbsaname, 1, ',');
  stabbrev = compbl(scan(cbsaname, 2, ','));

  if inMsort and percent = 100 then output HW7.HW7DarekarFinal100;
  if inMsort then output HW7.HW7DarekarFinal;
run;

*output proc contents and turn off listing destination;
ods listing close; 
ods output position = HW7.hw7darekardesc(drop = member); 
proc contents data = HW7.hw7darekarfinal varnum; 
run;

*compare descriptor portions;
proc compare base = Results.hw7dugginsdesc 
             compare = HW7.hw7darekardesc
             out = HW7.diffa
             &CompOpts;
run;

*compare content portions; 
proc compare base = Results.hw7dugginsfinal
             compare = HW7.hw7darekarfinal
             out = HW7.diffb
             &CompOpts;
run;

quit;

