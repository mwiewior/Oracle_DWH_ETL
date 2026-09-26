CREATE OR REPLACE PACKAGE pkg_etl_insert_sizes
AUTHID CURRENT_USER
AS
  PROCEDURE insert_table_bras;
  PROCEDURE insert_table_panties;
  PROCEDURE merge_table_ce_bra_size_grid;
  PROCEDURE merge_table_ce_panty_size_grid;
						
END pkg_etl_insert_sizes;
/

CREATE OR REPLACE PACKAGE BODY pkg_etl_insert_sizes
AS
---------------------------------------------------  
PROCEDURE insert_table_bras
IS
BEGIN
  EXECUTE IMMEDIATE ('TRUNCATE TABLE cls_bra_sizes');
  INSERT INTO cls_bra_sizes ( 
                              bra_size_id,
                              bra_size_uk,
                              bra_size_usa,
                              bra_size_eu,
                              bra_size_fr,
                              bra_size_uie
                            )
  SELECT bra_size_code,
         bra_size_uk,
         bra_size_usa,
         bra_size_eu,
         bra_size_fr,
         bra_size_uie 
  FROM wrk_bra_sizes;

  COMMIT;
  
EXCEPTION
  WHEN OTHERS THEN
  RAISE;

END insert_table_bras;
---------------------------------------------------  
PROCEDURE insert_table_panties
IS
BEGIN
  EXECUTE IMMEDIATE ('TRUNCATE TABLE cls_panty_sizes');
  INSERT INTO cls_panty_sizes (
                               panty_size_id,
                               panty_size_uk,
                               panty_size_usa,
                               panty_size_eu,
                               panty_size_fr,
                               panty_size_uie
                              )
  SELECT panty_size_code,
         panty_size_uk,
         panty_size_usa,
         panty_size_eu,
         panty_size_fr,
         panty_size_uie 
  FROM wrk_panty_sizes;

  COMMIT;
  
EXCEPTION
  WHEN OTHERS THEN
  RAISE;
  
END insert_table_panties;
--------------------------------------------------- 
---------------------------------------------------
PROCEDURE merge_table_ce_bra_size_grid
IS
BEGIN

MERGE INTO bl_3nf.ce_bra_size_grid t USING
    ( SELECT bra_size_id,
             bra_size_uk,
             bra_size_usa,
             bra_size_eu,
             bra_size_fr,
             bra_size_uie
      FROM   cls_bra_sizes
    MINUS
      SELECT bra_size_srcid AS bra_size_id,
             bra_size_uk,
             bra_size_usa,
             bra_size_eu,
             bra_size_fr,
             bra_size_uie
      FROM   bl_3nf.ce_bra_size_grid
    ) c ON ( c.bra_size_id = t.bra_size_srcid
       AND   t.bra_size_uk  = c.bra_size_uk
       AND   t.bra_size_usa = c.bra_size_usa
       AND   t.bra_size_eu  = c.bra_size_eu
       AND   t.bra_size_fr  = c.bra_size_fr
       AND   t.bra_size_uie = c.bra_size_uie)
    WHEN NOT matched THEN
    INSERT
      (
        bra_size_id,
        bra_size_srcid,
        bra_size_uk,
        bra_size_usa,
        bra_size_eu,
        bra_size_fr,
        bra_size_uie
      )
      VALUES
      (
        bl_3nf.ce_bra_size_grid_seq.NEXTVAL,
        c.bra_size_id,
        c.bra_size_uk,
        c.bra_size_usa,
        c.bra_size_eu,
        c.bra_size_fr,
        c.bra_size_uie
      ) ;
    COMMIT;
EXCEPTION
WHEN OTHERS THEN
    RAISE;
END merge_table_ce_bra_size_grid;
---------------------------------------------------
PROCEDURE merge_table_ce_panty_size_grid
IS
BEGIN

MERGE INTO bl_3nf.ce_panty_size_grid t USING
    ( SELECT panty_size_id,
             panty_size_uk,
             panty_size_usa,
             panty_size_eu,
             panty_size_fr,
             panty_size_uie
      FROM   cls_panty_sizes
    MINUS
      SELECT panty_size_srcid AS panty_size_id,
             panty_size_uk,
             panty_size_usa,
             panty_size_eu,
             panty_size_fr,
             panty_size_uie
      FROM   bl_3nf.ce_panty_size_grid
    ) c ON ( c.panty_size_id = t.panty_size_srcid 
       AND   t.panty_size_uk  = c.panty_size_uk
       AND   t.panty_size_usa = c.panty_size_usa
       AND   t.panty_size_eu  = c.panty_size_eu
       AND   t.panty_size_fr  = c.panty_size_fr
       AND   t.panty_size_uie = c.panty_size_uie)
    WHEN NOT matched THEN
    INSERT
      (
        panty_size_id,
        panty_size_srcid,
        panty_size_uk,
        panty_size_usa,
        panty_size_eu,
        panty_size_fr,
        panty_size_uie
      )
      VALUES
      (
        bl_3nf.ce_panty_size_grid_seq.NEXTVAL,
        c.panty_size_id,
        c.panty_size_uk,
        c.panty_size_usa,
        c.panty_size_eu,
        c.panty_size_fr,
        c.panty_size_uie
      ) ;
    COMMIT;
EXCEPTION
WHEN OTHERS THEN
    RAISE;
END merge_table_ce_panty_size_grid;
---------------------------------------------------

END pkg_etl_insert_sizes;
/