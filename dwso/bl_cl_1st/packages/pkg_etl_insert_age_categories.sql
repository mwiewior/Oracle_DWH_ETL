CREATE OR REPLACE PACKAGE pkg_etl_insert_age_categories
AUTHID CURRENT_USER
AS
  PROCEDURE insert_table_age_categories;
  PROCEDURE merge_table_ce_age_categories;
						
END pkg_etl_insert_age_categories;
/

CREATE OR REPLACE PACKAGE BODY pkg_etl_insert_age_categories
AS
---------------------------------------------------  
PROCEDURE insert_table_age_categories
IS
BEGIN
  EXECUTE IMMEDIATE ('TRUNCATE TABLE cls_age_categories');
  DECLARE
     CURSOR ac_cursor IS
             SELECT DISTINCT age_category_id,
            (CASE WHEN age_category_id = 1 THEN 'youth'
                  WHEN age_category_id = 2 THEN 'middle youth'
                  WHEN age_category_id = 3 THEN 'middle'
                  WHEN age_category_id = 4 THEN 'adult'
                  WHEN age_category_id = 5 THEN 'old'
             END)  AS age_category
             FROM cls_customers;
   BEGIN
     FOR ac_cursor_val IN ac_cursor LOOP
       INSERT INTO cls_age_categories (
                                       age_category_id,
                                       age_category 
                                       )
            VALUES (
                    ac_cursor_val.age_category_id,
                    ac_cursor_val.age_category 
                   );
      END LOOP;
   COMMIT;
  END;  
EXCEPTION
  WHEN OTHERS THEN
  RAISE;

END insert_table_age_categories;
---------------------------------------------------  
---------------------------------------------------
PROCEDURE merge_table_ce_age_categories
IS
BEGIN

MERGE INTO bl_3nf.ce_age_categories t USING
    ( SELECT age_category_id,
             age_category 
      FROM   cls_age_categories
    MINUS
      SELECT age_category_srcid AS age_category_id,
             age_category_desc  AS age_category
      FROM   bl_3nf.ce_age_categories
    ) c ON ( t.age_category_desc = c.age_category)
    WHEN MATCHED THEN
    UPDATE SET
             t.age_category_srcid = c.age_category_id
    WHEN NOT matched THEN
    INSERT
      (
        age_category_id ,
        age_category_srcid ,
        age_category_desc
      )
      VALUES
      (
        bl_3nf.ce_age_categories_seq.NEXTVAL,
        c.age_category_id ,
        c.age_category
      ) ;
    COMMIT;
EXCEPTION
WHEN OTHERS THEN
    RAISE;
END merge_table_ce_age_categories;
---------------------------------------------------
END pkg_etl_insert_age_categories;
/