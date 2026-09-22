        CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN

    -- ============================================================
    -- STEP 1: DECLARE VARIABLES
    -- ============================================================

    DECLARE 
        @start_time DATETIME,
        @end_time DATETIME,
        @batch_start_time DATETIME,
        @batch_end_time DATETIME;


    -- ============================================================
    -- STEP 2: START BATCH
    -- ============================================================

    BEGIN TRY

        SET @batch_start_time = GETDATE();

        PRINT '=============================================================================================';
        PRINT '                         STARTING BRONZE LAYER LOAD';
        PRINT '=============================================================================================';
        PRINT '';
        PRINT '>> Purpose: Load raw CRM and ERP source data into the Bronze Layer.';
        PRINT '>> Process: Truncate existing Bronze tables and reload them from CSV files.';
        PRINT '>> The Bronze Layer stores the raw data with minimal transformation.';
        PRINT '';
        PRINT '>> Batch Start Time: ' + CONVERT(NVARCHAR, @batch_start_time, 120);
        PRINT '=============================================================================================';
        PRINT '';


        -- ========================================================
        -- STEP 3: LOAD CRM TABLES
        -- ========================================================

        PRINT '----------------------------------------------------------------------------------------------';
        PRINT '                              LOADING CRM TABLES';
        PRINT '----------------------------------------------------------------------------------------------';
        PRINT '>> CRM Source: Customer, Product and Sales information';
        PRINT '>> Action: Clear existing CRM Bronze tables and load fresh data from CSV files.';
        PRINT '';


        -- ========================================================
        -- CRM CUSTOMER INFORMATION
        -- ========================================================

        SET @start_time = GETDATE();

        PRINT '>> [CRM 1/3] Processing bronze.crm_cust_info';
        PRINT '>> Truncating table: bronze.crm_cust_info';

        TRUNCATE TABLE bronze.crm_cust_info;

        PRINT '>> Inserting data from: cust_info.csv';

        BULK INSERT bronze.crm_cust_info
        FROM 'C:\Users\navup\Videos\warehouse\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> CRM Customer table loaded successfully.';
        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';

        PRINT '>> ___________________________________________________________________________________________';
        PRINT '';


        -- ========================================================
        -- CRM PRODUCT INFORMATION
        -- ========================================================

        SET @start_time = GETDATE();

        PRINT '>> [CRM 2/3] Processing bronze.crm_prd_info';
        PRINT '>> Truncating table: bronze.crm_prd_info';

        TRUNCATE TABLE bronze.crm_prd_info;

        PRINT '>> Inserting data from: prd_info.csv';

        BULK INSERT bronze.crm_prd_info
        FROM 'C:\Users\navup\Videos\warehouse\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> CRM Product table loaded successfully.';
        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';

        PRINT '>> ___________________________________________________________________________________________';
        PRINT '';


        -- ========================================================
        -- CRM SALES DETAILS
        -- ========================================================

        SET @start_time = GETDATE();

        PRINT '>> [CRM 3/3] Processing bronze.crm_sales_details';
        PRINT '>> Truncating table: bronze.crm_sales_details';

        TRUNCATE TABLE bronze.crm_sales_details;

        PRINT '>> Inserting data from: sales_details.csv';

        BULK INSERT bronze.crm_sales_details
        FROM 'C:\Users\navup\Videos\warehouse\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> CRM Sales table loaded successfully.';
        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';

        PRINT '>> ___________________________________________________________________________________________';
        PRINT '';


        -- ========================================================
        -- STEP 4: LOAD ERP TABLES
        -- ========================================================

        PRINT '----------------------------------------------------------------------------------------------';
        PRINT '                              LOADING ERP TABLES';
        PRINT '----------------------------------------------------------------------------------------------';
        PRINT '>> ERP Source: Customer, Location and Product Category information';
        PRINT '>> Action: Clear existing ERP Bronze tables and load fresh data from CSV files.';
        PRINT '';


        -- ========================================================
        -- ERP CUSTOMER
        -- ========================================================

        SET @start_time = GETDATE();

        PRINT '>> [ERP 1/3] Processing bronze.erp_cust_az12';
        PRINT '>> Truncating table: bronze.erp_cust_az12';

        TRUNCATE TABLE bronze.erp_cust_az12;

        PRINT '>> Inserting data from: CUST_AZ12.csv';

        BULK INSERT bronze.erp_cust_az12
        FROM 'C:\Users\navup\Videos\warehouse\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> ERP Customer table loaded successfully.';
        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';

        PRINT '>> ___________________________________________________________________________________________';
        PRINT '';


        -- ========================================================
        -- ERP LOCATION
        -- ========================================================

        SET @start_time = GETDATE();

        PRINT '>> [ERP 2/3] Processing bronze.erp_loc_a101';
        PRINT '>> Truncating table: bronze.erp_loc_a101';

        TRUNCATE TABLE bronze.erp_loc_a101;

        PRINT '>> Inserting data from: LOC_A101.csv';

        BULK INSERT bronze.erp_loc_a101
        FROM 'C:\Users\navup\Videos\warehouse\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> ERP Location table loaded successfully.';
        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';

        PRINT '>> ___________________________________________________________________________________________';
        PRINT '';


        -- ========================================================
        -- ERP PRODUCT CATEGORY
        -- ========================================================

        SET @start_time = GETDATE();

        PRINT '>> [ERP 3/3] Processing bronze.erp_px_cat_g1v2';
        PRINT '>> Truncating table: bronze.erp_px_cat_g1v2';

        TRUNCATE TABLE bronze.erp_px_cat_g1v2;

        PRINT '>> Inserting data from: PX_CAT_G1V2.csv';

        BULK INSERT bronze.erp_px_cat_g1v2
        FROM 'C:\Users\navup\Videos\warehouse\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> ERP Product Category table loaded successfully.';
        PRINT '>> Load Duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';

        PRINT '>> ___________________________________________________________________________________________';
        PRINT '';


        -- ========================================================
        -- STEP 5: BATCH COMPLETION
        -- ========================================================

        SET @batch_end_time = GETDATE();

        PRINT '';
        PRINT '=============================================================================================';
        PRINT '                         BRONZE LAYER LOAD COMPLETED';
        PRINT '=============================================================================================';
        PRINT '>> All CRM and ERP tables have been successfully loaded.';
        PRINT '>> Batch Start Time: ' + CONVERT(NVARCHAR, @batch_start_time, 120);
        PRINT '>> Batch End Time:   ' + CONVERT(NVARCHAR, @batch_end_time, 120);
        PRINT '>> Total Load Duration: '
            + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR)
            + ' seconds';
        PRINT '=============================================================================================';


    END TRY


    -- ============================================================
    -- STEP 6: ERROR HANDLING
    -- ============================================================

    BEGIN CATCH

        PRINT '';
        PRINT '=============================================================================================';
        PRINT '                              BRONZE LAYER LOAD FAILED';
        PRINT '=============================================================================================';
        PRINT '>> An error occurred while loading the Bronze Layer.';
        PRINT '>> Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT '>> Error Message: ' + ERROR_MESSAGE();
        PRINT '>> Error State: ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '>> Error Line: ' + CAST(ERROR_LINE() AS NVARCHAR);
        PRINT '=============================================================================================';

    END CATCH

END;
