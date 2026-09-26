CREATE OR REPLACE PACKAGE pkg_etl_insert_customers
AUTHID CURRENT_USER
AS
  PROCEDURE insert_table_customers;
  PROCEDURE merge_table_customers;
						
END pkg_etl_insert_customers;
/

CREATE OR REPLACE PACKAGE BODY pkg_etl_insert_customers
AS
---------------------------------------------------  
PROCEDURE insert_table_customers
IS
BEGIN
  EXECUTE IMMEDIATE ('TRUNCATE TABLE cls_customers_scd');
  BEGIN
    INSERT INTO cls_customers_scd
    SELECT --+PARALLEL(4)
           DISTINCT
           customer_id AS customer_surr_id,
           customer_srcid AS customer_surr_id,
           first_name,
           last_name,
           age,
           ac.age_category_desc AS age_category,
           email,
           phone,
           address,
           cs.city_desc AS city,
           cn.country_desc AS country,
           cr.region_desc AS region,
           start_dt,
           end_dt,
           is_active
    FROM   bl_3nf.ce_customers cc left join bl_3nf.ce_age_categories ac
                                         on cc.age_category_srcid = ac.age_category_srcid
                                  left join bl_3nf.ce_cities cs
                                         on cc.city_srcid = cs.city_srcid
                                  left join bl_3nf.ce_countries cn
                                         on cs.country_srcid = cn.country_srcid
                                  left join bl_3nf.ce_regions cr
                                         on cn.region_srcid = cr.region_srcid;
      
      END;
  COMMIT;
  
EXCEPTION
  WHEN OTHERS THEN
  RAISE;

END insert_table_customers;
--------------------------------------------------- 
PROCEDURE merge_table_customers
IS
BEGIN
  MERGE INTO bl_dm.dim_customers_scd t USING
    ( SELECT customer_surr_id,
             first_name,
             last_name,
             age,
             age_category,
             email,
             phone,
             address,
             city,
             country,
             region,
             start_dt,
             end_dt,
             is_active 
      FROM   cls_customers_scd
    MINUS
      SELECT customer_id AS customer_surr_id,
             first_name,
             last_name,
             age,
             age_category,
             email,
             phone,
             address,
             city,
             country,
             region,
             start_dt,
             end_dt,
             is_active           
      FROM   bl_dm.dim_customers_scd
    ) c ON (  
             t.first_name = c.first_name
       AND   t.last_name = c.last_name
       AND   t.age = c.age
       AND   t.age_category = c.age_category
       AND   t.email = c.email
       AND   t.phone = c.phone
       AND   t.address = c.address
       AND   t.city = c.city
       AND   t.country = c.country
       AND   t.region = c.region
       AND   t.start_dt = c.start_dt)
    WHEN matched THEN
    UPDATE SET 
               t.customer_id = c.customer_surr_id,
               t.end_dt = c.end_dt,
               t.is_active = c.is_active
    WHEN NOT matched THEN
    INSERT
      (
       customer_surr_id,
       customer_id,
       first_name,
       last_name,
       age,
       age_category,
       email,
       phone,
       address,
       city,
       country,
       region,
       start_dt,
       end_dt,
       is_active 
      )
      VALUES
      (
       bl_dm.dim_customers_seq.NEXTVAL,
       c.customer_surr_id,
       c.first_name,
       c.last_name,
       c.age,
       c.age_category,
       c.email,
       c.phone,
       c.address,
       c.city,
       c.country,
       c.region,
       c.start_dt,
       c.end_dt,
       c.is_active
      ) ;
    COMMIT;
  
EXCEPTION
  WHEN OTHERS THEN
  RAISE;

END merge_table_customers;
--------------------------------------------------- 
END pkg_etl_insert_customers;
/