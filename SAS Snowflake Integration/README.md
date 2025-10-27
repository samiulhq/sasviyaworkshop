# SAS ↔ Snowflake Connectivity Workshop

This workshop demonstrates how to connect SAS to Snowflake using:
- **LIBNAME engine for Snowflake**
- **Implicit SQL vs DATA Step**
- **Bulk Load into Snowflake**
- **Explicit SQL Passthrough**
- **CAS (Cloud Analytics Services) Integration with Snowflake**

---


## 1. Basic LIBNAME Connection to Snowflake

Use the `snow` engine to connect SAS to Snowflake.

```sas
/* basic Connection */
libname hlsbrnz snow authdomain='hlsSnowflake'
  DATABASE=HLS_DB
  SCHEMA=HLS_BRONZE
  PORT=443
  SERVER="sas-sandbox.snowflakecomputing.com"
  WAREHOUSE=HLS_WH
  role=hls_developer
  dbcommit=10000 autocommit=no
  readbuff=200 insertbuff=200
  PRESERVE_TAB_NAMES=YES
  SCANSTRINGCOLUMNS=YES;
```
## 2. Writing Data from SAS to Snowflake
```sas
options SASTRACE=',,,d';  /* Turns on SQL trace for debugging */

data hlsbrnz.class;
  set sashelp.class;
run;

data hlsbrnz.ADAE;
  set ADAM.ADAE;
run;
```

## 3. Implicit SQL Pushdown Example
```sas
/* WHERE in DATA step */
data adae_filtered1 (where = (age>63));
  set hlsbrnz.ADAE;
run;

/* WHERE pushed to Snowflake */
data adae_filtered2;
  set hlsbrnz.ADAE(where = (age>63));
run;
```

## 4. Query with PROC SQL
These examples demonstrate how WHERE clause filtering can be pushed to Snowflake.

```sas
proc sql;
  select * from hlsbrnz.class where Age>14;
quit;

/* Drop a table in Snowflake via SAS */
proc sql;
  drop table hlsbrnz.class;
quit;
```

## 5. Bulk Load into Snowflake
Using **`BULKLOAD=YES`** significantly accelerates large table writes.

```sas
libname hlsblk snow authdomain='hlsSnowflake'
  DATABASE=HLS_DB
  SCHEMA=HLS_BRONZE
  PORT=443
  SERVER="sas-sandbox.snowflakecomputing.com"
  WAREHOUSE=HLS_WH
  role=hls_developer
  dbcommit=10000 autocommit=no
  readbuff=200 insertbuff=200
  BULKLOAD=YES
  bl_internal_stage="@~/test1/"
  PRESERVE_TAB_NAMES=YES;

data hlsbrnz.prdsale_serial;
  set sashelp.prdsale;
run;

data hlsblk.prdsale_blk;
  set sashelp.prdsale;
run;
```
## 6. Explicit SQL Passthrough
Use explicit SQL when you want full control using native Snowflake SQL syntax.

```sas
/* Explicit SQL Passthrough */
proc sql;
  connect using hlsbrnz;
  execute (drop table IF EXISTS prdsale_serial) by hlsbrnz;
  execute (drop table IF EXISTS prdsale_blk) by hlsbrnz;
  execute (drop table IF EXISTS prdsale3_serial3) by hlsbrnz;
  execute (drop table IF EXISTS prdsale3_blk) by hlsbrnz;
  disconnect from hlsbrnz;
quit;

proc sql;
  connect using hlsbrnz;
  create table ADAE_test as
    select * from connection to hlsbrnz
      (select STUDYID, SITEID, USUBJID, AGE, RACE, SEX
       from ADAE
       where AGE > 70);
  disconnect from hlsbrnz;
quit;
```
## 7. Cloud Analytics Services (CAS) Connection to Snowflake
This section demonstrates how to connect from SAS Viya CAS to Snowflake for distributed processing.

```sas
/* Start CAS Session */
CAS mySession SESSOPTS=(CASLIB=casuser TIMEOUT=99 LOCALE="en_US" metrics=true);

/* Define connection parameters */
%let MYAUTHDOMAIN=hlsSnowflake;
%let MYSCHEMA=HLS_BRONZE;
%let MYSERVER="sas-sandbox.snowflakecomputing.com";
%let MYWAREHOUSE=HLS_WH;
%let MYDB=HLS_DB;

/* Create Snowflake CASLIB */
caslib snowlib desc='Snowflake Caslib'
     dataSource=(srctype='snowflake',
         authdomain="&MYAUTHDOMAIN.",
         server=&MYSERVER,
         database=&MYDB,
         schema=&MYSCHEMA,
         warehouse=&MYWAREHOUSE);
```
### List Snowflake Tables (not loaded to CAS)
```sas
proc casutil incaslib=snowlib;
    list files;
run;
```
### Save CAS table to Snowflake
```sas
proc casutil incaslib="snowlib" outcaslib="snowlib";
  load data=sashelp.cars casout="cars" replace;
  save casdata="cars" casout="cars_cas" replace;
  list files;
quit;
```
### Load Snowflake table into CAS
```sas
proc casutil incaslib="snowlib" outcaslib="snowlib";
  load casdata="AE_DM" casout="AE_DM" replace;
  list tables;
quit;

caslib _ALL_ assign;
cas mySession terminate;
```

## 

## 6. Explicit SQL Passthrough
