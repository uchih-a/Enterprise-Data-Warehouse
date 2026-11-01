--creating the products dim
-- Join crm_prod and erp_prod
/* 
1. Join the crm_prod and Erp_prod for the product Full infromation
2. Filter only The latest Products
3. Rename the column to friendly names
4. Load The dim into a view
*/
-- Seeing all the table
SELECT * FROM Silver.crm_prod_info; --Master Table
SELECT * FROM Silver.erp_prod_demo;

CREATE VIEW Gold.dim_products AS
SELECT
    ROW_NUMBER() 
        OVER (
            ORDER BY pn.product_start_date, pn.prod_id
            )               AS product_number,
    pn.prod_id              AS product_id,
    pn.category_id          AS category_id,
    pn.product_key          AS product_key,
    pn.product_name         AS product_name,
    pn.product_cost         AS product_cost,
    pn.product_line         AS product_line,
    pn.product_start_date   AS start_date,
    pd.prod_category        AS product_category,
    pd.prod_subcategory     AS product_subcategory,
    pd.prod_maintainance    AS product_maintainance
FROM Silver.crm_prod_info pn
LEFT JOIN Silver.erp_prod_demo pd
ON pn.category_id = pd.prod_id
WHERE pn.product_end_date is Null;
