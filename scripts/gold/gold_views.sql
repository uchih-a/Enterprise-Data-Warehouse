/* ============================================================================
   Project       : Data Warehouse
   Database      : DataWarehouse
   Layer         : GOLD (business-ready, dimensional model)
   Author        : Mutsala
   Script        : gold_views.sql

   Objects created (in dependency order):
       1. Gold.dim_customers   Customer dimension (CRM master + ERP enrichment)
       2. Gold.dim_products    Product dimension (current versions only)
       3. Gold.fact_sales      Sales fact at order-line grain

   Sources:
       Silver.crm_cust_info, Silver.erp_cust_demo, Silver.erp_loc_demo,
       Silver.crm_prod_info, Silver.erp_prod_demo, Silver.crm_sales_details

   Design notes:
       - Safe to re-run: CREATE OR ALTER VIEW is used throughout.
       - Surrogate keys are generated with ROW_NUMBER() ordered by the natural
         key. They are stable only while the set of members does not change.
         Always join facts to dimensions through the views, never by storing
         key values in another table. (See "Surrogate keys" in the docs.)
       - Each dimension has an "Unknown" member with key -1. The fact view maps
         unmatched dimension lookups to -1 so that no sales row is ever lost
         or silently dropped by a join.
       - Run gold_quality_checks.sql after every deployment and every load.

   Requires: SQL Server 2016 SP1 or later (CREATE OR ALTER).
============================================================================ */

USE [DataWarehouse];
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'Gold')
    EXEC (N'CREATE SCHEMA [Gold]');
GO


/* ============================================================================
   1. GOLD.DIM_CUSTOMERS
   Grain   : one row per customer
   Business key : customer_id (CRM), customer_number (cross-system key)

   Integration rules:
       - CRM is the master source for identity and marital status.
       - Gender: use CRM when it is Male or Female, otherwise fall back to ERP,
         otherwise 'n/a'.
       - Birthdate comes from ERP. Country comes from the ERP location table.
       - Both ERP tables are joined on the CRM cust_key. The location table is
         joined directly, so a customer with no ERP demographics still gets a
         country.
============================================================================ */
CREATE OR ALTER VIEW [Gold].[dim_customers]
AS
WITH customers AS
(
    SELECT
        ci.cust_id                              AS customer_id,
        ci.cust_key                             AS customer_number,
        ci.cust_firstname                       AS first_name,
        ci.cust_lastname                        AS last_name,
        ci.cust_material_status                 AS marital_status,
        CASE
            WHEN ci.cust_gndr   IN (N'Male', N'Female') THEN ci.cust_gndr
            WHEN cd.cust_gender IN (N'Male', N'Female') THEN cd.cust_gender
            ELSE N'n/a'
        END                                     AS gender,
        cd.cust_bdate                           AS birthdate,
        COALESCE(NULLIF(cl.loc_cntry, N''), N'n/a') AS country,
        ci.cust_create_date                     AS date_joined
    FROM Silver.crm_cust_info    AS ci
    LEFT JOIN Silver.erp_cust_demo AS cd
        ON cd.cust_cid = ci.cust_key
    LEFT JOIN Silver.erp_loc_demo  AS cl
        ON cl.loc_cid  = ci.cust_key
)
SELECT
    CAST(ROW_NUMBER() OVER (ORDER BY c.customer_id) AS INT) AS customer_key,
    c.customer_id,
    c.customer_number,
    c.first_name,
    c.last_name,
    c.marital_status,
    c.gender,
    c.birthdate,
    c.country,
    c.date_joined
FROM customers AS c

UNION ALL

-- Unknown member: receives fact rows whose customer cannot be resolved
SELECT
    -1,
    NULL,
    N'n/a',
    N'Unknown',
    N'Unknown',
    N'n/a',
    N'n/a',
    NULL,
    N'n/a',
    NULL;
GO


/* ============================================================================
   2. GOLD.DIM_PRODUCTS
   Grain   : one row per product (current version only)
   Business key : product_number (CRM product key, shared by all versions)

   Integration rules:
       - CRM is the master. A version is current when product_end_date IS NULL.
       - ERP supplies category, subcategory and the maintenance flag, joined on
         category_id. Missing ERP data becomes 'n/a'.
============================================================================ */
CREATE OR ALTER VIEW [Gold].[dim_products]
AS
WITH products AS
(
    SELECT
        pn.prod_id                              AS product_id,
        pn.product_key                          AS product_number,
        pn.product_name                         AS product_name,
        pn.category_id                          AS category_id,
        COALESCE(pd.prod_category,    N'n/a')   AS category,
        COALESCE(pd.prod_subcategory, N'n/a')   AS subcategory,
        pn.product_line                         AS product_line,
        pn.product_cost                         AS cost,
        COALESCE(pd.prod_maintainance, N'n/a')  AS maintenance_required,
        pn.product_start_date                   AS start_date
    FROM Silver.crm_prod_info AS pn
    LEFT JOIN Silver.erp_prod_demo AS pd
        ON pd.prod_id = pn.category_id
    WHERE pn.product_end_date IS NULL
)
SELECT
    CAST(ROW_NUMBER() OVER (ORDER BY p.product_id) AS INT) AS product_key,
    p.product_id,
    p.product_number,
    p.product_name,
    p.category_id,
    p.category,
    p.subcategory,
    p.product_line,
    p.cost,
    p.maintenance_required,
    p.start_date
FROM products AS p

UNION ALL

-- Unknown member: receives fact rows whose product cannot be resolved
SELECT
    -1,
    NULL,
    N'n/a',
    N'Unknown',
    N'n/a',
    N'n/a',
    N'n/a',
    N'n/a',
    NULL,
    N'n/a',
    NULL;
GO


/* ============================================================================
   3. GOLD.FACT_SALES
   Grain   : one row per order line (order number + product)

   - Replaces natural keys with the dimension surrogate keys.
   - LEFT JOINs keep every Silver sales row. Unmatched lookups map to -1.
   - Because each dimension has exactly one row per business key, the joins
     cannot multiply rows. gold_quality_checks.sql verifies this.
============================================================================ */
CREATE OR ALTER VIEW [Gold].[fact_sales]
AS
SELECT
    sd.sale_ord_num                         AS order_number,
    COALESCE(dc.customer_key, -1)           AS customer_key,
    COALESCE(dp.product_key,  -1)           AS product_key,
    sd.sale_ord_date                        AS order_date,
    sd.sale_ship_date                       AS shipping_date,
    sd.sale_due_date                        AS due_date,
    sd.sale_sales                           AS sales_amount,
    sd.sale_quantity                        AS quantity,
    sd.sale_price                           AS price
FROM Silver.crm_sales_details AS sd
LEFT JOIN Gold.dim_customers AS dc
    ON dc.customer_id    = sd.sale_cust_id
LEFT JOIN Gold.dim_products  AS dp
    ON dp.product_number = sd.sale_prd_key;
GO


/* ============================================================================
   4. OPTIONAL: GRANT READ ACCESS TO REPORTING USERS
      Uncomment and adjust the role name for your environment.
============================================================================ */
-- GRANT SELECT ON SCHEMA::[Gold] TO [reporting_reader];
-- GO

PRINT 'Gold views deployed: dim_customers, dim_products, fact_sales.';
GO