## 🚀 Introduction to CAS Concepts in SAS Viya

In this exercise, you'll learn foundational concepts in SAS Viya’s Cloud Analytic Services (CAS), including sessions, libraries, in-memory data handling, and persistence. We'll cover:

- Starting a CAS session
- Working with CASLIBs
- Promoting and saving in-memory tables
- Creating your own CASLIB
- Understanding session vs global scope

---

### 🟢 Step 1: Start a CAS Session

Start your CAS session to initiate the in-memory engine.

```sas
cas; 
```
### 🟢 Step 2: Assign available CAS Libraries
```sas
caslib _ALL_ assign;
```
### 🟢 Step 3: Move Data from SAS to CAS (Session-Scoped Table)
You can easily copy data from a SAS library to CAS. This table will be session-scoped and visible only during the current session.

```
data casuser.class;
  set sashelp.class;
run;
`````
#### ⚠️  Note:  `casuser.class`  will not be available in other cas sessions .

### 🟢 Step 4: Promote a Table to Global Scope using Data Step
```sas
data casuser.heart(promote=yes);
  set sashelp.heart;
run;
```
### 🟢 Step 5: Save In-Memory Tables to Files

You can persist the data by saving the table in different formats.

```sas
proc casutil incaslib=CASUSER outcaslib=CASUSER;
  save casdata='HEART';                       /* Default is .sashdat */
  save casdata='HEART' casout='Heart.parquet';
  save casdata='HEART' casout='Heart.csv';
run;
```

List the files available in CASUSER caslib
```sas
proc casutil incaslib=casuser;
list files;
run;
```

### 🟢 Step 6: Create Your Own CASLIB (Session-Scoped)
```sas
caslib mycas path="/nfsshare/sashls/home/&SYSUSERID." datasource=(SRCTYPE=PATH);
caslib _ALL_ assign;
```
Here `SYSUSERID` is an automatic macro variable available to your compute session. We used this to point to **your** home directory.

### 🟢 Step 7: Explore & Load Data

List the files available in the caslib you just created. You can copy or upload the `SMOKINGWEIGHT.csv` file to your home directory using the file explorer in SAS Studio.

```
proc casutil incaslib=mycas;
  list files;
run;
```

Load a CSV file into memory:

```sas
proc casutil incaslib=mycas outcaslib=mycas;
  load casdata='SMOKINGWEIGHT.csv' casout='my_cas_table';
run;
```

⚠️ **my_cas_table** is session-scoped and disappears when the session ends.

### 🟢 Step 8: Promote Table to Global Scope

```sas
proc casutil incaslib=mycas outcaslib=casuser;
  load casdata='SMOKINGWEIGHT.csv' casout='my_global_table' promote;
run;
```
📝 We use the `casuser` caslib  for promotion because mycas is session-scoped and will be dropped at session end

### 🟢 Step 9: Drop and Recreate CASLIB with Global Scope

You can also craete the caslib with global scope (requires proper authorization)

First drop the session-scoped CASLIB

```
caslib mycas drop;
```

Recreate mycas caslib with global scope
```sas
caslib mycas path="/nfsshare/sashls/home/&SYSUSERID." datasource=(SRCTYPE=PATH) global;
```
### Summary:
| Concept                  | Description                                  |
| ------------------------ | -------------------------------------------- |
| **Session-Scoped Table** | Exists only during current CAS session       |
| **Promoted Table**       | Globally accessible across all sessions      |
| **CASLIB**               | Pointer to data source (e.g., file system)   |
| **CASUSER**              | Unique Global Caslib for each user (personal, temporary) |
| **Global CASLIB**        | Available beyond one session  |


