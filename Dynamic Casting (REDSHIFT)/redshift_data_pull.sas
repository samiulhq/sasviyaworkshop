/**********************************************************************************
File name:            redshift_data_pull.sas

Purpose:              Pull tables from REDSHIFT with dynamic casting

Inputs:               tablename - REDSHIFT table name (source table for data pull) Required
                      schemaname - REDSHIFT schemaname (Case Sensitive) Optional
                      database - Name of database Optional
					  casdatalimit-Override default data limit to move data from CAS to SAS Library (optional) 
								    default is 100MB.	
					  username - Name 	

Outputs:              outlib - Ouput SAS library name
                      outtable - output sas table name


Last Updated by: 

	01May2024, Samiul Haque, Initial Release 
**********************************************************************************/



%macro redshift_data_pull(servername=,
authdomainname=,
tablename=,
schemaname=,
database=,
outlib=,
outtable=,
casdatalimit=100M);


libname RS_MCR redshift
server="&servername."
port=5439
authdomain="&authdomainname."
schema="&schemaname." /*case sensitive*/
database="&database."
/*         dbcommit = 0 */
;


cas thissession;
caslib _ALL_ assign;

%let max_num_of_columns = 1000;/*Maximum number of columns to expect in a table */

proc sql;
create table casuser.rshiftcolnames as
select name,type
from dictionary.columns
where libname = 'RS_MCR' and
memname="&tablename." ;
quit;


%if %sysfunc(clibexist(thissession,rslib)) %then %do;
  caslib rslib drop;
%end;

caslib rslib desc='REDSHIFT Caslib' 
     dataSource=(srctype="redshift"  
				 server="&servername."               
                 schema="&schemaname."
                 AUTHDOMAIN="&authdomainname"                 
                 DATABASE="&database.");


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
	myquery=' create table casuser.dynamic_cast as ( select * from connection to rslib  ( '|| myquery ||' ))';
	print myquery;

		fedSql.execDirect result=r2 / query=myquery;
run;
options casdatalimit=&casdatalimit.;

data &outlib..&outtable.;
set casuser.dynamic_cast;
run;

cas thissession terminate;

%mend redshift_data_pull;


/*sample usage of the macro*/
/*do not use quotation in macro assignment*/

%let tablename=<table name>;/*table name in UDP*/
%let schemaname=<schema name>;/*schema name case sensitive*/
%let database=dev; /*database name*/
%let outlib=work; /*output library*/
%let outtable=<tablename>;/*output sas table name*/
%let casdatalimit=1G; /* default is 100M have to increase for big data pull*/
%let servername=<your server address>;
%let authdomainname=<authenticaitondomain>;

%redshift_data_pull(servername=&servername.,
authdomainname=&authdomainname.,
tablename=&tablename.,
schemaname=&schemaname.,
database=&database.,
outlib=&outlib.,
outtable=&outtable.,
casdatalimit=&casdatalimit.);

/* ods trace on; */
/* options MPRINT SYMBOLGEN MPRINTNEST ; */

