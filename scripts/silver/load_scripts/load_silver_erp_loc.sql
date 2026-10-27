/*
===============================================================================
Script:      load_silver_erp_loc.sql
Layer:       Bronze -> Silver
Source:      Bronze.erp_loc_demo
Target:      Silver.erp_loc_demo
Load type:   Full refresh (TRUNCATE + INSERT inside a transaction)

Transformations:
  1. loc_cid   : remove hyphens (AW-00011000 -> AW00011000), strip CR/LF/spaces
  2. loc_cntry : strip CR/LF/spaces, standardise country names,
                 blank or NULL -> 'n/a'

Usage:
  EXEC Silver.load_erp_loc_demo;
===============================================================================
*/

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Silver')
    EXEC('CREATE SCHEMA Silver');
GO

IF OBJECT_ID('Silver.erp_loc_demo', 'U') IS NOT NULL
    DROP TABLE Silver.erp_loc_demo;
GO

CREATE TABLE Silver.erp_loc_demo (
    loc_cid         NVARCHAR(50)  NOT NULL,
    loc_cntry       NVARCHAR(50)  NOT NULL,
    dwh_create_date DATETIME2     NOT NULL DEFAULT SYSDATETIME()
);
GO

CREATE OR ALTER PROCEDURE Silver.load_erp_loc_demo
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @start_time DATETIME2 = SYSDATETIME(),
            @rows_in    INT,
            @rows_out   INT;

    BEGIN TRY
        PRINT '=====================================================';
        PRINT 'Loading Silver.erp_loc_demo';
        PRINT '=====================================================';

        SELECT @rows_in = COUNT(*) FROM Bronze.erp_loc_demo;

        BEGIN TRANSACTION;

            TRUNCATE TABLE Silver.erp_loc_demo;

            INSERT INTO Silver.erp_loc_demo (loc_cid, loc_cntry)
            SELECT
                REPLACE(c.cid_clean, '-', '') AS loc_cid,

                CASE
                    WHEN c.cntry_clean IS NULL OR c.cntry_clean = ''          THEN 'n/a'
                    WHEN UPPER(c.cntry_clean) IN ('US', 'USA', 'UNITED STATES') THEN 'United States'
                    WHEN UPPER(c.cntry_clean) IN ('UK', 'UNITED KINGDOM')       THEN 'United Kingdom'
                    WHEN UPPER(c.cntry_clean) IN ('DE', 'GERMANY')              THEN 'Germany'
                    ELSE c.cntry_clean
                END AS loc_cntry
            FROM Bronze.erp_loc_demo AS b
            CROSS APPLY (
                -- Strip CR / LF first, THEN trim. TRIM alone only removes spaces.
                SELECT
                    TRIM(REPLACE(REPLACE(b.loc_cid,   CHAR(13), ''), CHAR(10), '')) AS cid_clean,
                    TRIM(REPLACE(REPLACE(b.loc_cntry, CHAR(13), ''), CHAR(10), '')) AS cntry_clean
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

        PRINT 'ERROR loading Silver.erp_loc_demo';
        PRINT 'Message : ' + ERROR_MESSAGE();
        PRINT 'Number  : ' + CAST(ERROR_NUMBER() AS NVARCHAR(20));
        PRINT 'Line    : ' + CAST(ERROR_LINE()   AS NVARCHAR(20));

        THROW;
    END CATCH
END;
GO

EXEC Silver.load_erp_loc_demo;
GO

/*
-- Post-load validation (run manually)

-- Expect only: United States, United Kingdom, Germany, France, Australia, Canada, n/a
SELECT loc_cntry, COUNT(*) AS record_count
FROM Silver.erp_loc_demo
GROUP BY loc_cntry
ORDER BY record_count DESC;

-- Expect 0: no hidden CR/LF left in any text column
SELECT COUNT(*) AS dirty_rows
FROM Silver.erp_loc_demo
WHERE loc_cntry LIKE '%' + CHAR(13) + '%' OR loc_cntry LIKE '%' + CHAR(10) + '%'
   OR loc_cid   LIKE '%' + CHAR(13) + '%' OR loc_cid   LIKE '%' + CHAR(10) + '%';

-- Expect 0: no hyphens left in the key
SELECT COUNT(*) AS hyphen_rows FROM Silver.erp_loc_demo WHERE loc_cid LIKE '%-%';

-- Row counts should match
SELECT
    (SELECT COUNT(*) FROM Bronze.erp_loc_demo) AS bronze_rows,
    (SELECT COUNT(*) FROM Silver.erp_loc_demo) AS silver_rows;
*/