
/*
=====================================================================
SILVER: CRM PRODUCT INFORMATION
DEDUPLICATION, STANDARDIZATION AND DATA QUALITY VALIDATION
=====================================================================

POLICY:
1. Remove exact duplicate source records.
2. Report NULL product IDs.
3. Flag product IDs with conflicting business records.
4. Exclude ambiguous product IDs from Silver.
5. Split prod_key into category_id and product_key.
6. Validate category_id against Bronze.erp_prod_demo.
7. Standardize product names, costs and product lines.
8. Derive product_end_date from the next product version's start date.
9. Load transactionally and validate the Silver result.

ASSUMPTIONS:
- Bronze date columns are convertible to DATE.
- Silver.crm_prod_info contains the transformed columns below,
  plus the four DWH audit columns.
- Invalid category references are excluded from Silver.
=====================================================================
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @load_time DATETIME2(3) = SYSUTCDATETIME();
DECLARE @batch_id BIGINT = NULL;

DROP TABLE IF EXISTS #DistinctProducts;
DROP TABLE IF EXISTS #ProductQuality;
DROP TABLE IF EXISTS #ValidProducts;


/*=============================================================
  1. REMOVE EXACT DUPLICATE SOURCE RECORDS
=============================================================*/

SELECT DISTINCT
    prod_id,
    prod_key,
    prod_name,
    prod_cost,
    prod_line,
    prod_start_date,
    prod_end_date
INTO #DistinctProducts
FROM Bronze.crm_prod_info;


/*=============================================================
  2. CLASSIFY PRODUCT IDs
=============================================================*/

SELECT
    prod_id,
    COUNT_BIG(*) AS distinct_record_count
INTO #ProductQuality
FROM #DistinctProducts
WHERE prod_id IS NOT NULL
GROUP BY prod_id;


/*=============================================================
  3. REPORT EXACT DUPLICATES REMOVED
=============================================================*/

