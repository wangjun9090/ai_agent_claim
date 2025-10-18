-- Aggregate ICU visits and costs by unique member and date using GL_AMT
SELECT 
    COUNT(*) AS total_icu_visits,               -- Total number of unique ICU visits
    SUM(total_cost_per_visit) AS total_icu_cost, -- Total cost across all ICU visits
    ROUND(AVG(total_cost_per_visit), 2) AS avg_icu_cost -- Average cost per ICU visit
FROM (
    SELECT 
        member_id,
        visit_date,
        SUM(GL_AMT) AS total_cost_per_visit         -- Sum all GL_AMT for each unique visit
    FROM hive_metastore.off_orig.claims_member
    WHERE PROC_CD LIKE '99291%'                 -- Filter for ICU procedure codes (e.g., 99291)
        AND PLSRV_CD LIKE '%21%'                -- Filter for emergency/ICU service codes
        AND PROC_DT BETWEEN '2023-01-01' AND '2025-10-18' -- Time range: 2023 to current date
    GROUP BY member_id, visit_date
) t;
