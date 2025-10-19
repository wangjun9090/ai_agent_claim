-- Total unnecessary night ER visits - clean count with metrics
-- Total visits, unique people, and repeat visitors (2+ visits)
SELECT 
    COUNT(*) AS total_night_visits,                    -- Total visit count
    COUNT(DISTINCT MembershipNumber) AS total_people,  -- Unique people
    COUNT(CASE WHEN visits_per_person >= 2 THEN 1 END) AS repeat_visitors -- People with 2+ visits
FROM (
    -- Calculate visits per person
    SELECT 
        MembershipNumber, 
        COUNT(*) AS visits_per_person
    FROM (
        -- Identify individual night-time low-acuity ER visits
        SELECT 
            MembershipNumber, 
            PROC_DT
        FROM hive_metastore.off_orig.claims_member
        WHERE 
            -- Night/early morning: 8 PM to 8 AM
            (HOUR(PROC_DT) >= 20 OR HOUR(PROC_DT) < 8)
            -- Low-acuity procedures (not true emergencies)
            AND (
                PROC_CD = 'J3420'           -- Vitamin B12 injection
                OR PROC_CD = 'J3410'        -- Vitamin B1 injection  
                OR PROC_CD LIKE '96372%'    -- Subcutaneous injection
                OR PROC_CD LIKE '96374%'    -- IV push medication (hydration)
                OR PROC_CD LIKE 'J0702%'    -- Magnesium sulfate injection
                OR PROC_CD = '99284'        -- Level 4 ER visit (moderate acuity)
            )
        GROUP BY MembershipNumber, PROC_DT             -- Each date = 1 visit
    ) all_visits
    GROUP BY MembershipNumber                      -- Aggregate visits per person
) summary;
