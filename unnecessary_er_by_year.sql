-- Analyze yearly unnecessary night-time ER visits with cost and savings metrics
SELECT 
    YEAR(PROC_DT) AS visit_year,                                    -- Year of the visit
    COUNT(*) AS yearly_night_visits,                               -- Total number of night visits per year
    AVG(claim_amt) AS avg_er_cost_per_visit,                       -- Average ER cost per visit
    AVG(claim_amt) - 150 AS avg_savings_if_primary,                -- Average savings per visit if handled by primary care (assuming $150 per primary care visit)
    COUNT(*) * (AVG(claim_amt) - 150) AS total_savings_if_primary  -- Total potential savings if all visits went to primary care
FROM 
    hive_metastore.off_orig.claims_member
WHERE 
    -- Night/early morning: 8 PM to 8 AM
    (HOUR(PROC_DT) >= 20 OR HOUR(PROC_DT) < 8)
    -- Low-acuity procedures (not true emergencies)
    AND (
        PROC_CD = 'J3420'           -- Vitamin B12 injection
        OR PROC_CD = 'J3410'        -- Vitamin B1 injection
        OR PROC_CD LIKE '9637%'     -- Subcutaneous injection or IV push (hydration, electrolytes)
        OR PROC_CD LIKE 'J070%'     -- Magnesium sulfate injection (cramps, stress)
        OR PROC_CD = '99284'        -- Level 4 ER visit (moderate acuity, e.g., headache, nausea)
    )
    -- Limit to visits on or after January 1, 2023
    AND PROC_DT >= '2023-01-01'
GROUP BY 
    YEAR(PROC_DT)
ORDER BY 
    visit_year DESC;
