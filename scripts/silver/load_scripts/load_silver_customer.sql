
/*
=====================================================================
SILVER: CRM CUSTOMER INFORMATION
DEDUPLICATION AND CONFLICT DETECTION
=====================================================================

Policy:
1. Collapse exact duplicate business records.
2. Flag customer IDs with conflicting business records.
3. Exclude conflicting customer IDs from Silver.
4. Exclude and report NULL customer IDs.
5. Load only unambiguous customer records.

Exact comparison uses all seven business columns.
=====================================================================
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @load_time DATETIME2(3) = SYSUTCDATETIME();
DECLARE @batch_id BIGINT = NULL;


/*=============================================================
  1. REMOVE EXACT DUPLICATES IN A WORKING DATASET
=============================================================*/

DROP TABLE IF EXISTS #DistinctCustomers;
DROP TABLE IF EXISTS #CustomerQuality;

SELECT DISTINCT
    cust_id,
    cust_key,
    cust_firstname,
    cust_lastname,
    cust_material_status,
    cust_gndr,
    cust_create_date
INTO #DistinctCustomers
FROM Bronze.crm_cust_info;

SELECT * FROM #DistinctCustomers
/*=============================================================
  2. CLASSIFY CUSTOMER IDS
=============================================================*/

SELECT
    cust_id,
    COUNT(*) AS distinct_record_count
INTO #CustomerQuality
FROM #DistinctCustomers
WHERE cust_id IS NOT NULL
GROUP BY cust_id
HAVING COUNT(*) > 1;

SELECT * FROM #CustomerQuality
/*=============================================================
  3. REPORT EXACT DUPLICATES REMOVED
=============================================================*/

SELECT
    (SELECT COUNT_BIG(*)
     FROM Bronze.crm_cust_info) AS bronze_row_count,

    (SELECT COUNT_BIG(*)
     FROM #DistinctCustomers) AS distinct_business_row_count,

    (SELECT COUNT_BIG(*)
     FROM Bronze.crm_cust_info)
    -
    (SELECT COUNT_BIG(*)
     FROM #DistinctCustomers) AS exact_duplicate_rows_removed;


/*=============================================================
  4. FLAG CONFLICTING CUSTOMER IDS
=============================================================*/

SELECT
    d.cust_id,
    q.distinct_record_count,
    d.cust_key,
    d.cust_firstname,
    d.cust_lastname,
    d.cust_material_status,
    d.cust_gndr,
    d.cust_create_date
FROM #DistinctCustomers AS d
INNER JOIN #CustomerQuality AS q
    ON q.cust_id = d.cust_id
WHERE q.distinct_record_count > 1
ORDER BY d.cust_id, d.cust_create_date DESC;


/*=============================================================
  5. REPORT RECORDS WITH NULL CUSTOMER IDS
=============================================================*/

SELECT *
FROM #DistinctCustomers
WHERE cust_id IS NULL;


/*=============================================================
  6. LOAD ONLY UNAMBIGUOUS CUSTOMERS INTO SILVER
=============================================================*/

BEGIN TRY

    BEGIN TRANSACTION;

    TRUNCATE TABLE Silver.crm_cust_info;

    INSERT INTO Silver.crm_cust_info
    (
        cust_id,
        cust_key,
        cust_firstname,
        cust_lastname,
        cust_material_status,
        cust_gndr,
        cust_create_date,
        dwh_create_date,
        dwh_update_date,
        dwh_source,
        dwh_batch_id
    )
    SELECT
        d.cust_id,
        d.cust_key,

        NULLIF(TRIM(d.cust_firstname), ''),
        NULLIF(TRIM(d.cust_lastname), ''),

        CASE
            WHEN UPPER(TRIM(d.cust_material_status)) = 'S'
                THEN 'Single'
            WHEN UPPER(TRIM(d.cust_material_status)) = 'M'
                THEN 'Married'
            ELSE 'N/A'
        END,

        CASE
            WHEN UPPER(TRIM(d.cust_gndr)) = 'M'
                THEN 'Male'
            WHEN UPPER(TRIM(d.cust_gndr)) = 'F'
                THEN 'Female'
            ELSE 'N/A'
        END,

        d.cust_create_date,
        @load_time,
        @load_time,
        N'Bronze.crm_cust_info',
        @batch_id

    FROM #DistinctCustomers AS d
    INNER JOIN #CustomerQuality AS q
        ON q.cust_id = d.cust_id
    WHERE q.distinct_record_count = 1;


    /*=========================================================
      7. VALIDATE THE SILVER LOAD
    =========================================================*/

    IF EXISTS
    (
        SELECT 1
        FROM Silver.crm_cust_info
        WHERE cust_id IS NULL
    )
        THROW 50001, 'Silver contains NULL customer IDs.', 1;

    IF EXISTS
    (
        SELECT cust_id
        FROM Silver.crm_cust_info
        GROUP BY cust_id
        HAVING COUNT(*) > 1
    )
        THROW 50002, 'Silver contains duplicate customer IDs.', 1;

    IF EXISTS
    (
        SELECT 1
        FROM Silver.crm_cust_info
        WHERE cust_gndr IS NULL
           OR cust_gndr NOT IN ('Male', 'Female', 'N/A')
           OR cust_material_status IS NULL
           OR cust_material_status NOT IN ('Single', 'Married', 'N/A')
    )
        THROW 50003, 'Silver standardization validation failed.', 1;

    COMMIT TRANSACTION;

END TRY
BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;

END CATCH;


/*=============================================================
  8. LOAD SUMMARY
=============================================================*/

SELECT
    (SELECT COUNT_BIG(*)
     FROM Bronze.crm_cust_info) AS bronze_rows,

    (SELECT COUNT_BIG(*)
     FROM #DistinctCustomers) AS distinct_business_rows,

    (SELECT COUNT_BIG(*)
     FROM #CustomerQuality
     WHERE distinct_record_count > 1) AS conflicting_customer_ids,

    (SELECT COUNT_BIG(*)
     FROM #DistinctCustomers
     WHERE cust_id IS NULL) AS distinct_null_id_rows,

    (SELECT COUNT_BIG(*)
     FROM Silver.crm_cust_info) AS silver_rows;


/* Clean up temporary tables */

DROP TABLE IF EXISTS #CustomerQuality;
DROP TABLE IF EXISTS #DistinctCustomers;
