/*
=================================================================
Stored Procedure: Loading The Silver Layer
=================================================================
Scrip Purpose:
	This script includes one stored procedure which performs
	ETL (Exract, Transform, Load) process to populate
	'silver' schema tables from the 'bronze' schema. 
	Furthermore, it calculates the duration of each table 
	truncation and insertion.

Parameters: 
	None.
		This stored procedure does not accept any parameters or 
		return any values.

Usage Example:
	Exec Silver.load_bronze
=================================================================
*/
create or alter procedure Silver.load_silver as
begin
	declare @start_time datetime, @end_time datetime, @batch_start_time datetime, @batch_end_time datetime
	begin try
		set @batch_start_time = getdate();
		set @start_time = getdate();
		print '===================================================';
		print 'Loading The Silver Layer';
		print '===================================================';
		print '---------------------------------------------------';
		print 'Loading The CRM Tables';
		print '---------------------------------------------------';
		print '>> Truncating Table: crm_cust_info ';
		truncate table silver.crm_cust_info;

		print '>> Inserting Data Into: crm_cust_info';
		insert into silver.crm_cust_info (
			cst_id,
			cst_key,
			cst_firstname,
			cst_lastname,
			cst_marital_status,
			cst_gndr,
			cst_create_date
		)

		select
			cst_id,
			trim(cst_key) as cst_key,
			trim(cst_firstname) as cst_firstname,
			trim(cst_lastname) as cst_lastname,
			case 
				when upper(trim(cst_marital_status)) = 'M' then 'Married'
				when upper(trim(cst_marital_status)) = 'S' then 'Single'
				else 'n/a'
			end as cst_marital_status,
			case 
				when upper(trim(cst_gndr)) = 'M' then 'Male'
				when upper(trim(cst_gndr)) = 'F' then 'Female'
				else 'n/a'
			end as cst_gndr,
			cst_create_date
		from
		(
			select
			*,
			row_number() over(partition by cst_id order by cst_create_date desc) flag_last_create_date
			from bronze.crm_cust_info
			where cst_id is not null
		) t where flag_last_create_date = 1;
		set @end_time = getdate();
		print '>> Loading Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + 'seconds';
		print '---------------------------------------------------';

		---------------------------------------------------

		set @start_time = getdate();

		print '>> Truncating Table: crm_prd_info ';
		truncate table silver.crm_prd_info;

		print '>> Inserting Data Into: crm_prd_info';
		insert into silver.crm_prd_info (
			prd_id,
			cat_id,
			prd_key,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt
		)
		select
			prd_id,
			replace(substring(prd_key, 1, 5), '-', '_') as cat_id,
			substring(prd_key, 7, len(prd_key)) as prd_key,
			trim(prd_nm) as prd_nm,
			isnull(prd_cost, 0) as prd_cost,
			case upper(trim(prd_line))
				when 'M' then 'Mountain'
				when 'R' then 'Road'
				when 'S' then 'Other Sales'
				when 'T' then 'Touring'
				else 'n/a'
			end as prd_line,
			cast(prd_start_dt as date) as prd_start_dt,
			cast(lead(prd_start_dt) over(partition by prd_key order by prd_start_dt) - 1 as date) as prd_end_dt
		from bronze.crm_prd_info;
		set @end_time = getdate();
		print '>> Loading Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + 'seconds';
		print '---------------------------------------------------';

		---------------------------------------------------

		set @start_time = getdate();

		print '>> Truncating Table: crm_sales_details ';
		truncate table silver.crm_sales_details;

		print '>> Inserting Data Into: crm_sales_details';
		insert into silver.crm_sales_details (
			sls_osls_rd_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales,
			sls_quantity,
			sls_price
		)

		select
			sls_osls_rd_num,
			sls_prd_key,
			sls_cust_id,
			case 
				when sls_order_dt = 0 or len(sls_order_dt) != 8 then null
				else cast(cast(sls_order_dt as varchar) as date)
			end as sls_order_dt,
			case 
				when sls_ship_dt = 0 or len(sls_ship_dt) != 8 then null
				else cast(cast(sls_ship_dt as varchar) as date)
			end as sls_ship_dt,
			case 
				when sls_due_dt = 0 or len(sls_due_dt) != 8 then null
				else cast(cast(sls_due_dt as varchar) as date)
			end as sls_due_dt,
			case
				when sls_sales is null or sls_sales <= 0 or sls_sales != sls_quantity * abs(sls_price)
					then sls_quantity * abs(sls_price)
				else sls_sales
			end as sls_sales,
			sls_quantity,
			case
				when sls_price is null or sls_price <= 0
					then abs(sls_sales / nullif(sls_quantity, 0))
				else sls_price
			end as sls_price
		from Bronze.crm_sales_details;
		set @end_time = getdate();
		print '>> Loading Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + 'seconds';
		print '---------------------------------------------------';

		---------------------------------------------------

		set @start_time = getdate();
		print '---------------------------------------------------';
		print 'Loading The ERP Tables';
		print '---------------------------------------------------';
		print '>> Truncating Table: erp_cust_az12 ';
		truncate table silver.erp_cust_az12;

		print '>> Inserting Data Into: erp_cust_az12';
		insert into silver.erp_cust_az12 (
			cid,
			bdate,
			gen
		)

		select
			case
				when cid like 'NAS%'
					then substring(cid, 4, len(cid))
				else cid
			end as cid,
			case 
				when bdate > getdate() or bdate < '1924-01-01'
					then null
				else bdate
			end as bdate,
			case 
				when upper(trim(gen)) in ('F', 'FEMALE') then 'Female'
				when upper(trim(gen)) in ('M', 'MALE') then 'Male'
				else 'n/a'
			end as gen
		from bronze.erp_cust_az12;
		set @end_time = getdate();
		print '>> Loading Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + 'seconds';
		print '---------------------------------------------------';

		---------------------------------------------------

		set @start_time = getdate();

		print '>> Truncating Table: erp_loc_a101 ';
		truncate table silver.erp_loc_a101;

		print '>> Inserting Data Into: erp_loc_a101';
		insert into Silver.erp_loc_a101 (
			cid,
			cntry
		)
		select 
			replace(cid, '-', '') as cid,
			case
				when trim(cntry) = '' or cntry = null then 'n/a'
				when trim(cntry) in ('US', 'USA') then 'United States'
				when trim(cntry) in ('DE') then 'Germany'
				else trim(cntry)
			end as cntry
		from Bronze.erp_loc_a101;
		set @end_time = getdate();
		print '>> Loading Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + 'seconds';
		print '---------------------------------------------------';

		----------------------------------------------------

		set @start_time = getdate();

		print '>> Truncating Table: erp_px_cat_g1v2 ';
		truncate table silver.erp_px_cat_g1v2;

		print '>> Inserting Data Into: erp_px_cat_g1v2';
		insert into silver.erp_px_cat_g1v2 (
			id, 
			cat,
			subcat,
			maintenance
		)
		select
			id,
			cat,
			subcat,
			maintenance
		from Bronze.erp_px_cat_g1v2;

		set @end_time = getdate();
		print '>> Loading Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + 'seconds';
		set @batch_end_time = getdate();
		print '===================================================';
		print'Loading The Silver Layer Is Completed.';
		print '>> Silver Layer Load Duration: ' + cast(datediff(second, @batch_start_time, @batch_end_time) as nvarchar) + 'seconds';
	end try
	begin catch
		print'==================================================';
		print'AN ERROR HAS ECCURED';
		print'ERROR MESSAGE: ' + error_message();
		print'ERROR NUMBER: ' + cast(error_number() as nvarchar);
		print'==================================================';
	end catch
end
