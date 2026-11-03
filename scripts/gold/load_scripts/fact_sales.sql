-- Creating the fact table
SELECT * FROM Silver.crm_sales_details

/*
1. Select all the transaction 
2. Join dim_customer and dim_product
3. Update the customer key and product key 
4. create the fact table view
*/
CREATE VIEW Gold.fact_sales AS
SELECT 
    sd.sale_ord_num     AS order_number,
    cd.customer_id,
    pd.product_number,
    sd.sale_ord_date    AS order_date,
    sd.sale_due_date    AS due_date,
    sd.sale_sales       AS sales,
    sd.sale_quantity    AS quantity,
    sd.sale_price       AS price
FROM Silver.crm_sales_details sd 
LEFT JOIN Gold.dim_customers cd
ON sd.sale_cust_id = cd.customer_id
LEFT JOIN Gold.dim_products pd
ON sd.sale_prd_key = pd.product_key;