
libname duklib sasioduk file_type="parquet" file_path="/data-netapp-ultra/data/omop/cmsdesynpuf2.3";
libname duklib2 sasioduk file_type="parquet" file_path="/data-netapp-ultra/data/omop/metadata";
libname dukout sasioduk file_type="parquet" file_path="/data-netapp-ultra/scratch/sahaqu/dukout";

libname md sasioduk database="test.db";

/***This example is from https://data.ohdsi.org/QueryLibrary/ 
Query CE07

CE07: Comorbidities of patient with condition
Description
This query counts the top ten comorbidities for patients with diabetes

***/

proc sql;


connect using md;

create table dukout.ce07out as select * from connection to md
(
WITH snomed_diabetes AS (
SELECT ca.descendant_concept_id AS snomed_diabetes_id
  FROM read_parquet('/data-netapp-ultra/data/omop/metadata/concept.parquet') c
  JOIN read_parquet('/data-netapp-ultra/data/omop/metadata/concept_ancestor.parquet') ca
    ON ca.ancestor_concept_id = c.concept_id
 WHERE c.concept_code = '73211009'
),  people_with_diabetes AS (
SELECT ce.person_id,
       MIN(ce.condition_era_start_date) AS onset_date
  FROM read_parquet('/data-netapp-ultra/data/omop/cmsdesynpuf2.3/condition_era.parquet') ce
  JOIN snomed_diabetes sd
    ON sd.snomed_diabetes_id = ce.condition_concept_id
 GROUP BY ce.person_id
), non_diabetic AS (
SELECT person_id,
       condition_concept_id,
       condition_era_start_date
  FROM read_parquet('/data-netapp-ultra/data/omop/cmsdesynpuf2.3/condition_era.parquet')
 WHERE condition_concept_id NOT IN (SELECT snomed_diabetes_id FROM snomed_diabetes)
)
SELECT c.concept_name AS comorbidity,
       COUNT(DISTINCT diabetic.person_id) AS frequency        
  FROM people_with_diabetes diabetic
  JOIN non_diabetic comorb
    ON comorb.person_id = diabetic.person_id
   AND comorb.condition_era_start_date > diabetic.onset_date
  JOIN read_parquet('/data-netapp-ultra/data/omop/metadata/concept.parquet') c
    ON c.concept_id = comorb.condition_concept_id
 GROUP BY c.concept_name
 ORDER BY frequency DESC);

disconnect from md;

quit;

proc sql;
select * from dukout."ce07out.parquet"n;
quit;

libname cdm '/data-netapp-ultra/scratch/sahaqu/sasout';

proc sql;
create table snomed_diabetes AS 
SELECT ca.descendant_concept_id AS snomed_diabetes_id
  FROM cdm.concept c
  JOIN cdm.concept_ancestor ca
    ON ca.ancestor_concept_id = c.concept_id
 WHERE c.concept_code = '73211009'
;  
create table people_with_diabetes AS 
SELECT ce.person_id,
       MIN(ce.condition_era_start_date) AS onset_date
  FROM cdm.condition_era ce
  JOIN snomed_diabetes sd
    ON sd.snomed_diabetes_id = ce.condition_concept_id
 GROUP BY ce.person_id;

create table  non_diabetic AS 
SELECT person_id,
       condition_concept_id,
       condition_era_start_date
  FROM cdm.condition_era
 WHERE condition_concept_id NOT IN (SELECT snomed_diabetes_id FROM snomed_diabetes);

SELECT c.concept_name AS comorbidity,
       COUNT(DISTINCT diabetic.person_id) AS frequency        
  FROM people_with_diabetes diabetic
  JOIN non_diabetic comorb
    ON comorb.person_id = diabetic.person_id
   AND comorb.condition_era_start_date > diabetic.onset_date
  JOIN cdm.concept c
    ON c.concept_id = comorb.condition_concept_id
 GROUP BY c.concept_name
 ORDER BY frequency DESC;
quit;
