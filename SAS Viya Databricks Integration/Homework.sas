/*To Do*/

/* 1. Create a libname to databricks sandbox */





/* 2. Create a frequency table for gener by birth year */


/*3. Write the table back to data bricks give it a unique name (use your id) */


/* 4. Copy and promote the RWE_MEMBER table to your CASUER caslib */


/*5 Create a VA report */


/* 6 bonus: Try PORC FREQTAB on the CASUSER.RWE_MEMEBER Table compare it with proc freq*/

/* hint: */
/* proc freq data=CDTSPARK.RWE_MEMBER; */
/* table year_of_birth_no*gender_cd  / out= D_SPARK; */
/* run; */
/*  */
/* proc freqtab data=CASUSER.RWE_MEMBER; */
/* table year_of_birth_no*gender_cd  / out= D_CAS; */
/* run; */
