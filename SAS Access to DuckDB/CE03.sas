/* TEST 4 / Query CE003 */
/* CE03: Min/max, average length of condition stratified by age/gender */
/* Description */
/* Calculates the min, max, and average lenght of a condition and stratifies by age and gender. */

libname md sasioduk database="test.db";

proc sql;
connect using md;

select * from connection to md (

WITH hip_fracture  AS (
SELECT DISTINCT ca.descendant_concept_id
  FROM read_parquet('/data-netapp-ultra/data/omop/metadata/concept.parquet') c
  JOIN read_parquet('/data-netapp-ultra/data/omop/metadata/concept_ancestor.parquet') ca
    ON ca.ancestor_concept_id = c.concept_id
 WHERE c.concept_code = '359817006' /*Closed fracture of hip	*/
), people_with_hip_fracture AS (
SELECT DISTINCT
       p.person_id,
       c.concept_name AS gender,
       YEAR(ce.condition_era_start_date) - p.year_of_birth AS age,
	ce.condition_era_end_date::date - ce.condition_era_start_date::date +1 as duration,

       floor((YEAR(ce.condition_era_start_date) - p.year_of_birth)/10) AS age_grp
  FROM read_parquet('/data-netapp-ultra/data/omop/cmsdesynpuf2.3/condition_era.parquet') ce
  JOIN hip_fracture hf  
    ON hf.descendant_concept_id = ce.condition_concept_id
  JOIN read_parquet('/data-netapp-ultra/data/omop/cmsdesynpuf2.3/person.parquet') p
    ON p.person_id = ce.person_id
  JOIN read_parquet('/data-netapp-ultra/data/omop/metadata/concept.parquet') c
    ON c.concept_id = p.gender_concept_id
)
SELECT gender,
       CASE
         WHEN age_grp = 0 THEN '0-9'
         WHEN age_grp = 1 THEN '10-19'
         WHEN age_grp = 2 THEN '20-29'
         WHEN age_grp = 3 THEN '30-39'
         WHEN age_grp = 4 THEN '40-49'
         WHEN age_grp = 5 THEN '50-59'
         WHEN age_grp = 6 THEN '60-69'
         WHEN age_grp = 7 THEN '70-79'
         WHEN age_grp = 8 THEN '80-89'
         WHEN age_grp = 9 THEN '90-99'
         WHEN age_grp > 9 THEN '100+'
       END           AS age_grp,
       COUNT(*)      AS num_patients,
       MIN(duration) AS min_duration_count,
       MAX(duration) AS max_duration_count,
       AVG(duration) AS avg_duration_count
  FROM people_with_hip_fracture
 GROUP BY gender, age_grp
 ORDER BY gender, age_grp);

disconnect from md;
quit;



/*now run the same query with sas7bdat file*/
libname cdm '/data-netapp-ultra/scratch/sahaqu/sasout';

proc sql;

create table hip_fracture as 
SELECT DISTINCT ca.descendant_concept_id
  FROM cdm.concept c
  JOIN cdm.concept_ancestor ca
    ON ca.ancestor_concept_id = c.concept_id
 WHERE c.concept_code = '359817006';

create table people_with_hip_fracture as 
SELECT DISTINCT
       p.person_id,
       c.concept_name AS gender,
       YEAR(ce.condition_era_start_date) - p.year_of_birth AS age,
       intck('day',ce.condition_era_start_date,ce.condition_era_end_date) + 1 AS duration,
       floor((YEAR(ce.condition_era_start_date) - p.year_of_birth)/10) AS age_grp
  FROM cdm.condition_era ce
  JOIN hip_fracture hf  
    ON hf.descendant_concept_id = ce.condition_concept_id
  JOIN cdm.person p
    ON p.person_id = ce.person_id
  JOIN cdm.concept c
    ON c.concept_id = p.gender_concept_id;


SELECT gender, 
       CASE
         WHEN age_grp = 0 THEN '0-9'
         WHEN age_grp = 1 THEN '10-19'
         WHEN age_grp = 2 THEN '20-29'
         WHEN age_grp = 3 THEN '30-39'
         WHEN age_grp = 4 THEN '40-49'
         WHEN age_grp = 5 THEN '50-59'
         WHEN age_grp = 6 THEN '60-69'
         WHEN age_grp = 7 THEN '70-79'
         WHEN age_grp = 8 THEN '80-89'
         WHEN age_grp = 9 THEN '90-99'
         WHEN age_grp > 9 THEN '100+'
       END           AS age_grp1,
       COUNT(*)      AS num_patients,
       MIN(duration) AS min_duration_count,
       MAX(duration) AS max_duration_count,
       AVG(duration) AS avg_duration_count
  FROM people_with_hip_fracture
 GROUP BY gender, age_grp
 ORDER BY gender, age_grp;

quit;


