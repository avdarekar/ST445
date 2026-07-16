/* cap input rows for the captured run */
options obs=100;

/* The original script reads "EPA Data.csv", "EPA Data (1).csv" and
   "EPA Data (2).csv" (fixed-layout course extracts) via RawData(...),
   plus InputDS.pm10 / InputDS.aqssites / InputDS.methods (pre-built
   SAS datasets) and an InputDS format catalog member AQICAT, and
   compares its final output against Results.hw7dugginsdesc /
   Results.hw7dugginsfinal (an instructor answer key never distributed
   to students). None of this is in the repo -- the .gitignore
   excludes *.csv/*.txt/*.sas7bdat as course-proprietary. This
   autoexec builds small mock versions of everything the script reads,
   matching columns/informats/delimiters exactly. The PROC TRANSPOSE
   VAR range is shrunk from the original's day1-day140/day145-day247/
   day250-day273/day141-day144 (247 columns) to day1-day5 (5 columns)
   -- same mechanics, fewer of the same-shaped columns, since the
   original width is an artifact of a specific unavailable dataset
   rather than something the assignment logic depends on. script.sas
   is adjusted to match (see the in-script note). */

/* NOTE: like t002, the original script uses the documented SAS
   aggregate-storage INFILE syntax (filename RawData at a directory;
   infile RawData(member-name)). Jenner currently reads 0 rows through
   that member-name form (same regression test as t002, filed upstream
   -- internal tracker only). Worked around here with one flat fileref
   per member file; script.sas's INFILE targets are adjusted to match
   (see the in-script note). */
filename EPAcsv0 "%sysfunc(pathname(work))/EPA Data.csv";
filename EPAcsv1 "%sysfunc(pathname(work))/EPA Data (1).csv";
filename EPAcsv2 "%sysfunc(pathname(work))/EPA Data (2).csv";
libname InputDS "%sysfunc(pathname(work))";
libname Results "%sysfunc(pathname(work))";
libname HW7 "%sysfunc(pathname(work))";

/* AQICAT format: 1-digit AQI code -> category label, used by
   `aqidesc = put(aqi, aqicat.);` in script.sas */
proc format lib = InputDS;
  value aqicat 1 = 'Good'
               2 = 'Moderate'
               3 = 'Unhealthy for Sensitive Groups'
               4 = 'Unhealthy'
               5 = 'Very Unhealthy'
               6 = 'Hazardous';
run;

/* "EPA Data.csv": 6 header/metadata lines then data from firstobs=7,
   comma-delimited, multi-record input (siteid/aqscode/poc on line 1,
   then _date/_max/_aqi/_count each on their own following line). */
data _null_;
  file "%sysfunc(pathname(work))/EPA Data.csv";
  put "Site metadata line 1";
  put "Site metadata line 2";
  put "Site metadata line 3";
  put "Site metadata line 4";
  put "Site metadata line 5";
  put "Site metadata line 6";
  put "371830014,42101,1";
  put "a20190103";
  put "a412";
  put "a2";
  put "a18";
  put "371830014,42401,1";
  put "a20190104";
  put "a3";
  put "a1";
  put "a20";
run;

/* "EPA Data (1).csv": header row, firstobs=2, comma-delimited:
   date(mmddyy8.) siteid poc aqs aqi count aqscode */
data _null_;
  file "%sysfunc(pathname(work))/EPA Data (1).csv";
  put "date,siteid,poc,aqs,aqi,count,aqscode";
  put "01/05/19,371830014,1,415,2,19,42101";
  put "01/06/19,371830014,1,398,2,20,42101";
run;

/* "EPA Data (2).csv": 5 header/metadata lines, firstobs=6, dsd
   comma-delimited: siteid aqscode poc @, then 244 x (aqs aqi count) @ */
data _null_;
  file "%sysfunc(pathname(work))/EPA Data (2).csv";
  put "Metadata line 1";
  put "Metadata line 2";
  put "Metadata line 3";
  put "Metadata line 4";
  put "Metadata line 5";
  length rec $4000;
  rec = "371830014,81102,1";
  do i = 1 to 244;
    rec = catx(',', rec, put(300+i,3.), put(mod(i,6)+1,1.), put(mod(i,24),2.));
  end;
  put rec;
run;

/* InputDS.pm10: siteid/aqscode/poc + day1-day5 (shrunk from the
   original's day1-day140/day145-day247/day250-day273/day141-day144)
   + metric, transposed by PROC TRANSPOSE (id metric; var day1-day5;) */
data InputDS.pm10;
  length metric $4;
  input siteid aqscode poc metric $ day1 day2 day3 day4 day5;
  datalines;
371830014 81102 1 mean 12 14 11 16 13
;
run;

/* InputDS.aqssites: site metadata keyed by stcode/countycode/sitenum,
   plus cbsaname (parsed downstream into cityname/stabbrev) */
data InputDS.aqssites;
  length cbsaname $60;
  input stcode countycode sitenum localName $30. lat long cbsaname $60.;
  datalines;
37 183 14 Mecklenburg Near-Road         35.11 -80.86 Charlotte, NC
;
run;

/* InputDS.methods: measurement-method metadata keyed by aqscode */
data InputDS.methods;
  length parameter $50 mode $50 collectdescr $50 analysis $50;
  input aqscode parameter $30. mode $30. collectdescr $30. analysis $30.
        mdl estabdate : date9. closedate : date9.;
  datalines;
42101 Carbon monoxide               INSTRUMENTAL                   continuous monitor            NDIR PHOTOMETRY               0.1 01JAN2010 .
42401 Sulfur dioxide                INSTRUMENTAL                   continuous monitor            PULSED FLUORESCENT            0.2 01JAN2010 .
81102 PM10 Total 0-10um STP         INSTRUMENTAL                   continuous monitor            BETA ATTENUATION              1.0 01JAN2010 .
;
run;
