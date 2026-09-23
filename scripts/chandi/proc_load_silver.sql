-- ============================================================
-- SILVER LAYER LOAD PROCEDURE
-- ============================================================
-- Purpose:
-- This stored procedure loads cleaned and transformed data
-- from the Bronze Layer into the Silver Layer.
--
-- The Silver Layer contains standardized, cleaned and
-- business-ready data.
--
-- Main steps:
-- 1. Truncate existing Silver data
-- 2. Read data from Bronze tables
-- 3. Clean and transform the data
-- 4. Insert the transformed data into Silver tables
-- ============================================================


CREATE OR ALTER PROCEDURE silver.load_silver
AS
BEGIN

    -- ========================================================
    -- 1. CRM CUSTOMER INFORMATION
    -- ========================================================
    -- Purpose:
    -- Load cleaned customer information from Bronze CRM data.
    --
    -- Transformations performed:
    -- - Remove duplicate customer records
    -- - Keep the latest record for each customer
    -- - Remove extra spaces from names
    -- - Convert M/F codes into meaningful values
    -- - Replace unknown gender/status values with 'n/a'
    -- ========================================================


    PRINT '============================================================';
    PRINT 'Loading Silver CRM Customer Information';
    PRINT '============================================================';


    -- Remove existing Silver customer data before reloading.
    PRINT '>> Truncate table: silver.crm_cust_info';

    TRUNCATE TABLE silver.crm_cust_info;


    -- Insert cleaned customer data into Silver.
    PRINT '>> Insert data into table: silver.crm_cust_info';


    INSERT INTO silver.crm_cust_info (
        cst_id,
        cst_key,
        cst_firstname,
        cst_lastname,
        cst_material_status,
        cst_gndr,
        cst_create_date
    )

    SELECT
        cst_id,
        cst_key,

        -- Remove unnecessary spaces from first name.
        TRIM(cst_firstname) AS cst_firstname,

        -- Remove unnecessary spaces from last name.
        TRIM(cst_lastname) AS cst_lastname,

        -- Convert customer marital status codes
        -- into meaningful business values.
        CASE
            WHEN UPPER(TRIM(cst_material_status)) = 'M'
                THEN 'Married'

            WHEN UPPER(TRIM(cst_material_status)) = 'S'
                THEN 'Single'

            ELSE 'n/a'
        END AS cst_material_status,


        -- Convert gender codes into readable values.
        CASE
            WHEN UPPER(TRIM(cst_gndr)) = 'F'
                THEN 'Female'

            WHEN UPPER(TRIM(cst_gndr)) = 'M'
                THEN 'Male'

            ELSE 'n/a'
        END AS cst_gndr,

        cst_create_date

    FROM
    (
        SELECT
            *,

            -- Assign a ranking to customer records.
            -- The newest record for each customer gets rank = 1.
            ROW_NUMBER() OVER (
                PARTITION BY cst_id
                ORDER BY cst_create_date DESC
            ) AS flag_last

        FROM bronze.crm_cust_info

        -- Ignore records where customer ID is missing.
        WHERE cst_id IS NOT NULL

    ) t

    -- Keep only the latest record for each customer.
    WHERE flag_last = 1;


    PRINT '>> CRM Customer Information loaded successfully';


    -- ========================================================
    -- 2. CRM PRODUCT INFORMATION
    -- ========================================================
    -- Purpose:
    -- Load and standardize product information from Bronze.
    --
    -- Transformations:
    -- - Extract category ID from product key
    -- - Extract product key portion
    -- - Replace NULL product cost with 0
    -- - Convert product line codes into meaningful names
    -- - Convert product start/end dates to DATE
    -- - Generate product end date using the next start date
    -- ========================================================


    PRINT '============================================================';
    PRINT 'Loading Silver CRM Product Information';
    PRINT '============================================================';


    -- Remove existing Silver product data.
    PRINT '>> Truncate table: silver.crm_prd_info';

    TRUNCATE TABLE silver.crm_prd_info;


    -- Insert transformed product data.
    PRINT '>> Insert data into table: silver.crm_prd_info';


    INSERT INTO silver.crm_prd_info (
        prd_id,
        cat_id,
        prd_key,
        prd_nm,
        prd_cost,
        prd_line,
        prd_start_dt,
        prd_end_dt
    )

    SELECT

        prd_id,

        -- Extract the category portion from the product key.
        -- Example: 'CAT-12345' → 'CAT_1' depending on source format.
        REPLACE(
            SUBSTRING(prd_key, 1, 5),
            '-',
            '_'
        ) AS cat_id,


        -- Extract the product key after the category portion.
        SUBSTRING(
            prd_key,
            7,
            LEN(prd_key)
        ) AS prd_key,


        prd_nm,


        -- Replace missing product cost with 0.
        ISNULL(prd_cost, 0) AS prd_cost,


        -- Convert product line codes into readable descriptions.
        CASE
            WHEN UPPER(TRIM(prd_line)) = 'M'
                THEN 'Mountain'

            WHEN UPPER(TRIM(prd_line)) = 'R'
                THEN 'Road'

            WHEN UPPER(TRIM(prd_line)) = 'S'
                THEN 'Other Sales'

            WHEN UPPER(TRIM(prd_line)) = 'T'
                THEN 'Touring'

            ELSE 'n/a'
        END AS prd_line,


        -- Convert product start date into DATE format.
        CAST(prd_start_dt AS DATE) AS prd_start_dt,


        -- Use the next product start date as the current
        -- product's end date minus one day.
        --
        -- LEAD() looks at the next record within the same
        -- product key.
        CAST(
            LEAD(prd_start_dt) OVER (
                PARTITION BY prd_key
                ORDER BY prd_start_dt
            ) - 1
            AS DATE
        ) AS prd_end_dt


    FROM bronze.crm_prd_info;


    PRINT '>> CRM Product Information loaded successfully';


    -- ========================================================
    -- 3. CRM SALES DETAILS
    -- ========================================================
    -- Purpose:
    -- Load cleaned sales transactions from Bronze.
    --
    -- Transformations:
    -- - Convert integer dates into DATE
    -- - Handle invalid dates
    -- - Correct invalid/missing sales values
    -- - Correct missing/invalid prices
    -- ========================================================


    PRINT '============================================================';
    PRINT 'Loading Silver CRM Sales Details';
    PRINT '============================================================';


    -- Remove existing Silver sales data.
    PRINT '>> Truncate table: silver.crm_sales_details';

    TRUNCATE TABLE silver.crm_sales_details;


    -- Insert cleaned sales data.
    PRINT '>> Insert data into table: silver.crm_sales_details';


    INSERT INTO silver.crm_sales_details (
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

    SELECT

        sls_ord_num,
        sls_prd_key,
        sls_cust_id,


        -- Convert order date from YYYYMMDD integer
        -- into a proper SQL DATE.
        --
        -- Invalid or zero dates are converted to NULL.
        CASE
            WHEN sls_order_dt = 0
              OR LEN(sls_order_dt) != 8
                THEN NULL

            ELSE CAST(
                CAST(sls_order_dt AS VARCHAR)
                AS DATE
            )
        END AS sls_order_dt,


        -- Convert shipping date.
        CASE
            WHEN sls_ship_dt = 0
              OR LEN(sls_ship_dt) != 8
                THEN NULL

            ELSE CAST(
                CAST(sls_ship_dt AS VARCHAR)
                AS DATE
            )
        END AS sls_ship_dt,


        -- Convert due date.
        CASE
            WHEN sls_due_dt = 0
              OR LEN(sls_due_dt) != 8
                THEN NULL

            ELSE CAST(
                CAST(sls_due_dt AS VARCHAR)
                AS DATE
            )
        END AS sls_due_dt,


        -- Validate and correct sales amount.
        --
        -- If sales is NULL, zero/negative, or does not equal
        -- quantity × price, calculate it again.
        CASE
            WHEN sls_sales IS NULL
              OR sls_sales <= 0
              OR sls_sales != sls_quantity * ABS(sls_price)

                THEN sls_quantity * ABS(sls_price)

            ELSE sls_sales
        END AS sls_sales,


        sls_quantity,


        -- Validate price.
        --
        -- If price is missing or invalid, calculate it as:
        -- Sales / Quantity
        --
        -- NULLIF prevents a divide-by-zero error.
        CASE
            WHEN sls_price IS NULL
              OR sls_price <= 0

                THEN sls_sales /
                     NULLIF(sls_quantity, 0)

            ELSE sls_price
        END AS sls_price


    FROM bronze.crm_sales_details;


    PRINT '>> CRM Sales Details loaded successfully';


    -- ========================================================
    -- 4. ERP CUSTOMER
    -- ========================================================
    -- Purpose:
    -- Clean ERP customer information.
    --
    -- Transformations:
    -- - Remove 'NAS' prefix from customer IDs
    -- - Remove future birth dates
    -- - Standardize gender values
    -- ========================================================


    PRINT '============================================================';
    PRINT 'Loading Silver ERP Customer Information';
    PRINT '============================================================';


    PRINT '>> Truncate table: silver.erp_cust_az12';

    TRUNCATE TABLE silver.erp_cust_az12;


    PRINT '>> Insert data into table: silver.erp_cust_az12';


    INSERT INTO silver.erp_cust_az12 (
        cid,
        bdate,
        gen
    )

    SELECT

        -- Remove the 'NAS' prefix from customer IDs.
        CASE
            WHEN cid LIKE 'NAS%'
                THEN SUBSTRING(cid, 4, LEN(cid))

            ELSE cid
        END AS cid,


        -- Future birth dates are invalid,
        -- therefore convert them to NULL.
        CASE
            WHEN bdate > GETDATE()
                THEN NULL

            ELSE bdate
        END AS bdate,


        -- Standardize gender values.
        CASE
            WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE')
                THEN 'Female'

            WHEN UPPER(TRIM(gen)) IN ('M', 'MALE')
                THEN 'Male'

            ELSE 'n/a'
        END AS gen


    FROM bronze.erp_cust_az12;


    PRINT '>> ERP Customer Information loaded successfully';


    -- ========================================================
    -- 5. ERP LOCATION
    -- ========================================================
    -- Purpose:
    -- Clean and standardize customer country information.
    --
    -- Transformations:
    -- - Replace '-' in customer IDs
    -- - Convert country codes into country names
    -- - Handle missing country values
    -- ========================================================


    PRINT '============================================================';
    PRINT 'Loading Silver ERP Location Information';
    PRINT '============================================================';


    PRINT '>> Truncate table: silver.erp_loc_a101';

    TRUNCATE TABLE silver.erp_loc_a101;


    PRINT '>> Insert data into table: silver.erp_loc_a101';


    INSERT INTO silver.erp_loc_a101 (
        cid,
        cntry
    )

    SELECT

        -- Standardize customer ID by replacing '-'
        -- with a space.
        REPLACE(cid, '-', ' ') AS cid,


        -- Convert country codes into full country names.
        CASE
            WHEN TRIM(cntry) = 'DE'
                THEN 'Germany'

            WHEN TRIM(cntry) IN ('US', 'USA')
                THEN 'United States'

            -- Missing country values are assigned Germany
            -- based on the source/business rule.
            WHEN TRIM(cntry) = ''
              OR cntry IS NULL
                THEN 'Germany'

            ELSE TRIM(cntry)
        END AS cntry


    FROM bronze.erp_loc_a101;


    PRINT '>> ERP Location Information loaded successfully';


    -- ========================================================
    -- 6. ERP PRODUCT CATEGORY
    -- ========================================================
    -- Purpose:
    -- Move product category information from Bronze to Silver.
    --
    -- This table currently does not require additional
    -- transformations, so the data is directly inserted.
    -- ========================================================


    PRINT '============================================================';
    PRINT 'Loading Silver ERP Product Category';
    PRINT '============================================================';


    PRINT '>> Truncate table: silver.erp_px_cat';

    TRUNCATE TABLE silver.erp_px_cat;


    PRINT '>> Insert data into table: silver.erp_px_cat';


    INSERT INTO silver.erp_px_cat (
        id,
        cat,
        subcat,
        maintenance
    )

    SELECT
        id,
        cat,
        subcat,
        maintenance

    FROM bronze.erp_px_cat;


    PRINT '>> ERP Product Category loaded successfully';


    -- ========================================================
    -- SILVER LAYER LOAD COMPLETED
    -- ========================================================

    PRINT '============================================================';
    PRINT 'Silver Layer Load Completed Successfully';
    PRINT '============================================================';

END;
GO
