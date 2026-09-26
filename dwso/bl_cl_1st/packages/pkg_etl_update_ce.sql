CREATE OR REPLACE PACKAGE pkg_etl_update_tables
AUTHID CURRENT_USER
AS
  PROCEDURE update_table_customers;
  PROCEDURE update_table_employees;
  PROCEDURE update_table_payment_methods;
  PROCEDURE update_table_products;
						
END pkg_etl_update_tables;
/

CREATE OR REPLACE PACKAGE BODY pkg_etl_update_tables
AS
---------------------------------------------------  
PROCEDURE update_table_customers
IS
BEGIN

 MERGE INTO bl_3nf.ce_customers t USING
    ( SELECT a.customer_id,
             a.start_dt,
             a.end_dt,
             a.is_active
      FROM   cls_customers a, bl_3nf.ce_customers b
      WHERE  a.customer_id = b.customer_srcid 
        AND  a.start_dt < b.start_dt
        AND  UPPER(SUBSTR(TRIM(a.is_active),1,4)) <> 'FALSE'
    ) c ON ( c.customer_id = t.customer_srcid
       AND   c.start_dt = t.start_dt)
    WHEN matched THEN
    UPDATE SET 
               t.end_dt  = SYSDATE,
               t.is_active = 'false'; 

  COMMIT;
  
EXCEPTION
  WHEN OTHERS THEN
  RAISE;

END update_table_customers;
---------------------------------------------------  
PROCEDURE update_table_employees
IS
BEGIN

 MERGE INTO bl_3nf.ce_employees t USING
    ( SELECT a.employee_id,
             a.start_dt,
             a.end_dt,
             a.is_active
      FROM   cls_employees a, bl_3nf.ce_employees b
      WHERE  a.employee_id = b.employee_srcid 
        AND  a.start_dt < b.start_dt
        AND  UPPER(SUBSTR(TRIM(a.is_active),1,4)) <> 'FALSE'
    ) c ON ( c.employee_id = t.employee_srcid
       AND   c.start_dt = t.start_dt)
    WHEN matched THEN
    UPDATE SET 
               t.end_dt  = SYSDATE,
               t.is_active = 'false'; 

  COMMIT;
  
EXCEPTION
  WHEN OTHERS THEN
  RAISE;

END update_table_employees;
---------------------------------------------------  
PROCEDURE update_table_payment_methods
IS
BEGIN

 MERGE INTO bl_3nf.ce_payment_methods t USING
    ( SELECT a.payment_method_id,
             a.bank,
             a.start_dt,
             a.end_dt,
             a.is_active
      FROM   cls_payment_methods a, bl_3nf.ce_payment_methods b
      WHERE  a.bank = b.bank_desc 
        AND  a.start_dt < b.start_dt 
        AND  UPPER(SUBSTR(TRIM(a.is_active),1,4)) <> 'FALSE'
    ) c ON ( c.bank = t.bank_desc
       AND   c.start_dt = t.start_dt)
    WHEN matched THEN
    UPDATE SET 
               t.end_dt  = SYSDATE,
               t.is_active = 'false'; 

  COMMIT;
  
EXCEPTION
  WHEN OTHERS THEN
  RAISE;

END update_table_payment_methods;
--------------------------------------------------- 
PROCEDURE update_table_products
IS
BEGIN

 MERGE INTO bl_3nf.ce_products t USING
    ( SELECT a.product_id,
             a.start_dt,
             a.end_dt,
             a.is_active
      FROM   cls_products a, bl_3nf.ce_products b
      WHERE  a.product_id = b.product_srcid 
        AND  a.start_dt < b.start_dt  
        AND  UPPER(SUBSTR(TRIM(a.is_active),1,4)) <> 'FALSE'
    ) c ON ( c.product_id = t.product_srcid
       AND   c.start_dt = t.start_dt)
    WHEN matched THEN
    UPDATE SET 
               t.end_dt  = SYSDATE,
               t.is_active = 'false'; 

  COMMIT;
  
EXCEPTION
  WHEN OTHERS THEN
  RAISE;

END update_table_products;
--------------------------------------------------- 
END pkg_etl_update_tables;
/