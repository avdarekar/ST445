/* cap input rows for the captured run */
options obs=100;

/* The original script reads Cities.txt / States.txt / Contract.txt /
   Mortgaged.txt via RawData(...) infile, plus InputDS.freeclear and
   InputDS.renters (pre-built SAS datasets), and compares its final
   output against Results.hw6dugginsipums2005 / Results.hw6dugginsdesc
   (an instructor answer key never distributed to students). None of
   this raw data is in the repo -- the .gitignore excludes
   *.txt/*.csv/*.sas7bdat as course-proprietary. This autoexec builds
   small mock versions of the six source tables the script reads,
   matching their columns/types/delimiters exactly. */

/* NOTE: the original script uses the documented SAS aggregate-storage
   INFILE syntax: a FILENAME statement pointing at a directory, then
   INFILE fileref(member-name) to read one member file from it. Per
   the SAS 9.4 INFILE statement documentation, fileref(file) specifies
   a fileref of an aggregate storage location and the name of a file
   or member that resides in that location. Jenner currently reads 0
   rows through that member-name form (filed as a regression test
   upstream, internal tracker only). Worked around here with one flat
   fileref per member file so this bundle demonstrates the rest of the
   script logic; the INFILE statements in script.sas are adjusted to
   match (see the in-script note) -- everything after the INFILE
   targets (informats, delimiters, firstobs, missover) is unmodified. */
filename Cities "%sysfunc(pathname(work))/Cities.txt";
filename States "%sysfunc(pathname(work))/States.txt";
filename Contract "%sysfunc(pathname(work))/Contract.txt";
filename Mortgaged "%sysfunc(pathname(work))/Mortgaged.txt";
libname InputDS "%sysfunc(pathname(work))";
libname Results "%sysfunc(pathname(work))";
libname HW6 "%sysfunc(pathname(work))";

/* Cities.txt: tab-delimited, header row, firstobs=2: city / citypop */
data _null_;
  file "%sysfunc(pathname(work))/Cities.txt" dlm='09'x;
  put "City" '09'x "Population";
  put "Raleigh" '09'x "4635";
  put "Charlotte" '09'x "8746";
  put "Durham" '09'x "2789";
  put "Columbia" '09'x "1336";
  put "Greenville" '09'x "703";
  put "Charleston" '09'x "1503";
run;

/* States.txt: tab-delimited, dsd, header row, firstobs=2:
   serial / state $20. / +5 city $40. */
data _null_;
  file "%sysfunc(pathname(work))/States.txt" dlm='09'x dsd;
  put "Serial" '09'x "State" '09'x "City";
  put "1001" '09'x "North Carolina     " '09'x "Raleigh";
  put "1002" '09'x "North Carolina     " '09'x "Charlotte";
  put "1003" '09'x "South Carolina     " '09'x "Columbia";
  put "1004" '09'x "South Carolina     " '09'x "Greenville";
  put "1005" '09'x "North Carolina     " '09'x "Durham";
  put "1006" '09'x "South Carolina     " '09'x "Charleston";
run;

/* Contract.txt: tab-delimited, header row, firstobs=2:
   Serial Metro CountyFIPS MortPay(dollar6.) HHI(dollar10.) HomeVal(dollar10.) */
data _null_;
  file "%sysfunc(pathname(work))/Contract.txt" dlm='09'x;
  put "Serial" '09'x "Metro" '09'x "CountyFIPS" '09'x "MortPay" '09'x "HHI" '09'x "HomeVal";
  put "1001" '09'x "2" '09'x "183" '09'x "$1,450" '09'x "$168,000" '09'x "$210,000";
  put "1003" '09'x "2" '09'x "079" '09'x "$1,320" '09'x "$169,900" '09'x "$180,000";
run;

/* Mortgaged.txt: same shape, missover. Serial 1002 (Charlotte, NC) is
   given HHI > $500,000 so the "NC households over $500,000" PROC
   REPORT step later in script.sas has a row to show. */
data _null_;
  file "%sysfunc(pathname(work))/Mortgaged.txt" dlm='09'x;
  put "Serial" '09'x "Metro" '09'x "CountyFIPS" '09'x "MortPay" '09'x "HHI" '09'x "HomeVal";
  put "1002" '09'x "4" '09'x "119" '09'x "$5,610" '09'x "$612,000" '09'x "$1,340,000";
  put "1005" '09'x "4" '09'x "063" '09'x "$1,720" '09'x "$174,800" '09'x "$375,000";
run;

/* InputDS.freeclear: owned outright, no mortgage */
data InputDS.freeclear;
  input Serial Metro CountyFIPS $ MortPay HHI HomeVal;
  datalines;
1004 2 045 0 165500 92000
1006 4 019 0 173200 410000
;
run;

/* InputDS.renters: renter households (FIPS renamed to CountyFIPS downstream) */
data InputDS.renters;
  input Serial Metro FIPS $ MortPay HHI HomeVal;
  datalines;
1007 2 183 0 166500 .
1008 4 119 0 170200 .
;
run;
