******************************************************;
*** TEST sasioduk  performance on OMOP data ;
*** ;
*** Initial Release****************
samiul.haque@sas.com
******************************************************;

/* *This is an cohort used in Natures paper 
Ahmadi, N., Nguyen, Q.V., Sedlmayr, M. et al
. A comparative patient-level prediction study in OMOP CDM: applicative 
potential and insights from synthetic data. Sci Rep 14, 2287 (2024). 
https://doi.org/10.1038/s41598-024-52723-y*****/

/*Cohort sql code is available at 
https://github.com/NajiaAhmadi/Benchmarking-Analysis-of-PLP-vs-MLR3/blob/main/cohort_target.sql*/

/* We use sql passtrhough here because window function is not available in PROC SQL*/ 

options sastrace=',,,d' sastraceloc=saslog nostsuffix msglevel=i;

%let dbfile_data=/data-netapp-ultra/scratch/sahaqu/omop_data.db;
%let dbfile_metadata=/data-netapp-ultra/scratch/sahaqu/omop_metadata.db;


%let dbfile=/shared-data/anbise/data/scratch/sahaqu_test.db;

libname md sasioduk database="test.db";

libname duklib sasioduk file_type="parquet" file_path="/data-netapp-ultra/data/omop/cmsdesynpuf2.3"
database="&dbfile_data";
libname duklib2 sasioduk file_type="parquet" file_path="/data-netapp-ultra/data/omop/metadata" database="&dbfile_metadata";
libname dukout sasioduk file_type="parquet" file_path="/data-netapp-ultra/scratch/sahaqu/dukout";

proc sql;
connect using md;
/* select * from connection to md( */
/* select count(*) from read_parquet("/data-netapp-ultra/data/omop/cmsdesynpuf2.3/person.parquet")); */

execute(CREATE TEMP TABLE Codesets  (codeset_id int NOT NULL,
  concept_id bigint NOT NULL
)
;) by md;

execute(INSERT INTO Codesets (codeset_id, concept_id)
SELECT 0 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from read_parquet("/data-netapp-ultra/data/omop/metadata/concept.parquet") where concept_id in (319844,315286,4185932)
) I
) C UNION ALL 
SELECT 1 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from read_parquet("/data-netapp-ultra/data/omop/metadata/concept.parquet") where concept_id in (313217,4306655,442289)
) I
) C
;
) by md;



execute(CREATE TEMP TABLE qualified_events
AS
SELECT
event_id, person_id, start_date, end_date, op_start_date, op_end_date, visit_occurrence_id
FROM
(
  select pe.event_id, pe.person_id, pe.start_date, pe.end_date, pe.op_start_date, pe.op_end_date, row_number() over (partition by pe.person_id order by pe.start_date ASC) as ordinal, cast(pe.visit_occurrence_id as bigint) as visit_occurrence_id
  FROM (
select P.ordinal as event_id, P.person_id, P.start_date, P.end_date, op_start_date, op_end_date, cast(P.visit_occurrence_id as bigint) as visit_occurrence_id
FROM
(
  select E.person_id, E.start_date, E.end_date,
         row_number() OVER (PARTITION BY E.person_id ORDER BY E.sort_date ASC, E.event_id) ordinal,
         OP.observation_period_start_date as op_start_date, OP.observation_period_end_date as op_end_date, cast(E.visit_occurrence_id as bigint) as visit_occurrence_id
  FROM 
  (
  
SELECT C.person_id, C.condition_occurrence_id as event_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, (C.condition_start_date + 1*INTERVAL'1 day')) as end_date,
  C.visit_occurrence_id, C.condition_start_date as sort_date
FROM 
(
  SELECT co.* 
  FROM read_parquet("/data-netapp-ultra/data/omop/cmsdesynpuf2.3/condition_occurrence.parquet") co
  JOIN Codesets cs on (co.condition_concept_id = cs.concept_id and cs.codeset_id = 0)
) C

  ) E
	JOIN read_parquet("/data-netapp-ultra/data/omop/cmsdesynpuf2.3/observation_period.parquet") OP on E.person_id = OP.person_id and E.start_date >=  OP.observation_period_start_date and E.start_date <= op.observation_period_end_date
  WHERE (OP.OBSERVATION_PERIOD_START_DATE + 0*INTERVAL'1 day') <= E.START_DATE AND (E.START_DATE + 0*INTERVAL'1 day') <= OP.OBSERVATION_PERIOD_END_DATE
) P
WHERE P.ordinal = 1

) pe
) QE
;


) by md;
/*  */
/* create table dukout.qualified_events as select * from connection to md (select * from qualified_events); */


