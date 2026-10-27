
/*
=============================================================
MEDALLION ARCHITECTURE
SILVER LAYER - SALES DETAILS
=============================================================

Source:
    Bronze.crm_sales_details

Destination:
    Silver.crm_sales_details

Transformations:
    1. Trim and standardize text keys
    2. Convert YYYYMMDD values into DATE
    3. Reconcile sales amount and unit price
    4. Validate quantity and financial values
    5. Validate product and customer references
    6. Reject invalid date sequences
    7. Prevent duplicate inserts
    8. Populate Silver processing metadata
    9. Use transaction and error handling

Metadata:
    dwh_create_date  -> Default UTC timestamp
    dwh_update_date  -> Default UTC timestamp
    dwh_source       -> Source table identifier
    dwh_batch_id     -> NULL until batch tracking exists
=============================================================
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

    BEGIN TRANSACTION;

    ;WITH Standardized AS
    (
        SELECT
            NULLIF(TRIM(sale_ord_num), '')
                AS sale_ord_num,

            NULLIF(TRIM(sale_prd_key), '')
                AS sale_prd_key,

            sale_cust_id,

            CASE
                WHEN LEN(
                    TRIM(CONVERT(VARCHAR(30), sale_ord_date))
                ) = 8
                THEN TRY_CONVERT(
                    DATE,
                    CONVERT(VARCHAR(8), sale_ord_date),
                    112
                )
            END AS sale_ord_date,

            CASE
                WHEN LEN(
                    TRIM(CONVERT(VARCHAR(30), sale_ship_date))
                ) = 8
                THEN TRY_CONVERT(
                    DATE,
                    CONVERT(VARCHAR(8), sale_ship_date),
                    112
                )
            END AS sale_ship_date,

            CASE
                WHEN LEN(
                    TRIM(CONVERT(VARCHAR(30), sale_due_date))
                ) = 8
                THEN TRY_CONVERT(
                    DATE,
                    CONVERT(VARCHAR(8), sale_due_date),
                    112
                )
            END AS sale_due_date,

            sale_sales,
            sale_quantity,
            sale_price

        FROM Bronze.crm_sales_details
    ),

    Calculated AS
    (
        SELECT
            *,

            CASE
                WHEN sale_quantity > 0
                 AND sale_price IS NOT NULL
                 AND sale_price <> 0
                THEN
                    sale_quantity * ABS(sale_price)
            END AS expected_sales

        FROM Standardized
    ),

    Cleaned AS
    (
        SELECT
            sale_ord_num,
            sale_prd_key,
            sale_cust_id,
            sale_ord_date,
            sale_ship_date,
            sale_due_date,

            CASE
                WHEN expected_sales IS NOT NULL
                 AND (
                        sale_sales IS NULL
                     OR sale_sales <= 0
                     OR sale_sales <> expected_sales
                 )
                THEN expected_sales

                WHEN sale_sales > 0
                THEN sale_sales

                ELSE NULL
            END AS sale_sales,

            sale_quantity,

            ROUND(
                CASE
                    WHEN sale_price IS NULL
                      OR sale_price <= 0
                    THEN
                        CASE
                            WHEN sale_quantity > 0
                             AND sale_sales > 0
                            THEN
                                sale_sales /
                                NULLIF(sale_quantity, 0)
                        END

                    ELSE sale_price
                END,
                2
            ) AS sale_price

        FROM Calculated
    )

    INSERT INTO Silver.crm_sales_details
    (
        sale_ord_num,
        sale_prd_key,
        sale_cust_id,
        sale_ord_date,
        sale_ship_date,
        sale_due_date,
        sale_sales,
        sale_quantity,
        sale_price,
        dwh_source,
        dwh_batch_id
    )

    SELECT
        c.sale_ord_num,
        c.sale_prd_key,
        c.sale_cust_id,
        c.sale_ord_date,
        c.sale_ship_date,
        c.sale_due_date,
        c.sale_sales,
        c.sale_quantity,
        c.sale_price,

        N'Bronze.crm_sales_details' AS dwh_source,

        NULL AS dwh_batch_id

    FROM Cleaned AS c

    WHERE
        -- Required business keys
        c.sale_ord_num IS NOT NULL
        AND c.sale_prd_key IS NOT NULL
        AND c.sale_cust_id IS NOT NULL

        -- Valid financial values
        AND c.sale_quantity > 0
        AND c.sale_sales > 0
        AND c.sale_price > 0

        -- Valid date sequence when dates are available
        AND (
            c.sale_ord_date IS NULL
            OR (
                (
                    c.sale_ship_date IS NULL
                    OR c.sale_ord_date <= c.sale_ship_date
                )
                AND
                (
                    c.sale_due_date IS NULL
                    OR c.sale_ord_date <= c.sale_due_date
                )
            )
        )

        -- Product referential integrity
        AND EXISTS
        (
            SELECT 1
            FROM Silver.crm_prod_info AS p
            WHERE p.product_key = c.sale_prd_key
        )

        -- Customer referential integrity
        AND EXISTS
        (
            SELECT 1
            FROM Silver.crm_cust_info AS cu
            WHERE cu.cust_id = c.sale_cust_id
        )

        -- Prevent duplicate inserts on reruns
        AND NOT EXISTS
        (
            SELECT 1
            FROM Silver.crm_sales_details AS existing
            WHERE existing.sale_ord_num = c.sale_ord_num
              AND existing.sale_prd_key = c.sale_prd_key
        );

    DECLARE @RowsInserted INT = @@ROWCOUNT;

    COMMIT TRANSACTION;

    -- Load summary
    SELECT
        'Silver.crm_sales_details' AS destination_table,
        @RowsInserted AS rows_inserted,
        SYSUTCDATETIME() AS load_completed_utc;

END TRY

BEGIN CATCH

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    SELECT
        ERROR_NUMBER() AS error_number,
        ERROR_MESSAGE() AS error_message,
        ERROR_LINE() AS error_line;

    THROW;

END CATCH;
