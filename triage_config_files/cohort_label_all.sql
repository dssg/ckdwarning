-- Create EGFR data to get the patients with abnormal values
-- Get the Window for the abnormal values for the time span after the as of date
WITH 
egfr_window AS (
    SELECT
        entity_id, 
        first_value(is_abnormal) OVER win as abnormal -- First value of is_abnormal after the as of date
    FROM
        ml_latest.egfr_analysis egfr
    WHERE
        egfr.event_dttm BETWEEN '{as_of_date}' :: DATE AND '{as_of_date}' :: DATE + interval '{label_timespan}' 
        WINDOW win as  (PARTITION BY entity_id
                        ORDER BY event_dttm ASC)
), 
egfr_out AS (
    -- Create a window of abnormal values before the as_of_date
    SELECT
        entity_id, 
        MAX(is_abnormal :: int) OVER win as abnormal -- Max Abnormal
    FROM
        ml_latest.egfr_analysis egfr
    WHERE
        egfr.event_dttm < ('{as_of_date}' :: DATE)  
        WINDOW win as  (PARTITION BY entity_id
                        ORDER BY event_dttm ASC)
),
dem_data AS (
  -- Create Demographic data to map to the right demographic to buid the cohort
  -- Remove the patients who are dead or outside age range on as of date
  -- Remove the patients who do not have an encounter in 2 years

    SELECT dem.entity_id FROM ml_latest.demographics dem, ml_latest.encounters enc
    WHERE dem.entity_id = enc.entity_id
    AND (DATE_PART('year', AGE('{as_of_date}', enc.visit_admit_dttm)) < 2 AND enc.encounter_type IN (select id from test.clinical_visit_codes))
    AND (DATE_PART('year','{as_of_date}':: DATE) - DATE_PART('year', dem.birth_date)) between 18 and 85
    AND (dem.death_date ISNULL OR dem.death_date > '{as_of_date}')

), 
cohort_data AS (
  -- Create Cohort data by removing the patients who had an abnormal reading atleast once  
  SELECT dem.entity_id 
  FROM dem_data dem
  WHERE 
    dem.entity_id IN (
      SELECT DISTINCT entity_id 
      FROM ml_latest.pat_all_flt_ckd 
      WHERE (ckd_label_date >= ('{as_of_date}' :: DATE) OR ckd_label_date ISNULL) 
    )
    AND dem.entity_id NOT IN (SELECT DISTINCT entity_id FROM egfr_out WHERE abnormal = 1)
),
calc_data AS (
  -- Join with Demographic and EGFR values to get the the labels   
  SELECT 
    cohort.entity_id, 
    CASE 
      WHEN 
          MAX (egfr_window.abnormal :: int) = 1 
      THEN 1
      WHEN
          MAX (egfr_window.abnormal :: int) = 0 
      THEN 0
      ELSE null
    END AS outcome
  FROM
    cohort_data as cohort
    LEFT JOIN egfr_window
    ON 
      cohort.entity_id = egfr_window.entity_id
  GROUP BY
    cohort.entity_id
)

--SELECT outcome, COUNT(entity_id) FROM calc_data GROUP BY outcome  ORDER by outcome DESC
SELECT entity_id, outcome::int FROM calc_data 
