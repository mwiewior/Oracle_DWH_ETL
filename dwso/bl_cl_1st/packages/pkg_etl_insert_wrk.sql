CREATE OR REPLACE PACKAGE pkg_etl_insert_wrk
AUTHID CURRENT_USER
AS
  PROCEDURE insert_table (table_name_to   IN VARCHAR2,
                          table_name_from IN VARCHAR2);
						
END pkg_etl_insert_wrk;
/

CREATE OR REPLACE PACKAGE BODY pkg_etl_insert_wrk
AS
---------------------------------------------------  
PROCEDURE insert_table (table_name_to   IN VARCHAR2,
                        table_name_from IN VARCHAR2)
IS
BEGIN
  EXECUTE IMMEDIATE ('TRUNCATE TABLE ' || table_name_to);
  EXECUTE IMMEDIATE ('INSERT INTO ' || table_name_to || ' SELECT * FROM ' || table_name_from);
  COMMIT;
END insert_table;
END pkg_etl_insert_wrk;
/