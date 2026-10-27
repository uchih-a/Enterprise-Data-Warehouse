--customer Extra information 
SELECT * FROM Bronze.erp_cust_demo;
-- Clean the cust_cid Handling the Extra chatacters NAS
SELECT 
    CASE 
        WHEN cust_cid LIKE 'NAS%' THEN SUBSTRING(cust_cid, 4, LEN(cust_cid)) 
        ELSE cust_cid
    END AS cust_id
FROM Bronze.erp_cust_demo;
-- checking impossible dates
SELECT cust_bdate FROM Bronze.erp_cust_demo
WHERE cust_bdate > GETDATE();

-- Check distinct genders 
SELECT DISTINCT cust_gender FROM Bronze.erp_cust_demo;
SELECT cust_gender FROM Bronze.erp_cust_demo;


-- =========================================================
-- SILVER LAYER: CUSTOMER EXTRA INFORMATION
-- Source: Bronze.erp_cust_demo
-- =========================================================


SELECT
    cust_gender,
    COUNT(*) AS record_count
FROM Bronze.erp_cust_demo
GROUP BY cust_gender
ORDER BY record_count DESC;


-- Final Clean and Transformation
SELECT 
    CASE 
        WHEN cust_cid LIKE 'NAS%' THEN SUBSTRING(cust_cid, 4, LEN(cust_cid)) 
        ELSE cust_cid
    END AS cust_id,
    CASE 
        WHEN cust_bdate > GETDATE() THEN NULL
        ELSE cust_bdate
    END AS cust_bdate,
    CASE 
        WHEN UPPER(TRIM(cust_gender)) IN ('M', 'MALE') THEN 'Male'
        WHEN UPPER(TRIM(cust_gender)) IN ('F', 'Female') THEN 'Female'
        ELSE 'n/a'
    END AS cust_gender
FROM Bronze.erp_cust_demo;

-- Final Clean and Transformation
SELECT 
    CASE 
        WHEN cust_cid LIKE 'NAS%' THEN SUBSTRING(cust_cid, 4, LEN(cust_cid)) 
        ELSE cust_cid
    END AS cust_id,
    CASE 
        WHEN cust_bdate > GETDATE() THEN NULL
        ELSE cust_bdate
    END AS cust_bdate,
    CASE 
        WHEN UPPER(TRIM(cust_gender)) IN ('M', 'MALE') THEN 'Male'
        WHEN UPPER(TRIM(cust_gender)) IN ('F', 'Female') THEN 'Female'
        ELSE 'n/a'
    END AS cust_gender
FROM Bronze.erp_cust_demo;