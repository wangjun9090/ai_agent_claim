-- Identify inpatient stays longer than 4 days, summing costs
SELECT 
    proc_cd,
    proc_desc,
    COUNT(DISTINCT patient_id) AS patient_count,
    AVG(dtl_ln_seq_num) AS avg_stay_days,
    SUM(dtl_ln_seq_num) AS total_stay_days,
    SUM(cost) AS total_cost
FROM 
    claims
WHERE 
    place_code = '21'
    AND dtl_ln_seq_num > 4
GROUP BY 
    proc_cd,
    proc_desc
ORDER BY 
    total_cost DESC
LIMIT 10;


-- Find duplicate drug claims within 30 days for the same patient
SELECT 
    a.proc_cd,
    a.proc_desc,
    a.NDC,
    COUNT(DISTINCT a.patient_id) AS patient_count,
    SUM(a.cost) AS total_cost
FROM 
    claims a
WHERE 
    a.revenue_code = '0250'
    AND EXISTS (
        SELECT 1 
        FROM claims b 
        WHERE b.patient_id = a.patient_id 
        AND b.NDC = a.NDC 
        AND ABS(DATEDIFF(day, b.service_date, a.service_date)) < 30 
        AND b.id != a.id
    )
GROUP BY 
    a.proc_cd,
    a.proc_desc,
    a.NDC
ORDER BY 
    total_cost DESC
-- Identify imaging procedures without fracture or stroke diagnosis
SELECT 
    proc_cd,
    proc_desc,
    COUNT(DISTINCT patient_id) AS patient_count,
    SUM(cost) AS total_cost
FROM 
    claims
WHERE 
    proc_cd LIKE '7%'
    AND diagnosis_code NOT LIKE 'S%'
    AND diagnosis_code NOT LIKE 'I6%'
GROUP BY 
    proc_cd,
    proc_desc
ORDER BY 
    total_cost DESC
LIMIT 10;
LIMIT 10;

-- Identify nursing claims with excessive hours or duplicates
SELECT 
    proc_cd,
    proc_desc,
    COUNT(DISTINCT patient_id) AS patient_count,
    AVG(claimed_hours) AS avg_hours,
    SUM(claimed_hours) AS total_hours,
    SUM(cost) AS total_cost
FROM 
    claims
WHERE 
    revenue_code = '0255'
    AND (
        claimed_hours > 4 -- Excessive hours threshold (adjust based on your data)
        OR EXISTS (
            SELECT 1
            FROM claims b
            WHERE b.patient_id = claims.patient_id
            AND b.service_date = claims.service_date
            AND b.revenue_code = '0255'
            AND b.id != claims.id
        )
    )
GROUP BY 
    proc_cd,
    proc_desc
ORDER BY 
    total_cost DESC
LIMIT 10;
