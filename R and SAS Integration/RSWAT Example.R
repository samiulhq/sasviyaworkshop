library(swat)


Sys.setenv(CAS_CLIENT_SSL_CA_LIST='/opt/certificates/my_CAS_Viya4POC_cert.pem')   

uname<-rstudioapi::askForPassword("SAS username")
pass<-rstudioapi::askForPassword("SAS password")


session<-swat::CAS("sas-cas-server-default-bin-sashls1.eastus.cloudapp.azure.com",5570,username=uname,password=pass)


#print caslib names

caslibinfo<-cas.table.caslibInfo(session)
print(caslibinfo$CASLibInfo$Name)


currentCaslib <- 'PUBLIC'
tableinfo<-cas.table.tableInfo(session,caslib=currentCaslib)


#print table names in the Caslib
print(tableinfo$TableInfo$Name)

stentTable <- defCasTable(session,caslib=currentCaslib,tablename ="STENT_FAILURE")
head(stentTable)

cas.table.loadTable(session, 
                    path="CARS.sashdat",caslib=currentCaslib,
                    casOut=list(name="CARS_GLOBAL", caslib=currentCaslib),promote=TRUE)


#another way to fetch data from CAS tables
cas.table.fetch(session,table=list(caslib=currentCaslib,name="STENT_FAILURE"))




#moving data from R to SAS Viya, mtcars is a dataframe available to R we will move this over to Viya

head(mtcars)
#notice we are writting to CASUSER caslib which is not shared across users, Promote must be set to true for making the table persistant in memory

mtcars_cas=as.casTable(session,mtcars,casOut = list(name='mtcars_sh',caslib='CASUSER',promote=TRUE))

#we can also save the table as parquet or sashdat or csv file

mtcars_cas=cas.table.save(session,
                          caslib="CASUSER", #target caslib
                          name='mtcars_sh.parquet',#output file name
                          table=c(name='mtcars_sh',caslib="CASUSER"), #source table information
                          replace=TRUE
                          )

cas.table.fileInfo(session,caslib=c(name="CASUSER"))

cas.upload.file(session,data='varimp.csv',casout=list(caslib='CASUSER',name='mytable'))

currentCaslib <- 'CASUSER'
tableinfo<-cas.table.tableInfo(session,caslib=currentCaslib)
print(tableinfo$TableInfo$Name)
class <- cas.read.csv(session, "varimp.csv",casOut =list(caslib='CASUSER',name='mytable_',promote=TRUE))
