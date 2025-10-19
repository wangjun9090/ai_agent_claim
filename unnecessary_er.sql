-- Count unnecessary night-time ER visits (e.g., vitamin shots, pain meds, fluids)
-- that could have been handled by primary care, using procedure codes only
SELECT 
    COUNT(*) AS unnecessary_night_visits,
    member_id,
    PROC_DT,
    PROC_CD
FROM 
    hive_metastore.off_orig.claims_member
WHERE 
    -- Filter for night/early morning: 8 PM to 8 AM
    (HOUR(PROC_DT) >= 20 OR HOUR(PROC_DT) < 8)
    -- Filter for low-acuity procedures that are not true emergencies
    AND (
        PROC_CD = 'J3420' -- Vitamin B12 injection
        OR PROC_CD = 'J3410' -- Vitamin B1 injection
        OR PROC_CD LIKE '96372%' -- Subcutaneous injection (often nutrition or mild pain relief)
        OR PROC_CD LIKE '96374%' -- IV push medication (e.g., hydration, electrolytes)
        OR PROC_CD LIKE 'J0702%' -- Magnesium sulfate injection (common for cramps, stress)
        OR PROC_CD = '99284' -- Level 4 ER visit - moderate, often headache, nausea, minor injury
    )
GROUP BY 
    member_id,
    PROC_DT,
    PROC_CD
ORDER BY 
    PROC_DT DESC;
