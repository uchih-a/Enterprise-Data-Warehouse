/*
===============================================================================
Script:      load_silver_erp_cust_demo.sql
Layer:       Bronze -> Silver
Source:      Bronze.erp_cust_demo
Target:      Silver.erp_cust_demo
Load type:   Full refresh (TRUNCATE + INSERT, wrapped in a transaction)

Transformations:
  1. cust_id     : strip the 'NAS' prefix from cust_cid; trim whitespace/CR/LF
  2. cust_bdate  : future birth dates are set to NULL
  3. cust_gender : strip CR/LF + spaces, normalise to 'Male' / 'Female' / 'n/a'

Usage:
  EXEC Silver.load_erp_cust_demo;
===============================================================================
*/

-- ============================================================================
-- 1. Make sure the Silver schema exists
-- ============================================================================
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Silver')
    EXEC('CREATE SCHEMA Silver');
GO

-- ============================================================================
-- 2. Silver table (adjust data types to match your Bronze table if needed)
-- ============================================================================
IF OBJECT_ID('Silver.erp_cust_demo', 'U') IS NOT NULL
    DROP TABLE Silver.erp_cust_demo;
GO

CREATE TABLE Silver.erp_cust_demo (
    cust_id         NVARCHAR(50)  NOT NULL,
    cust_bdate      DATE          NULL,
    cust_gender     NVARCHAR(10)  NOT NULL,
    dwh_create_date DATETIME2     NOT NULL DEFAULT SYSDATETIME()   -- audit column
);
GO

-- ============================================================================
-- 3. Load procedure
-- ============================================================================
CREATE OR ALTER PROCEDURE Silver.load_erp_cust_demo
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;   -- any runtime error rolls back the whole transaction

    DECLARE @start_time DATETIME2 = SYSDATETIME(),
            @rows_in    INT,
            @rows_out   INT;

    BEGIN TRY
        PRINT '=====================================================';
        PRINT 'Loading Silver.erp_cust_demo';
        PRINT '=====================================================';

        SELECT @rows_in = COUNT(*) FROM Bronze.erp_cust_demo;

        BEGIN TRANSACTION;

            -- Full refresh. TRUNCATE is transactional in SQL Server, so a
            -- failed insert will not leave the Silver table empty.
            TRUNCATE TABLE Silver.erp_cust_demo;

            INSERT INTO Silver.erp_cust_demo (cust_id, cust_bdate, cust_gender)
            SELECT
                -- Remove 'NAS' prefix, and any stray CR/LF/spaces
                CASE
                    WHEN c.cust_cid_clean LIKE 'NAS%'
                        THEN SUBSTRING(c.cust_cid_clean, 4, LEN(c.cust_cid_clean))
                    ELSE c.cust_cid_clean
                END AS cust_id,

                -- Birth dates in the future are invalid
                CASE
                    WHEN b.cust_bdate > CAST(GETDATE() AS DATE) THEN NULL
                    ELSE b.cust_bdate
                END AS cust_bdate,

                -- Standardise gender
                CASE
                    WHEN UPPER(c.cust_gender_clean) IN ('M', 'MALE')   THEN 'Male'
                    WHEN UPPER(c.cust_gender_clean) IN ('F', 'FEMALE') THEN 'Female'
                    ELSE 'n/a'
                END AS cust_gender
            FROM Bronze.erp_cust_demo AS b
            CROSS APPLY (
                -- Clean the text columns once, reuse above
                SELECT
                    TRIM(REPLACE(REPLACE(b.cust_cid,    CHAR(13), ''), CHAR(10), '')) AS cust_cid_clean,
                    TRIM(REPLACE(REPLACE(b.cust_gender, CHAR(13), ''), CHAR(10), '')) AS cust_gender_clean
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

        PRINT '=====================================================';
        PRINT 'ERROR loading Silver.erp_cust_demo';
        PRINT 'Message : ' + ERROR_MESSAGE();
        PRINT 'Number  : ' + CAST(ERROR_NUMBER() AS NVARCHAR(20));
        PRINT 'Line    : ' + CAST(ERROR_LINE()   AS NVARCHAR(20));
        PRINT '=====================================================';

        THROW;   -- re-raise so schedulers / pipelines see the failure
    END CATCH
END;
GO

-- ============================================================================
-- 4. Run the load
-- ============================================================================
EXEC Silver.load_erp_cust_demo;
GO

-- ============================================================================
-- 5. Post-load validation (run manually)
-- ============================================================================
/*
-- Only Male / Female / n/a should appear
SELECT cust_gender, COUNT(*) AS record_count
FROM Silver.erp_cust_demo
GROUP BY cust_gender
ORDER BY record_count DESC;

-- No NAS prefixes should remain
SELECT COUNT(*) AS nas_left FROM Silver.erp_cust_demo WHERE cust_id LIKE 'NAS%';

-- No future birth dates should remain
SELECT COUNT(*) AS future_dates FROM Silver.erp_cust_demo WHERE cust_bdate > GETDATE();

-- Row counts should match
SELECT
    (SELECT COUNT(*) FROM Bronze.erp_cust_demo) AS bronze_rows,
    (SELECT COUNT(*) FROM Silver.erp_cust_demo) AS silver_rows;
*/