/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in the data warehouse. 
    The Gold layer represents the final dimension and fact tables (Star Schema)

    Each view performs transformations and combines data from the Silver layer 
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
===============================================================================
*/

/* 
-- =============================================================================
Create Dimension: gold.dim_customers
-- =============================================================================
*/
CREATE OR ALTER VIEW gold.dim_customers AS
SELECT 
ROW_NUMBER() OVER (ORDER BY ci.cst_id) customer_key,
ci.cst_id costumer_id,
ci.cst_key costumer_number,
ci.cst_firstname first_name,
ci.cst_lastname last_name,
la.CNTRY country,
ci.cst_marital_status marital_status,
CASE WHEN ci.cst_gndr != 'N/a' THEN ci.cst_gndr -- CRM is the deciding gender
ELSE COALESCE(ca.GEN,'n/a') 
END gender,
ca.BDATE birthdate,
ci.cst_create_date create_date
FROM silver.crm_cust_info ci
LEFT Join silver.erp_CUST_AZ12 ca
ON ci.cst_key = ca.CID
LEFT JOIN silver.erp_LOC_A101 la
ON ci.cst_key = la.CID;

GO

/* 
-- =============================================================================
Create Dimension: gold.dim_products
-- =============================================================================
*/
CREATE OR ALTER VIEW gold.dim_products AS
SELECT 
ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt,pn.prd_id) AS product_key,
pn.prd_id AS product_id,
pn.prd_key AS product_number,
pn.prd_nm AS product_name,
pn.cat_id AS product_catgory_id,
pc.CAT AS category,
pc.SUBCAT AS subcategory,
pc.MAINTENANCE AS maintenance,
pn.prd_cost AS cost,
pn.prd_line AS product_line,
pn.prd_start_dt AS start_date 
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_PX_CAT_G1V2 pc
ON pn.cat_id = pc.ID
WHERE pn.prd_end_dt IS NULL /* Filter historical data */;

GO

/* 
-- =============================================================================
Create Fact Table: gold.fact_sales
-- =============================================================================
*/
CREATE OR ALTER VIEW gold.fact_sales AS
SELECT 
sd.sls_ord_num AS order_number,
pr.product_key AS product_key,
cu.customer_key AS customer_key, 
sd.sls_order_dt AS order_date, 
sd.sls_ship_dt AS shipping_date,
sd.sls_due_dt AS due_date,
sd.sls_sales AS sales_amount,
sd.sls_quantity AS quantity,
sd.sls_price AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_customers cu
ON sd.sls_cust_id = cu.costumer_id
LEFT JOIN gold.dim_products pr
ON sd.sls_prd_key = pr.product_number
