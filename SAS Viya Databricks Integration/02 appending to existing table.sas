/*create a test table*/

data test;
id=1;
name='A';
run;

data CDTSPARK.aptbl;
set test;
run;	

/*append new data to the table in Databricks*/

data test;
id=2;
name='B';
run;


proc append base=CDTSPARK.aptbl data=WORK.test;
run;

/*delete the table */

proc sql; 
  drop table cdtspark.aptbl;
quit;