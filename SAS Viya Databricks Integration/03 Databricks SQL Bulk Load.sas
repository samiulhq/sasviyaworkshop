/* Note : variable value in quotes generate errors, So keep it without quotes. */
%let MYDBRICKS=<databricks server address>;
%let MYPWD=<databricks personal access token>;
%let MYHTTPPATH=<http path>;

%let MYDRIVERCLASS="cdata.jdbc.databricks.DatabricksDriver";
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
  bulkload=yes /*note bulkload option*/
  character_multiplier=1
  dbmax_text=50
 	 
  BL_APPLICATIONID=<azure application id goes here only needed for bulk load >
  bl_accountname="&MYSTRGACC"
  bl_filesystem="&MYFS"
  bl_folder="&MYBLFLDR"
  BL_DELETE_DATAFILE=NO
  properties="Catalog=&MYCATALOG;Other=ConnectRetryWaitTime=20;DefaultColumnSize=1024;"
;
options casdatalimit=ALL;

/*move data to databricks using sql COPY INTO */
data cdtspark.RWE_MEMBER;
set D800K.RWE_MEMBER;
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
