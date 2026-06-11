/*
===============================================================================
DDL Script: Create silver Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'silver' schema, dropping existing tables 
    if they already exist.
	  Run this script to re-define the DDL structure of 'silver' Tables
===============================================================================
*/

IF OBJECT_ID('silver.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_cust_info;
GO

CREATE TABLE silver.crm_cust_info (
cst_id INT,
cst_key NVARCHAR(50),
cst_firstname NVARCHAR(50),
cst_lastname NVARCHAR(50),
cst_marital_status NVARCHAR(50),
cst_gndr NVARCHAR(50),
cst_create_date DATE,
dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO


IF OBJECT_ID('silver.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_prd_info;
GO
CREATE TABLE silver.crm_prd_info (
prd_id INT,
prd_key VARCHAR(50),
prd_nm VARCHAR(50),
prd_cost INT,
prd_line VARCHAR(50),
prd_start_dt DATE,
prd_end_dt DATE,
dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO


IF OBJECT_ID('silver.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE silver.crm_sales_details;
GO
CREATE TABLE silver.crm_sales_details(
sls_ord_num VARCHAR(50),
sls_prd_key VARCHAR(50),
sls_cust_id INT,
sls_order_dt INT,
sls_ship_dt INT,
sls_due_dt INT,
sls_sales INT,
sls_quantity INT,
sls_price INT,
dwh_create_date DATETIME2 DEFAULT GETDATE()

);
GO

IF OBJECT_ID('silver.erp_CUST_AZ12', 'U') IS NOT NULL
    DROP TABLE silver.erp_CUST_AZ12;
GO
CREATE TABLE silver.erp_CUST_AZ12(
CID VARCHAR(50),
BDATE DATE,
GEN VARCHAR(50),
dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO


IF OBJECT_ID('silver.erp_LOC_A101', 'U') IS NOT NULL
    DROP TABLE silver.erp_LOC_A101;
GO
CREATE TABLE silver.erp_LOC_A101(
CID VARCHAR(50),
CNTRY VARCHAR(50),
dwh_create_date DATETIME2 DEFAULT GETDATE()
);
GO


IF OBJECT_ID('silver.erp_PX_CAT_G1V2', 'U') IS NOT NULL
    DROP TABLE silver.erp_PX_CAT_G1V2;
GO
CREATE TABLE silver.erp_PX_CAT_G1V2(
ID VARCHAR(50),
CAT VARCHAR(50),
SUBCAT VARCHAR(50),
MAINTENANCE  VARCHAR(50),
dwh_create_date DATETIME2 DEFAULT GETDATE()
);
