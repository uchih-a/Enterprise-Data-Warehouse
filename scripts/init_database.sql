/* ============================================================================
   Project       : Data Warehouse
   Database      : DataWarehouse
   Author        : <Your Name>
   Description   : Initializes the Data Warehouse database and schemas.
   
   Architecture:
       Bronze  -> Raw / source data
       Silver  -> Cleaned / standardized data
       Gold    -> Business-ready / dimensional data

   Notes:
       - Script is designed to be safely re-runnable.
       - Existing database and schemas are preserved.
       - SQL Server batch requirements are respected.
============================================================================ */


/* ============================================================================
   1. CREATE DATABASE
============================================================================ */

USE master;
GO

IF DB_ID(N'DataWarehouse') IS NULL
BEGIN
    PRINT 'Creating database [DataWarehouse]...';

    CREATE DATABASE [DataWarehouse];

    PRINT 'Database [DataWarehouse] created successfully.';
END
ELSE
BEGIN
    PRINT 'Database [DataWarehouse] already exists. Skipping creation.';
END;
GO


/* ============================================================================
   2. SWITCH TO DATA WAREHOUSE
============================================================================ */

USE [DataWarehouse];
GO


/* ============================================================================
   3. CREATE BRONZE SCHEMA
      Purpose: Raw data loaded directly from source systems.
============================================================================ */

IF NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = N'Bronze'
)
BEGIN
    EXEC(N'CREATE SCHEMA [Bronze]');

    PRINT 'Schema [Bronze] created successfully.';
END
ELSE
BEGIN
    PRINT 'Schema [Bronze] already exists. Skipping creation.';
END;
GO


/* ============================================================================
   4. CREATE SILVER SCHEMA
      Purpose: Cleaned, validated, standardized and transformed data.
============================================================================ */

IF NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = N'Silver'
)
BEGIN
    EXEC(N'CREATE SCHEMA [Silver]');

    PRINT 'Schema [Silver] created successfully.';
END
ELSE
BEGIN
    PRINT 'Schema [Silver] already exists. Skipping creation.';
END;
GO


/* ============================================================================
   5. CREATE GOLD SCHEMA
      Purpose: Business-ready data used by analytics, reporting and BI tools.
============================================================================ */

IF NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = N'Gold'
)
BEGIN
    EXEC(N'CREATE SCHEMA [Gold]');

    PRINT 'Schema [Gold] created successfully.';
END
ELSE
BEGIN
    PRINT 'Schema [Gold] already exists. Skipping creation.';
END;
GO


/* ============================================================================
   6. VERIFY DATABASE
============================================================================ */

SELECT
    DB_NAME() AS DatabaseName,
    SUSER_SNAME() AS ExecutedBy,
    GETDATE() AS ExecutionTime;
GO


/* ============================================================================
   7. VERIFY SCHEMAS
============================================================================ */

SELECT
    schema_id AS SchemaID,
    name AS SchemaName
FROM sys.schemas
WHERE name IN
(
    N'Bronze',
    N'Silver',
    N'Gold'
)
ORDER BY
    schema_id;
GO


/* ============================================================================
   END OF INITIALIZATION
============================================================================ */

PRINT '============================================================';
PRINT 'Data Warehouse initialization completed successfully.';
PRINT 'Database : DataWarehouse';
PRINT 'Schemas  : Bronze | Silver | Gold';
PRINT '============================================================';
GO
