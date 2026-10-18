/*
=============================================================
BRONZE LAYER — BULK LOAD
=============================================================
Purpose  : Full reload of all Bronze source tables
Sources  : CRM  → /var/opt/mssql/data/source_crm/
           ERP  → /var/opt/mssql/data/source_erp/
Pattern  : TRUNCATE → BULK INSERT per table
Author   : Mutsala
=============================================================
*/


/*
=============================================================
INITIALISE RUN
=============================================================
*/

DECLARE @batch_start   DATETIME2(3) = SYSUTCDATETIME();
DECLARE @step_start    DATETIME2(3);
DECLARE @rows_loaded   INT;

PRINT '============================================================';
PRINT 'BRONZE LAYER LOAD — STARTED: ' + CONVERT(NVARCHAR, SYSUTCDATETIME(), 120);
PRINT '============================================================';


/*
=============================================================
1. CRM SOURCE TABLES
=============================================================
*/

PRINT '';
PRINT '------------------------------------------------------------';
PRINT 'SECTION 1 OF 2 — CRM';
PRINT '------------------------------------------------------------';


/* ── 1.1  CRM CUSTOMER INFORMATION ─────────────────────────── */

BEGIN TRY

    SET @step_start = SYSUTCDATETIME();
    PRINT '';
    PRINT '  [1.1] Bronze.crm_cust_info — loading...';

    TRUNCATE TABLE Bronze.crm_cust_info;

    BULK INSERT Bronze.crm_cust_info
    FROM '/var/opt/mssql/data/source_crm/cust_info.csv'
    WITH
    (
        FIRSTROW        = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR   = '0x0a',
        TABLOCK
    );

    SET @rows_loaded = ROWCOUNT_BIG();

    PRINT '  [1.1] Rows loaded : ' + CAST(@rows_loaded AS NVARCHAR);
    PRINT '  [1.1] Duration    : '
        + CAST(DATEDIFF(MILLISECOND, @step_start, SYSUTCDATETIME()) AS NVARCHAR)
        + ' ms';
    PRINT '  [1.1] Status      : SUCCESS';

END TRY
BEGIN CATCH

    PRINT '  [1.1] Status      : *** FAILED ***';
    PRINT '  [1.1] Error       : ' + ERROR_MESSAGE();
    PRINT '  [1.1] Severity    : ' + CAST(ERROR_SEVERITY() AS NVARCHAR);
    PRINT '  [1.1] State       : ' + CAST(ERROR_STATE()    AS NVARCHAR);
    PRINT '  [1.1] Line        : ' + CAST(ERROR_LINE()     AS NVARCHAR);

END CATCH;
GO


/* ── 1.2  CRM PRODUCT INFORMATION ──────────────────────────── */

DECLARE @step_start DATETIME2(3) = SYSUTCDATETIME();
DECLARE @rows_loaded INT;

BEGIN TRY

    PRINT '';
    PRINT '  [1.2] Bronze.crm_prod_info — loading...';

    TRUNCATE TABLE Bronze.crm_prod_info;

    BULK INSERT Bronze.crm_prod_info
    FROM '/var/opt/mssql/data/source_crm/prd_info.csv'
    WITH
    (
        FIRSTROW        = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR   = '0x0a',
        TABLOCK
    );

    SET @rows_loaded = ROWCOUNT_BIG();

    PRINT '  [1.2] Rows loaded : ' + CAST(@rows_loaded AS NVARCHAR);
    PRINT '  [1.2] Duration    : '
        + CAST(DATEDIFF(MILLISECOND, @step_start, SYSUTCDATETIME()) AS NVARCHAR)
        + ' ms';
    PRINT '  [1.2] Status      : SUCCESS';

END TRY
BEGIN CATCH

    PRINT '  [1.2] Status      : *** FAILED ***';
    PRINT '  [1.2] Error       : ' + ERROR_MESSAGE();
    PRINT '  [1.2] Severity    : ' + CAST(ERROR_SEVERITY() AS NVARCHAR);
    PRINT '  [1.2] State       : ' + CAST(ERROR_STATE()    AS NVARCHAR);
    PRINT '  [1.2] Line        : ' + CAST(ERROR_LINE()     AS NVARCHAR);

