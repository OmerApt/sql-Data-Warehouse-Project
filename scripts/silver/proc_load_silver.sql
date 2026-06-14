/*

This Script Defines the silver.load_silver Stored prucedure.
The Procedure deletes old data of each silver layer table and inserts new data from
their parallel bronze layer tables. 

*/


CREATE OR ALTER PROCEDURE silver.load_silver AS 
BEGIN
DECLARE @start_time DATETIME,@end_time DATETIME,@batch_start_time DATETIME,@batch_end_time DATETIME;
	BEGIN TRY
		SET @batch_start_time = GETDATE();

		PRINT '================================================';
        PRINT 'Loading Silver Layer';
        PRINT '================================================';

		PRINT '------------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '------------------------------------------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.crm_cust_info';
		TRUNCATE TABLE silver.crm_cust_info;
		PRINT('>> Inserting data into: silver.crm_cust_info')
		INSERT INTO silver.crm_cust_info(
		cst_id,
		cst_key,
		cst_firstname,
		cst_lastname,
		cst_marital_status,
		cst_gndr,
		cst_create_date)
		SELECT 
		cst_id,
		cst_key,
		TRIM(cst_firstname) cst_firstname,
		TRIM(cst_lastname) cst_lastname,
		CASE WHEN TRIM(UPPER(cst_marital_status)) = 'M' THEN 'Married'
		WHEN TRIM(UPPER(cst_marital_status)) = 'S' THEN 'Single'
		ELSE 'N/a'
		END cst_marital_status,
		CASE WHEN TRIM(UPPER(cst_gndr)) = 'M' THEN 'Male'
		WHEN TRIM(UPPER(cst_gndr)) = 'F' THEN 'Female'
		ELSE 'N/a'
		END cst_gndr,
		cst_create_date
		FROM (
		SELECT *,
		ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
		FROM bronze.crm_cust_info) t WHERE flag_last = 1
		SET @end_time = GETDATE();
		PRINT('Time of insertion: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds')
		PRINT('--------------------------')

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.crm_prd_info';
		TRUNCATE TABLE silver.crm_prd_info;
		PRINT('>> Inserting data into: silver.crm_prd_info')
		INSERT INTO silver.crm_prd_info (
		prd_id
		,cat_id
		,prd_key
		,prd_nm
		,prd_cost
		,prd_line
		,prd_start_dt
		,prd_end_dt
		)
		select 
		prd_id,
		REPLACE(SUBSTRING(prd_key,1,5),'-','_') AS cat_id,
		SUBSTRING(prd_key,7,LEN(prd_key)) AS prd_key,
		prd_nm,
		ISNULL(prd_cost,0) prd_cost,
		CASE UPPER(TRIM(prd_line)) WHEN 'M' THEN 'Mountain'
		WHEN 'R' THEN 'Road'
		WHEN 'S' THEN 'Other Sales'
		WHEN 'T' THEN 'Touring'
		ELSE 'n/a'
		END prd_line,
		CAST (prd_start_dt AS DATE) prd_start_dt,
		CAST (DATEADD(DAY,-1,LEAD(prd_start_dt,1) OVER (PARTITION BY prd_Key ORDER BY prd_start_dt)) AS DATE) AS prd_end_dt
		from bronze.crm_prd_info
		SET @end_time = GETDATE();
		PRINT('Time of insertion: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds')
		PRINT('--------------------------')

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.crm_sales_details';
		TRUNCATE TABLE silver.crm_sales_details;
		PRINT('>> Inserting data into: silver.crm_sales_details');
		INSERT INTO silver.crm_sales_details(
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		sls_order_dt,
		sls_ship_dt,
		sls_due_dt,
		sls_sales,
		sls_quantity,
		sls_price
		)
		Select 
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
		ELSE CAST(CAST(sls_order_dt AS varchar) AS DATE)
		END sls_order_dt,
		CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
		ELSE CAST(CAST(sls_ship_dt AS varchar) AS DATE)
		END sls_ship_dt,
		CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
		ELSE CAST(CAST(sls_due_dt AS varchar) AS DATE)
		END sls_due_dt,
		CASE WHEN sls_sales IS NULL OR sls_sales < 0 OR sls_sales != sls_quantity * ABS(sls_price)
		THEN sls_quantity * ABS(sls_price)
		ELSE sls_sales
		END AS sls_sales,
		sls_quantity,
		CASE WHEN sls_price IS NULL OR sls_price <= 0
		THEN sls_sales / NULLIF(sls_quantity,0)
		ELSE sls_price
		END AS sls_price
		From bronze.crm_sales_details
		SET @end_time = GETDATE();
		PRINT('Time of insertion: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds')
		PRINT('--------------------------')

		PRINT '------------------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '------------------------------------------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.erp_CUST_AZ12';
		TRUNCATE TABLE silver.erp_CUST_AZ12;
		PRINT('>> Inserting data into: silver.erp_CUST_AZ12');
		INSERT INTO silver.erp_CUST_AZ12(CID,BDATE,GEN)
		SELECT 
		CASE WHEN CID LIKE 'NAS%' THEN SUBSTRING(CID,4,LEN(CID))
		ELSE CID
		END AS CID,
		CASE WHEN BDATE > GETDATE() THEN NULL
		ELSE BDATE
		END AS BDATE,
		CASE WHEN UPPER(TRIM(GEN)) IN('F','Female') THEN 'Female'
		WHEN UPPER(TRIM(GEN)) IN('M','Male') then 'Male'
		ELSE 'n/a'
		END AS GEN
		FROM bronze.erp_CUST_AZ12
		SET @end_time = GETDATE();
		PRINT('Time of insertion: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds')
		PRINT('--------------------------')

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.erp_LOC_A101';
		TRUNCATE TABLE silver.erp_LOC_A101;
		PRINT('>> Inserting data into: silver.erp_LOC_A101');
		INSERT INTO silver.erp_LOC_A101(CID,CNTRY)
		SELECT 
		REPLACE(TRIM(CID),'-','') AS CID,
		CASE WHEN UPPER(TRIM(CNTRY)) IN ('US','USA','United States') THEN 'United States'
		WHEN UPPER(TRIM(CNTRY)) IN ('DE','Germany') THEN 'Germany'
		WHEN NULLIF(UPPER(TRIM(CNTRY)),'') IS NULL THEN 'n/a'
		ELSE CNTRY
		END AS CNTRY
		FROM bronze.erp_LOC_A101
		SET @end_time = GETDATE();
		PRINT('Time of insertion: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds')
		PRINT('--------------------------')

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.erp_PX_CAT_G1V2';
		TRUNCATE TABLE silver.erp_PX_CAT_G1V2;
		PRINT('>> Inserting data into: silver.erp_PX_CAT_G1V2');
		INSERT INTO silver.erp_PX_CAT_G1V2(ID,CAT,SUBCAT,MAINTENANCE)
		SELECT 
		ID,
		CAT,
		SUBCAT,
		MAINTENANCE
		FROM bronze.erp_PX_CAT_G1V2;
		SET @end_time = GETDATE();
		PRINT('Time of insertion: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' seconds')
		PRINT('--------------------------')

		SET @batch_end_time = GETDATE();
		PRINT '=========================================='
		PRINT 'Loading Silver Layer is Completed';
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
		PRINT '=========================================='
	END TRY
	BEGIN CATCH
		PRINT '=========================================='
		PRINT 'ERROR OCCURED DURING LOADING SILVER LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '=========================================='
	END CATCH
END

EXEC silver.load_silver
