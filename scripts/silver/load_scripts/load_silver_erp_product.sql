/*
===============================================================================
Script:      load_silver_erp_product.sql
Layer:       Bronze -> Silver
Source:      Bronze.erp_prod_demo
Target:      Silver.erp_prod_demo
Load type:   Full refresh (TRUNCATE + INSERT inside a transaction)

Transformations:
  - Strip hidden CR/LF characters and leading/trailing spaces from every
    text column (TRIM alone only removes spaces, not CHAR(13) / CHAR(10)).
  - Descriptive columns that are blank or NULL become 'n/a'.
  - prod_id is a key, so it is cleaned but never defaulted.

Usage:
  EXEC Silver.load_erp_prod_demo;
===============================================================================
*/

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Silver')
    EXEC('CREATE SCHEMA Silver');
GO

IF OBJECT_ID('Silver.erp_prod_demo', 'U') IS NOT NULL
    DROP TABLE Silver.erp_prod_demo;
GO

-- Adjust data types to match your Bronze table if they differ
CREATE TABLE Silver.erp_prod_demo (
    prod_id           NVARCHAR(50)  NOT NULL,
    prod_category     NVARCHAR(100) NOT NULL,
    prod_subcategory  NVARCHAR(100) NOT NULL,
    prod_maintainance NVARCHAR(50)  NOT NULL,
    dwh_create_date   DATETIME2     NOT NULL DEFAULT SYSDATETIME()
);
GO

CREATE OR ALTER PROCEDURE Silver.load_erp_prod_demo
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @start_time DATETIME2 = SYSDATETIME(),
            @rows_in    INT,
            @rows_out   INT;

    BEGIN TRY
        PRINT '=====================================================';
        PRINT 'Loading Silver.erp_prod_demo';
        PRINT '=====================================================';

        SELECT @rows_in = COUNT(*) FROM Bronze.erp_prod_demo;

        BEGIN TRANSACTION;

            TRUNCATE TABLE Silver.erp_prod_demo;

            INSERT INTO Silver.erp_prod_demo
                (prod_id, prod_category, prod_subcategory, prod_maintainance)
            SELECT
                c.prod_id_clean,
                ISNULL(NULLIF(c.category_clean,    ''), 'n/a'),
                ISNULL(NULLIF(c.subcategory_clean, ''), 'n/a'),
                ISNULL(NULLIF(c.maintenance_clean, ''), 'n/a')
            FROM Bronze.erp_prod_demo AS b
            CROSS APPLY (
                -- Strip CR / LF first, THEN trim
                SELECT
                    TRIM(REPLACE(REPLACE(b.prod_id,           CHAR(13), ''), CHAR(10), '')) AS prod_id_clean,
                    TRIM(REPLACE(REPLACE(b.prod_category,     CHAR(13), ''), CHAR(10), '')) AS category_clean,
                    TRIM(REPLACE(REPLACE(b.prod_subcategory,  CHAR(13), ''), CHAR(10), '')) AS subcategory_clean,
                    TRIM(REPLACE(REPLACE(b.prod_maintainance, CHAR(13), ''), CHAR(10), '')) AS maintenance_clean
            ) AS c;

            SET @rows_out = @@ROWCOUNT;

        COMMIT TRANSACTION;

        PRINT 'Rows read from Bronze : ' + CAST(@rows_in  AS NVARCHAR(20));
        PRINT 'Rows loaded to Silver : ' + CAST(@rows_out AS NVARCHAR(20));
        PRINT 'Duration (seconds)    : '
              + CAST(DATEDIFF(SECOND, @start_time, SYSDATETIME()) AS NVARCHAR(20));
        PRINT '=====================================================';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        PRINT 'ERROR loading Silver.erp_prod_demo';
        PRINT 'Message : ' + ERROR_MESSAGE();
        PRINT 'Number  : ' + CAST(ERROR_NUMBER() AS NVARCHAR(20));
        PRINT 'Line    : ' + CAST(ERROR_LINE()   AS NVARCHAR(20));

        THROW;
    END CATCH
END;
GO

EXEC Silver.load_erp_prod_demo;
GO

/*
-- Post-load validation (run manually)

-- Expect: only 'Yes' and 'No' (plus 'n/a' if blanks existed)
SELECT prod_maintainance, COUNT(*) AS record_count
FROM Silver.erp_prod_demo
GROUP BY prod_maintainance;

-- Expect 0: no hidden CR/LF left in any column
SELECT COUNT(*) AS dirty_rows
FROM Silver.erp_prod_demo
WHERE CONCAT(prod_id, prod_category, prod_subcategory, prod_maintainance) LIKE '%' + CHAR(13) + '%'
   OR CONCAT(prod_id, prod_category, prod_subcategory, prod_maintainance) LIKE '%' + CHAR(10) + '%';

-- Expect 0: prod_id must be unique
SELECT prod_id, COUNT(*) AS n
FROM Silver.erp_prod_demo
GROUP BY prod_id HAVING COUNT(*) > 1;

-- Relationship check to the CRM product table (should be 0 if the keys align)
SELECT e.prod_id
FROM Silver.erp_prod_demo e
WHERE NOT EXISTS (SELECT 1 FROM Silver.crm_prod_info p WHERE p.category_id = e.prod_id);

-- Row counts should match
SELECT
    (SELECT COUNT(*) FROM Bronze.erp_prod_demo) AS bronze_rows,
    (SELECT COUNT(*) FROM Silver.erp_prod_demo) AS silver_rows;
*/