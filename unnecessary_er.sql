-- Analyze avoidable ER visits with cost and savings estimates for low-acuity procedure codes
SELECT 
    YEAR(PROC_DT) AS visit_year,                          -- Year of the visit
    COUNT(*) AS avoidable_visits,                         -- Total number of avoidable ER visits
    COUNT(*) * 1500 AS rough_dollar_cost,                 -- Estimated total cost (assuming $1500 per visit)
    COUNT(*) * (1500 - 150) AS rough_dollar_saved         -- Estimated total savings if handled by primary care (assuming $150 per primary care visit)
FROM 
    hive_metastore.off_orig.claims_member
WHERE 
    -- Low-acuity ER visit codes
    PROC_CD IN (
        '99281',    -- Level 1 ER visit (minimal acuity)
        '99282',    -- Level 2 ER visit (low acuity)
        '99283',    -- Level 3 ER visit (moderate acuity)
        '99284'     -- Level 4 ER visit (moderate acuity, e.g., headache, nausea)
    )
    -- Date range: January 1, 2023 to October 18, 2025
    AND PROC_DT BETWEEN '2023-01-01' AND '2025-10-18'
GROUP BY 
    YEAR(PROC_DT)
ORDER BY 
    visit_year DESC;