END CATCH;
GO


/* ── 1.3  CRM SALES DETAILS ─────────────────────────────────── */

DECLARE @step_start DATETIME2(3) = SYSUTCDATETIME();
DECLARE @rows_loaded INT;

BEGIN TRY

    PRINT '';
    PRINT '  [1.3] Bronze.crm_sales_details — loading...';

    TRUNCATE TABLE Bronze.crm_sales_details;

    BULK INSERT Bronze.crm_sales_details
    FROM '/var/opt/mssql/data/source_crm/sales_details.csv'
    WITH
    (
        FIRSTROW        = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR   = '0x0a',
        TABLOCK
    );

    SET @rows_loaded = ROWCOUNT_BIG();

    PRINT '  [1.3] Rows loaded : ' + CAST(@rows_loaded AS NVARCHAR);
    PRINT '  [1.3] Duration    : '
        + CAST(DATEDIFF(MILLISECOND, @step_start, SYSUTCDATETIME()) AS NVARCHAR)
        + ' ms';
    PRINT '  [1.3] Status      : SUCCESS';

END TRY
BEGIN CATCH

    PRINT '  [1.3] Status      : *** FAILED ***';
    PRINT '  [1.3] Error       : ' + ERROR_MESSAGE();
    PRINT '  [1.3] Severity    : ' + CAST(ERROR_SEVERITY() AS NVARCHAR);
    PRINT '  [1.3] State       : ' + CAST(ERROR_STATE()    AS NVARCHAR);
    PRINT '  [1.3] Line        : ' + CAST(ERROR_LINE()     AS NVARCHAR);

END CATCH;
GO


/*
=============================================================
2. ERP SOURCE TABLES
=============================================================
*/

PRINT '';
PRINT '------------------------------------------------------------';
PRINT 'SECTION 2 OF 2 — ERP';
PRINT '------------------------------------------------------------';


/* ── 2.1  ERP CUSTOMER DEMOGRAPHICS ────────────────────────── */

DECLARE @step_start DATETIME2(3) = SYSUTCDATETIME();
DECLARE @rows_loaded INT;

BEGIN TRY

    PRINT '';
    PRINT '  [2.1] Bronze.erp_cust_demo — loading...';

    TRUNCATE TABLE Bronze.erp_cust_demo;

    BULK INSERT Bronze.erp_cust_demo
    FROM '/var/opt/mssql/data/source_erp/CUST_AZ12.csv'
    WITH
    (
        FIRSTROW        = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR   = '0x0a',
        TABLOCK
    );

    SET @rows_loaded = ROWCOUNT_BIG();

    PRINT '  [2.1] Rows loaded : ' + CAST(@rows_loaded AS NVARCHAR);
    PRINT '  [2.1] Duration    : '
        + CAST(DATEDIFF(MILLISECOND, @step_start, SYSUTCDATETIME()) AS NVARCHAR)
        + ' ms';
    PRINT '  [2.1] Status      : SUCCESS';

END TRY
BEGIN CATCH

    PRINT '  [2.1] Status      : *** FAILED ***';
    PRINT '  [2.1] Error       : ' + ERROR_MESSAGE();
    PRINT '  [2.1] Severity    : ' + CAST(ERROR_SEVERITY() AS NVARCHAR);
    PRINT '  [2.1] State       : ' + CAST(ERROR_STATE()    AS NVARCHAR);
    PRINT '  [2.1] Line        : ' + CAST(ERROR_LINE()     AS NVARCHAR);

END CATCH;
GO


/* ── 2.2  ERP CUSTOMER LOCATION ─────────────────────────────── */

DECLARE @step_start DATETIME2(3) = SYSUTCDATETIME();
DECLARE @rows_loaded INT;

