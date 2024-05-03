/**********************************************************************************
File name:            redshift_data_pull.sas


File type:            macro function and test file

Purpose:              pull data from UDP (snowflake) with dynamic casting

Inputs:               tablename - REDSHIFT table name (source table for data pull) Required
                      schemaname - REDSHIFT schemaname (Case Sensitive) Optional
                      database - Name of database Optional					 	
					  username - username
					  password - Database password
					  authdomainname - Name of the authetnication domain (if set up)
					  where - where cluase passed to REDSHIFT
					  limit - limit number of observation pulled from REDSHIFT

Outputs:              outlib - Ouput SAS library name (Compute Library default is WORK)
                      outtable - output sas table name


Last Updated by: 

	03May2024, Samiul Haque, update:
	- added new macro arguments username, password, where, and limit
	01May2024, Samiul Haque, Initial Release 

	
**********************************************************************************/



%macro redshift_data_pull(servername=,
authdomainname=,
username=,
password=,
tablename=redshiftoutput,
schemaname=,
database=,
outlib=work,
outtable=,
where=,
limit=);




cas thissession;
caslib _ALL_ assign;



%if %sysfunc(clibexist(thissession,rslib)) %then %do;
  caslib rslib drop;
%end;


%put %length(&authdomainname.);

%if %length(&authdomainname.) %then %do;

libname RS_MCR redshift
server="&servername."
port=5439
authdomain="&authdomainname."
schema="&schemaname." /*case sensitive*/
database="&database."
/*         dbcommit = 0 */
;


caslib rslib desc='REDSHIFT Caslib' 
     dataSource=(srctype="redshift"  
				 server="&servername."               
                 schema="&schemaname."
                 AUTHDOMAIN="&authdomainname"                 
                 DATABASE="&database.");

%end ;

%else %do;

libname RS_MCR redshift
server="&servername."
port=5439
user="&username."
password="&password."
schema="&schemaname." /*case sensitive*/
 password="&password" 
database="&database."
/*         dbcommit = 0 */
;


caslib rslib desc='REDSHIFT Caslib' 
     dataSource=(srctype="redshift"  
				 server="&servername."               
                 schema="&schemaname."
                 username="&username"
				 password="&password"                 
                 DATABASE="&database.");
%end;




%let max_num_of_columns = 1000;/*Maximum number of columns to expect in a table */

proc sql;
create table casuser.rshiftcolnames as
select name,type
from dictionary.columns
where libname = 'RS_MCR' and
memname="&tablename." ;
quit;



proc cas;
	myquery='select ';
	table.fetch result =r/table={name='rshiftcolnames', caslib='casuser'}  to=&max_num_of_columns.; 
	describe r.Fetch; 

  do row over r.Fetch; 
	if row.type ='char' then do;
      myquery= myquery || 'max(length(' || strip(row.name) ||')) as ' || strip(row.name) ||', ';
    end;
	end;
	myquery=substr(myquery, 1, length(myquery)-1);


	myquery=myquery || ' from ' || "&tablename.";	

	myquery=' create table casuser.collengths as ( select * from connection to rslib  ( '|| myquery ||' ))';
	print myquery;
	 fedSql.execDirect result=r2 / query=myquery;
run;


proc cas;
	table.fetch result=mxlen/table={name='collengths', caslib='casuser'} to=&max_num_of_columns.;
	myquery='select ';
	table.fetch result=r/table={name='rshiftcolnames', caslib='casuser'} to=&max_num_of_columns.;

	do row over r.Fetch;
		
	if row.type='char' then do;
		columnlength=mxlen.Fetch[1, strip(row.name)];

		if columnlength=. then
			do;
				columnlength=1;
			end;
		myquery=myquery || 'cast( ' || strip(row.name) 
			||' as char('|| columnlength 
|| ')) as ' || strip(row.name) ||', ';
	end;
	
	else;
	myquery=myquery || strip(row.name) || ', ';
	end;
	
	end;
	myquery=substr(myquery, 1, length(myquery)-1);
	myquery=myquery || ' from ' || "&tablename.";
	

	%if %length(&where.) %then %do;
		myquery= myquery || " where &where. ";
	%end;

	%if %length(&limit.) %then %do;
		myquery= myquery || " limit " ||"&limit.";
	%end;

	print myquery;
	symput('QUERY',myquery);		
run;

%put &=QUERY;

proc sql;
connect using RS_MCR;
create table &outlib..&outtable. as select * from connection to RS_MCR
(&QUERY.);
quit;

cas thissession terminate;

%mend redshift_data_pull;



/*sample usage of the macro*/
%let tablename=TEST_SAMIUL;/*table name in UDP*/
%let schemaname=public;/*schema name case sensitive*/
%let database=dev; /*database name*/
/* %let outlib=work; /*output library */
%let outtable=test2;/*output sas table name*/
%let servername=jaskal-redshift-cluster.cjy1oxmlfiyz.us-east-1.redshift.amazonaws.com;
%let authdomainname=RedShift;
ods trace on;
options MPRINT SYMBOLGEN MPRINTNEST ;

%redshift_data_pull(servername=&servername.,
authdomainname=&authdomainname., 
tablename=&tablename.,
schemaname=&schemaname.,
database=&database.,
outtable=&outtable.,
where= firstname='Mary');



