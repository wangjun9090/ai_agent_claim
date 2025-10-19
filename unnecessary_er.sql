-- Analyze yearly avoidable night-time ER visits by claim, with cost and savings metrics
SELECT 
    YEAR(PROC_DT) AS visit_year,                          -- Year of the visit
    COUNT(DISTINCT claim_id) AS avoidable_er_visits,      -- Total number of unique avoidable ER visits
    AVG(total_cost) AS avg_insurer_cost_per_visit,        -- Average cost per visit paid by insurer
    COUNT(DISTINCT claim_id) * AVG(total_cost) AS total_savings  -- Total potential savings for insurer
FROM (
    -- Aggregate total cost (jl_amt) for each ER visit (by claim_id and date)
    SELECT 
        claim_id, 
        PROC_DT, 
        SUM(jl_amt) AS total_cost
    FROM 
        hive_metastore.off_orig.claims_member
    WHERE 
        -- CDC low-acuity ER visit codes
        PROC_CD IN (
            '99281',    -- Level 1 ER visit (minimal acuity)
            '99282',    -- Level 2 ER visit (low acuity)
            '99283',    -- Level 3 ER visit (moderate acuity)
            '99284'     -- Level 4 ER visit (moderate acuity, e.g., headache, nausea)
        )
        -- Date range: January 1, 2023 to October 18, 2025
        AND PROC_DT BETWEEN '2023-01-01' AND '2025-10-18'
        -- Night/early morning: 8 PM to 8 AM
        AND (HOUR(PROC_DT) >= 20 OR HOUR(PROC_DT) < 8)
    GROUP BY 
        claim_id, 
        PROC_DT
    HAVING 
        COUNT(*) = 1  -- Only include visits with a single low-acuity procedure (no bundled severe conditions)
) t
GROUP BY 
    YEAR(PROC_DT)
ORDER BY 
    visit_year DESC;