BEGIN TRY

    PRINT '';
    PRINT '  [2.2] Bronze.erp_loc_demo — loading...';

    TRUNCATE TABLE Bronze.erp_loc_demo;

    BULK INSERT Bronze.erp_loc_demo
    FROM '/var/opt/mssql/data/source_erp/LOC_A101.csv'
    WITH
    (
        FIRSTROW        = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR   = '0x0a',
        TABLOCK
    );

    SET @rows_loaded = ROWCOUNT_BIG();

    PRINT '  [2.2] Rows loaded : ' + CAST(@rows_loaded AS NVARCHAR);
    PRINT '  [2.2] Duration    : '
        + CAST(DATEDIFF(MILLISECOND, @step_start, SYSUTCDATETIME()) AS NVARCHAR)
        + ' ms';
    PRINT '  [2.2] Status      : SUCCESS';

END TRY
BEGIN CATCH

    PRINT '  [2.2] Status      : *** FAILED ***';
    PRINT '  [2.2] Error       : ' + ERROR_MESSAGE();
    PRINT '  [2.2] Severity    : ' + CAST(ERROR_SEVERITY() AS NVARCHAR);
    PRINT '  [2.2] State       : ' + CAST(ERROR_STATE()    AS NVARCHAR);
    PRINT '  [2.2] Line        : ' + CAST(ERROR_LINE()     AS NVARCHAR);

END CATCH;
GO


/* ── 2.3  ERP PRODUCT INFORMATION ──────────────────────────── */

DECLARE @step_start  DATETIME2(3) = SYSUTCDATETIME();
DECLARE @batch_start DATETIME2(3);     -- re-declared here; value printed below
DECLARE @rows_loaded INT;

BEGIN TRY

    PRINT '';
    PRINT '  [2.3] Bronze.erp_prod_demo — loading...';

    TRUNCATE TABLE Bronze.erp_prod_demo;

    BULK INSERT Bronze.erp_prod_demo
    FROM '/var/opt/mssql/data/source_erp/PX_CAT_G1V2.csv'
    WITH
    (
        FIRSTROW        = 2,
        FIELDTERMINATOR = ',',
        ROWTERMINATOR   = '0x0a',
        TABLOCK
    );

    SET @rows_loaded = ROWCOUNT_BIG();

    PRINT '  [2.3] Rows loaded : ' + CAST(@rows_loaded AS NVARCHAR);
    PRINT '  [2.3] Duration    : '
        + CAST(DATEDIFF(MILLISECOND, @step_start, SYSUTCDATETIME()) AS NVARCHAR)
        + ' ms';
    PRINT '  [2.3] Status      : SUCCESS';

END TRY
BEGIN CATCH

    PRINT '  [2.3] Status      : *** FAILED ***';
    PRINT '  [2.3] Error       : ' + ERROR_MESSAGE();
    PRINT '  [2.3] Severity    : ' + CAST(ERROR_SEVERITY() AS NVARCHAR);
    PRINT '  [2.3] State       : ' + CAST(ERROR_STATE()    AS NVARCHAR);
    PRINT '  [2.3] Line        : ' + CAST(ERROR_LINE()     AS NVARCHAR);

END CATCH;


/*
=============================================================
EXECUTION SUMMARY
=============================================================
*/

PRINT '';
PRINT '============================================================';
PRINT 'BRONZE LAYER LOAD — COMPLETED: ' + CONVERT(NVARCHAR, SYSUTCDATETIME(), 120);
PRINT '============================================================';
PRINT '';

-- Quick row-count audit across all six tables
SELECT
    'Bronze.crm_cust_info'    AS table_name, COUNT(*) AS rows_loaded FROM Bronze.crm_cust_info    UNION ALL
SELECT
    'Bronze.crm_prod_info'    AS table_name, COUNT(*) AS rows_loaded FROM Bronze.crm_prod_info    UNION ALL
SELECT
    'Bronze.crm_sales_details'AS table_name, COUNT(*) AS rows_loaded FROM Bronze.crm_sales_details UNION ALL
SELECT
    'Bronze.erp_cust_demo'    AS table_name, COUNT(*) AS rows_loaded FROM Bronze.erp_cust_demo    UNION ALL
SELECT
    'Bronze.erp_loc_demo'     AS table_name, COUNT(*) AS rows_loaded FROM Bronze.erp_loc_demo     UNION ALL
SELECT
    'Bronze.erp_prod_demo'    AS table_name, COUNT(*) AS rows_loaded FROM Bronze.erp_prod_demo;
GO