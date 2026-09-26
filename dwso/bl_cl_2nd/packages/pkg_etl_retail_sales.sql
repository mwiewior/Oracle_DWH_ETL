CREATE OR REPLACE PACKAGE pkg_etl_insert_retail_sales
AUTHID CURRENT_USER
AS
  PROCEDURE insert_table_retail_sales;
  PROCEDURE insert_table_fct_retail_sales;
  
END pkg_etl_insert_retail_sales;
/

CREATE OR REPLACE PACKAGE BODY pkg_etl_insert_retail_sales
AS
---------------------------------------------------  
PROCEDURE insert_table_retail_sales
IS
BEGIN
  EXECUTE IMMEDIATE ('TRUNCATE TABLE cls_fct_retail_sales_dd');
INSERT INTO cls_fct_retail_sales_dd
SELECT receipt_id,
       cr.receipt_dt AS event_dt,
       ce.employee_id AS employee_surr_id,
       cm.customer_id AS customer_surr_id, 
       ct.store_id AS store_id,
       cr.payment_method_id AS payment_method_surr_id,
       cr.product_detail_id AS product_detail_surr_id,
       cr.receipt_sum_usd AS tot_sale_sum,
       ROUND ( dbms_random.value( 100, 99999), 2) AS tot_sale_amount,
       cr.insert_dt AS insert_dt,
       SYSDATE AS update_dt
FROM   bl_3nf.ce_receipts cr left join bl_3nf.ce_employees ce
                                    on cr.employee_id = ce.employee_id
                             left join bl_3nf.ce_customers cm
                                    on cr.customer_id = cm.customer_id
                             left join bl_3nf.ce_stores ct
                                    on cr.store_id = ct.store_id
                             left join bl_3nf.ce_product_details cpd
                                    on cr.product_detail_id = cpd.product_details_id;

COMMIT;
  
EXCEPTION
  WHEN OTHERS THEN
  RAISE;

END insert_table_retail_sales;
---------------------------------------------------  
PROCEDURE insert_table_fct_retail_sales
IS
BEGIN
   INSERT INTO  
             bl_dm.fct_retail_sales_dd
   SELECT    
             bl_dm.fct_retail_sales_dd_seq.NEXTVAL AS sale_id,
             a.receipt_id,
             a.event_dt,
             c.employee_surr_id,
             b.customer_surr_id,
             d.store_surr_id,
             e.payment_method_id,
             f.product_surr_id,
             a.tot_sale_sum,
             a.tot_sale_amount,
             a.insert_dt,
             a.update_dt 
      FROM   cls_fct_retail_sales_dd a INNER JOIN bl_dm.dim_customers_scd b ON a.customer_surr_id = b.customer_id
                                       INNER JOIN bl_dm.dim_employees_scd c ON a.employee_surr_id = c.employee_id
                                       INNER JOIN bl_dm.dim_stores_scd d ON a.store_surr_id = d.store_id
                                       INNER JOIN bl_dm.dim_payment_methods_scd e ON a.payment_method_surr_id = e.payment_method_id
                                       INNER JOIN bl_dm.dim_products_scd f ON a.product_surr_id = f.product_id;
    COMMIT;
EXCEPTION
WHEN OTHERS THEN
    RAISE;
END insert_table_fct_retail_sales;
---------------------------------------------------
END pkg_etl_insert_retail_sales;
/