CREATE OR REPLACE PACKAGE pkg_etl_insert_stores
AUTHID CURRENT_USER
AS
  PROCEDURE insert_table_stores;
  PROCEDURE merge_table_dim_stores;
  
END pkg_etl_insert_stores;
/

CREATE OR REPLACE PACKAGE BODY pkg_etl_insert_stores
AS
---------------------------------------------------  
PROCEDURE insert_table_stores
IS
BEGIN
  EXECUTE IMMEDIATE ('TRUNCATE TABLE cls_stores_scd');
  DECLARE
     CURSOR s_cur IS 
          SELECT  DISTINCT
                  store_id AS store_surr_id,
                  store_srcid AS store_id,
                  store_desc,
                  phone,
                  address,
                  cs.city_desc AS city,
                  cn.country_desc AS country,
                  cr.region_desc AS region,
                  insert_dt,
                  SYSDATE AS update_dt
          FROM    bl_3nf.ce_stores   cc left join bl_3nf.ce_cities cs
                                               on cc.city_srcid = cs.city_srcid
                                        left join bl_3nf.ce_countries cn
                                               on cs.country_srcid = cn.country_srcid
                                        left join bl_3nf.ce_regions cr
                                               on cn.region_srcid = cr.region_srcid;
    
     TYPE fetch_array IS TABLE OF s_cur%ROWTYPE;
     s_array fetch_array;
    BEGIN
      OPEN s_cur;
      LOOP
        FETCH s_cur BULK COLLECT INTO s_array;
    
        FORALL i IN 1..s_array.COUNT
        INSERT INTO cls_stores_scd
        VALUES s_array(i);
        EXIT WHEN s_cur%NOTFOUND;
      END LOOP;
      CLOSE s_cur;
      COMMIT;
    END;  
EXCEPTION
  WHEN OTHERS THEN
  RAISE;

END insert_table_stores;
---------------------------------------------------  
PROCEDURE merge_table_dim_stores
IS
BEGIN
DECLARE
   CURSOR c_data IS
    SELECT   a.store_surr_id,
             a.store_desc,
             b.phone,
             b.address,
             a.city,
             a.country,
             a.region,
             a.insert_dt,
             a.update_dt
      FROM   cls_stores_scd a LEFT OUTER JOIN bl_dm.dim_stores_scd b 
                                           ON a.store_surr_id = b.store_id;
   TYPE t__data IS TABLE OF c_data%rowtype INDEX BY binary_integer;
   t_data t__data;
   
BEGIN
   OPEN c_data;
   loop
      fetch c_data BULK COLLECT INTO t_data;
      exit WHEN t_data.count = 0;
      FOR idx IN t_data.FIRST .. t_data.LAST loop
         IF t_data(idx).phone IS NULL THEN
      INSERT INTO bl_dm.dim_stores_scd
      SELECT bl_dm.dim_stores_seq.NEXTVAL,
             store_surr_id, 
             store_desc, 
             phone, 
             address, 
             city, 
             country, 
             region, 
             insert_dt, 
             update_dt 
      FROM (SELECT store_surr_id,
                   store_desc,
                   phone,
                   address,
                   city,
                   country,
                   region,
                   insert_dt,
                   update_dt 
            FROM cls_stores_scd
               MINUS
            SELECT a.store_surr_id,
                   a.store_desc,
                   a.phone,
                   a.address,
                   a.city,
                   a.country,
                   a.region,
                   a.insert_dt,
                   a.update_dt  
            FROM cls_stores_scd a, bl_dm.dim_stores_scd b 
      WHERE b.store_id = a.store_surr_id
        AND b.store_desc = a.store_desc
        AND b.phone = a.phone
        AND b.address = a.address
        AND b.city = a.city
        AND b.country = a.country
        AND b.region = a.region);
      ELSE
      UPDATE bl_dm.dim_stores_scd
      SET    update_dt = t_data(idx).update_dt;
      END IF;
   END loop;
  END loop;
 CLOSE c_data;
END;
EXCEPTION
WHEN OTHERS THEN
    RAISE;
END merge_table_dim_stores;
---------------------------------------------------
END pkg_etl_insert_stores;
/