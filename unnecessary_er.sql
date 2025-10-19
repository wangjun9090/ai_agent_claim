-- Analyze yearly unnecessary night-time ER visits by claim, with cost and savings metrics
SELECT 
    YEAR(PROC_DT) AS visit_year,                                    -- Year of the visit
    COUNT(DISTINCT CLM_ID) AS yearly_night_visits,                 -- Count unique claims (each ER visit counts once)
    AVG(total_claim) AS avg_er_cost_per_visit,                     -- Average cost per ER visit
    AVG(total_claim) - 150 AS avg_save_if_primary,                 -- Average savings per visit if handled by primary care (assuming $150 per primary care visit)
    COUNT(DISTINCT CLM_ID) * (AVG(total_claim) - 150) AS total_savings  -- Total potential savings if all visits went to primary care
FROM (
    -- Aggregate claim amounts by claim ID and procedure date for single-procedure visits
    SELECT 
        CLM_ID, 
        PROC_DT, 
        SUM(claim_amt) AS total_claim
    FROM 
        hive_metastore.off_orig.claims_member
    WHERE 
        -- Night/early morning: 8 PM to 8 AM
        (HOUR(PROC_DT) >= 20 OR HOUR(PROC_DT) < 8)
        -- Low-acuity procedures (not true emergencies)
        AND PROC_CD IN (
            'J3420',    -- Vitamin B12 injection
            'J3410',    -- Vitamin B1 injection
            '96372',    -- Subcutaneous injection
            '96374',    -- IV push medication (hydration, electrolytes)
            'J0702',    -- Magnesium sulfate injection (cramps, stress)
            '99284'     -- Level 4 ER visit (moderate acuity, e.g., headache, nausea)
        )
    GROUP BY 
        CLM_ID, 
        PROC_DT
    HAVING 
        COUNT(*) = 1  -- Only include visits with a single procedure (no additional conditions)
) grouped_visits
GROUP BY 
    YEAR(PROC_DT)
ORDER BY 
    visit_year DESC;
