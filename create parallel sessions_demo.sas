
%macro gsignon(num);
	%do i=1 %to &num;
		%let rc=%sysfunc(grdsvc_enable(task&i, "context=default-launcher"));
		signon task&i macvar=rtask&i;
	%end;
%mend gsignon;

%macro gsignoff(num);
	%do i=1 %to &num;
		signoff task&i wait=no;
	%end;
%mend gsignoff;

/********** end macros **********/
%let numsess=4;

/*** numsess = How many grid sessions you want ***/
%gsignon(num=&numsess);



rsubmit process=task1 wait=no;
libname test '/nfsshare/sashls/home/sahaqu/PoC/Scatter Gather/data';



data test.bootsamples1;
	set test.bootsamples1;
	boot=1;
run;

proc sort data=test.bootsamples1;
	by descending Height;
run;

endrsubmit;
rsubmit process=task2 wait=no;
libname test '/nfsshare/sashls/home/sahaqu/PoC/Scatter Gather/data';

data test.bootsamples2;
	set test.bootsamples2;
	boot=2;
run;

proc sort data=test.bootsamples2;
	by descending Height;
run;

endrsubmit;
rsubmit process=task3 wait=no;
libname test '/nfsshare/sashls/home/sahaqu/PoC/Scatter Gather/data';

data test.bootsamples3;
	set test.bootsamples3;
	boot=3;
run;

proc sort data=test.bootsamples3;
	by descending Height ;
run;

endrsubmit;


rsubmit process=task4 wait=no;

libname test '/nfsshare/sashls/home/sahaqu/PoC/Scatter Gather/data';
data test.bootsamples4;
	set test.bootsamples4;
	boot=4;
run;

proc sort data=test.bootsamples4;
	by descending Height ;
run;

endrsubmit;
waitfor _all_;

/* data test.sortedbyboot; */
/* 	merge test.bootsamples1 test.bootsamples2 test.bootsamples3 test.bootsamples4; */
/* run; */

%gsignoff(num=&numsess);