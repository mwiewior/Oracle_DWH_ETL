CREATE OR REPLACE PACKAGE pkg_etl_insert_receipts
AUTHID CURRENT_USER
AS
  PROCEDURE insert_table_receipts;
  PROCEDURE merge_table_ce_receipts;
					
END pkg_etl_insert_receipts;
/

CREATE OR REPLACE PACKAGE BODY pkg_etl_insert_receipts
AS
---------------------------------------------------  
PROCEDURE insert_table_receipts
IS
BEGIN
  EXECUTE IMMEDIATE ('TRUNCATE TABLE cls_receipts');
  BEGIN
  
    INSERT INTO cls_receipts (
                                receipt_id,
                                receipt_dt,
                                store_id,
                                employee_id,
                                customer_id,
                                payment_method_id,
                                product_detail_id,
                                receipt_sum,
                                insert_dt
                              )
    SELECT receipt_id,
           receipt_dt,
           store_id,
           employee_id,
           customer_id,
           payment_method_id,
           product_detail_id,
           receipt_sum,
           SYSDATE AS insert_dt
    FROM (
        SELECT TRUNC(dbms_random.value(100000000000, 9999999999999)) AS receipt_id ,
               TRUNC ( (sysdate + 4) + dbms_random.value ( 1, 1000 ) )    AS receipt_dt ,
               ROUND ( dbms_random.value ( ( SELECT MIN ( store_id ) FROM bl_3nf.ce_stores), 
                                           ( SELECT MAX ( store_id ) FROM bl_3nf.ce_stores) ) ) AS store_id ,
               ROUND ( dbms_random.value ( ( SELECT MIN ( employee_id) FROM bl_3nf.ce_employees WHERE UPPER(SUBSTR(TRIM(is_active),1,4))='TRUE'),
                                           ( SELECT MAX ( employee_id) FROM bl_3nf.ce_employees WHERE UPPER(SUBSTR(TRIM(is_active),1,4))='TRUE'))) AS employee_id,
               ROUND ( dbms_random.value ( ( SELECT MIN ( customer_id ) FROM bl_3nf.ce_customers WHERE UPPER(SUBSTR(TRIM(is_active),1,4))='TRUE'), 
                                           ( SELECT MAX ( customer_id ) FROM bl_3nf.ce_customers WHERE UPPER(SUBSTR(TRIM(is_active),1,4))='TRUE') ) ) AS customer_id,
               ROUND ( dbms_random.value ( ( SELECT MIN ( payment_method_id ) FROM bl_3nf.ce_payment_methods WHERE UPPER(SUBSTR(TRIM(is_active),1,4))='TRUE'), 
                                           ( SELECT MAX ( payment_method_id ) FROM bl_3nf.ce_payment_methods WHERE UPPER(SUBSTR(TRIM(is_active),1,4))='TRUE') ) ) AS payment_method_id,
               ROUND ( dbms_random.value ( ( SELECT MIN ( product_details_id ) FROM bl_3nf.ce_product_details a INNER JOIN bl_3nf.ce_products b
                                                                                  ON a.product_srcid = b.product_srcid               
                                                                                  WHERE UPPER(SUBSTR(TRIM(is_active),1,4))='TRUE'), 
                                           ( SELECT MAX ( product_details_id ) FROM bl_3nf.ce_product_details a INNER JOIN bl_3nf.ce_products b
                                                                                  ON a.product_srcid = b.product_srcid               
                                                                                  WHERE UPPER(SUBSTR(TRIM(is_active),1,4))='TRUE') ) ) AS product_detail_id,
               ROUND ( dbms_random.value( 100, 99999), 2) AS receipt_sum 
         FROM (SELECT * FROM dual connect by level <1000000)
        );
  
  END;

  COMMIT;
  
EXCEPTION
  WHEN OTHERS THEN
  RAISE;

END insert_table_receipts;
--------------------------------------------------- 
---------------------------------------------------
PROCEDURE merge_table_ce_receipts
IS
BEGIN

MERGE INTO bl_3nf.ce_receipts t USING
    ( SELECT receipt_id,
             receipt_dt,
             store_id,
             employee_id,
             customer_id,
             payment_method_id,
             product_detail_id,
             receipt_sum,
             insert_dt
      FROM   cls_receipts
    MINUS
      SELECT receipt_id,
             receipt_dt,
             store_id,
             employee_id,
             customer_id,
             payment_method_id,
             product_detail_id,
             receipt_sum_usd AS receipt_sum,
             insert_dt 
      FROM   bl_3nf.ce_receipts
    ) c ON (  
             c.receipt_id = t.receipt_id
       AND   c.insert_dt = t.insert_dt
       AND   c.receipt_dt = t.receipt_dt
       AND   c.customer_id = t.customer_id
       AND   c.employee_id = t.employee_id
       AND   c.receipt_sum = t.receipt_sum_usd
       AND   c.product_detail_id = t.product_detail_id
       )
    WHEN NOT matched THEN
    INSERT
      (
        receipt_id,
        receipt_dt,
        store_id,
        employee_id,
        customer_id,
        payment_method_id,
        product_detail_id,
        receipt_sum_usd,
        insert_dt 
      )
      VALUES
      (
        c.receipt_id,
        c.receipt_dt,
        c.store_id,
        c.employee_id,
        c.customer_id,
        c.payment_method_id,
        c.product_detail_id,
        c.receipt_sum,
        c.insert_dt
      ) ;
    COMMIT;
EXCEPTION
WHEN OTHERS THEN
    RAISE;
END merge_table_ce_receipts;
---------------------------------------------------
END pkg_etl_insert_receipts;
/