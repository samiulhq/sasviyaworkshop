/* Note : variable value in quotes generate errors, So keep it without quotes. */
%let MYDBRICKS=<databricks server address>;
%let MYPWD=<databricks personal access token>;
%let MYHTTPPATH=< http path>;


%let MYDRIVERCLASS="cdata.jdbc.databricks.DatabricksDriver";
%let MYCATALOG=hive_metastore;
%let MYSCHEMA=default;
%let MYUID=token;


options sastrace=',,,d' sastraceloc=saslog;



libname CdtSpark spark platform=databricks
  driverClass=&MYDRIVERCLASS
  server="&MYDBRICKS"
  database="&MYSCHEMA"
  httpPath="&MYHTTPPATH"
  port=443
  user="&MYUID"
  password="&MYPWD"
  bulkload=no
  character_multiplier=1
  dbmax_text=50 
  properties="Catalog=&MYCATALOG;Other=ConnectRetryWaitTime=20;DefaultColumnSize=1024;"
;

/*move data to databricks using sql INSERT (not bulkload)*/
data cdtspark.test_insert;
set sashelp.prdsal2;
run;

/*implicit sql pass through */

Proc SQL;
create table test as select * from CdtSpark.class ;
run;quit;

/*explicit sql passthrough*/
proc sql;
connect using cdtspark;
create table test as select * 
	from connection to cdtspark
    	 (select *       from class where age > 12);

run;
quit;
