/*
=============================================================
MEDALLION ARCHITECTURE
BRONZE LAYER
=============================================================

Sources:
    1. CRM
    2. ERP

Purpose:
    - Preserve source data
    - Support raw file ingestion
    - Maintain ingestion metadata
    - Avoid premature business validation

Database: SQL Server
=============================================================
*/


/*
=============================================================
1. CREATE SCHEMAS
=============================================================
*/

IF NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = 'Bronze'
)
BEGIN
    EXEC('CREATE SCHEMA Bronze');
END;
GO


/*
=============================================================
2. CRM SOURCE TABLES
=============================================================
*/


/* CRM CUSTOMER INFORMATION */

CREATE TABLE Bronze.crm_cust_info
(
    cust_id INT,
    cust_key NVARCHAR(50),
    cust_firstname NVARCHAR(50),
    cust_lastname NVARCHAR(50),
    cust_material_status NVARCHAR(50),
    cust_gndr NVARCHAR(50),
    cust_create_date DATE,

    -- Ingestion metadata
    dwh_create_date DATETIME2(3)
        NOT NULL
        DEFAULT SYSUTCDATETIME()
);
GO


/* CRM PRODUCT INFORMATION */

CREATE TABLE Bronze.crm_prod_info
(
    prod_id INT,
    prod_key NVARCHAR(50),
    prod_name NVARCHAR(50),
    prod_cost DECIMAL(10,2),
    prod_line NVARCHAR(50),
    prod_start_date DATE,
    prod_end_date DATE,

    -- Ingestion metadata
    dwh_create_date DATETIME2(3)
        NOT NULL
        DEFAULT SYSUTCDATETIME()
);
GO


/* CRM SALES INFORMATION */

CREATE TABLE Bronze.crm_sales_details
(
    sale_ord_num NVARCHAR(50),
    sale_prd_key NVARCHAR(50),
    sale_cust_id INT,
    sale_ord_date DATE,
    sale_ship_date DATE,
    sale_due_date DATE,
    sale_sales DECIMAL(10,2),
    sale_quantity INT,
    sale_price DECIMAL(10,2),

    -- Ingestion metadata
    dwh_create_date DATETIME2(3)
        NOT NULL
        DEFAULT SYSUTCDATETIME()
);
GO


/*
=============================================================
3. ERP SOURCE TABLES
=============================================================
*/


/* ERP CUSTOMER DEMOGRAPHICS */

CREATE TABLE Bronze.erp_cust_demo
(
    cust_cid NVARCHAR(50),
    cust_bdate DATE,
    cust_gender NVARCHAR(50),

    -- Ingestion metadata
    dwh_create_date DATETIME2(3)
        NOT NULL
        DEFAULT SYSUTCDATETIME()
);
GO


/* ERP CUSTOMER LOCATION */

CREATE TABLE Bronze.erp_loc_demo
(
    loc_cid NVARCHAR(50),
    loc_cntry NVARCHAR(50),

    -- Ingestion metadata
    dwh_create_date DATETIME2(3)
        NOT NULL
        DEFAULT SYSUTCDATETIME()
);
GO


/* ERP PRODUCT INFORMATION */

CREATE TABLE Bronze.erp_prod_demo
(
    prod_id NVARCHAR(50),
    prod_category NVARCHAR(50),
    prod_subcategory NVARCHAR(50),
    prod_maintainance NVARCHAR(50),

    -- Ingestion metadata
    dwh_create_date DATETIME2(3)
        NOT NULL
        DEFAULT SYSUTCDATETIME()
);
GO
