-- Option 1: Using GL_AMT (raw claim amount)
SELECT 
    COUNT(*) AS total_icu_visits,           -- Total number of ICU visits from 2023 to 2025
    SUM(GL_AMT) AS total_icu_cost,          -- Total ICU cost based on raw claim amounts
    AVG(GL_AMT) AS avg_icu_cost             -- Average cost per ICU visit
FROM hive_metastore.off_orig.claims_member
WHERE PROC_CD LIKE '99291%'               -- Filter for ICU procedure codes (e.g., 99291)
    AND PLSRV_CD LIKE '%21%'              -- Filter for emergency/ICU service codes
    AND PROC_DT BETWEEN '2023-01-01' AND '2025-10-18'; -- Time range: 2023 to current date

-- Option 2: Using PAID_AMT (actual paid amount, if GL_AMT is unreliable)
SELECT 
    COUNT(*) AS total_icu_visits,           -- Total number of ICU visits from 2023 to 2025
    SUM(PAID_AMT) AS total_icu_cost,        -- Total ICU cost based on actual payments
    AVG(PAID_AMT) AS avg_icu_cost           -- Average cost per ICU visit
FROM hive_metastore.off_orig.claims_member
WHERE PROC_CD LIKE '99291%'               -- Filter for ICU procedure codes (e.g., 99291)
    AND PLSRV_CD LIKE '%21%'              -- Filter for emergency/ICU service codes
    AND PROC_DT BETWEEN '2023-01-01' AND '2025-10-18'; -- Time range: 2023 to current date