SELECT
    (SELECT COUNT_BIG(*)
     FROM Bronze.crm_prod_info) AS bronze_row_count,

    (SELECT COUNT_BIG(*)
     FROM #DistinctProducts) AS distinct_business_row_count,

    (SELECT COUNT_BIG(*)
     FROM Bronze.crm_prod_info)
    -
    (SELECT COUNT_BIG(*)
     FROM #DistinctProducts) AS exact_duplicate_rows_removed;


/*=============================================================
  4. REPORT CONFLICTING PRODUCT IDS
=============================================================*/

SELECT
    d.prod_id,
    q.distinct_record_count,
    d.prod_key,
    d.prod_name,
    d.prod_cost,
    d.prod_line,
    d.prod_start_date,
    d.prod_end_date
FROM #DistinctProducts AS d
INNER JOIN #ProductQuality AS q
    ON q.prod_id = d.prod_id
WHERE q.distinct_record_count > 1
ORDER BY d.prod_id;


/*=============================================================
  5. REPORT NULL PRODUCT IDS
=============================================================*/

SELECT *
FROM #DistinctProducts
WHERE prod_id IS NULL;


/*=============================================================
  6. PREPARE VALID, TRANSFORMED PRODUCTS

  - Keep only unambiguous, non-NULL product IDs.
  - Extract category and product keys.
  - Clean product names and costs.
  - Standardize product lines.
  - Derive end dates using the next start date for each product key.
=============================================================*/

;WITH UnambiguousProducts AS
(
    SELECT d.*
    FROM #DistinctProducts AS d
    INNER JOIN #ProductQuality AS q
        ON q.prod_id = d.prod_id
    WHERE q.distinct_record_count = 1
      AND d.prod_id IS NOT NULL
),
ParsedProducts AS
(
    SELECT
        prod_id,

        REPLACE(
            SUBSTRING(prod_key, 1, 5),
            '-',
            '_'
        ) AS category_id,

        NULLIF(
            TRIM(SUBSTRING(prod_key, 7, LEN(prod_key))),
            ''
        ) AS product_key,

        NULLIF(TRIM(prod_name), '') AS product_name,

        prod_cost,

        CASE UPPER(TRIM(prod_line))
            WHEN 'M' THEN 'Mountain'
            WHEN 'R' THEN 'Road'
            WHEN 'S' THEN 'Other Sales'
            WHEN 'T' THEN 'Touring'
            ELSE 'N/A'
        END AS product_line,

        TRY_CONVERT(DATE, prod_start_date) AS product_start_date,

        TRY_CONVERT(DATE, prod_end_date) AS source_product_end_date

    FROM UnambiguousProducts
),
ProductsWithNextStart AS
(
    SELECT
        p.*,

        LEAD(product_start_date) OVER
        (
            PARTITION BY product_key
            ORDER BY product_start_date, prod_id
        ) AS next_product_start_date

    FROM ParsedProducts AS p
)
SELECT
    p.prod_id,
    p.category_id,
    p.product_key,
    p.product_name,

    ISNULL(p.prod_cost, 0) AS product_cost,

    p.product_line,
    p.product_start_date,

    CASE
        WHEN p.next_product_start_date IS NOT NULL
            THEN DATEADD(
                DAY,
                -1,
                p.next_product_start_date
            )
        ELSE NULL
    END AS product_end_date

INTO #ValidProducts
FROM ProductsWithNextStart AS p;


/*=============================================================
  7. REPORT CATEGORY REFERENCES THAT DO NOT EXIST
=============================================================*/

SELECT
    p.prod_id,
    p.category_id,
    p.product_key,
    p.product_name
FROM #ValidProducts AS p
WHERE p.category_id IS NULL
   OR NOT EXISTS
   (
       SELECT 1
       FROM Bronze.erp_prod_demo AS e
       WHERE e.prod_id = p.category_id
   )
ORDER BY p.prod_id;


/*=============================================================
  8. REPORT OTHER TRANSFORMATION ISSUES
=============================================================*/

-- Missing product names
SELECT *
FROM #ValidProducts
WHERE product_name IS NULL;

-- NULL or negative source costs
SELECT
    prod_id,
    prod_name,
    prod_cost
FROM #DistinctProducts
WHERE prod_cost IS NULL
   OR prod_cost < 0;

-- Invalid or missing start dates
SELECT *
FROM #ValidProducts
WHERE product_start_date IS NULL;

-- Invalid date ranges after end-date derivation
SELECT *
FROM #ValidProducts
WHERE product_end_date < product_start_date;


/*=============================================================
  9. LOAD SILVER TRANSACTIONALLY
=============================================================*/

BEGIN TRY

    BEGIN TRANSACTION;

    TRUNCATE TABLE Silver.crm_prod_info;

    INSERT INTO Silver.crm_prod_info
    (
        prod_id,
        category_id,
        product_key,
        product_name,
        product_cost,
        product_line,
        product_start_date,
        product_end_date,
        dwh_create_date,
        dwh_update_date,
        dwh_source,
        dwh_batch_id
    )
    SELECT
        p.prod_id,
        p.category_id,
        p.product_key,
        p.product_name,
        p.product_cost,
        p.product_line,
        p.product_start_date,
        p.product_end_date,

        @load_time,
        @load_time,
        N'Bronze.crm_prod_info',
        @batch_id

    FROM #ValidProducts AS p

    WHERE p.category_id IS NOT NULL

      AND EXISTS
      (
          SELECT 1
          FROM Bronze.erp_prod_demo AS e
          WHERE e.prod_id = p.category_id
      )

      AND p.product_start_date IS NOT NULL

      AND (
          p.product_end_date IS NULL
          OR p.product_end_date >= p.product_start_date
      );


    /*=========================================================
      10. VALIDATE THE SILVER LOAD
    =========================================================*/

    -- Product IDs must be unique and non-NULL.
    IF EXISTS
    (
        SELECT 1
        FROM Silver.crm_prod_info
        WHERE prod_id IS NULL
    )
        THROW 50011, 'Silver contains NULL product IDs.', 1;

    IF EXISTS
    (
        SELECT prod_id
        FROM Silver.crm_prod_info
        GROUP BY prod_id
        HAVING COUNT_BIG(*) > 1
    )
        THROW 50012, 'Silver contains duplicate product IDs.', 1;


    -- Product categories must exist in the ERP reference table.
    IF EXISTS
    (
        SELECT 1
        FROM Silver.crm_prod_info AS s
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM Bronze.erp_prod_demo AS e
            WHERE e.prod_id = s.category_id
        )
    )
        THROW 50013, 'Silver contains invalid product categories.', 1;


    -- Validate costs, names, start dates and date ranges.
    IF EXISTS
    (
        SELECT 1
        FROM Silver.crm_prod_info
        WHERE product_cost < 0
           OR product_name IS NULL
           OR product_start_date IS NULL
           OR (
               product_end_date IS NOT NULL
               AND product_end_date < product_start_date
           )
    )
        THROW 50014, 'Silver product data quality validation failed.', 1;


    -- Product-line values must be standardized.
    IF EXISTS
    (
        SELECT 1
        FROM Silver.crm_prod_info
        WHERE product_line NOT IN
        (
            'Mountain',
            'Road',
            'Other Sales',
            'Touring',
            'N/A'
        )
        OR product_line IS NULL
    )
        THROW 50015, 'Silver product-line validation failed.', 1;


    COMMIT TRANSACTION;

END TRY
BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;

END CATCH;


/*=============================================================
  11. LOAD SUMMARY
=============================================================*/

SELECT
    (SELECT COUNT_BIG(*)
     FROM Bronze.crm_prod_info) AS bronze_rows,

    (SELECT COUNT_BIG(*)
     FROM #DistinctProducts) AS distinct_business_rows,

    (SELECT COUNT_BIG(*)
     FROM #ProductQuality
     WHERE distinct_record_count > 1) AS conflicting_product_ids,

    (SELECT COUNT_BIG(*)
     FROM #DistinctProducts
     WHERE prod_id IS NULL) AS null_product_id_rows,

    (SELECT COUNT_BIG(*)
     FROM #ValidProducts) AS unambiguous_products_before_validation,

    (SELECT COUNT_BIG(*)
     FROM #ValidProducts AS p
     WHERE p.category_id IS NOT NULL
       AND EXISTS
       (
           SELECT 1
           FROM Bronze.erp_prod_demo AS e
           WHERE e.prod_id = p.category_id
       )
       AND p.product_start_date IS NOT NULL
       AND (
           p.product_end_date IS NULL
           OR p.product_end_date >= p.product_start_date
       )) AS expected_silver_rows,

    (SELECT COUNT_BIG(*)
     FROM Silver.crm_prod_info) AS actual_silver_rows;


/*=============================================================
  12. CLEAN UP TEMPORARY TABLES
=============================================================*/

DROP TABLE IF EXISTS #ValidProducts;
DROP TABLE IF EXISTS #ProductQuality;
DROP TABLE IF EXISTS #DistinctProducts;
