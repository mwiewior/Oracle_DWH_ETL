CREATE OR REPLACE PACKAGE pkg_etl_insert_stores
AUTHID CURRENT_USER
AS
  PROCEDURE insert_table_stores;
  PROCEDURE merge_table_ce_stores;
  
END pkg_etl_insert_stores;
/

CREATE OR REPLACE PACKAGE BODY pkg_etl_insert_stores
AS
---------------------------------------------------  
PROCEDURE insert_table_stores
IS
BEGIN
  EXECUTE IMMEDIATE ('TRUNCATE TABLE cls_stores');
  INSERT INTO cls_stores (
                              store_id,
                              store_code,
                              store_name,
                              manager_id,
                              phone,
                              address,
                              city_id,
                              insert_dt,
                              update_dt
                            )
  SELECT store_code || '-' || SUBSTR(phone,1,3) AS store_id,
         store_code,
         store_name,
         manager_id,
         phone,
         address,
         wct.city_id,
         wst.start_dt AS insert_dt,
         SYSDATE AS update_dt
  FROM   wrk_stores wst left join wrk_cities wct on wst.city = wct.city_desc
  WHERE  wct.city_id IS NOT NULL;

  COMMIT;
  
EXCEPTION
  WHEN OTHERS THEN
  RAISE;

END insert_table_stores;
---------------------------------------------------  
---------------------------------------------------
PROCEDURE merge_table_ce_stores
IS
BEGIN

MERGE INTO bl_3nf.ce_stores t USING
    ( SELECT store_id,
             store_code,
             store_name,
             manager_id,
             phone,
             address,
             city_id,
             insert_dt,
             update_dt
      FROM   cls_stores
    MINUS
      SELECT store_srcid AS store_id,
             store_code,
             store_desc AS store_name,
             manager_number AS manager_id,
             phone,
             address,
             city_srcid AS city_id,
             insert_dt,
             update_dt
      FROM   bl_3nf.ce_stores
    ) c ON ( c.store_id = t.store_srcid
       AND   t.store_desc  = c.store_name
       AND   t.store_code  = c.store_code
       AND   t.manager_number = c.manager_id
       AND   t.phone  = c.phone
       AND   t.address = c.address
       AND   t.city_srcid  = c.city_id
       AND   c.insert_dt = t.insert_dt )
    WHEN matched THEN
    UPDATE SET
              t.update_dt  = c.update_dt
    WHEN NOT matched THEN
    INSERT
      (
        store_id,
        store_srcid,
        store_code,
        store_desc,
        manager_number,
        phone,
        address,
        city_srcid,
        insert_dt,
        update_dt
      )
      VALUES
      (
        bl_3nf.ce_stores_seq.NEXTVAL,
        c.store_id,
        c.store_code,
        c.store_name,
        c.manager_id,
        c.phone,
        c.address,
        c.city_id,
        c.insert_dt,
        SYSDATE
      ) ;
    COMMIT;
EXCEPTION
WHEN OTHERS THEN
    RAISE;
END merge_table_ce_stores;
---------------------------------------------------
END pkg_etl_insert_stores;
/