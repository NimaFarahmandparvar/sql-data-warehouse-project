/*
=================================================================
Stored Procedure: Loading The Bronze Layer
=================================================================
Scrip Purpose:
	This script includes one stored procedure which bulk inserts
	data from external CSV files into the Bronze schema tables. 
	Furthermore, it calculates the duration of each table 
	truncation and insertion.

Parameters: 
	None.
		This stored procedure does not accept any parameters or 
		return any values.

Usage Example:
	Exec Bronze.load_bronze
=================================================================
*/
create or alter procedure bronze.load_bronze as
Begin
	declare @start_time datetime, @end_time datetime, @batch_start_time datetime, @batch_end_time datetime;
	begin try
		set @batch_start_time = getdate();
		print '===================================================';
		print 'Loading The Bronze Layer';
		print '===================================================';

		print '---------------------------------------------------';
		print 'Loading The CRM Tables';
		print '---------------------------------------------------';

		set @start_time = getdate();
		print '<<Truncating Table: crm_cust_info ';
		truncate table bronze.crm_cust_info;

		print '<<Inserting Data Into: crm_cust_info';
		bulk insert bronze.crm_cust_info
		from 'D:\NarmAfzar\Microsoft SQL Server 2022\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);
		set @end_time = getdate();
		print '<<Load Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + 'seconds';
		print '---------------------------------------------------';

		set @start_time = getdate();
		print '<<Truncating Table: crm_prd_info ';
		truncate table bronze.crm_prd_info;
		print '<<Inserting Data Into: crm_prd_info';
		bulk insert bronze.crm_prd_info
		from 'D:\NarmAfzar\Microsoft SQL Server 2022\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);
		set @end_time = getdate();
		print '<<Load Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + 'seconds';
		print '---------------------------------------------------';

		set @start_time = getdate();
		print '<<Truncating Table: crm_sales_details ';
		truncate table bronze.crm_sales_details;
		print '<<Inserting Data Into: crm_sales_details';
		bulk insert bronze.crm_sales_details
		from 'D:\NarmAfzar\Microsoft SQL Server 2022\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);
		set @end_time = getdate();
		print '<<Load Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + 'seconds';
		print '---------------------------------------------------';

		print '---------------------------------------------------';
		print 'Loading The ERP Tables';
		print '---------------------------------------------------';

		set @start_time = getdate();
		print '<<Truncating Table: erp_px_cat_g1v2 ';
		truncate table bronze.erp_px_cat_g1v2;
		print '<<Inserting Data Into: erp_px_cat_g1v2';
		bulk insert bronze.erp_px_cat_g1v2
		from 'D:\NarmAfzar\Microsoft SQL Server 2022\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\px_cat_g1v2.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);
		set @end_time = getdate();
		print '<<Load Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + 'seconds';
		print '---------------------------------------------------';

		set @start_time = getdate();
		print '<<Truncating Table: erp_loc_a101 ';
		truncate table bronze.erp_loc_a101;
		print '<<Inserting Data Into: erp_loc_a101';
		bulk insert bronze.erp_loc_a101
		from 'D:\NarmAfzar\Microsoft SQL Server 2022\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\loc_a101.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);
		set @end_time = getdate();
		print '<<Load Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + 'seconds';
		print '---------------------------------------------------';

		set @start_time = getdate();
		print '<<Truncating Table: erp_cust_az12 ';
		truncate table bronze.erp_cust_az12;
		print '<<Inserting Data Into: erp_cust_az12';
		bulk insert bronze.erp_cust_az12
		from 'D:\NarmAfzar\Microsoft SQL Server 2022\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			tablock
		);
		set @end_time = getdate();
		print '<<Load Duration: ' + cast(datediff(second, @start_time, @end_time) as nvarchar) + 'seconds';
		print '---------------------------------------------------';
		set @batch_end_time = getdate();
		print'==================================================';
		print'Loading The Bronze Layer Is Completed.';
		print '<<Whole Load Duration: ' + cast(datediff(second, @batch_start_time, @batch_end_time) as nvarchar) + 'seconds';
		print'==================================================';

	end try
	begin catch
		print'==================================================';
		print'AN ERROR HAS ECCURED';
		print'ERROR MESSAGE' + error_message();
		print'ERROR NUMBER' + cast(error_number() as nvarchar);
		print'==================================================';
	end catch
End
