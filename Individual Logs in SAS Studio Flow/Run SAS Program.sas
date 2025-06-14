/*print log in the same folder where code is */

/* initial release April 1, 2025*/
/*samiul.haque@sas.com*/
/* Added ODS html5 output April 2, 2025*/


%put &=datetimestamp_log;
%put &=datetimestamp_lst;

%macro checkMacroVar;
	%if %length(&filepath) > 0 %then %do;
		%put &=filepath;
		%let serverlen=%length(sasserver:);
		%let sasfilepath=%substr(&filepath, %eval(&serverlen + 1));

		/* Get the current date and time */
		data _null_;
			call symputx('datetime', put(datetime(), 
				yymmddn8.)||'_'||translate(put(time(), time8.), 'HHMM', ':'));
		run;

		%let logfilename=%sysfunc(tranwrd(&sasfilepath, .sas, .log));
		%let lstfilename=%sysfunc(tranwrd(&sasfilepath, .sas, .html));

		%if &datetimestamp_log=1 %then %do;

			%let datetime = %sysfunc(date(), date9.)-%sysfunc(time(), time8.);

			%let finallogfilename=%substr(&logfilename, 1, 
				%length(&logfilename)-4)_&datetime..log;

			/* Example to display the new macro variable */
			%put &finallogfilename;
			%let logfilename=&finallogfilename;
		%end;

		%if &datetimestamp_lst=1 %then %do;

			%let datetime = %sysfunc(date(), date9.)-%sysfunc(time(), time8.);
			%let finallstfilename=%substr(&lstfilename, 1, 
				%length(&lstfilename)-5)_&datetime..html;

			/* Example to display the new macro variable */
			%put &finallstfilename;
			%let lstfilename=&finallstfilename;
		%end;
		%put &=lstfilename;

		proc printto new log="&logfilename.";
		run;

	
		ods html5 file="&lstfilename.";
		%include "&sasfilepath." / source2;
		ods html5 close;

		proc printto;
		run;

	%end;
	%else %do;
		%put 'End of flow';
	%end;
%mend checkMacroVar;

%checkMacroVar;
