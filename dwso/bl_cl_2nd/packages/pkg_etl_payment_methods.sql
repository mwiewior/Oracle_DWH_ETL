CREATE OR REPLACE PACKAGE pkg_etl_insert_payment_methods
AUTHID CURRENT_USER
AS
  PROCEDURE insert_table_payment_methods;
  PROCEDURE merge_table_payment_methods;
					
END pkg_etl_insert_payment_methods;
/

CREATE OR REPLACE PACKAGE BODY pkg_etl_insert_payment_methods
AS
---------------------------------------------------  
PROCEDURE insert_table_payment_methods
IS
BEGIN
  EXECUTE IMMEDIATE ('TRUNCATE TABLE cls_payment_methods_scd');
INSERT INTO cls_payment_methods_scd
SELECT DISTINCT
    payment_method_id AS payment_method_surr_id,
    payment_method_srcid AS payment_method_id,
    payment_method_desc,
    bank_desc AS bank_name,
    start_dt,
    end_dt,
    is_active
FROM   bl_3nf.ce_payment_methods;

  COMMIT;
  
EXCEPTION
  WHEN OTHERS THEN
  RAISE;

END insert_table_payment_methods;
---------------------------------------------------
PROCEDURE merge_table_payment_methods
IS
BEGIN

MERGE INTO bl_dm.dim_payment_methods_scd t USING
    ( SELECT payment_method_surr_id,
             payment_method_desc,
             bank_name,
             start_dt,
             end_dt,
             is_active
      FROM   cls_payment_methods_scd
    MINUS
      SELECT payment_method_id,
             payment_method_desc,
             bank_name,
             start_dt,
             end_dt,
             is_active          
      FROM   bl_dm.dim_payment_methods_scd
    ) c ON ( t.payment_method_desc = c.payment_method_desc
        AND  t.bank_name = c.bank_name
        AND  t.start_dt = c.start_dt)
    WHEN matched THEN
    UPDATE SET 
               t.payment_method_id = c.payment_method_surr_id,
               t.end_dt = c.end_dt,
               t.is_active = c.is_active
    WHEN NOT matched THEN
    INSERT
      (
       payment_method_surr_id,
       payment_method_id,
       payment_method_desc,
       bank_name,
       start_dt,
       end_dt,
       is_active
      )
      VALUES
      (
       bl_dm.dim_payment_methods_seq.NEXTVAL,
       c.payment_method_surr_id,
       c.payment_method_desc,
       c.bank_name,
       c.start_dt,
       c.end_dt,
       c.is_active
      ) ;
    COMMIT;
EXCEPTION
WHEN OTHERS THEN
    RAISE;
END merge_table_payment_methods;
---------------------------------------------------
END pkg_etl_insert_payment_methods;
/