/* Note : variable value in quotes generate errors, So keep it without quotes. */
%let MYDBRICKS=<databricks server address>;
%let MYPWD=<databricks personal access token>;
%let MYHTTPPATH=<http path>;

%let MYDRIVERCLASS="cdata.jdbc.databricks.DatabricksDriver" /*("com.simba.databricks.jdbc.Driver" for newer version of Viya)*/;
%let MYCATALOG=hive_metastore;
%let MYSCHEMA=default;
%let MYUID=token;


%let MYSTRGACC=<storage account name if using bulkload>;
%let MYFS=bulkload;
%let MYBLFLDR=db_bulkload;
%let MYTNTID=<tenant id for storage account if using bulkload>;

options sastrace=',,,d' sastraceloc=saslog;
options azuretenantid="&MYTNTID";


libname CdtSpark spark platform=databricks
  driverClass=&MYDRIVERCLASS
  server="&MYDBRICKS"
  database="&MYSCHEMA"
  httpPath="&MYHTTPPATH"
  port=443
  user="&MYUID"
  password="&MYPWD"
  bulkload=yes /*no*/
  character_multiplier=1
  dbmax_text=50
 
  BL_APPLICATIONID="<application id for bulkload from azure>"
  bl_accountname="&MYSTRGACC"
  bl_filesystem="&MYFS"
  bl_folder="&MYBLFLDR"
  BL_DELETE_DATAFILE=NO

  properties="Catalog=&MYCATALOG;Other=ConnectRetryWaitTime=20;DefaultColumnSize=1024;"
;

/* observe the logs and explain the difference between 2 data step statements*/

data test1;
set CDTSPARK.MENTAL_HEALTH(where=(age>23));
run;

data test2(where=(age>23));
set CDTSPARK.MENTAL_HEALTH;
run;


data test3;
set CDTSPARK.MENTAL_HEALTH(where=(age>23) keep=id gender age);
run;

/*observe the log to understand how implicit sql passthrough works*/
proc freq data=cdtspark.MENTAL_HEALTH;
table gad3 gad4;
run;



/*let us connect to a different schema*/

%let MYCATALOG=samples;
%let MYSCHEMA=nyctaxi;
%let MYUID=token;



libname dbsample spark platform=databricks
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

