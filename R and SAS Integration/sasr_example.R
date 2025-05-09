library(sasr)
library(reticulate)
use_python('/usr/bin/python3')

#get a sas session. This function returns the last session created or creates a new sas session if there are no previous session
my_sas_session <- get_sas_session()

###test if the session is active################################################
er<-try({run_sas("")},silent=TRUE)

if(class(er)=='try-error'){ 
  if(any(grepl("package:sasr", search()))) detach("package:sasr")
  library(sasr)
  print('Restarting SAS Compute Session....')
  my_sas_session <- get_sas_session()
}
################################################################################



#submit a code to sas compute
result <- run_sas("
   proc freq data = sashelp.heart;
   tables _CHARACTER_;
   run;
 ")


#result contains LOG and LST

#See Log
cat(result$LOG)

#See Result
cat(result$LST)


#can we copy sas dataset to R? for this let us produce some output first


result <- run_sas("
   proc freq data = sashelp.heart;
   tables sex / out=FreqCount;
   run;
 ")


result <- run_sas("
   proc print data = sashelp.heart;
   run;
 ")

#copy the data

freq_count <-  my_sas_session$sd2df('FreqCount',libref='WORK')

print(freq_count)

#move some data from R to sas we will move mtcars dataframe available in R to SAS WORK library

upload <- my_sas_session$df2sd(mtcars,table ='mt_df',libref='WORK')


#Now we can run SAS PROCS on WORK.mt_df dataset


result <- run_sas("
   proc freq data = work.mt_df;
   tables _NUMERIC_ / out=mean;
   run;
 ")


#we can check if the table was created in SAS session

my_sas_session$datasets(libref="WORK")
my_sas_session$endsas()