execute(
CREATE TEMP TABLE Inclusion_0
AS
SELECT
0 as inclusion_rule_id, person_id, event_id
FROM
(
  select pe.person_id, pe.event_id
  FROM qualified_events pe
JOIN (

select 0 as index_id, person_id, event_id
FROM
(
  select E.person_id, E.event_id 
  FROM qualified_events E
  INNER JOIN
  (

select 0 as index_id, cc.person_id, cc.event_id
from (SELECT p.person_id, p.event_id 
FROM qualified_events P
JOIN (

SELECT C.person_id, C.condition_occurrence_id as event_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, (C.condition_start_date + 1*INTERVAL'1 day')) as end_date,
  C.visit_occurrence_id, C.condition_start_date as sort_date
FROM 
(
  SELECT co.* 
  FROM read_parquet("/data-netapp-ultra/data/omop/cmsdesynpuf2.3/condition_occurrence.parquet") co
  JOIN Codesets cs on (co.condition_concept_id = cs.concept_id and cs.codeset_id = 1)
) C

) A on A.person_id = P.person_id  AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE AND A.START_DATE >= (P.START_DATE + 0*INTERVAL'1 day') AND A.START_DATE <= P.OP_END_DATE ) cc 
GROUP BY cc.person_id, cc.event_id
HAVING COUNT(cc.event_id) >= 1

  ) CQ on E.person_id = CQ.person_id and E.event_id = CQ.event_id
  GROUP BY E.person_id, E.event_id
  HAVING COUNT(index_id) = 1
) G

) AC on AC.person_id = pe.person_id AND AC.event_id = pe.event_id
) Results
;
ANALYZE Inclusion_0
;
CREATE TEMP TABLE inclusion_events
AS
SELECT
inclusion_rule_id, person_id, event_id
FROM
(select inclusion_rule_id, person_id, event_id from Inclusion_0) I;
ANALYZE inclusion_events
;
TRUNCATE TABLE Inclusion_0;
DROP TABLE Inclusion_0;
CREATE TEMP TABLE included_events
AS
SELECT
event_id, person_id, start_date, end_date, op_start_date, op_end_date
FROM
(
  SELECT event_id, person_id, start_date, end_date, op_start_date, op_end_date, row_number() over (partition by person_id order by start_date ASC) as ordinal
  from
  (
    select Q.event_id, Q.person_id, Q.start_date, Q.end_date, Q.op_start_date, Q.op_end_date, SUM(coalesce(POWER(cast(2 as bigint), I.inclusion_rule_id), 0)) as inclusion_rule_mask
    from qualified_events Q
    LEFT JOIN inclusion_events I on I.person_id = Q.person_id and I.event_id = Q.event_id
    GROUP BY Q.event_id, Q.person_id, Q.start_date, Q.end_date, Q.op_start_date, Q.op_end_date
  ) MG 
  
  WHERE (MG.inclusion_rule_mask = POWER(cast(2 as bigint),1)-1)
) Results
WHERE Results.ordinal = 1
;
) by md;



execute(
CREATE TEMP TABLE cohort_rows
AS
SELECT
person_id, start_date, end_date
FROM
( 
	select F.person_id, F.start_date, F.end_date
	FROM (
	  select I.event_id, I.person_id, I.start_date, CE.end_date, row_number() over (partition by I.person_id, I.event_id order by CE.end_date) as ordinal
	  from included_events I
	  join ( 


select event_id, person_id, op_end_date as end_date from included_events
    ) CE on I.event_id = CE.event_id and I.person_id = CE.person_id and CE.end_date >= I.start_date
	) F
	WHERE F.ordinal = 1
) FE;

) by md;



execute (

CREATE TEMP TABLE final_cohort
AS
SELECT
person_id, min(start_date) as start_date, end_date
FROM
( 
	SELECT
		 c.person_id
		, c.start_date
		, MIN(ed.end_date) AS end_date
	FROM cohort_rows c
	JOIN ( 
    SELECT
      person_id
      , (event_date + -1 * 0*INTERVAL'1 day')  as end_date
    FROM
    (
      SELECT
        person_id
        , event_date
        , event_type
        , SUM(event_type) OVER (PARTITION BY person_id ORDER BY event_date, event_type ROWS UNBOUNDED PRECEDING) AS interval_status
      FROM
      (
        SELECT
          person_id
          , start_date AS event_date
          , -1 AS event_type
        FROM cohort_rows
        UNION ALL
        SELECT
          person_id
          , (end_date + 0*INTERVAL'1 day') as end_date
          , 1 AS event_type
        FROM cohort_rows
      ) RAWDATA
    ) e
    WHERE interval_status = 0
  ) ed ON c.person_id = ed.person_id AND ed.end_date >= c.start_date
	GROUP BY c.person_id, c.start_date
) e
group by person_id, end_date


) by md;

create table dukout.final_cohort as select * from connection to md (select * from final_cohort);


disconnect from md;
quit;
