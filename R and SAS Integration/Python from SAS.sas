/*This Example Show how to submit python program */

%let barplotX =Height;
%let groupVar=Sex;
%put &=groupVar;


proc python;
submit;
import matplotlib.pyplot as plt
print(sys.version)
import pandas as pd

plt.clf()
df = SAS.sd2df('SASHELP.CLASS')
print(df.head())
Xvar=SAS.symget('barplotX')
groups=SAS.symget('groupVar')
print(f" Variable = {Xvar}")
print(f" Group = {groups}")

rslt_df = df[df[groups]=='M']
print(rslt_df.head())
plt.hist(rslt_df[Xvar],  
         alpha=0.5, # the transaparency parameter 
         label='Height (Male)') 

rslt_df = df[df[groups]=='F']
print(rslt_df.head())
plt.hist(rslt_df[Xvar],  
         alpha=0.5, # the transaparency parameter 
         label='Height (Female)')  

plt.legend(loc='upper right') 
plt.show()
SAS.pyplot(plt)

endsubmit;
run;

/*you can use the infile options to run an external python script*/

proc python infile='/nfsshare/sashls/custdata/Amgen/codes/Python Examples/sample1.py';
submit;
endsubmit;
run;

proc python infile='/nfsshare/sashls/custdata/Amgen/codes/Python Examples/list python packages.py';
submit;
endsubmit;
run;


