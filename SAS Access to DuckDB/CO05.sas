******************************************************;
*** TEST sasioduk vs sas7bdat performance on OMOP data ;
*** ;
*** Initial Release****************
samiul.haque@sas.com
******************************************************;

/**Establish duckdb connection*****/

libname duklib sasioduk file_type="parquet" file_path="/data-netapp-ultra/data/omop/cmsdesynpuf2.3";
libname duklib2 sasioduk file_type="parquet" file_path="/data-netapp-ultra/data/omop/metadata";

/*Test 1 this is from  https://github.com/OHDSI/OMOP-Queries/blob/master/md/Condition_Occurence.md */

/**CO05 :Breakout of condition by gender, age Condition concept id is 31967 which indicates NAUSEA
We are looking at demographics of patient with NAUSEA */
proc sql;
	SELECT
	concept_name AS gender, age, gender_age_freq
	FROM (SELECT
	gender_concept_id, age, COUNT(1) as gender_age_freq
	FROM (SELECT
	year_of_birth, month_of_birth, day_of_birth, gender_concept_id, 
		condition_start_date, INT(yrdif(MDY(1, 1, year_of_birth), 
		condition_start_date, 'AGE')) AS age
		FROM (SELECT
		person_id, condition_start_date
		FROM duklib."condition_occurrence.parquet"n
		WHERE
		condition_concept_id=31967 AND
		person_id IS NOT NULL) AS from_cond
		LEFT JOIN duklib."person.parquet"n as from_person
		ON from_cond.person_id=from_person.person_id) AS gender_count
		GROUP BY gender_concept_id, age
/* 		ORDER BY gender_age_freq */) AS gender_id_age_count
		LEFT JOIN duklib2."concept.parquet"n as concept_list ON 
		gender_id_age_count.gender_concept_id=concept_list.concept_id
		ORDER BY gender_age_freq DESC;
quit;

/*now run the same sql with sas7bdat*/

libname sasout '/data-netapp-ultra/scratch/sahaqu/sasout';
proc sql;
	SELECT
	concept_name AS gender, age, gender_age_freq
	FROM (SELECT
	gender_concept_id, age, COUNT(1) as gender_age_freq
	FROM (SELECT
	year_of_birth, month_of_birth, day_of_birth, gender_concept_id, 
		condition_start_date, INT(yrdif(MDY(1, 1, year_of_birth), 
		condition_start_date, 'AGE')) AS age
		FROM (SELECT
		person_id, condition_start_date
		FROM sasout.condition_occurrence
		WHERE
		condition_concept_id=31967 AND
		person_id IS NOT NULL) AS from_cond
		LEFT JOIN sasout.person as from_person
		ON from_cond.person_id=from_person.person_id) AS gender_count
		GROUP BY gender_concept_id, age
		/* 	  ORDER BY gender_age_freq */) AS gender_id_age_count
		LEFT JOIN sasout.concept as concept_list ON 
		gender_id_age_count.gender_concept_id=concept_list.concept_id
		ORDER BY gender_age_freq DESC;
quit;



