--1 Identify inpatient stays longer than 4 days, summing costs
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


--2 Find duplicate drug claims within 30 days for the same patient
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
--3 Identify imaging procedures without fracture or stroke diagnosis
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

--4  Identify nursing claims with excessive hours or duplicates

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


-- Identify upcoded inpatient procedures (e.g., 99233 without complex diagnoses)
SELECT 
    proc_cd,
    proc_desc,
    COUNT(DISTINCT patient_id) AS patient_count,
    SUM(cost) AS total_cost
FROM 
    claims
WHERE 
    place_code = '21'
    AND proc_cd IN ('99233', '99239') -- High-complexity hospital care or discharge
    AND diagnosis_code NOT LIKE 'I2%' -- Exclude complex heart conditions
    AND diagnosis_code NOT LIKE 'J96%' -- Exclude respiratory failure
    AND diagnosis_code NOT LIKE 'C%' -- Exclude cancer
GROUP BY 
    proc_cd,
    proc_desc
ORDER BY 
    total_cost DESC
LIMIT 10;

-- Identify high-cost inpatient drugs vs. standard rates
SELECT 
    NDC,
    proc_desc,
    COUNT(DISTINCT patient_id) AS patient_count,
    AVG(cost) AS avg_cost,
    SUM(cost) AS total_cost
FROM 
    claims
WHERE 
    place_code = '21'
    AND revenue_code = '0250'
    AND cost > (SELECT AVG(cost) * 2 FROM claims WHERE revenue_code = '0250' AND place_code != '21') -- Twice outpatient average
GROUP BY 
    NDC,
    proc_desc
ORDER BY 
    total_cost DESC
LIMIT 10;

-- Identify ER visits for minor conditions (low/moderate E/M) without justifying procedures
SELECT 
    claim_id,
    GROUP_CONCAT(DISTINCT proc_cd SEPARATOR ', ') AS proc_codes,
    GROUP_CONCAT(DISTINCT proc_desc SEPARATOR '; ') AS proc_descriptions,
    COUNT(DISTINCT membershipNumber) AS patient_count,
    AVG(GL_AMT) AS avg_cost,
    SUM(GL_AMT) AS total_cost
FROM 
    claims a
WHERE 
    PLSRV_CD = '23'
    AND EXISTS (
        -- Check for low/moderate E/M codes indicating potential minor issues
        SELECT 1 
        FROM claims b 
        WHERE b.claim_id = a.claim_id 
        AND b.proc_cd IN ('99281', '99282', '99283')
    )
    AND NOT EXISTS (
        -- Exclude claims with procedures justifying ER visit
        SELECT 1 
        FROM claims c 
        WHERE c.claim_id = a.claim_id 
        AND c.proc_cd IN (
            '99284', '99285',           -- High complexity E/M
            '99291', '99292',           -- Critical care
            '96360', '96361',           -- IV hydration
            '96365', '96366', '96367', '96368', -- IV infusion
            '96372', '96373', '96374', '96375', '96376', '96377', '96379', -- Therapeutic injections
            '12001', '12002', '12004', '12005', '12006', '12007', -- Simple laceration repair
            '10060', '10061',           -- Incision and drainage
            '29105', '29125', '29130', -- Splint application (arm, hand examples)
            '10120', '10121',           -- Foreign body removal
            '93000', '93005', '93010', -- EKG
            '71045', '71046', '71047', '71048', -- Chest X-ray
            '70450', '70460', '70470', -- CT head
            '94640',                    -- Nebulizer treatment
            '76705',                    -- Ultrasound abdomen limited
            '25500'                     -- Closed treatment of radial shaft fracture
        )
    )
    AND (
        -- Optional: Keyword match in proc_desc for minor conditions
        UPPER(proc_desc) LIKE '%HEADACHE%' 
        OR UPPER(proc_desc) LIKE '%HEAD PAIN%' 
        OR UPPER(proc_desc) LIKE '%COLD%' 
        OR UPPER(proc_desc) LIKE '%URI%' 
        OR UPPER(proc_desc) LIKE '%UPPER RESPIRATORY%' 
        OR UPPER(proc_desc) LIKE '%MINOR%' 
        OR UPPER(proc_desc) LIKE '%BRONCHITIS%' 
        OR UPPER(proc_desc) LIKE '%SPRAIN%'
    )
GROUP BY 
    claim_id
ORDER BY 
    total_cost DESC
LIMIT 10;


-- Identify ER visits for minor conditions (low/moderate E/M) without high-complexity justifying procedures
SELECT 
    a.claim_id,
    collect_list(a.proc_cd) AS proc_codes,
    collect_list(a.proc_desc) AS proc_descriptions,
    COUNT(DISTINCT a.membershipNumber) AS patient_count,
    AVG(a.GL_AMT) AS avg_cost,
    SUM(a.GL_AMT) AS total_cost
FROM 
    claims a
WHERE 
    a.PLSRV_CD = '23'
    AND EXISTS (
        -- Check for low/moderate E/M codes indicating potential minor issues
        SELECT 1 
        FROM claims b 
        WHERE b.claim_id = a.claim_id 
        AND b.proc_cd IN ('99281', '99282', '99283')
    )
    AND NOT EXISTS (
        -- Exclude claims with high-complexity E/M or critical care
        SELECT 1 
        FROM claims c 
        WHERE c.claim_id = a.claim_id 
        AND c.proc_cd IN (
            '99284', '99285', -- High complexity E/M
            '99291', '99292' -- Critical care
        )
    )
GROUP BY 
    a.claim_id
ORDER BY 
    total_cost DESC
LIMIT 100;
