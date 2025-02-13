#this examples shows how to run a pre-defined sas job leveraging REST API

library(httr)
library(jsonlite)

uname<-rstudioapi::askForPassword("SAS username")
pass<-rstudioapi::askForPassword("SAS password")


viya_host<-'https://sashls1.eastus.cloudapp.azure.com/'
httr::set_config(config(ssl_verifypeer = 0L))


#try to get response without authorziation (returns error)
get_response <- GET(url = viya_host)
print(get_response)


#REST API call with credential for getting access_token

headers = c(
  'Authorization' = 'Basic c2FzLmNsaTo=',
  'Content-Type' = 'application/x-www-form-urlencoded'
)

body = list(
  'grant_type' = 'password',
  'username' = paste0(uname),
  'password' = paste0(pass)
)

response <- POST(url = "https://sashls1.eastus.cloudapp.azure.com/SASLogon/oauth/token", body = body, add_headers(headers), encode = 'form')

response_df=fromJSON((content(response,'text')))

print(response_df)

#Use access token for subsequent REST API calls

headers = c(
  'Authorization' =  paste('Bearer',response_df$access_token) )


#Run a Pre-Defined Job in SAS Viya using REST API this can also be submitted as Asynchrounous call
res <- POST(url = "https://sashls1.eastus.cloudapp.azure.com/SASJobExecution/?_program=%2FPublic%2FJobs%2Fjob_means", add_headers(headers))



result_df=fromJSON((content(res,'text')))
print(result_df)



#Now run the job with a parameter / macro we will change the by variable
res <- POST(url = "https://sashls1.eastus.cloudapp.azure.com/SASJobExecution/?_program=%2FPublic%2FJobs%2Fjob_means&byvar=make", add_headers(headers))

result_df=fromJSON((content(res,'text')))
print(result_df)




#Now we will access a CAS table that the SAS Job created in Viya environment using R SWAT API.

library(swat)
Sys.setenv(CAS_CLIENT_SSL_CA_LIST='/opt/certificates/my_CAS_Viya4POC_cert.pem')    
session<-CAS("sas-cas-server-default-bin-sashls1.eastus.cloudapp.azure.com",5570,username=uname,password=pass)

currentCaslib <- 'PUBLIC'
tableinfo<-cas.table.tableInfo(session,caslib=currentCaslib)

#Print all table names in the PUBLIC caslib.

print(tableinfo$TableInfo$Name)
msrp_means_table <- defCasTable(session,caslib=currentCaslib,"MSRP_MEANS")
head(msrp_means_table)
cars_table <- defCasTable(session,caslib=currentCaslib,"CARS")
head(cars_table)


cas.simple.summary(session,  
                     inputs = c("MSRP"),  table = 
                       c(name = "CARS", caslib="public",  groupBy = "Origin"),  subset=c("MEAN", "MAX", "MIN", "N"), casOut = list(name = "means_summary", replace = TRUE))


cas.table.fetch(session,  table = "means_summary")

means_summary <- defCasTable(session,"means_summary")

means_summary_df= to.data.frame(to.casDataFrame(means_summary))

print(means_summary)

cas_table=as.casTable(session,means_summary_df,casOut = c(name="test1",caslib='PUBLIC',promote=TRUE))

