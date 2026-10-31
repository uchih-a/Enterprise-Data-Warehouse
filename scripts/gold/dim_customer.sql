SELECT * FROM Silver.crm_cust_info;
SELECT * FROM Silver.erp_cust_demo;
SELECT * FROM Silver.erp_loc_demo;

--Creating the customer Dimensions
--Data Intergration of Gender, Renaming to user Friendly names.
-- Create view for the gold layer
CREATE VIEW Gold.dim_customers AS
SELECT
    ROW_NUMBER() OVER (ORDER BY ci.cust_id) AS customer_key,
    ci.cust_id AS customer_id,
    ci.cust_firstname AS first_name,
    ci.cust_lastname AS last_name,
    ci.cust_material_status AS material_status,
    ci.cust_create_date AS date_joined,
    cd.cust_bdate AS birthdate,
    CASE WHEN ci.cust_gndr != 'N/A' THEN ci.cust_gndr
         ELSE COALESCE(cd.cust_gender, 'n/a')
    END AS gender,
    cl.loc_cntry AS country
FROM Silver.crm_cust_info ci
LEFT JOIN Silver.erp_cust_demo cd
ON ci.cust_key = cd.cust_id
LEFT JOIN Silver.erp_loc_demo cl
ON cd.cust_id = cl.loc_cid;
-- Investigating The Joins and the data merge.
--Duplicates
SELECT cust_id FROM(
    SELECT
    ci.cust_id,
    ci.cust_firstname,
    ci.cust_lastname,
    ci.cust_material_status,
    ci.cust_gndr,
    ci.cust_create_date,
    cd.cust_bdate,
    cd.cust_gender,
    cl.loc_cntry
FROM Silver.crm_cust_info ci
LEFT JOIN Silver.erp_cust_demo cd
ON ci.cust_key = cd.cust_id
LEFT JOIN Silver.erp_loc_demo cl
ON cd.cust_id = cl.loc_cid
) t 
GROUP BY cust_id 
HAVING COUNT(*) > 1;

--Checking Gender and Data Intergration of the Gender
SELECT DISTINCT
    ci.cust_gndr,
    cd.cust_gender AS old_gender,
    CASE WHEN cd.cust_gender = 'n/a' OR cd.cust_gender IS NULL THEN ci.cust_gndr
         WHEN ci.cust_gndr = 'N/A' OR ci.cust_gndr IS NULL THEN cd.cust_gender
         ELSE ci.cust_gndr
    END AS Gender
FROM Silver.crm_cust_info ci
LEFT JOIN Silver.erp_cust_demo cd
ON ci.cust_key = cd.cust_id
LEFT JOIN Silver.erp_loc_demo cl
ON cd.cust_id = cl.loc_cid
ORDER BY 1, 2;
