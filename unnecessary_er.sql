-- Analyze pure avoidable night-time ER visits with strict filtering for low-acuity only
WITH clean_visits AS (
    -- Identify single-procedure, low-acuity night-time ER visits with no bundled services
    SELECT 
        claim_id, 
        YEAR(PROC_DT) AS year, 
        PROC_DT, 
        SUM(jl_amt) AS total_payer_cost
    FROM 
        hive_metastore.off_orig.claims_member
    WHERE 
        -- Date range: January 1, 2023 to October 18, 2025
        PROC_DT BETWEEN '2023-01-01' AND '2025-10-18'
        -- Low-acuity ER visit codes only
        AND PROC_CD IN (
            '99281',    -- Level 1 ER visit (minimal acuity)
            '99282',    -- Level 2 ER visit (low acuity)
            '99283',    -- Level 3 ER visit (moderate acuity)
            '99284'     -- Level 4 ER visit (moderate acuity)
        )
        -- Night/early morning: 8 PM to 8 AM
        AND (HOUR(PROC_DT) >= 20 OR HOUR(PROC_DT) < 8)
    GROUP BY 
        claim_id, 
        PROC_DT, 
        YEAR(PROC_DT)
    HAVING 
        COUNT(*) = 1  -- Only visits with exactly one procedure (no bundled services)
        AND NOT EXISTS (
            -- Exclude visits where same member/same day has ANY other procedures:
            -- - Non-992 codes (anything outside low-acuity ER)
            -- - Critical care codes (99291+)
            -- - ECG tests
            -- - Surgical procedures  
            -- - Diagnostic/consult codes
            SELECT 1 
            FROM hive_metastore.off_orig.claims_member other
            WHERE other.MembershipNumber = claims_member.MembershipNumber
                AND other.PROC_DT = claims_member.PROC_DT
                AND other.PROC_CD NOT IN ('99281', '99282', '99283', '99284')
                AND other.PROC_CD NOT LIKE '992%'      -- Exclude critical care (99291+)
                AND other.PROC_CD NOT LIKE '9304%'     -- Exclude ECG tests
                AND other.PROC_CD NOT LIKE '71%'       -- Exclude surgical procedures
                AND other.PROC_CD NOT LIKE '0%'        -- Exclude diagnostic/consult codes
        )
)
-- Annual summary: visits, average cost, and potential savings if handled by primary care
SELECT 
    year,
    COUNT(*) AS pure_avoidable_visits,                    -- Total pure avoidable ER visits per year
    AVG(total_payer_cost) AS avg_payer_cost_per_visit,    -- Average cost per visit paid by insurer
    AVG(total_payer_cost) - 150 AS avg_savings_if_primary, -- Average savings per visit (assuming $150 primary care)
    COUNT(*) * (AVG(total_payer_cost) - 150) AS total_savings_estimate  -- Total estimated savings
FROM 
    clean_visits
GROUP BY 
    year
ORDER BY 
    year DESC;
