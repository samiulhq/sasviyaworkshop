#load libraries connect to CAS

library(swat)
library(tidyr)

Sys.setenv(CAS_CLIENT_SSL_CA_LIST='/opt/certificates/my_CAS_Viya4POC_cert.pem') 

uname<-rstudioapi::askForPassword("SAS username")
pass<-rstudioapi::askForPassword("SAS password")

session<-swat::CAS("sas-cas-server-default-bin-sashls1.eastus.cloudapp.azure.com",5570,username=uname,password=pass)

currentCaslib <- 'PUBLIC'
df <- cas.table.tableInfo(session,caslib=currentCaslib)
print(df$TableInfo$Name)


cas.table.tableInfo(session,caslib=currentCaslib)
varselect_tbl <- defCasTable(session,caslib=currentCaslib,"ACS_COHORT_VARSELECT")
head(varselect_tbl)

allvars<-colnames(varselect_tbl)
inputvars<-allvars[-(46)] #removing the target variable from inputvars list # AV_MI_CC_FLG


#load decission tree action set
loadActionSet(session,"decisionTree")
results<-cas.decisionTree.forestTrain(session,
                                      inputs=inputvars,
                                      table=list(name="ACS_COHORT_VARSELECT",caslib=currentCaslib),
                                      target="AV_MI_CC_FLG",
                                      seed=32,
                                      varImp=TRUE,
                                      nominals=allvars,
                                      bootstrap=0.3
                                      )
print(results$DTreeVarImpInfo)
write.csv(results$DTreeVarImpInfo,file = 'varimp.csv',row.names =  FALSE)
