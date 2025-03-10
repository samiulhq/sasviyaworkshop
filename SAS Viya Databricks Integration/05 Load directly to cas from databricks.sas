/* note: if your table is too large do not attempt to load everything into CAS
directly*/

%let MYDBRICKS=<databricks server address>;
%let MYPWD=<databricks personal access token>;
%let MYHTTPPATH=<http path>;

%let MYDRIVERCLASS=cdata.jdbc.databricks.DatabricksDriver;
%let MYCATALOG=hive_metastore;
%let MYSCHEMA=default;
%let MYUID=token;


options sastrace=',,,d' sastraceloc=saslog;

caslib DBHLSCAS datasource=(srctype='spark',
              platform=databricks,
              username="&MYUID",
              password="&MYPWD",
              schema="&MYSCHEMA",
              server="&MYDBRICKS",
              httpPath="&MYHTTPPATH",
              driverclass="&MYDRIVERCLASS",
              bulkload=no,
              port=443,
              useSsl=yes,
              charMultiplier=1,
              dbmaxText=50,
              properties="Catalog=&MYCATALOG;DefaultColumnSize=255;Other=ConnectRetryWaitTime=20"
            );

caslib _ALL_ assign;

proc casutil incaslib=DBHLSCAS;
list files;
run;

proc casutil incaslib=DBHLSCAS;
load casdata='air' casout='air' outcaslib=DBHLSCAS;
run;

proc casutil incaslib=DBHLSCAS;
load casdata='class' casout='myclass' outcaslib=CASUSER;
run;

