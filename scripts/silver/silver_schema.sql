/*
=============================================================
MEDALLION ARCHITECTURE
SILVER LAYER
=============================================================

Sources:
    1. CRM
    2. ERP

Purpose:
    - Clean and standardize Bronze data
    - Prepare data for integration
    - Preserve business-relevant attributes
    - Track data lineage and processing metadata

Current implementation:
    - Same business columns as Bronze
    - Silver metadata added
    - Business validation/transformation can be added
      during INSERT/UPDATE from Bronze

Database: SQL Server
=============================================================
*/


/*
=============================================================
1. CREATE SILVER SCHEMA
=============================================================
*/

IF NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = 'Silver'
)
BEGIN
    EXEC('CREATE SCHEMA Silver');
END;
GO


/*
=============================================================
2. CRM SILVER TABLES
=============================================================
*/


/* CRM CUSTOMER INFORMATION */

IF OBJECT_ID('Silver.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE Silver.crm_cust_info;
GO

CREATE TABLE Silver.crm_cust_info
(
    cust_id              INT,
    cust_key             NVARCHAR(50),
    cust_firstname       NVARCHAR(50),
    cust_lastname        NVARCHAR(50),
    cust_material_status NVARCHAR(50),
    cust_gndr            NVARCHAR(50),
    cust_create_date     DATE,

    -- Silver processing metadata
    dwh_create_date      DATETIME2(3)
        NOT NULL
        DEFAULT SYSUTCDATETIME(),

    dwh_update_date      DATETIME2(3)
        NOT NULL
        DEFAULT SYSUTCDATETIME(),

    dwh_source           NVARCHAR(50)
        NOT NULL,

    dwh_batch_id         BIGINT
);
GO


/* CRM PRODUCT INFORMATION */


/* CRM PRODUCT INFORMATION */

IF OBJECT_ID('Silver.crm_prod_info', 'U') IS NOT NULL
    DROP TABLE Silver.crm_prod_info;
GO

CREATE TABLE Silver.crm_prod_info
(
    prod_id             INT             NOT NULL,
    category_id         NVARCHAR(50)    NOT NULL,
    product_key         NVARCHAR(50)    NOT NULL,
    product_name        NVARCHAR(255)   NULL,
    product_cost        DECIMAL(10,2)   NOT NULL,
    product_line        NVARCHAR(50)    NOT NULL,
    product_start_date  DATE            NOT NULL,
    product_end_date    DATE            NULL,

    -- Silver processing metadata
    dwh_create_date     DATETIME2(3)
        NOT NULL
        DEFAULT SYSUTCDATETIME(),

    dwh_update_date     DATETIME2(3)
        NOT NULL
        DEFAULT SYSUTCDATETIME(),

    dwh_source          NVARCHAR(50)
        NOT NULL,

    dwh_batch_id        BIGINT,

    -- Data quality constraints
    CONSTRAINT PK_Silver_crm_prod_info
        PRIMARY KEY (prod_id),

    CONSTRAINT CK_Silver_crm_prod_info_cost
        CHECK (product_cost >= 0),

    CONSTRAINT CK_Silver_crm_prod_info_dates
        CHECK (
            product_end_date IS NULL
            OR product_end_date >= product_start_date
        )
);
GO



/* CRM SALES INFORMATION */

IF OBJECT_ID('Silver.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE Silver.crm_sales_details;
GO

CREATE TABLE Silver.crm_sales_details
(
    sale_ord_num   NVARCHAR(50),
    sale_prd_key   NVARCHAR(50),
    sale_cust_id   INT,
    sale_ord_date  DATE,
    sale_ship_date DATE,
    sale_due_date  DATE,
    sale_sales     DECIMAL(10,2),
    sale_quantity  INT,
    sale_price     DECIMAL(10,2),

    -- Silver processing metadata
    dwh_create_date DATETIME2(3)
        NOT NULL
        DEFAULT SYSUTCDATETIME(),

    dwh_update_date DATETIME2(3)
        NOT NULL
        DEFAULT SYSUTCDATETIME(),

    dwh_source      NVARCHAR(50)
        NOT NULL,

    dwh_batch_id    BIGINT
);
GO


/*
=============================================================
3. ERP SILVER TABLES
=============================================================
*/


/* ERP CUSTOMER DEMOGRAPHICS */

IF OBJECT_ID('Silver.erp_cust_demo', 'U') IS NOT NULL
    DROP TABLE Silver.erp_cust_demo;
GO

CREATE TABLE Silver.erp_cust_demo
(
    cust_cid    NVARCHAR(50),
    cust_bdate  DATE,
    cust_gender NVARCHAR(50),

    -- Silver processing metadata
    dwh_create_date DATETIME2(3)
        NOT NULL
        DEFAULT SYSUTCDATETIME(),

    dwh_update_date DATETIME2(3)
        NOT NULL
        DEFAULT SYSUTCDATETIME(),

    dwh_source      NVARCHAR(50)
        NOT NULL,

    dwh_batch_id    BIGINT
);
GO


/* ERP CUSTOMER LOCATION */

IF OBJECT_ID('Silver.erp_loc_demo', 'U') IS NOT NULL
    DROP TABLE Silver.erp_loc_demo;
GO

CREATE TABLE Silver.erp_loc_demo
(
    loc_cid   NVARCHAR(50),
    loc_cntry NVARCHAR(50),

    -- Silver processing metadata
    dwh_create_date DATETIME2(3)
        NOT NULL
        DEFAULT SYSUTCDATETIME(),

    dwh_update_date DATETIME2(3)
        NOT NULL
        DEFAULT SYSUTCDATETIME(),

    dwh_source      NVARCHAR(50)
        NOT NULL,

    dwh_batch_id    BIGINT
);
GO


/* ERP PRODUCT INFORMATION */

IF OBJECT_ID('Silver.erp_prod_demo', 'U') IS NOT NULL
    DROP TABLE Silver.erp_prod_demo;
GO

CREATE TABLE Silver.erp_prod_demo
(
    prod_id           NVARCHAR(50),
    prod_category     NVARCHAR(50),
    prod_subcategory  NVARCHAR(50),
    prod_maintainance NVARCHAR(50),

    -- Silver processing metadata
    dwh_create_date DATETIME2(3)
        NOT NULL
        DEFAULT SYSUTCDATETIME(),

    dwh_update_date DATETIME2(3)
        NOT NULL
        DEFAULT SYSUTCDATETIME(),

    dwh_source      NVARCHAR(50)
        NOT NULL,

    dwh_batch_id    BIGINT
);
GO