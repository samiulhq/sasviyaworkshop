/*redshift connection*/ 
libname R1 redshift
server='example.redshift.com'
port=5439
authdomain="RedShift" /*use username and password if you do not have authdomain*/
schema='public'
database=dev;

/* libref to disk to save table*/
libname mylib '/nfsshare/sashls2/data/Redshift';


/*this is implicit sql query SAS translates and send sql command to REDSHIFT*/
proc sql;
	create table mylib.test1 as select * from R1.test_table;
run;

/*this is explicit SQL query (preferred) */

proc sql;
	connect using R1;
	create table mylib.test2 as select * from connection to R1
	(select * from test_table); /*explicit SQL using REDSHIFT's SQL */
	disconnect from R1;
quit;

/*Explicit SQL Passthrough casting Character column length this will speed 
up data pull for long character columns. Notice how the variables are assigned new character lengths*/
/*we have not used mylib. in proc sql, so table will be saved in work library*/

proc sql;
	connect using R1;
	create table test3 as select * from connection to R1
	(select cast(firstname as char(10)) as fristname, cast(lastname as char(15)) 
		as firstname, active from test_table);
	disconnect from R1;
quit;

/*If you want to load data into CAS*/ 

cas;
caslib _ALL_ assign;


/*the following code drops a existing table from caslib*/ 
/*drop a global scope table if exsist*/ 

proc casutil;
droptable casdata='test3' incaslib='casuser' quiet;
run;

data casuser.test3(promote=yes);
set test3;
run;

/*save in caslib path */

proc casutil;
save casdata='test3' casout='test3.sashdat'  incaslib='casuser' outcaslib='casuser' replace;/*save as sashdat*/
save casdata='test3' casout='test3.parquet'  incaslib='casuser' outcaslib='casuser' replace;/*save as parquet*/
run;



/*can I pull data directly to CASLIB? Yes but beaware of memory limit*/ 

caslib RED
dataSource=(srctype='redshift'
server='example.redsfhit.com'
authdomain='RedShift'
database="dev"
schema="public");

caslib _ALL_ assign;

/*explicit sql passthrough using proc fedsql*/

proc fedsql sessref=CASAUTO;
create table casuser.fsql_test as select * from connection to RED
(select cast(firstname as char(10)) as fristname, cast(lastname as char(15)) 
		as firstname, active from test_table);
quit;

/*another way to submit fedsql query through proc cas*/ 

proc cas;
 fedSql.execDirect query='                                  
  create table casuser.fsql_test_2 as select * from connection to RED                      
  ( select cast(firstname as char(10)) as fristname, cast(lastname as char(15)) 
		as firstname, active from test_table)';
quit;

