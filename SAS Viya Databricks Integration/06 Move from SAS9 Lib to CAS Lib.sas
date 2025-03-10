%let MYDBRICKS=<databricks server address>;
%let MYPWD=<databricks personal access token>;
%let MYHTTPPATH=<http path>;

%let MYDRIVERCLASS=cdata.jdbc.databricks.DatabricksDriver;
%let MYCATALOG=hive_metastore;
%let MYSCHEMA=default;
%let MYUID=token;


options sastrace=',,,d' sastraceloc=saslog;


libname CdtSpark spark platform=databricks
  driverClass="&MYDRIVERCLASS"
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
