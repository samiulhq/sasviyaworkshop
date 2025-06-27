/* This example shows how to submit R code using PROC IML */

%put &=SYSUSERID; /*this automatic macro variable determines your user id*/

%let filepath = /nfsshare/sashls/home/&SYSUSERID./ggplout_out.pdf;

%put &=filepath;

proc iml;

print "-------------  R Results  --------------------";
call ExportDataSetToR("Sashelp.Class", "df" );
filepath="&filepath.";
submit filepath / R;

fn<-"&filepath"
if (file.exists(fn)) {
  #Delete file if it exists
  file.remove(fn)
}

library(ggplot2)
names(df)
pdf(file="&filepath")
print(df)

# Use semi-transparent fill
ggplot(df, aes(x=Height, color=Sex, fill=Sex)) +
  geom_histogram(position="identity", alpha=0.5)

dev.off()
endsubmit;

call ImportDataSetFromR("work.df", "df");
quit;
