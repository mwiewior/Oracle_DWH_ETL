-- Corrected, single-pass install script for the lupanava-dwh corpus.
-- Replaces the broken first load.sql/reload data.sql (narrative guides mixed with SQL,
-- out of dependency order, hardcoded absolute VM paths). Run as a DBA-privileged user
-- (e.g. SYSTEM); ALTER SESSION SET CURRENT_SCHEMA is used throughout instead of
-- connecting as each low-privilege schema user directly.
--
-- Repoint the 5 CREATE DIRECTORY paths below at wherever dwso/sa_src/sources/ actually
-- lands on the target host/container before running this.
SET DEFINE OFF
WHENEVER SQLERROR CONTINUE

-- Tablespace
-- Create a new tablespace. 

CREATE TABLESPACE tbs_pdb_dwh DATAFILE
    'TBS_PDB_DWH.DBF' SIZE 104857600
        AUTOEXTEND ON NEXT 20971520
NOLOGGING SEGMENT SPACE MANAGEMENT AUTO EXTENT MANAGEMENT LOCAL AUTOALLOCATE;

-- User: sa_src
-- Create a new user.

CREATE USER sa_src IDENTIFIED BY "123" DEFAULT TABLESPACE tbs_pdb_dwh;

-- User: bl_cl_1st
-- Create a new user.

CREATE USER bl_cl_1st IDENTIFIED BY "123" DEFAULT TABLESPACE tbs_pdb_dwh;

-- User: bl_cl_2nd
-- Create a new user.

CREATE USER bl_cl_2nd IDENTIFIED BY "123" DEFAULT TABLESPACE tbs_pdb_dwh;

-- User: bl_3nf
-- Create a new user.

CREATE USER bl_3nf IDENTIFIED BY "123" DEFAULT TABLESPACE tbs_pdb_dwh;

-- User: bl_dm
-- Create a new user.

CREATE USER bl_dm IDENTIFIED BY "123" DEFAULT TABLESPACE tbs_pdb_dwh;

-- User: data_mart
-- Create a new user.

CREATE USER data_mart IDENTIFIED BY "123" DEFAULT TABLESPACE tbs_pdb_dwh;

-- Base grants: sa_src
-- Grant Connect Role and Resource Role.

GRANT CONNECT TO sa_src;
GRANT RESOURCE TO sa_src;

-- Base grants: bl_cl_1st
-- Grant Connect Role and Resource Role.

GRANT CONNECT TO bl_cl_1st;
GRANT RESOURCE TO bl_cl_1st;

-- Base grants: bl_cl_2nd
-- Grant Connect Role and Resource Role.

GRANT CONNECT TO bl_cl_2nd;
GRANT RESOURCE TO bl_cl_2nd;

-- Base grants: bl_3nf
-- Grant Connect Role and Resource Role.

GRANT CONNECT TO bl_3nf;
GRANT RESOURCE TO bl_3nf;

-- Base grants: bl_dm
-- Grant Connect Role and Resource Role.

GRANT CONNECT TO bl_dm;
GRANT RESOURCE TO bl_dm;

-- Base grants: data_mart
-- Grant DBA, Connect Role and Resource Role.

GRANT CONNECT TO data_mart;
GRANT RESOURCE TO data_mart;
GRANT DBA TO data_mart;

-- Inherit privileges (all schemas)
-- Oracle 12c+ security requirement: an AUTHID CURRENT_USER procedure (e.g. PKG_GRANTS,
-- used throughout this schema to issue GRANT statements from within PL/SQL) needs the
-- invoking user's INHERIT PRIVILEGES grant on the procedure owner before the invoker's
-- real privileges are exercised inside the procedure body. This grants every schema owner
-- here permission to let SYSTEM's real privileges apply when SYSTEM invokes their
-- AUTHID CURRENT_USER packages (e.g. via ALTER SESSION SET CURRENT_SCHEMA).
GRANT INHERIT PRIVILEGES ON USER SYSTEM TO sa_src;
GRANT INHERIT PRIVILEGES ON USER SYSTEM TO bl_cl_1st;
GRANT INHERIT PRIVILEGES ON USER SYSTEM TO bl_cl_2nd;
GRANT INHERIT PRIVILEGES ON USER SYSTEM TO bl_3nf;
GRANT INHERIT PRIVILEGES ON USER SYSTEM TO bl_dm;
GRANT INHERIT PRIVILEGES ON USER SYSTEM TO data_mart;

-- Directories
CREATE OR REPLACE DIRECTORY external_geo_tables AS '/tmp/corpus/dwso/sa_src/sources/geography';
CREATE OR REPLACE DIRECTORY external_cust_tables AS '/tmp/corpus/dwso/sa_src/sources/customers';
CREATE OR REPLACE DIRECTORY external_emp_tables AS '/tmp/corpus/dwso/sa_src/sources/employees';
CREATE OR REPLACE DIRECTORY external_ext_tables AS '/tmp/corpus/dwso/sa_src/sources';
CREATE OR REPLACE DIRECTORY external_prod_tables AS '/tmp/corpus/dwso/sa_src/sources/products';

-- Object: sa_src/dwso/sa_src/packages/pkg_grants.sql
ALTER SESSION SET CURRENT_SCHEMA = sa_src;
CREATE OR REPLACE PACKAGE pkg_grants
AUTHID CURRENT_USER
AS
  PROCEDURE user_grant (grant_name  IN VARCHAR2,
						            schema_name IN VARCHAR2,
                        object_name IN VARCHAR2,
                        user_name   IN VARCHAR2);
						
  PROCEDURE user_grant (grant_name IN VARCHAR2,
                        user_name  IN VARCHAR2,
                        comments   IN boolean := FALSE);
END pkg_grants;
/


CREATE OR REPLACE PACKAGE BODY pkg_grants AS
  
  PROCEDURE user_grant (grant_name  IN VARCHAR2,
                        schema_name IN VARCHAR2,
                        object_name IN VARCHAR2,
                        user_name   IN VARCHAR2) 
  IS
  BEGIN
	  EXECUTE IMMEDIATE ('GRANT ' || grant_name || ' ON ' || schema_name || '.' || object_name || ' TO ' || user_name);
  END user_grant;
  
 PROCEDURE user_grant (grant_name VARCHAR2, 
                       user_name  VARCHAR2,
                       comments   IN boolean := FALSE)
   IS
  BEGIN
      IF comments THEN
        EXECUTE IMMEDIATE ('GRANT ' || grant_name || ' TO ' || user_name || ' WITH ADMIN OPTION');
      END IF;
        EXECUTE IMMEDIATE ('GRANT ' || grant_name || ' TO ' || user_name);
  END;
END pkg_grants;
/

-- Object: sa_src/dwso/sa_src/tables/ext_bra_sizes.sql
ALTER SESSION SET CURRENT_SCHEMA = sa_src;
-- EXT_BRA_SIZES.
CREATE TABLE ext_bra_sizes
  (
    bra_size_code NUMBER(10 ),
    bra_size_uk   VARCHAR2 ( 200 CHAR ),
    bra_size_usa  VARCHAR2 ( 200 CHAR ),
    bra_size_eu   VARCHAR2 ( 200 CHAR ),
    bra_size_fr   VARCHAR2 ( 200 CHAR ),
    bra_size_uie  VARCHAR2 ( 200 CHAR )
  )
  ORGANIZATION EXTERNAL
  (
    TYPE oracle_loader 
    DEFAULT DIRECTORY external_ext_tables 
    ACCESS PARAMETERS (fields terminated BY ',') 
    LOCATION ('bra_size_grid.csv')
  )
  REJECT LIMIT UNLIMITED;

-- Object: sa_src/dwso/sa_src/tables/ext_countries.sql
ALTER SESSION SET CURRENT_SCHEMA = sa_src;
-- EXT_COUNTRIES.

    CREATE TABLE ext_countries
        (country_id     NUMBER ( 10 ),
         country_desc   VARCHAR2 ( 200 CHAR ),
         country_code   VARCHAR2 ( 3 )
         )
    ORGANIZATION EXTERNAL
        (TYPE oracle_loader
         DEFAULT DIRECTORY external_geo_tables
         ACCESS PARAMETERS
            (records delimited BY 0x'0D0A'
             nobadfile nodiscardfile nologfile fields terminated BY ';'
             missing field VALUES are NULL 
                (country_id INTEGER EXTERNAL (4),
                 country_desc CHAR(200),
                 country_code CHAR(3) )
             )
         LOCATION ('iso_3166.tab')
    )
    REJECT LIMIT UNLIMITED;

-- Object: sa_src/dwso/sa_src/tables/ext_customers.sql
ALTER SESSION SET CURRENT_SCHEMA = sa_src;
-- EXT_CUSTOMERS.
    CREATE TABLE ext_customers
        (
         passport_number VARCHAR2 ( 200 CHAR ),
         first_name      VARCHAR2 ( 200 CHAR ),
         last_name       VARCHAR2 ( 200 CHAR ),
         gender          VARCHAR2 ( 200 CHAR ),
         age             NUMBER ( 38 ),
         email           VARCHAR2 ( 200 CHAR ),
         phone           VARCHAR2 ( 200 CHAR ),
         address         VARCHAR2 ( 200 CHAR ),
         city            VARCHAR2 ( 200 CHAR ),
         country_id      NUMBER ( 38 ),
         start_dt        DATE,
         end_dt          DATE,
         is_active       VARCHAR2 ( 200 CHAR )
         )
    ORGANIZATION EXTERNAL
        (TYPE oracle_loader DEFAULT DIRECTORY external_cust_tables
                            ACCESS PARAMETERS (fields terminated BY ',')
                            LOCATION 
                                  ('customers_1.csv',  'customers_2.csv',
                                   'customers_3.csv',  'customers_4.csv',
                                   'customers_5.csv',  'customers_6.csv',
                                   'customers_7.csv',  'customers_8.csv',
                                   'customers_9.csv',  'customers_10.csv',
                                   'customers_11.csv', 'customers_12.csv',
                                   'customers_13.csv', 'customers_14.csv',
                                   'customers_15.csv', 'customers_16.csv',
                                   'customers_17.csv', 'customers_18.csv',
                                   'customers_19.csv', 'customers_20.csv',
                                   'customers_21.csv', 'customers_22.csv',
                                   'customers_23.csv', 'customers_24.csv',
                                   'customers_25.csv', 'customers_26.csv',
                                   'customers_27.csv', 'customers_28.csv',
                                   'customers_29.csv', 'customers_30.csv',
                                   'customers_31.csv', 'customers_32.csv',
                                   'customers_33.csv', 'customers_34.csv',
                                   'customers_35.csv', 'customers_36.csv',
                                   'customers_37.csv', 'customers_38.csv',
                                   'customers_39.csv', 'customers_40.csv',
                                   'customers_41.csv', 'customers_42.csv',
                                   'customers_43.csv', 'customers_44.csv',
                                   'customers_45.csv', 'customers_46.csv',
                                   'customers_47.csv', 'customers_48.csv',
                                   'customers_49.csv', 'customers_50.csv'
                                  )
    )
    REJECT LIMIT UNLIMITED;

-- Object: sa_src/dwso/sa_src/tables/ext_employees.sql
ALTER SESSION SET CURRENT_SCHEMA = sa_src;
-- EXT_EMPLOYEES.
    CREATE TABLE ext_employees
        (employee_code        VARCHAR2 ( 100 CHAR ),
         first_name           VARCHAR2 ( 100 CHAR ),
         last_name            VARCHAR2 ( 100 CHAR ),
         age                  NUMBER ( 38 ),
         store_srcid          VARCHAR2 ( 100 CHAR ),
         position_name        VARCHAR2 ( 100 CHAR ),
         position_grade_srcid VARCHAR2 ( 100 CHAR ),
         work_experience      NUMBER ( 38 ),
         email                VARCHAR2 ( 100 CHAR ),
         phone                VARCHAR2 ( 100 CHAR ),
         personal_address     VARCHAR2 ( 100 CHAR ),
         currency             VARCHAR2 ( 100 CHAR ),
         currency_code        VARCHAR2 ( 100 CHAR ),
         month_salary         NUMBER ( 38,3 ),
         credit_card          NUMBER ( 38 ),
         start_date           DATE,
         end_date             DATE,
         is_active            VARCHAR2 ( 100 CHAR )
         )
    ORGANIZATION EXTERNAL
        (TYPE oracle_loader DEFAULT DIRECTORY external_emp_tables
                            ACCESS PARAMETERS (fields terminated BY ',')
                            LOCATION 
                                  ('employees_1.csv',  'employees_2.csv',
                                   'employees_3.csv',  'employees_4.csv',
                                   'employees_5.csv',  'employees_6.csv',
                                   'employees_7.csv',  'employees_8.csv',
                                   'employees_9.csv',  'employees_10.csv',
                                   'employees_11.csv', 'employees_12.csv',
                                   'employees_13.csv', 'employees_14.csv',
                                   'employees_15.csv', 'employees_16.csv',
                                   'employees_17.csv', 'employees_18.csv',
                                   'employees_19.csv', 'employees_20.csv'
                                  )
    )
    REJECT LIMIT UNLIMITED;
    
COMMIT;

-- Object: sa_src/dwso/sa_src/tables/ext_full_data.sql
ALTER SESSION SET CURRENT_SCHEMA = sa_src;
-- EXT_FULL_DATA.
    CREATE TABLE ext_full_data
          (country_id           NUMBER(10,0),
           county_desc          VARCHAR2(200 CHAR),
           structure_code       NUMBER(10,0),
           structure_desc       VARCHAR2(200 CHAR)
           )
    ORGANIZATION EXTERNAL (
        TYPE oracle_loader
        DEFAULT DIRECTORY external_geo_tables
         ACCESS PARAMETERS
            (records delimited BY 0x'0D0A'
             nobadfile nodiscardfile nologfile fields terminated BY ';'
             missing field VALUES are NULL
                  (
                   country_id INTEGER EXTERNAL (4),
                   county_desc CHAR(200),
                   structure_code INTEGER EXTERNAL,
                   structure_desc CHAR(200) )
             )
        LOCATION ('iso_3166_geo_un_contries.tab')
    )
    REJECT LIMIT UNLIMITED;

-- Object: sa_src/dwso/sa_src/tables/ext_panty_sizes.sql
ALTER SESSION SET CURRENT_SCHEMA = sa_src;
-- EXT_PANTY_SIZES.
    CREATE TABLE ext_panty_sizes
        (
         panty_size_code NUMBER(20 ),
         panty_size_uk   VARCHAR2 ( 200 CHAR ),
         panty_size_usa  VARCHAR2 ( 200 CHAR ),
         panty_size_eu   VARCHAR2 ( 200 CHAR ),
         panty_size_fr   VARCHAR2 ( 200 CHAR ),
         panty_size_uie  VARCHAR2 ( 200 CHAR )
         )
    ORGANIZATION EXTERNAL
        (TYPE oracle_loader DEFAULT DIRECTORY external_ext_tables
                            ACCESS PARAMETERS (fields terminated BY ',')
                            LOCATION ('panties_size_grid.csv')
    )
    REJECT LIMIT UNLIMITED;

-- Object: sa_src/dwso/sa_src/tables/ext_payment_methods.sql
ALTER SESSION SET CURRENT_SCHEMA = sa_src;
-- EXT_PAYMENT_METHODS.
    CREATE TABLE ext_payment_methods
        (
         payment_method_name VARCHAR2 ( 200 CHAR ),
         bank                VARCHAR2 ( 200 CHAR ),
         start_dt            DATE,
         end_dt              DATE,
         is_active           VARCHAR2 ( 200 CHAR )        
         )
    ORGANIZATION EXTERNAL
        (TYPE oracle_loader DEFAULT DIRECTORY external_ext_tables
                            ACCESS PARAMETERS (fields terminated BY ',')
                            LOCATION ('payment_methods.csv')
    )
    REJECT LIMIT UNLIMITED;

-- Object: sa_src/dwso/sa_src/tables/ext_products.sql
ALTER SESSION SET CURRENT_SCHEMA = sa_src;
-- EXT_PRODUCTS.
CREATE TABLE ext_products
  (
    product_id      VARCHAR2 ( 300 CHAR ),
    product_name    VARCHAR2 ( 300 BYTE ),
    line_name       VARCHAR2 ( 300 CHAR ),
    collection_name VARCHAR2 ( 300 CHAR ),
    product_type    VARCHAR2 ( 300 CHAR ),
    color           VARCHAR2 ( 300 CHAR ),
    panty_size_id   VARCHAR2 ( 300 CHAR ),
    price           VARCHAR2 ( 300 CHAR ),
    balance         VARCHAR2 ( 300 CHAR ),
    start_dt        DATE,
    end_dt          DATE,
    is_active       VARCHAR2 ( 300 CHAR )
  )
    ORGANIZATION EXTERNAL
        (TYPE oracle_loader DEFAULT DIRECTORY external_prod_tables
                         ACCESS PARAMETERS (fields terminated BY ',')
                         LOCATION ('products_1.csv', 'products_2.csv',
                                   'products_3.csv', 'products_4.csv',
                                   'products_5.csv', 'products_6.csv')
    )
    REJECT LIMIT UNLIMITED;

-- Object: sa_src/dwso/sa_src/tables/ext_stores.sql
ALTER SESSION SET CURRENT_SCHEMA = sa_src;
-- EXT_STORES.
    CREATE TABLE ext_stores
  (
    store_code VARCHAR2 ( 200 CHAR ),
    store_name VARCHAR2 ( 200 BYTE ),
    manager_id VARCHAR2 ( 200 BYTE ),
    phone      VARCHAR2 ( 200 BYTE ),
    address    VARCHAR2 ( 200 BYTE ),
    city       VARCHAR2 ( 200 BYTE ),
    country_id VARCHAR2 ( 200 BYTE ),
    insert_dt  DATE
  )
    ORGANIZATION EXTERNAL
        (TYPE oracle_loader DEFAULT DIRECTORY external_ext_tables
                            ACCESS PARAMETERS (fields terminated BY ',')
                            LOCATION ('stores.csv')
    )
    REJECT LIMIT UNLIMITED;

-- Object: sa_src/dwso/sa_src/tables/ext_structures.sql
ALTER SESSION SET CURRENT_SCHEMA = sa_src;
-- EXT_STRUCTURES.
    CREATE TABLE ext_structures  
          (child_code           NUMBER(10,0),
           parent_code          NUMBER(10,0),
           structure_desc       VARCHAR2(200 CHAR),
           structure_level      VARCHAR2(200 CHAR)
           )
    ORGANIZATION EXTERNAL (
        TYPE oracle_loader
        DEFAULT DIRECTORY external_geo_tables
         ACCESS PARAMETERS
            (records delimited BY 0x'0D'
             nobadfile nodiscardfile nologfile fields terminated BY ';'
             missing field VALUES are NULL
                  (
                   child_code INTEGER EXTERNAL (4),
                   parent_code INTEGER EXTERNAL,
                   structure_desc CHAR(200),
                   structure_level CHAR(200) 
                   )
             )
        LOCATION ('iso_3166_geo_un.tab')
    )
    REJECT LIMIT UNLIMITED;

-- Object: bl_cl_1st/dwso/bl_cl_1st/packages/pkg_drop_tables.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
CREATE OR REPLACE PACKAGE pkg_drop 
  AUTHID CURRENT_USER AS
  PROCEDURE drop_proc ( object_name IN VARCHAR2, object_type VARCHAR2);
END pkg_drop;
/
CREATE OR REPLACE PACKAGE BODY  pkg_drop AS 
  PROCEDURE drop_proc (object_name IN VARCHAR2, object_type VARCHAR2) IS
  ex_grants exception;
  ex_inv_table_name exception;
  ex_exist_syn_name exception;
  ex_table exception;
  ex_public_synonym exception;
  ex_synonym exception;
  pragma exception_init( ex_grants, -01031 );
  pragma exception_init( ex_inv_table_name, -00903 );
  pragma exception_init( ex_exist_syn_name, -00955 );
  pragma exception_init( ex_table, -00942 );
  pragma exception_init( ex_public_synonym, -01432 );
  pragma exception_init( ex_synonym, -01434 );
	BEGIN
	  IF object_type = 'TABLE' THEN
		EXECUTE IMMEDIATE 'drop ' || object_type || ' ' || object_name || ' cascade constraints';
	  ELSE
		EXECUTE IMMEDIATE 'drop ' || object_type || ' ' || object_name;
	  END IF;
	  
	  exception
	  WHEN ex_table THEN
		   dbms_output.put_line(object_type || ' ' || object_name ||' does not exist');
		   -- insert into log_table (error_message, error_code);
	  WHEN ex_grants  THEN
		   dbms_output.put_line('User has no grants');
	  WHEN ex_inv_table_name THEN
		   dbms_output.put_line('Invalid table name');
	  WHEN ex_exist_syn_name THEN
		   dbms_output.put_line('Name is already used by an existing object');
	  WHEN ex_public_synonym THEN
		   dbms_output.put_line(object_type || ' ' || object_name ||' does not exist');
	  WHEN ex_synonym THEN
		  dbms_output.put_line(object_type || ' ' || object_name ||' does not exist');
	  WHEN others THEN
		   raise;
	END;
END pkg_drop;
/

-- Object: bl_cl_1st/dwso/bl_cl_1st/packages/pkg_etl_insert_age_categories.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
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

-- Object: bl_cl_1st/dwso/bl_cl_1st/packages/pkg_etl_insert_customers.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
CREATE OR REPLACE PACKAGE pkg_etl_insert_customers
AUTHID CURRENT_USER
AS
  PROCEDURE insert_table_customers;
  PROCEDURE merge_table_customers_first;
  PROCEDURE merge_table_customers_second;
						
END pkg_etl_insert_customers;
/

CREATE OR REPLACE PACKAGE BODY pkg_etl_insert_customers
AS
---------------------------------------------------  
PROCEDURE insert_table_customers
IS
BEGIN
  EXECUTE IMMEDIATE ('TRUNCATE TABLE cls_customers');
  INSERT INTO cls_customers (
                              customer_id,
                              first_name,
                              last_name,
                              age,
                              age_category_id,
                              email,
                              phone,
                              address,
                              city_id,
                              start_dt,
                              end_dt,
                              is_active
                            )
SELECT   passport_number as customer_id,
         first_name,
         last_name,
         age,
         (case when age >= 18 and age <25 then 1
               when age >= 25 and age <35 then 2
               when age >= 35 and age <45 then 3
               when age >= 45 and age <55 then 4
               when age >= 55 then 5
          end) as age_category_id,
         email,
         phone,
         address,
         wct.city_id,
         start_dt,
         end_dt,
         is_active
  FROM wrk_customers wst inner join wrk_cities wct on wst.city = wct.city_desc;

  COMMIT;
  
EXCEPTION
  WHEN OTHERS THEN
  RAISE;

END insert_table_customers;
--------------------------------------------------- 
PROCEDURE merge_table_customers_first
IS
BEGIN

MERGE INTO bl_3nf.ce_customers t USING
    ( SELECT customer_id,
             first_name,
             last_name,
             age,
             age_category_id,
             email,
             phone,
             address,
             city_id,
             start_dt,
             end_dt,
             is_active
      FROM   cls_customers
    MINUS
      SELECT customer_srcid AS customer_id,
             first_name,
             last_name,
             age,
             age_category_srcid AS age_category_id,
             email,
             phone,
             address,
             city_srcid AS city_id,
             start_dt,
             end_dt,
             is_active
      FROM   bl_3nf.ce_customers
    ) c ON ( c.customer_id = t.customer_srcid
       AND   c.first_name = t.first_name
       AND   c.last_name = t.last_name
       AND   c.age = t.age
       AND   t.age_category_srcid  = c.age_category_id
       AND   c.email = t.email
       AND   c.phone = t.phone
       AND   c.address = t.address
       AND   t.city_srcid  = c.city_id
       AND   c.start_dt = t.start_dt)
    WHEN MATCHED THEN 
    UPDATE SET
       t.end_dt  = c.end_dt,
       t.is_active = c.is_active
    WHEN NOT matched THEN
    INSERT
      (
        customer_id,
        customer_srcid,
        first_name,
        last_name,
        age,
        age_category_srcid,
        email,
        phone,
        address,
        city_srcid,
        start_dt,
        end_dt,
        is_active
      )
      VALUES
      (
        bl_3nf.ce_customers_seq.NEXTVAL,
        c.customer_id,
        c.first_name,
        c.last_name,
        c.age,
        c.age_category_id,
        c.email,
        c.phone,
        c.address,
        c.city_id,
        c.start_dt,
        c.end_dt,
        'TRUE'
      ) ;
    COMMIT;
EXCEPTION
WHEN OTHERS THEN
    RAISE;
END merge_table_customers_first;
---------------------------------------------------
PROCEDURE merge_table_customers_second
IS
BEGIN

MERGE INTO bl_3nf.ce_customers t USING
    ( SELECT customer_id,
             first_name,
             last_name,
             age,
             age_category_id,
             email,
             phone,
             address,
             city_id,
             start_dt,
             end_dt,
             is_active
      FROM   cls_customers
    MINUS
      SELECT customer_srcid AS customer_id,
             first_name,
             last_name,
             age,
             age_category_srcid AS age_category_id,
             email,
             phone,
             address,
             city_srcid AS city_id,
             start_dt,
             end_dt,
             is_active
      FROM   bl_3nf.ce_customers
    ) c ON ( c.customer_id = t.customer_srcid
       AND   c.first_name = t.first_name
       AND   c.last_name = t.last_name
       AND   c.age = t.age
       AND   t.age_category_srcid  = c.age_category_id
       AND   c.email = t.email
       AND   c.phone = t.phone
       AND   c.address = t.address
       AND   t.city_srcid  = c.city_id
       AND   c.start_dt = t.start_dt)
    WHEN MATCHED THEN 
    UPDATE SET
       t.end_dt  = c.end_dt,
       t.is_active = c.is_active
    WHEN NOT matched THEN
    INSERT
      (
        customer_id,
        customer_srcid,
        first_name,
        last_name,
        age,
        age_category_srcid,
        email,
        phone,
        address,
        city_srcid,
        start_dt,
        end_dt,
        is_active
      )
      VALUES
      (
        bl_3nf.ce_customers_seq.NEXTVAL,
        c.customer_id,
        c.first_name,
        c.last_name,
        c.age,
        c.age_category_id,
        c.email,
        c.phone,
        c.address,
        c.city_id,
        sysdate,
        c.end_dt,
        'TRUE'
      ) ;
    COMMIT;
EXCEPTION
WHEN OTHERS THEN
    RAISE;
END merge_table_customers_second;
---------------------------------------------------
END pkg_etl_insert_customers;
/

-- Object: bl_cl_1st/dwso/bl_cl_1st/packages/pkg_etl_insert_employees.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
CREATE OR REPLACE PACKAGE pkg_etl_insert_employees
AUTHID CURRENT_USER
AS
  PROCEDURE insert_table_employees;
  PROCEDURE insert_table_position_grade;
  PROCEDURE merge_table_ce_position_grades;
  PROCEDURE merge_table_employees_first;
  PROCEDURE merge_table_employees_second;
						
END pkg_etl_insert_employees;
/

CREATE OR REPLACE PACKAGE BODY pkg_etl_insert_employees
AS
---------------------------------------------------  
PROCEDURE insert_table_employees
IS
BEGIN
  EXECUTE IMMEDIATE ('TRUNCATE TABLE cls_employees');
  INSERT INTO cls_employees (
                              employee_id,
                              first_name,
                              last_name,
                              store_id,
                              position_name,
                              position_grade_id,
                              work_experience,
                              email,
                              phone,
                              start_dt,
                              end_dt,
                              is_active
                            )
  SELECT employee_code AS employee_id,
         first_name,
         last_name,
         store_srcid,
         position_name,
         cpg.position_grade_id,
         we.work_experience,
         email,
         phone,
         start_dt,
         end_dt,
         is_active
  FROM wrk_employees we left join cls_position_grade cpg
                               on we.position_grade_srcid = cpg.position_grade;

  COMMIT;
  
EXCEPTION
  WHEN OTHERS THEN
  RAISE;

END insert_table_employees;
---------------------------------------------------  
PROCEDURE insert_table_position_grade
IS
BEGIN
  EXECUTE IMMEDIATE ('TRUNCATE TABLE cls_position_grade');
  INSERT INTO cls_position_grade (
                                   position_grade_id,
                                   position_grade,
                                   work_experience
                            )
  SELECT work_experience || ' ' || SUBSTR(position_grade,1,2) as position_grade_id,
         position_grade,
         work_experience
  FROM   (
  SELECT DISTINCT position_grade_srcid AS position_grade,
         (case when position_grade_srcid = 'novice' then 3
               when position_grade_srcid = 'middle' then 5
               when position_grade_srcid = 'experienced' then 10
               when position_grade_srcid = 'expert' then 15
          end) as work_experience
  FROM wrk_employees
         );

  COMMIT;
  
EXCEPTION
  WHEN OTHERS THEN
  RAISE;

END insert_table_position_grade;
---------------------------------------------------  
---------------------------------------------------
PROCEDURE merge_table_ce_position_grades
IS
BEGIN

MERGE INTO bl_3nf.ce_position_grades t USING
    ( SELECT position_grade_id,
             position_grade,
             work_experience
      FROM   cls_position_grade
    MINUS
      SELECT position_grade_srcid AS position_grade_id,
             position_grade_desc  AS position_grade,
             work_experience
      FROM   bl_3nf.ce_position_grades
    ) c ON ( c.position_grade = t.position_grade_desc
       AND   t.position_grade_srcid = c.position_grade_id
       AND   c.work_experience = t.work_experience)
    WHEN NOT matched THEN
    INSERT
      (
        position_grade_id ,
        position_grade_srcid ,
        position_grade_desc,
        work_experience
      )
      VALUES
      (
        bl_3nf.ce_position_grades_seq.NEXTVAL,
        c.position_grade_id ,
        c.position_grade,
        c.work_experience
      ) ;
    COMMIT;
EXCEPTION
WHEN OTHERS THEN
    RAISE;
END merge_table_ce_position_grades;
---------------------------------------------------
PROCEDURE merge_table_employees_first
IS
BEGIN

MERGE INTO bl_3nf.ce_employees t USING
    ( SELECT employee_id,
             first_name,
             last_name,
             store_id,
             position_name,
             position_grade_id,
             work_experience,
             email,
             phone,
             start_dt,
             end_dt,
             is_active
      FROM   cls_employees
    MINUS
      SELECT 
             employee_srcid AS employee_id,
             first_name,
             last_name,
             store_srcid AS store_id,
             position_name,
             position_grade_srcid AS position_grade_id,
             work_experience,
             email,
             phone,
             start_dt,
             end_dt,
             is_active
      FROM   bl_3nf.ce_employees
    ) c ON ( c.employee_id = t.employee_srcid
       AND   c.first_name = t.first_name
       AND   c.last_name = t.last_name
       AND   c.position_name = t.position_name
       AND   t.position_grade_srcid = c.position_grade_id
       AND   c.work_experience = t.work_experience
       AND   t.store_srcid = c.store_id
       AND   c.email = t.email
       AND   c.phone = t.phone
       )
    WHEN MATCHED THEN
    UPDATE SET 
               t.end_dt  = c.end_dt,
               t.is_active = c.is_active
    WHEN NOT matched THEN
    INSERT
      (
        employee_id,
        employee_srcid,
        first_name,
        last_name,
        store_srcid,
        position_name,
        position_grade_srcid,
        work_experience,
        email,
        phone,
        start_dt,
        end_dt,
        is_active
      )
      VALUES
      (
        bl_3nf.ce_employees_seq.NEXTVAL,
        c.employee_id,
        c.first_name,
        c.last_name,
        c.store_id,
        c.position_name,
        c.position_grade_id,
        c.work_experience,
        c.email,
        c.phone,
        c.start_dt,
        c.end_dt,
        c.is_active
      ) ;
    COMMIT;
EXCEPTION
WHEN OTHERS THEN
    RAISE;
END merge_table_employees_first;
---------------------------------------------------
PROCEDURE merge_table_employees_second
IS
BEGIN

MERGE INTO bl_3nf.ce_employees t USING
    ( SELECT employee_id,
             first_name,
             last_name,
             store_id,
             position_name,
             position_grade_id,
             work_experience,
             email,
             phone,
             start_dt,
             end_dt,
             is_active
      FROM   cls_employees
    MINUS
      SELECT 
             employee_srcid AS employee_id,
             first_name,
             last_name,
             store_srcid AS store_id,
             position_name,
             position_grade_srcid AS position_grade_id,
             work_experience,
             email,
             phone,
             start_dt,
             end_dt,
             is_active
      FROM   bl_3nf.ce_employees
    ) c ON ( c.employee_id = t.employee_srcid
       AND   c.first_name = t.first_name
       AND   c.last_name = t.last_name
       AND   c.position_name = t.position_name
       AND   t.position_grade_srcid = c.position_grade_id
       AND   c.work_experience = t.work_experience
       AND   t.store_srcid = c.store_id
       AND   c.email = t.email
       AND   c.phone = t.phone
       )
    WHEN MATCHED THEN
    UPDATE SET 
               t.end_dt  = c.end_dt,
               t.is_active = c.is_active
    WHEN NOT matched THEN
    INSERT
      (
        employee_id,
        employee_srcid,
        first_name,
        last_name,
        store_srcid,
        position_name,
        position_grade_srcid,
        work_experience,
        email,
        phone,
        start_dt,
        end_dt,
        is_active
      )
      VALUES
      (
        bl_3nf.ce_employees_seq.NEXTVAL,
        c.employee_id,
        c.first_name,
        c.last_name,
        c.store_id,
        c.position_name,
        c.position_grade_id,
        c.work_experience,
        c.email,
        c.phone,
        sysdate,
        c.end_dt,
        c.is_active
      ) ;
    COMMIT;
EXCEPTION
WHEN OTHERS THEN
    RAISE;
END merge_table_employees_second;
---------------------------------------------------
END pkg_etl_insert_employees;
/

-- Object: bl_cl_1st/dwso/bl_cl_1st/packages/pkg_etl_insert_geography.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
CREATE OR REPLACE PACKAGE pkg_etl_insert_geography
AUTHID CURRENT_USER
AS
  PROCEDURE insert_table_continents;
  PROCEDURE insert_table_regions;
  PROCEDURE insert_table_countries;
  PROCEDURE insert_table_cities;
  PROCEDURE merge_table_ce_continents;
  PROCEDURE merge_table_ce_regions;
  PROCEDURE merge_table_ce_countries;
  PROCEDURE merge_table_ce_cities;
  
END pkg_etl_insert_geography;
/

CREATE OR REPLACE PACKAGE BODY pkg_etl_insert_geography
AS
---------------------------------------------------  
PROCEDURE insert_table_continents
IS
BEGIN
  EXECUTE IMMEDIATE ('TRUNCATE TABLE cls_continents');
  INSERT INTO cls_continents (
                              continent_id,
                              continent_desc
                            )
  SELECT child_code, 
         structure_desc
  FROM   wrk_structures
  WHERE  
         structure_level LIKE 'Continents';

  COMMIT;
  
EXCEPTION
  WHEN OTHERS THEN
  RAISE;

END insert_table_continents;
---------------------------------------------------  
PROCEDURE insert_table_regions
IS
BEGIN
  EXECUTE IMMEDIATE ('TRUNCATE TABLE cls_regions');
  INSERT INTO cls_regions (
                              region_id,
                              region_desc,
                              continent_id
                            )
  SELECT 
         child_code, 
         structure_desc,
         parent_code
  FROM   wrk_structures
  WHERE 
         structure_level LIKE 'Regions';

  COMMIT;
  
EXCEPTION
  WHEN OTHERS THEN
  RAISE;
  
END insert_table_regions;
---------------------------------------------------  
PROCEDURE insert_table_countries
IS
BEGIN
  EXECUTE IMMEDIATE ('TRUNCATE TABLE cls_countries');
  INSERT INTO cls_countries (
                              country_id,
                              country_desc,
                              country_code,
                              region_id
                            )
  SELECT DISTINCT
                  wcs.country_id, 
                  wcs.county_desc,
                  wc.country_code,
                  wcs.structure_code
  FROM            wrk_full_data wcs LEFT JOIN 
                  wrk_countries wc  ON wcs.country_id = wc.country_id;

  COMMIT;
  
EXCEPTION
  WHEN OTHERS THEN
  RAISE;
  
END insert_table_countries;
--------------------------------------------------- 
PROCEDURE insert_table_cities
IS
BEGIN
  EXECUTE IMMEDIATE ('TRUNCATE TABLE cls_cities');
  INSERT INTO cls_cities (
                              city_id,
                              city_desc,
                              country_id
                            )
  SELECT 
        city_id,
        city_desc,
        country_id
  FROM  wrk_cities
  WHERE city_id IS NOT NULL 
    AND city_desc IS NOT NULL
    AND country_id IS NOT NULL;

  COMMIT;
  
EXCEPTION
  WHEN OTHERS THEN
  RAISE;
  
END insert_table_cities;
---------------------------------------------------
---------------------------------------------------
PROCEDURE merge_table_ce_continents
IS
BEGIN

MERGE INTO bl_3nf.ce_continents t USING
    ( SELECT continent_id, 
             continent_desc
      FROM   cls_continents
    MINUS
      SELECT continent_srcid AS continent_id,
             continent_desc          
      FROM   bl_3nf.ce_continents
    ) c ON ( c.continent_id = t.continent_srcid
        AND  c.continent_desc = t.continent_desc)
    WHEN NOT matched THEN
    INSERT
      (
        continent_id,
        continent_srcid,
        continent_desc
      )
      VALUES
      (
        bl_3nf.ce_continents_seq.NEXTVAL,
        c.continent_id,
        c.continent_desc
      ) ;
    COMMIT;
EXCEPTION
WHEN OTHERS THEN
    RAISE;
END merge_table_ce_continents;
---------------------------------------------------
PROCEDURE merge_table_ce_regions
IS
BEGIN

MERGE INTO bl_3nf.ce_regions t USING
    ( SELECT continent_id,
             region_id, 
             region_desc
      FROM   cls_regions
    MINUS
      SELECT continent_srcid,
             region_srcid AS region_id,
             region_desc          
      FROM   bl_3nf.ce_regions
    ) c ON ( c.region_id = t.region_srcid
       AND   c.continent_id = t.continent_srcid
       AND   c.region_desc = t.region_desc)
    WHEN NOT matched THEN
    INSERT
      (
        region_ID ,
        region_SRCID ,
        continent_srcid,
        region_desc
      )
      VALUES
      (
        bl_3nf.ce_regions_seq.NEXTVAL,
        c.region_id,
        c.continent_id,
        c.region_desc
      ) ;
    COMMIT;
EXCEPTION
WHEN OTHERS THEN
    RAISE;
END merge_table_ce_regions;
---------------------------------------------------
PROCEDURE merge_table_ce_countries
IS
BEGIN

MERGE INTO bl_3nf.ce_countries t USING
    ( SELECT region_id,
             country_id, 
             country_desc
      FROM   cls_countries
    MINUS
      SELECT region_srcid,
             country_srcid AS country_id,
             country_desc          
      FROM   bl_3nf.ce_countries
    ) c ON ( c.country_id = t.country_srcid
        AND  c.region_id = t.region_srcid 
        AND  c.country_desc = t.country_desc)
    WHEN NOT matched THEN
    INSERT
      (
        country_ID ,
        country_SRCID ,
        region_srcid,
        country_desc
      )
      VALUES
      (
        bl_3nf.ce_countries_seq.NEXTVAL,
        c.country_id,
        c.region_id,
        c.country_desc
      ) ;
    COMMIT;
EXCEPTION
WHEN OTHERS THEN
    RAISE;
END merge_table_ce_countries;
---------------------------------------------------
PROCEDURE merge_table_ce_cities
IS
BEGIN

MERGE INTO bl_3nf.ce_cities t USING
    ( SELECT country_id,
             city_id, 
             city_desc
      FROM   cls_cities
    MINUS
      SELECT country_srcid,
             city_srcid AS city_id,
             city_desc          
      FROM   bl_3nf.ce_cities
    ) c ON ( c.city_id = t.city_srcid)
    WHEN NOT matched THEN
    INSERT
      (
        city_id,
        city_srcid,
        country_srcid,
        city_desc
      )
      VALUES
      (
        bl_3nf.ce_cities_seq.NEXTVAL,
        c.city_id,
        c.country_id,
        c.city_desc
      ) ;
    COMMIT;
EXCEPTION
WHEN OTHERS THEN
    RAISE;
END merge_table_ce_cities;
---------------------------------------------------
END pkg_etl_insert_geography;
/

-- Object: bl_cl_1st/dwso/bl_cl_1st/packages/pkg_etl_insert_payment_methods.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
CREATE OR REPLACE PACKAGE pkg_etl_insert_payment_methods
AUTHID CURRENT_USER
AS
  PROCEDURE insert_table_payment_methods;
  PROCEDURE merge_table_ce_pm_first;
  PROCEDURE merge_table_ce_pm_second;
						
END pkg_etl_insert_payment_methods;
/

CREATE OR REPLACE PACKAGE BODY pkg_etl_insert_payment_methods
AS
---------------------------------------------------  
PROCEDURE insert_table_payment_methods
IS
BEGIN
  EXECUTE IMMEDIATE ('TRUNCATE TABLE cls_payment_methods');
  INSERT INTO cls_payment_methods (
                                   payment_method_id,
                                   payment_method,
                                   bank,
                                   start_dt,
                                   end_dt,
                                   is_active
                                   )
SELECT SUBSTR(bank,1,5) || '-' || SUBSTR(payment_method_name,1,2) AS payment_method_id,
       payment_method_name AS payment_method,
       bank,
       start_dt,
       end_dt,
       is_active
  FROM wrk_payment_methods;

  COMMIT;
  
EXCEPTION
  WHEN OTHERS THEN
  RAISE;

END insert_table_payment_methods;
---------------------------------------------------  
PROCEDURE merge_table_ce_pm_first
IS
BEGIN

MERGE INTO bl_3nf.ce_payment_methods t USING
    ( SELECT payment_method_id,
             payment_method,
             bank,
             start_dt,
             end_dt,
             is_active
      FROM   cls_payment_methods
    MINUS
      SELECT payment_method_srcid AS payment_method_id,
             payment_method_desc AS payment_method,
             bank_desc AS bank,
             start_dt,
             end_dt,
             is_active
      FROM   bl_3nf.ce_payment_methods
    ) c ON ( c.payment_method = t.payment_method_desc
       AND   c.payment_method_id = t.payment_method_srcid
       AND   c.bank = t.bank_desc
       AND   c.start_dt = t.start_dt
            )
    WHEN matched THEN
    UPDATE SET 
               t.end_dt  = c.end_dt,
               t.is_active = c.is_active
    WHEN NOT matched THEN
    INSERT
      (
        payment_method_id,
        payment_method_srcid,
        payment_method_desc,
        bank_desc,
        start_dt,
        end_dt,
        is_active
      )
      VALUES
      (
        bl_3nf.ce_payment_methods_seq.NEXTVAL,
        c.payment_method_id,
        c.payment_method,
        c.bank,
        c.start_dt,
        c.end_dt,
        c.is_active
      ) ;
    COMMIT;
EXCEPTION
WHEN OTHERS THEN
    RAISE;
END merge_table_ce_pm_first;
---------------------------------------------------
PROCEDURE merge_table_ce_pm_second
IS
BEGIN

MERGE INTO bl_3nf.ce_payment_methods t USING
    ( SELECT payment_method_id,
             payment_method,
             bank,
             start_dt,
             end_dt,
             is_active
      FROM   cls_payment_methods
    MINUS
      SELECT payment_method_srcid AS payment_method_id,
             payment_method_desc AS payment_method,
             bank_desc AS bank,
             start_dt,
             end_dt,
             is_active
      FROM   bl_3nf.ce_payment_methods
    ) c ON ( c.payment_method = t.payment_method_desc
       AND   c.payment_method_id = t.payment_method_srcid
       AND   c.bank = t.bank_desc
       AND   c.start_dt = t.start_dt
            )
    WHEN matched THEN
    UPDATE SET 
               t.end_dt  = c.end_dt,
               t.is_active = c.is_active
    WHEN NOT matched THEN
    INSERT
      (
        payment_method_id,
        payment_method_srcid,
        payment_method_desc,
        bank_desc,
        start_dt,
        end_dt,
        is_active
      )
      VALUES
      (
        bl_3nf.ce_payment_methods_seq.NEXTVAL,
        c.payment_method_id,
        c.payment_method,
        c.bank,
        sysdate,
        c.end_dt,
        c.is_active
      ) ;
    COMMIT;
EXCEPTION
WHEN OTHERS THEN
    RAISE;
END merge_table_ce_pm_second;
---------------------------------------------------
END pkg_etl_insert_payment_methods;
/

-- Object: bl_cl_1st/dwso/bl_cl_1st/packages/pkg_etl_insert_products.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
CREATE OR REPLACE PACKAGE pkg_etl_insert_products
AUTHID CURRENT_USER
AS
  PROCEDURE insert_table_product_types;
  PROCEDURE insert_table_collections;
  PROCEDURE insert_table_lines;
  PROCEDURE insert_table_products;
  PROCEDURE insert_table_product_details;
  PROCEDURE merge_table_ce_collections;
  PROCEDURE merge_table_ce_lines;
  PROCEDURE merge_table_ce_product_types;
  PROCEDURE merge_table_ce_products_first;
  PROCEDURE merge_table_ce_products_second;
  PROCEDURE merge_table_ce_product_details;
  
END pkg_etl_insert_products;
/

CREATE OR REPLACE PACKAGE BODY pkg_etl_insert_products
AS
---------------------------------------------------  
PROCEDURE insert_table_product_types
IS
BEGIN
  EXECUTE IMMEDIATE ('TRUNCATE TABLE cls_product_types');
  INSERT INTO cls_product_types (
                                 product_type_id,
                                 product_type,
                                 start_dt,
                                 is_active
                                 )
  SELECT   SUBSTR(product_type,1,1) || ' ' || 'tp' AS product_type_id,
           product_type,
           SYSDATE AS start_dt,
           'TRUE' AS is_active
  FROM     (SELECT DISTINCT product_type
           FROM wrk_products);

  COMMIT;
  
EXCEPTION
  WHEN OTHERS THEN
  RAISE;

END insert_table_product_types;
---------------------------------------------------  
PROCEDURE insert_table_collections
IS
BEGIN
  EXECUTE IMMEDIATE ('TRUNCATE TABLE cls_collections');
  INSERT INTO cls_collections (
                                 collection_id,
                                 collection_name,
                                 start_dt,
                                 is_active
                                 )
  SELECT   SUBSTR(collection_name,1,3) || ' ' || 'COLL' as collection_id,
           collection_name,
           SYSDATE AS start_dt,
           'TRUE' AS is_active
  FROM     (SELECT DISTINCT collection_name
            FROM wrk_products);

  COMMIT;
  
EXCEPTION
  WHEN OTHERS THEN
  RAISE;

END insert_table_collections;
---------------------------------------------------
PROCEDURE insert_table_lines
IS
BEGIN
  EXECUTE IMMEDIATE ('TRUNCATE TABLE cls_lines');
  INSERT INTO cls_lines (
                                 line_id,
                                 line_name,
                                 collection_id,
                                 start_dt,
                                 is_active
                                 )
  SELECT   SUBSTR(line_name, 1,12) || '-' || 'LIN' as line_id,
           a.line_name,
           b.collection_id,
           SYSDATE AS start_dt,
           'TRUE' AS is_active
  FROM     (SELECT DISTINCT line_name, collection_name
           FROM wrk_products) a left join cls_collections b 
                                       ON a.collection_name = b.collection_name;

  COMMIT;
  
EXCEPTION
  WHEN OTHERS THEN
  RAISE;

END insert_table_lines;
---------------------------------------------------
PROCEDURE insert_table_products
IS
BEGIN
  EXECUTE IMMEDIATE ('TRUNCATE TABLE cls_products');
  INSERT INTO cls_products (
                                 product_id,
                                 product_name,
                                 line_id,
                                 product_type_id,
                                 start_dt,
                                 end_dt,
                                 is_active
                                 )
  SELECT   a.product_id, 
           a.product_name,
           b.line_id,
           c.product_type_id,
           a.start_dt,
           a.end_dt,
           a.is_active
  FROM     wrk_products a LEFT JOIN cls_lines b 
                                 ON a.line_name = b.line_name
                          LEFT JOIN cls_product_types c 
                                 ON a.product_type = c.product_type;

  COMMIT;
  
EXCEPTION
  WHEN OTHERS THEN
  RAISE;

END insert_table_products;
---------------------------------------------------
PROCEDURE insert_table_product_details
IS
BEGIN
  EXECUTE IMMEDIATE ('TRUNCATE TABLE cls_product_details');
  INSERT INTO cls_product_details (
                                   product_detail_id,
                                   product_id,
                                   bra_size_id,
                                   panty_size_id,
                                   color,
                                   price,
                                   balance,
                                   insert_dt,
                                   update_dt
                                 )
  SELECT SUBSTR(c.product_id,1,8) || '-' || SUBSTR(a.bra_size_id,1,4) || '-' || SUBSTR(a.panty_size_id,1,4)AS product_detail_id, 
         c.product_id,
         a.bra_size_id,
         a.panty_size_id,
         a.color,
         a.price,
         a.balance,
         SYSDATE AS insert_dt,
         SYSDATE AS update_dt
  FROM   (
  SELECT product_id,
         bsg.bra_size_id AS bra_size_id,
         0 AS panty_size_id,
         color,
         to_number(price, '9999.99') AS price,
         to_number(substr(balance,1,4)) AS balance
  FROM wrk_products pr JOIN cls_bra_sizes bsg 
                         ON pr.panty_size_id = bsg.bra_size_id
  WHERE pr.product_type = 'bra'
  UNION ALL
  SELECT product_id,
         0 AS bra_size_id,
         bsg.panty_size_id AS panty_size_id,
         color,
         to_number(price, '9999.99') AS price,
         to_number(substr(balance,1,4)) AS balance
  FROM wrk_products pr JOIN cls_panty_sizes bsg 
                         ON pr.panty_size_id = bsg.panty_size_id
  WHERE pr.product_type = 'panty') a LEFT JOIN cls_products c 
                                            ON a.product_id = c.product_id;

  COMMIT;
  
EXCEPTION
  WHEN OTHERS THEN
  RAISE;

END insert_table_product_details;
---------------------------------------------------  
---------------------------------------------------
PROCEDURE merge_table_ce_collections
IS
BEGIN

MERGE INTO bl_3nf.ce_collections t USING
    ( SELECT collection_id,
             collection_name,
             start_dt AS update_dt
      FROM   cls_collections
    MINUS
      SELECT collection_srcid AS collection_id,
             collection_desc AS collection_name,
             update_dt
      FROM   bl_3nf.ce_collections
    ) c ON (c.collection_name = t.collection_desc
        AND c.collection_id = t.collection_srcid
            )
    WHEN MATCHED THEN
    UPDATE SET
          t.update_dt  = SYSDATE
    WHEN NOT matched THEN
    INSERT
      (
        collection_id,
        collection_srcid,
        collection_desc,
        update_dt
      )
      VALUES
      (
        bl_3nf.ce_collections_seq.NEXTVAL,
        c.collection_id,
        c.collection_name,
        SYSDATE
      ) ;
    COMMIT;
EXCEPTION
WHEN OTHERS THEN
    RAISE;
END merge_table_ce_collections;
---------------------------------------------------
PROCEDURE merge_table_ce_lines
IS
BEGIN

MERGE INTO bl_3nf.ce_lines t USING
    ( SELECT line_id,
             line_name,
             collection_id,
             start_dt AS update_dt
      FROM   cls_lines
    MINUS
      SELECT line_srcid AS line_id,
             line_desc  AS line_name,
             collection_srcid AS collection_id,
             update_dt
      FROM   bl_3nf.ce_lines
    ) c ON ( c.line_name = t.line_desc
         AND t.line_srcid = c.line_id
         AND t.collection_srcid  = c.collection_id
           )
    WHEN MATCHED THEN 
      UPDATE SET
       t.update_dt  = SYSDATE 
    WHEN NOT matched THEN
    INSERT
      (
        line_id,
        line_srcid,
        line_desc,
        collection_srcid,
        update_dt
      )
      VALUES
      (
        bl_3nf.ce_lines_seq.NEXTVAL,
        c.line_id,
        c.line_name,
        c.collection_id,
        SYSDATE
      ) ;
    COMMIT;
EXCEPTION
WHEN OTHERS THEN
    RAISE;
END merge_table_ce_lines;
---------------------------------------------------
PROCEDURE merge_table_ce_product_types
IS
BEGIN
MERGE INTO bl_3nf.ce_product_types t USING
    ( SELECT product_type_id,
             product_type,
             start_dt AS update_dt
      FROM   cls_product_types
    MINUS
      SELECT product_type_srcid AS product_type_id,
             product_type_desc  AS product_type,
             update_dt
      FROM   bl_3nf.ce_product_types
    ) c ON (  
             c.product_type = t.product_type_desc
        AND  t.product_type_srcid = c.product_type_id
           )
    WHEN MATCHED THEN
    UPDATE SET
         t.update_dt = SYSDATE
    WHEN NOT matched THEN
    INSERT
      (
        product_type_id,
        product_type_srcid,
        product_type_desc,
        update_dt
      )
      VALUES
      (
        bl_3nf.ce_product_types_seq.NEXTVAL,
        c.product_type_id,
        c.product_type,
        SYSDATE
      ) ;
    COMMIT;
EXCEPTION
WHEN OTHERS THEN
    RAISE;
END merge_table_ce_product_types;
---------------------------------------------------
PROCEDURE merge_table_ce_products_first
IS
BEGIN

MERGE INTO bl_3nf.ce_products t USING
    ( SELECT product_id,
             product_name,
             line_id,
             product_type_id,
             start_dt,
             end_dt,
             is_active
      FROM   cls_products
    MINUS
      SELECT product_srcid AS product_id,
             product_desc  AS product_name,
             line_srcid AS line_id,
             product_type_srcid AS product_type_id,            
             start_dt,
             end_dt,
             is_active
      FROM   bl_3nf.ce_products
    ) c ON ( t.product_srcid = c.product_id
        AND  c.product_name = t.product_desc 
        AND  t.line_srcid = c.line_id
        AND  t.product_type_srcid = c.product_type_id
        AND  c.start_dt = t.start_dt
)
    WHEN MATCHED THEN
    UPDATE SET 
           t.end_dt = c.end_dt,
           t.is_active = c.is_active
    WHEN NOT matched THEN
    INSERT
      (
        product_id,
        product_srcid,
        product_desc,
        line_srcid,
        product_type_srcid,
        start_dt,
        end_dt,
        is_active
      )
      VALUES
      (
        bl_3nf.ce_products_seq.NEXTVAL,
        c.product_id,
        c.product_name,
        c.line_id,
        c.product_type_id,
        c.start_dt,
        c.end_dt,
        c.is_active
      ) ;
    COMMIT;
EXCEPTION
WHEN OTHERS THEN
    RAISE;
END merge_table_ce_products_first;
---------------------------------------------------
PROCEDURE merge_table_ce_products_second
IS
BEGIN

MERGE INTO bl_3nf.ce_products t USING
    ( SELECT product_id,
             product_name,
             line_id,
             product_type_id,
             start_dt,
             end_dt,
             is_active
      FROM   cls_products
    MINUS
      SELECT product_srcid AS product_id,
             product_desc  AS product_name,
             line_srcid AS line_id,
             product_type_srcid AS product_type_id,            
             start_dt,
             end_dt,
             is_active
      FROM   bl_3nf.ce_products
    ) c ON ( t.product_srcid = c.product_id
        AND  c.product_name = t.product_desc 
        AND  t.line_srcid = c.line_id
        AND  t.product_type_srcid = c.product_type_id
        AND  c.start_dt = t.start_dt
)
    WHEN MATCHED THEN
    UPDATE SET 
           t.end_dt = c.end_dt,
           t.is_active = c.is_active
    WHEN NOT matched THEN
    INSERT
      (
        product_id,
        product_srcid,
        product_desc,
        line_srcid,
        product_type_srcid,
        start_dt,
        end_dt,
        is_active
      )
      VALUES
      (
        bl_3nf.ce_products_seq.NEXTVAL,
        c.product_id,
        c.product_name,
        c.line_id,
        c.product_type_id,
        sysdate,
        c.end_dt,
        c.is_active
      ) ;
    COMMIT;
EXCEPTION
WHEN OTHERS THEN
    RAISE;
END merge_table_ce_products_second;
---------------------------------------------------
PROCEDURE merge_table_ce_product_details
IS
BEGIN

MERGE INTO bl_3nf.ce_product_details t USING
    ( SELECT product_detail_id,
             product_id,
             bra_size_id,
             panty_size_id,
             color,
             price,
             balance,
             insert_dt,
             update_dt
      FROM   cls_product_details
    MINUS
      SELECT product_details_srcid AS product_detail_id,
             product_srcid  AS product_id,
             bra_size_srcid AS bra_size_id,
             panty_size_srcid AS panty_size_id,            
             color,
             price,
             product_balance AS balance,
             insert_dt,
             update_dt
      FROM   bl_3nf.ce_product_details
    ) c ON ( t.product_srcid = c.product_id
       AND   c.bra_size_id = t.bra_size_srcid
       AND   t.product_details_srcid = c.product_detail_id
       AND   c.panty_size_id = t.panty_size_srcid
       AND   c.color = t.color
       AND   c.price = t.price
       AND   c.balance = t.product_balance
    )
    WHEN matched THEN
    UPDATE SET 
           t.update_dt = SYSDATE
    WHEN NOT matched THEN
    INSERT
      (
        product_details_id,
        product_details_srcid,
        product_srcid,
        bra_size_srcid,
        panty_size_srcid,
        color,
        price,
        product_balance,
        insert_dt,
        update_dt
      )
      VALUES
      (
        bl_3nf.ce_product_details_seq.NEXTVAL,
        c.product_detail_id,
        c.product_id,
        c.bra_size_id,
        c.panty_size_id,
        c.color,
        c.price,
        c.balance,
        c.insert_dt,
        SYSDATE
      ) ;
    COMMIT;
EXCEPTION
WHEN OTHERS THEN
    RAISE;
END merge_table_ce_product_details;
---------------------------------------------------
END pkg_etl_insert_products;
/

-- Object: bl_cl_1st/dwso/bl_cl_1st/packages/pkg_etl_insert_receipts.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
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

-- Object: bl_cl_1st/dwso/bl_cl_1st/packages/pkg_etl_insert_sizes.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
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

-- Object: bl_cl_1st/dwso/bl_cl_1st/packages/pkg_etl_insert_stores.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
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

-- Object: bl_cl_1st/dwso/bl_cl_1st/packages/pkg_etl_insert_wrk.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
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

-- Object: bl_cl_1st/dwso/bl_cl_1st/packages/pkg_etl_update_ce.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
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

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/cls_age_categories/cls_age_categories.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;

CREATE TABLE cls_age_categories
  (
    age_category_id NUMBER ( 10 ) NOT NULL,
    age_category    VARCHAR2 ( 200 CHAR ) NOT NULL
  );

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/cls_bra_sizes/cls_bra_sizes.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;

CREATE TABLE cls_bra_sizes
  ( 
    bra_size_id  NUMBER ( 10 ) NOT NULL,
    bra_size_uk  VARCHAR2 ( 200 CHAR ) NOT NULL,
    bra_size_usa VARCHAR2 ( 200 CHAR ) NOT NULL,
    bra_size_eu  VARCHAR2 ( 200 CHAR ) NOT NULL,
    bra_size_fr  VARCHAR2 ( 200 CHAR ) NOT NULL,
    bra_size_uie VARCHAR2 ( 200 CHAR ) NOT NULL
  );

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/cls_cities/cls_cities.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;

CREATE TABLE cls_cities
  (
    city_id    VARCHAR2(200 CHAR) NOT NULL,
    city_desc  VARCHAR2(200 CHAR) NOT NULL,
    country_id NUMBER ( 10 ) NOT NULL
  );

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/cls_collections/cls_collections.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;

CREATE TABLE cls_collections
  (
    collection_id   VARCHAR2 ( 200 CHAR ) NOT NULL,
    collection_name VARCHAR2 ( 200 CHAR ) NOT NULL,
    start_dt        DATE DEFAULT '01-JAN-1990',
    end_dt          DATE DEFAULT '31-DEC-9999',
    is_active       VARCHAR2 ( 200 CHAR ) NOT NULL
  );

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/cls_continents/cls_continents.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;

CREATE TABLE cls_continents
  (
    continent_id   NUMBER ( 10 ) NOT NULL,
    continent_desc VARCHAR2 ( 200 CHAR ) NOT NULL
  );

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/cls_countries/cls_countries.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;

CREATE TABLE cls_countries
  (
    country_id   NUMBER ( 10 ) NOT NULL,
    country_desc VARCHAR2 ( 200 CHAR ) NOT NULL,
    country_code VARCHAR2 ( 3 ) Default 'NN',
    region_id    NUMBER ( 10 ) NOT NULL
  );

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/cls_customers/cls_customers.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;

CREATE TABLE cls_customers
  (
    customer_id     VARCHAR2 ( 200 CHAR ) NOT NULL,
    first_name      VARCHAR2 ( 200 CHAR ) NOT NULL,
    last_name       VARCHAR2 ( 200 CHAR ) NOT NULL,
    age             NUMBER ( 38 ) NOT NULL,
    age_category_id NUMBER ( 38 ) NOT NULL,
    email           VARCHAR2 ( 200 CHAR ) NOT NULL,
    phone           VARCHAR2 ( 200 CHAR ) NOT NULL,
    address         VARCHAR2 ( 200 CHAR ) NOT NULL,
    city_id         VARCHAR2 ( 200 CHAR ) NOT NULL,
    start_dt        DATE DEFAULT '01-JAN-1990',
    end_dt          DATE DEFAULT '31-DEC-9999',
    is_active       VARCHAR2 ( 200 CHAR ) NOT NULL
  );

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/cls_employees/cls_employees.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;

CREATE TABLE cls_employees
  (
    employee_id       VARCHAR2 ( 100 CHAR ) NOT NULL,
    first_name        VARCHAR2 ( 100 CHAR ) NOT NULL,
    last_name         VARCHAR2 ( 100 CHAR ) NOT NULL,
    store_id          VARCHAR2 ( 100 CHAR ) NOT NULL,
    position_name     VARCHAR2 ( 100 CHAR ) NOT NULL,
    position_grade_id VARCHAR2 ( 100 CHAR ) NOT NULL,
    work_experience   NUMBER ( 38 ) NOT NULL,
    email             VARCHAR2 ( 100 CHAR ) NOT NULL,
    phone             VARCHAR2 ( 100 CHAR ) NOT NULL,
    start_dt          DATE DEFAULT '01-JAN-1990',
    end_dt            DATE DEFAULT '31-DEC-9999',
    is_active         VARCHAR2 ( 200 CHAR ) NOT NULL
  );

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/cls_lines/cls_lines.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;

CREATE TABLE cls_lines
  (
    line_id       VARCHAR2 ( 200 CHAR ) NOT NULL,
    line_name     VARCHAR2 ( 200 CHAR ) NOT NULL,
    collection_id VARCHAR2 ( 200 CHAR ) NOT NULL,
    start_dt      DATE DEFAULT '01-JAN-1990',
    end_dt        DATE DEFAULT '31-DEC-9999',
    is_active     VARCHAR2 ( 200 CHAR ) NOT NULL
  );

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/cls_panty_sizes/cls_panty_sizes.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;

CREATE TABLE cls_panty_sizes
(
 panty_size_id  NUMBER ( 10 ) NOT NULL,
 panty_size_uk  VARCHAR2 ( 200 CHAR ) NOT NULL,
 panty_size_usa VARCHAR2 ( 200 CHAR ) NOT NULL,
 panty_size_eu  VARCHAR2 ( 200 CHAR ) NOT NULL,
 panty_size_fr  VARCHAR2 ( 200 CHAR ) NOT NULL,
 panty_size_uie VARCHAR2 ( 200 CHAR ) NOT NULL
);

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/cls_payment_methods/cls_payment_methods.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;

CREATE TABLE cls_payment_methods
  (
    payment_method_id VARCHAR2 ( 200 CHAR ) NOT NULL,
    payment_method    VARCHAR2 ( 200 CHAR ) NOT NULL,
    bank              VARCHAR2 ( 200 CHAR ) NOT NULL,
    start_dt          DATE DEFAULT '01-JAN-1990',
    end_dt            DATE DEFAULT '31-DEC-9999',
    is_active         VARCHAR2 ( 200 CHAR ) NOT NULL
  );

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/cls_position_grade/cls_position_grade.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;

CREATE TABLE cls_position_grade
  (
    position_grade_id VARCHAR2 ( 200 CHAR ) NOT NULL,
    position_grade    VARCHAR2 ( 200 CHAR ) NOT NULL,
    work_experience   NUMBER ( 10 ) NOT NULL
  );

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/cls_product_details/cls_product_details.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;

CREATE TABLE cls_product_details
  (
    product_detail_id VARCHAR2 ( 200 CHAR ) NOT NULL,
    product_id        VARCHAR2 ( 200 CHAR ) NOT NULL,
    bra_size_id       NUMBER ( 10 ) DEFAULT 0,
    panty_size_id     NUMBER ( 10 ) DEFAULT 0,
    color             VARCHAR2 ( 200 CHAR ) NOT NULL,
    price             NUMBER ( 10,2 ) NOT NULL,
    balance           NUMBER ( 10,2 ) NOT NULL,
    insert_dt         DATE DEFAULT '01-JAN-1990' ,
    update_dt         DATE DEFAULT '31-DEC-9999'
  );

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/cls_product_types/cls_product_types.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;

CREATE TABLE cls_product_types
  (
    product_type_id VARCHAR2 ( 200 CHAR ) NOT NULL,
    product_type    VARCHAR2 ( 200 CHAR ) NOT NULL,
    start_dt        DATE DEFAULT '01-JAN-1990',
    end_dt          DATE DEFAULT '31-DEC-9999',
    is_active       VARCHAR2 ( 200 CHAR ) NOT NULL
  );

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/cls_products/cls_products.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;

CREATE TABLE cls_products
  (
    product_id      VARCHAR2 ( 200 CHAR ) NOT NULL,
    product_name    VARCHAR2 ( 200 CHAR ) NOT NULL,
    line_id         VARCHAR2 ( 200 CHAR ) NOT NULL,
    product_type_id VARCHAR2 ( 200 CHAR ) NOT NULL,
    start_dt        DATE DEFAULT '01-JAN-1990',
    end_dt          DATE DEFAULT '31-DEC-9999',
    is_active       VARCHAR2 ( 200 CHAR ) NOT NULL
  );

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/cls_receipts/cls_receipts.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;

CREATE TABLE cls_receipts
  (
    receipt_id        NUMBER ( 38 ) NOT NULL,
    receipt_dt        DATE NOT NULL,
    store_id          NUMBER ( 38 ) NOT NULL,
    employee_id       NUMBER ( 38 ) NOT NULL,
    customer_id       NUMBER ( 38 ) NOT NULL,
    payment_method_id NUMBER ( 38 ) NOT NULL,
    product_detail_id NUMBER ( 38 ) NOT NULL,
    receipt_sum       NUMBER ( 38 ) NOT NULL,
    insert_dt         DATE DEFAULT '31-DEC-1999'
  );

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/cls_regions/cls_regions.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;

CREATE TABLE cls_regions
  (
    region_id    NUMBER ( 10 ) NOT NULL,
    region_desc  VARCHAR2(200 CHAR) NOT NULL,
    continent_id NUMBER ( 10 ) NOT NULL
  );

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/cls_stores/cls_stores.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;

CREATE TABLE cls_stores
  (
    store_id     VARCHAR2 ( 200 CHAR ) NOT NULL,
    store_code   VARCHAR2 ( 200 CHAR ) NOT NULL,
    store_name   VARCHAR2 ( 200 CHAR ) NOT NULL,
    manager_id   VARCHAR2 ( 200 CHAR ) NOT NULL,
    phone        VARCHAR2 ( 200 CHAR ) NOT NULL,
    address      VARCHAR2 ( 200 CHAR ) NOT NULL,
    city_id      VARCHAR2 ( 200 CHAR ) NOT NULL,
    insert_dt    DATE DEFAULT '01-JAN-1990',
    update_dt    DATE DEFAULT '31-DEC-9999'
  );

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/wrk_bra_sizes/wrk_bra_sizes.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;

CREATE TABLE wrk_bra_sizes
( 
  bra_size_code NUMBER (10),
  bra_size_uk  VARCHAR2 ( 200 CHAR ),
  bra_size_usa VARCHAR2 ( 200 CHAR ),
  bra_size_eu  VARCHAR2 ( 200 CHAR ),
  bra_size_fr  VARCHAR2 ( 200 CHAR ),
  bra_size_uie VARCHAR2 ( 200 CHAR )
);

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/wrk_cities/wrk_cities.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;

CREATE TABLE wrk_cities
(
 city_id     VARCHAR2 ( 200 BYTE ),
 city_desc   VARCHAR2 ( 200 BYTE ),
 country_id  NUMBER ( 10 )
);

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/wrk_countries/wrk_countries.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;

CREATE TABLE wrk_countries
(
 country_id     NUMBER ( 10 ),
 country_desc   VARCHAR2 ( 200 CHAR ),
 country_code   VARCHAR2 ( 3 )
);

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/wrk_customers/wrk_customers.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;

CREATE TABLE wrk_customers
  (
    passport_number VARCHAR2 ( 200 CHAR ),
    first_name      VARCHAR2 ( 200 CHAR ),
    last_name       VARCHAR2 ( 200 CHAR ),
    gender          VARCHAR2 ( 200 CHAR ),
    age             NUMBER ( 38 ),
    email           VARCHAR2 ( 200 CHAR ),
    phone           VARCHAR2 ( 200 CHAR ),
    address         VARCHAR2 ( 200 CHAR ),
    city            VARCHAR2 ( 200 CHAR ),
    country_id      VARCHAR2 ( 200 CHAR ),
    start_dt        DATE,
    end_dt          DATE,
    is_active       VARCHAR2 ( 200 CHAR )
  );

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/wrk_employees/wrk_employees.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;

CREATE TABLE wrk_employees
(
 employee_code        VARCHAR2 ( 100 CHAR ),
 first_name           VARCHAR2 ( 100 CHAR ),
 last_name            VARCHAR2 ( 100 CHAR ),
 age                  NUMBER ( 38 ),
 store_srcid          VARCHAR2 ( 100 CHAR ),
 position_name        VARCHAR2 ( 100 CHAR ),
 position_grade_srcid VARCHAR2 ( 100 CHAR ),
 work_experience      NUMBER ( 38 ),
 email                VARCHAR2 ( 100 CHAR ),
 phone                VARCHAR2 ( 100 CHAR ),
 personal_address     VARCHAR2 ( 100 CHAR ),
 currency             VARCHAR2 ( 100 CHAR ),
 currency_code        VARCHAR2 ( 100 CHAR ),
 month_salary         NUMBER ( 38,3 ),
 credit_card          NUMBER ( 38 ),
 start_dt             DATE,
 end_dt               DATE,
 is_active            VARCHAR2 ( 100 CHAR )
);

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/wrk_full_data/wrk_full_data.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;

CREATE TABLE wrk_full_data
(
 country_id           NUMBER(10,0),
 county_desc          VARCHAR2(200 CHAR),
 structure_code       NUMBER(10,0),
 structure_desc       VARCHAR2(200 CHAR)
);

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/wrk_panty_sizes/wrk_panty_sizes.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;

CREATE TABLE wrk_panty_sizes
(
 panty_size_code NUMBER (20),
 panty_size_uk  VARCHAR2 ( 200 CHAR ),
 panty_size_usa VARCHAR2 ( 200 CHAR ),
 panty_size_eu  VARCHAR2 ( 200 CHAR ),
 panty_size_fr  VARCHAR2 ( 200 CHAR ),
 panty_size_uie VARCHAR2 ( 200 CHAR )
);

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/wrk_payment_methods/wrk_payment_methods.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;

CREATE TABLE wrk_payment_methods
  (
    payment_method_name VARCHAR2 ( 200 CHAR ),
    bank                VARCHAR2 ( 200 CHAR ),
    start_dt            DATE,
    end_dt              DATE,
    is_active           VARCHAR2 ( 100 BYTE )
  );

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/wrk_products/wrk_products.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;

CREATE TABLE wrk_products
(
    product_id      VARCHAR2 ( 200 CHAR ),
    product_name    VARCHAR2 ( 200 CHAR ),
    line_name       VARCHAR2 ( 200 CHAR ),
    collection_name VARCHAR2 ( 200 CHAR ),
    product_type    VARCHAR2 ( 200 CHAR ),
    color           VARCHAR2 ( 200 CHAR ),
    panty_size_id   VARCHAR2 ( 200 CHAR ),
    price           VARCHAR2 ( 200 CHAR ),
    balance         VARCHAR2 ( 200 CHAR ),
    start_dt        DATE,
    end_dt          DATE,
    is_active       VARCHAR2 ( 100 BYTE )
);

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/wrk_stores/wrk_stores.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;

CREATE TABLE wrk_stores
  (
    store_code VARCHAR2 ( 200 CHAR ),
    store_name VARCHAR2 ( 200 CHAR ),
    manager_id VARCHAR2 ( 200 CHAR ),
    phone      VARCHAR2 ( 200 CHAR ),
    address    VARCHAR2 ( 200 CHAR ),
    city       VARCHAR2 ( 200 CHAR ),
    country_id VARCHAR2 ( 200 CHAR ),
    start_dt   DATE
  );

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/wrk_structures/wrk_structures.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;

CREATE TABLE wrk_structures  
(
 child_code           NUMBER(10,0),
 parent_code          NUMBER(10,0),
 structure_desc       VARCHAR2(200 CHAR),
 structure_level      VARCHAR2(200 CHAR)
);

-- Object: bl_cl_2nd/dwso/bl_cl_2nd/packages/pkg_drop.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_2nd;
CREATE OR REPLACE PACKAGE pkg_drop 
  AUTHID CURRENT_USER AS
  PROCEDURE drop_proc ( object_name IN VARCHAR2, object_type VARCHAR2);
END pkg_drop;
/
CREATE OR REPLACE PACKAGE BODY  pkg_drop AS 
  PROCEDURE drop_proc (object_name IN VARCHAR2, object_type VARCHAR2) IS
  ex_grants exception;
  ex_inv_table_name exception;
  ex_exist_syn_name exception;
  ex_table exception;
  ex_public_synonym exception;
  ex_synonym exception;
  pragma exception_init( ex_grants, -01031 );
  pragma exception_init( ex_inv_table_name, -00903 );
  pragma exception_init( ex_exist_syn_name, -00955 );
  pragma exception_init( ex_table, -00942 );
  pragma exception_init( ex_public_synonym, -01432 );
  pragma exception_init( ex_synonym, -01434 );
	BEGIN
	  IF object_type = 'TABLE' THEN
		EXECUTE IMMEDIATE 'drop ' || object_type || ' ' || object_name || ' cascade constraints';
	  ELSE
		EXECUTE IMMEDIATE 'drop ' || object_type || ' ' || object_name;
	  END IF;
	  
	  exception
	  WHEN ex_table THEN
		   dbms_output.put_line(object_type || ' ' || object_name ||' does not exist');
		   -- insert into log_table (error_message, error_code);
	  WHEN ex_grants  THEN
		   dbms_output.put_line('User has no grants');
	  WHEN ex_inv_table_name THEN
		   dbms_output.put_line('Invalid table name');
	  WHEN ex_exist_syn_name THEN
		   dbms_output.put_line('Name is already used by an existing object');
	  WHEN ex_public_synonym THEN
		   dbms_output.put_line(object_type || ' ' || object_name ||' does not exist');
	  WHEN ex_synonym THEN
		  dbms_output.put_line(object_type || ' ' || object_name ||' does not exist');
	  WHEN others THEN
		   raise;
	END;
END pkg_drop;
/

-- Object: bl_cl_2nd/dwso/bl_cl_2nd/packages/pkg_etl_customers.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_2nd;
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

-- Object: bl_cl_2nd/dwso/bl_cl_2nd/packages/pkg_etl_employees.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_2nd;
CREATE OR REPLACE PACKAGE pkg_etl_insert_employees
AUTHID CURRENT_USER
AS
  PROCEDURE insert_table_employees;
  PROCEDURE merge_table_employees;
  
END pkg_etl_insert_employees;
/

CREATE OR REPLACE PACKAGE BODY pkg_etl_insert_employees
AS
---------------------------------------------------  
PROCEDURE insert_table_employees
IS
BEGIN
  EXECUTE IMMEDIATE ('TRUNCATE TABLE cls_employees_scd');
  INSERT INTO cls_employees_scd
SELECT DISTINCT
      employee_id AS employee_surr_id,
      employee_srcid AS employee_id,
      first_name,
      last_name,
      ce.store_srcid AS store_number,
      position_name,
      position_grade_desc AS position_grade,
      ce.work_experience,
      ce.email,
      ce.phone,
      ce.start_dt,
      ce.end_dt,
      ce.is_active
FROM  bl_3nf.ce_employees ce left join bl_3nf.ce_position_grades pg
                                     on ce.position_grade_srcid = pg.position_grade_srcid
                             left join bl_3nf.ce_stores pf
                                     on ce.store_srcid = pf.store_srcid;

  COMMIT;
  
EXCEPTION
  WHEN OTHERS THEN
  RAISE;

END insert_table_employees;
---------------------------------------------------  
PROCEDURE merge_table_employees
IS
BEGIN
  MERGE INTO bl_dm.dim_employees_scd t USING
    ( SELECT employee_surr_id,
             first_name,
             last_name,
             store_number,
             position_name,
             position_grade,
             work_experience,
             email,
             phone,
             start_dt,
             end_dt,
             is_active
      FROM   cls_employees_scd
    MINUS
      SELECT employee_id,
             first_name,
             last_name,
             store_number,
             position_name,
             position_grade,
             work_experience,
             email,
             phone,
             start_dt,
             end_dt,
             is_active          
      FROM   bl_dm.dim_employees_scd
    ) c ON ( 
             t.first_name = c.first_name
       AND   t.last_name = c.last_name
       AND   t.store_number = c.store_number
       AND   t.position_name = c.position_name
       AND   t.position_grade = c.position_grade
       AND   t.work_experience = c.work_experience
       AND   t.email = c.email
       AND   t.phone = c.phone
       AND   t.start_dt = c.start_dt)
    WHEN matched THEN
    UPDATE SET 
               t.employee_id = c.employee_surr_id,
               t.end_dt = c.end_dt,
               t.is_active = c.is_active
    WHEN NOT matched THEN
    INSERT
      (
       employee_surr_id,
       employee_id,
       first_name,
       last_name,
       store_number,
       position_name,
       position_grade,
       work_experience,
       email,
       phone,
       start_dt,
       end_dt,
       is_active
      )
      VALUES
      (
       bl_dm.dim_employees_seq.NEXTVAL,
       c.employee_surr_id,
       c.first_name,
       c.last_name,
       c.store_number,
       c.position_name,
       c.position_grade,
       c.work_experience,
       c.email,
       c.phone,
       c.start_dt,
       c.end_dt,
       c.is_active
      ) ;
    COMMIT;
  
EXCEPTION
  WHEN OTHERS THEN
  RAISE;

END merge_table_employees;
---------------------------------------------------
END pkg_etl_insert_employees;
/

-- Object: bl_cl_2nd/dwso/bl_cl_2nd/packages/pkg_etl_insert_retail_sales.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_2nd;
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
DECLARE
     CURSOR rt_cursor IS
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
   BEGIN
     FOR rt_cursor_val IN rt_cursor LOOP
       INSERT INTO cls_fct_retail_sales_dd (
                                            receipt_id,
                                            event_dt,
                                            employee_surr_id,
                                            customer_surr_id,
                                            store_surr_id,
                                            payment_method_surr_id,
                                            product_surr_id,
                                            tot_sale_sum,
                                            tot_sale_amount,
                                            insert_dt,
                                            update_dt
                                       )
            VALUES (
                    rt_cursor_val.receipt_id,
                    rt_cursor_val.event_dt,
                    rt_cursor_val.employee_surr_id,
                    rt_cursor_val.customer_surr_id,
                    rt_cursor_val.store_id,
                    rt_cursor_val.payment_method_surr_id,
                    rt_cursor_val.product_detail_surr_id,
                    rt_cursor_val.tot_sale_sum,
                    rt_cursor_val.tot_sale_amount,
                    rt_cursor_val.insert_dt,
                    rt_cursor_val.update_dt
                   );
      END LOOP;
   COMMIT;
  END;  
EXCEPTION
  WHEN OTHERS THEN
  RAISE;

END insert_table_retail_sales;
---------------------------------------------------  
PROCEDURE insert_table_fct_retail_sales
IS
BEGIN
   DECLARE
     CURSOR rc_cursor IS
            SELECT bl_dm.fct_retail_sales_dd_seq.NEXTVAL AS sale_id,
                   a.receipt_id,
                   a.event_dt,
                   c.employee_surr_id,
                   b.customer_surr_id,
                   d.store_surr_id,
                   f.payment_method_id,
                   e.product_surr_id,
                   a.tot_sale_sum,
                   a.tot_sale_amount,
                   a.insert_dt,
                   a.update_dt 
            FROM   cls_fct_retail_sales_dd a INNER JOIN bl_dm.dim_customers_scd b ON a.customer_surr_id = b.customer_id
                                             INNER JOIN bl_dm.dim_employees_scd c ON a.employee_surr_id = c.employee_id
                                             INNER JOIN bl_dm.dim_stores_scd d ON a.store_surr_id = d.store_id
                                             INNER JOIN bl_dm.dim_payment_methods_scd f ON a.payment_method_surr_id = f.payment_method_id
                                             INNER JOIN bl_dm.dim_products_scd e ON a.product_surr_id = e.product_id;
   BEGIN
     FOR rc_cursor_val IN rc_cursor LOOP
       INSERT INTO bl_dm.fct_retail_sales_dd (
                                              sale_id,
                                              receipt_id,
                                              event_dt,
                                              employee_surr_id,
                                              customer_surr_id,
                                              store_surr_id,
                                              payment_method_id,
                                              product_surr_id,
                                              tot_sale_sum,
                                              tot_sale_amount,
                                              insert_dt,
                                              update_dt
                                             )
            VALUES (
                    rc_cursor_val.sale_id,
                    rc_cursor_val.receipt_id,
                    rc_cursor_val.event_dt,
                    rc_cursor_val.employee_surr_id,
                    rc_cursor_val.customer_surr_id,
                    rc_cursor_val.store_surr_id,
                    rc_cursor_val.payment_method_id,
                    rc_cursor_val.product_surr_id,
                    rc_cursor_val.tot_sale_sum,
                    rc_cursor_val.tot_sale_amount,
                    rc_cursor_val.insert_dt,
                    rc_cursor_val.update_dt 
                   );
      END LOOP;
   COMMIT;
  END;
EXCEPTION
WHEN OTHERS THEN
    RAISE;
END insert_table_fct_retail_sales;
---------------------------------------------------
END pkg_etl_insert_retail_sales;
/

-- Object: bl_cl_2nd/dwso/bl_cl_2nd/packages/pkg_etl_payment_methods.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_2nd;
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

-- Object: bl_cl_2nd/dwso/bl_cl_2nd/packages/pkg_etl_products.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_2nd;
CREATE OR REPLACE PACKAGE pkg_etl_insert_products
AUTHID CURRENT_USER
AS
  PROCEDURE insert_table_products;
  PROCEDURE merge_table_products;
						
END pkg_etl_insert_products;
/

CREATE OR REPLACE PACKAGE BODY pkg_etl_insert_products
AS
---------------------------------------------------  
PROCEDURE insert_table_products
IS
BEGIN
  EXECUTE IMMEDIATE ('TRUNCATE TABLE cls_products_scd');
  DECLARE
       CURSOR s_cur IS 
          SELECT DISTINCT
                 cc.product_details_id AS product_surr_id,
                 cc.product_details_srcid AS product_id,
                 cs.product_desc AS product_desc,
                 cl.line_desc AS line_name,
                 ccl.collection_desc AS collection_name,
                 pt.product_type_desc AS product_type,
                 bra_size_uk,
                 bra_size_usa,
                 bra_size_eu,
                 bra_size_fr,
                 bra_size_uie,
                 panty_size_uk,
                 panty_size_usa,
                 panty_size_eu,
                 panty_size_fr,
                 panty_size_uie,
                 color,
                 price,
                 cs.start_dt,
                 cs.end_dt,
                 cs.is_active
          FROM   bl_3nf.ce_product_details cc left join bl_3nf.ce_products cs
                                                     on cc.product_srcid = cs.product_srcid
                                              left join bl_3nf.ce_bra_size_grid cn
                                                     on cc.bra_size_srcid = cn.bra_size_srcid
                                              left join bl_3nf.ce_panty_size_grid cr
                                                     on cc.panty_size_srcid = cr.panty_size_srcid
                                              left join bl_3nf.ce_lines cl
                                                     on cs.line_srcid = cl.line_srcid
                                              left join bl_3nf.ce_collections ccl
                                                     on cl.collection_srcid = ccl.collection_srcid
                                              left join bl_3nf.ce_product_types pt
                                                     on cs.product_type_srcid = pt.product_type_srcid;
       TYPE fetch_array IS TABLE OF s_cur%ROWTYPE;
       s_array fetch_array;
      BEGIN
        OPEN s_cur;
        LOOP
          FETCH s_cur BULK COLLECT INTO s_array;
      
          FORALL i IN 1..s_array.COUNT
          INSERT INTO cls_products_scd
          VALUES s_array(i);
          EXIT WHEN s_cur%NOTFOUND;
        END LOOP;
        CLOSE s_cur;
        COMMIT;
      END;

EXCEPTION
  WHEN OTHERS THEN
  RAISE;

END insert_table_products;
---------------------------------------------------  
PROCEDURE merge_table_products
IS
BEGIN
MERGE INTO bl_dm.dim_products_scd t USING
    ( SELECT product_surr_id,
             product_desc,
             line_name,
             collection_name,
             product_type,
             bra_size_uk,
             bra_size_usa,
             bra_size_eu,
             bra_size_fr,
             bra_size_uie,
             panties_size_uk,
             panties_size_usa,
             panties_size_eu,
             panties_size_fr,
             panties_size_uie,
             color,
             price,
             start_dt,
             end_dt,
             is_active 
      FROM   cls_products_scd
    MINUS
      SELECT product_id,
             product_desc,
             line_name,
             collection_name,
             product_type,
             bra_size_uk,
             bra_size_usa,
             bra_size_eu,
             bra_size_fr,
             bra_size_uie,
             panties_size_uk,
             panties_size_usa,
             panties_size_eu,
             panties_size_fr,
             panties_size_uie,
             color,
             price,
             start_dt,
             end_dt,
             is_active           
      FROM   bl_dm.dim_products_scd
    ) c ON ( t.product_desc = c.product_desc
       AND   t.line_name = c.line_name
       AND   t.collection_name = c.collection_name
       AND   t.product_type = c.product_type
       AND   t.bra_size_uk = c.bra_size_uk
       AND   t.bra_size_usa = c.bra_size_usa
       AND   t.bra_size_eu = c.bra_size_eu
       AND   t.bra_size_fr = c.bra_size_fr
       AND   t.bra_size_uie = c.bra_size_uie
       AND   t.panties_size_uk = c.panties_size_uk
       AND   t.panties_size_usa = c.panties_size_usa
       AND   t.panties_size_eu = c.panties_size_eu
       AND   t.panties_size_fr = c.panties_size_fr
       AND   t.panties_size_uie = c.panties_size_uie
       AND   t.color = c.color
       AND   t.price = c.price
       AND   t.start_dt = c.start_dt)
    WHEN matched THEN
    UPDATE SET t.product_id = c.product_surr_id,
               t.end_dt = c.end_dt,
               t.is_active = c.is_active
    WHEN NOT matched THEN
    INSERT
      (
        product_surr_id,
        product_id,
        product_desc,
        line_name,
        collection_name,
        product_type,
        bra_size_uk,
        bra_size_usa,
        bra_size_eu,
        bra_size_fr,
        bra_size_uie,
        panties_size_uk,
        panties_size_usa,
        panties_size_eu,
        panties_size_fr,
        panties_size_uie,
        color,
        price,
        start_dt,
        end_dt,
        is_active 
      )
      VALUES
      (
        bl_dm.dim_products_seq.NEXTVAL,
        c.product_surr_id,
        c.product_desc,
        c.line_name,
        c.collection_name,
        c.product_type,
        c.bra_size_uk,
        c.bra_size_usa,
        c.bra_size_eu,
        c.bra_size_fr,
        c.bra_size_uie,
        c.panties_size_uk,
        c.panties_size_usa,
        c.panties_size_eu,
        c.panties_size_fr,
        c.panties_size_uie,
        c.color,
        c.price,
        c.start_dt,
        c.end_dt,
        c.is_active 
      ) ;
    COMMIT;
  
EXCEPTION
  WHEN OTHERS THEN
  RAISE;
  
END merge_table_products;
--------------------------------------------------- 
END pkg_etl_insert_products;
/

-- Object: bl_cl_2nd/dwso/bl_cl_2nd/packages/pkg_etl_retail_sales.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_2nd;
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

-- Object: bl_cl_2nd/dwso/bl_cl_2nd/packages/pkg_etl_stores.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_2nd;
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

-- Object: bl_cl_2nd/dwso/bl_cl_2nd/tables/cls_customers/cls_customers_scd.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_2nd;

CREATE TABLE cls_customers_scd (
    customer_surr_id   NUMBER(38) NOT NULL,
    customer_id        VARCHAR2(100 BYTE) NOT NULL,
    first_name         VARCHAR2(100 BYTE) NOT NULL,
    last_name          VARCHAR2(100 BYTE) NOT NULL,
    age                NUMBER(38) NOT NULL,
    age_category       VARCHAR2(100 BYTE) NOT NULL,
    email              VARCHAR2(100 BYTE) NOT NULL,
    phone              VARCHAR2(100 BYTE) NOT NULL,
    address            VARCHAR2(100 BYTE) NOT NULL,
    city               VARCHAR2(100 BYTE) NOT NULL,
    country            VARCHAR2(100 BYTE) NOT NULL,
    region             VARCHAR2(100 BYTE) NOT NULL,
    start_dt           DATE DEFAULT '01-JAN-1990',
    end_dt             DATE DEFAULT '31-DEC-9999',
    is_active          VARCHAR2 ( 200 CHAR ) NOT NULL
);

-- Object: bl_cl_2nd/dwso/bl_cl_2nd/tables/cls_employees/cls_employees_scd.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_2nd;

CREATE TABLE cls_employees_scd
  (
    employee_surr_id NUMBER(38) NOT NULL,
    employee_id      VARCHAR2(50 BYTE) NOT NULL,
    first_name       VARCHAR2(50 BYTE) NOT NULL,
    last_name        VARCHAR2(50 BYTE) NOT NULL,
    store_number     VARCHAR2(50 BYTE) NOT NULL,
    position_name    VARCHAR2(50 BYTE) NOT NULL,
    position_grade   VARCHAR2(50 BYTE) NOT NULL,
    work_experience  NUMBER(10) NOT NULL,
    email            VARCHAR2(50 BYTE) NOT NULL,
    phone            VARCHAR2(50 BYTE) NOT NULL,
    start_dt         DATE DEFAULT '01-JAN-1990',
    end_dt           DATE DEFAULT '31-DEC-9999',
    is_active        VARCHAR2 ( 200 CHAR ) NOT NULL
  );

-- Object: bl_cl_2nd/dwso/bl_cl_2nd/tables/cls_payment_methods/cls_payment_methods_scd.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_2nd;

CREATE TABLE cls_payment_methods_scd
  (
    payment_method_surr_id NUMBER(38) NOT NULL,
    payment_method_id      VARCHAR2(40 BYTE) NOT NULL,
    payment_method_desc    VARCHAR2(40 BYTE) NOT NULL,
    bank_name              VARCHAR2(40 BYTE),
    start_dt               DATE DEFAULT '01-JAN-1990',
    end_dt                 DATE DEFAULT '31-DEC-9999',
    is_active              VARCHAR2 ( 200 CHAR ) NOT NULL
  );

-- Object: bl_cl_2nd/dwso/bl_cl_2nd/tables/cls_products/cls_products_scd.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_2nd;

CREATE TABLE cls_products_scd (
    product_surr_id     NUMBER(38) NOT NULL,
    product_id          VARCHAR2(100 BYTE) NOT NULL,
    product_desc        VARCHAR2(100 BYTE) NOT NULL,
    line_name           VARCHAR2(100 BYTE) NOT NULL,
    collection_name     VARCHAR2(100 BYTE) NOT NULL,
    product_type        VARCHAR2(100 BYTE) NOT NULL,
    bra_size_uk         VARCHAR2(100 BYTE) DEFAULT '0',
    bra_size_usa        VARCHAR2(100 BYTE) DEFAULT '0',
    bra_size_eu         VARCHAR2(100 BYTE) DEFAULT '0',
    bra_size_fr         VARCHAR2(100 BYTE) DEFAULT '0',
    bra_size_uie        VARCHAR2(100 BYTE) DEFAULT '0',
    panties_size_uk     VARCHAR2(100 BYTE) DEFAULT '0',
    panties_size_usa    VARCHAR2(100 BYTE) DEFAULT '0',
    panties_size_eu     VARCHAR2(100 BYTE) DEFAULT '0',
    panties_size_fr     VARCHAR2(100 BYTE) DEFAULT '0',
    panties_size_uie    VARCHAR2(100 BYTE) DEFAULT '0',
    color               VARCHAR2(100 BYTE),
    price               NUMBER(38),
    start_dt            DATE DEFAULT '01-JAN-1990',
    end_dt              DATE DEFAULT '31-DEC-9999',
    is_active           VARCHAR2 ( 200 CHAR ) NOT NULL
);

-- Object: bl_cl_2nd/dwso/bl_cl_2nd/tables/cls_retail_sales_dd/cls_fact_retail_sales.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_2nd;

CREATE TABLE cls_fct_retail_sales_dd (
    receipt_id               NUMBER(38) NOT NULL,
    event_dt                 DATE NOT NULL,
    employee_surr_id         NUMBER(38) NOT NULL,
    customer_surr_id         NUMBER(38) NOT NULL,
    store_surr_id            NUMBER(38) NOT NULL,
    payment_method_surr_id   NUMBER(38) NOT NULL,
    product_surr_id          NUMBER(38) NOT NULL,
    tot_sale_sum             NUMBER(38) NOT NULL,
    tot_sale_amount          NUMBER(38) NOT NULL,
    insert_dt                DATE NOT NULL,
    update_dt                DATE NOT NULL
);

-- Object: bl_cl_2nd/dwso/bl_cl_2nd/tables/cls_stores/cls_stores.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_2nd;

CREATE TABLE cls_stores_scd
  (
    store_surr_id NUMBER(38) NOT NULL,
    store_id      VARCHAR2(50 BYTE) NOT NULL,
    store_desc    VARCHAR2(50 BYTE) NOT NULL,
    phone         VARCHAR2(50 BYTE) NOT NULL,
    address       VARCHAR2(50 BYTE) NOT NULL,
    city          VARCHAR2(100 BYTE) NOT NULL,
    country       VARCHAR2(100 BYTE) NOT NULL,
    region        VARCHAR2(100 BYTE) NOT NULL,
    insert_dt     DATE DEFAULT '01-JAN-1990',
    update_dt     DATE DEFAULT SYSDATE
  );

-- Object: bl_cl_2nd/dwso/bl_cl_2nd/tables/cls_time_day/cls_time_day.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_2nd;

CREATE TABLE cls_time_day (
    date_dt                  DATE NOT NULL,
    week_day_full_name       VARCHAR2(10) NOT NULL,
    week_day_short_name      VARCHAR2(10) NOT NULL,
    day_number_of_week       NUMBER(10) NOT NULL,
    day_number_of_month      NUMBER(10) NOT NULL,
    day_number_of_year       NUMBER(10) NOT NULL,
    month_year               VARCHAR2(10) NOT NULL,
    month_full_name          VARCHAR2(10) NOT NULL,
    month_short_name         VARCHAR2(10) NOT NULL,
    month_number_of_year     NUMBER(10) NOT NULL,
    quarter_year             VARCHAR2(10) NOT NULL,
    quarter_number_of_year   VARCHAR2(10) NOT NULL,
    half_year_number         VARCHAR2(10) NOT NULL,
    half_year                VARCHAR2(10) NOT NULL,
    year                     VARCHAR2(10) NOT NULL
);

-- Object: bl_3nf/dwso/bl_3nf/packages/pkg_drop_tables.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
CREATE OR REPLACE PACKAGE pkg_drop 
  AUTHID CURRENT_USER AS
  PROCEDURE drop_proc ( object_name IN VARCHAR2, object_type VARCHAR2);
END pkg_drop;
/
CREATE OR REPLACE PACKAGE BODY  pkg_drop AS 
  PROCEDURE drop_proc (object_name IN VARCHAR2, object_type VARCHAR2) IS
  ex_grants exception;
  ex_inv_table_name exception;
  ex_exist_syn_name exception;
  ex_table exception;
  ex_public_synonym exception;
  ex_synonym exception;
  pragma exception_init( ex_grants, -01031 );
  pragma exception_init( ex_inv_table_name, -00903 );
  pragma exception_init( ex_exist_syn_name, -00955 );
  pragma exception_init( ex_table, -00942 );
  pragma exception_init( ex_public_synonym, -01432 );
  pragma exception_init( ex_synonym, -01434 );
	BEGIN
	  IF object_type = 'TABLE' THEN
		EXECUTE IMMEDIATE 'drop ' || object_type || ' ' || object_name || ' cascade constraints';
	  ELSE
		EXECUTE IMMEDIATE 'drop ' || object_type || ' ' || object_name;
	  END IF;
	  
	  exception
	  WHEN ex_table THEN
		   dbms_output.put_line(object_type || ' ' || object_name ||' does not exist');
		   -- insert into log_table (error_message, error_code);
	  WHEN ex_grants  THEN
		   dbms_output.put_line('User has no grants');
	  WHEN ex_inv_table_name THEN
		   dbms_output.put_line('Invalid table name');
	  WHEN ex_exist_syn_name THEN
		   dbms_output.put_line('Name is already used by an existing object');
	  WHEN ex_public_synonym THEN
		   dbms_output.put_line(object_type || ' ' || object_name ||' does not exist');
	  WHEN ex_synonym THEN
		  dbms_output.put_line(object_type || ' ' || object_name ||' does not exist');
	  WHEN others THEN
		   raise;
	END;
END pkg_drop;
/

-- Object: bl_3nf/dwso/bl_3nf/packages/pkg_grants.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
CREATE OR REPLACE PACKAGE pkg_grants
AUTHID CURRENT_USER
AS
  PROCEDURE user_grant (grant_name  IN VARCHAR2,
						            schema_name IN VARCHAR2,
                        object_name IN VARCHAR2,
                        user_name   IN VARCHAR2);
						
  PROCEDURE user_grant (grant_name IN VARCHAR2,
                        user_name  IN VARCHAR2,
                        comments   IN boolean := FALSE);
END pkg_grants;
/


CREATE OR REPLACE PACKAGE BODY pkg_grants AS
  
  PROCEDURE user_grant (grant_name  IN VARCHAR2,
                        schema_name IN VARCHAR2,
                        object_name IN VARCHAR2,
                        user_name   IN VARCHAR2) 
  IS
  BEGIN
	  EXECUTE IMMEDIATE ('GRANT ' || grant_name || ' ON ' || schema_name || '.' || object_name || ' TO ' || user_name);
  END user_grant;
  
 PROCEDURE user_grant (grant_name VARCHAR2, 
                       user_name  VARCHAR2,
                       comments   IN boolean := FALSE)
   IS
  BEGIN
      IF comments THEN
        EXECUTE IMMEDIATE ('GRANT ' || grant_name || ' TO ' || user_name || ' WITH ADMIN OPTION');
      END IF;
        EXECUTE IMMEDIATE ('GRANT ' || grant_name || ' TO ' || user_name);
  END;
END pkg_grants;
/

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_age_categories/ce_age_categories.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;

CREATE TABLE ce_age_categories
  (
    age_category_id    NUMBER(10) NOT NULL,
    age_category_srcid NUMBER(10) NOT NULL,
    age_category_desc  VARCHAR2(40 BYTE) NOT NULL,
    CONSTRAINT age_category_id_pk PRIMARY KEY ( age_category_id ),
    CONSTRAINT age_category_srcid_unq UNIQUE ( age_category_srcid )
  );

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_age_categories/ce_age_categories_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
CREATE SEQUENCE ce_age_categories_seq
 START WITH     1
 INCREMENT BY   1
 NOCACHE
 NOCYCLE;

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_bra_size_grid/ce_bra_size_grid.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;

CREATE TABLE ce_bra_size_grid
  (
    bra_size_id    NUMBER(10) NOT NULL,
    bra_size_srcid NUMBER(10) NOT NULL,
    bra_size_uk    VARCHAR2(10 BYTE),
    bra_size_usa   VARCHAR2(10 BYTE),
    bra_size_eu    VARCHAR2(10 BYTE),
    bra_size_fr    VARCHAR2(10 BYTE),
    bra_size_uie   VARCHAR2(10 BYTE),
    CONSTRAINT bra_size_id_pk PRIMARY KEY ( bra_size_id ),
    CONSTRAINT bra_size_srcid_unq UNIQUE ( bra_size_srcid )
  );

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_bra_size_grid/ce_bra_size_grid_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
CREATE SEQUENCE ce_bra_size_grid_seq
 START WITH     1
 INCREMENT BY   1
 NOCACHE
 NOCYCLE;

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_cities/ce_cities_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
CREATE SEQUENCE ce_cities_seq
 START WITH     1
 INCREMENT BY   1
 NOCACHE
 NOCYCLE;

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_collections/ce_collections.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;

CREATE TABLE ce_collections
  (
    collection_id    NUMBER ( 38 ) NOT NULL,
    collection_srcid VARCHAR2 ( 200 CHAR ) NOT NULL,
    collection_desc  VARCHAR2 ( 200 CHAR ) NOT NULL,
    update_dt        DATE DEFAULT SYSDATE,
    CONSTRAINT collection_id_pk PRIMARY KEY ( collection_id ),
    CONSTRAINT collection_srcid_unq UNIQUE ( collection_srcid )
  );

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_collections/ce_collections_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
CREATE SEQUENCE ce_collections_seq
 START WITH     1
 INCREMENT BY   1
 NOCACHE
 NOCYCLE;

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_continents/ce_continents.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;

CREATE TABLE ce_continents
  (
    continent_id    NUMBER ( 10 ) NOT NULL,
    continent_srcid NUMBER ( 10 ) NOT NULL,
    continent_desc  VARCHAR2 ( 200 CHAR ) NOT NULL,
    CONSTRAINT continent_id_pk PRIMARY KEY ( continent_id ),
    CONSTRAINT continent_srcid_unq UNIQUE ( continent_srcid )
  );

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_continents/ce_continents_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
CREATE SEQUENCE ce_continents_seq
 START WITH     1
 INCREMENT BY   1
 NOCACHE
 NOCYCLE;

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_countries/ce_countries_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
CREATE SEQUENCE ce_countries_seq
 START WITH     1
 INCREMENT BY   1
 NOCACHE
 NOCYCLE;

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_customers/ce_customers_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
CREATE SEQUENCE ce_customers_seq
 START WITH     1
 INCREMENT BY   1
 NOCACHE
 NOCYCLE;

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_employees/ce_employees_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
CREATE SEQUENCE ce_employees_seq
 START WITH     1
 INCREMENT BY   1
 NOCACHE
 NOCYCLE;

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_lines/ce_lines.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;

CREATE TABLE ce_lines
  (
    line_id          NUMBER(10) NOT NULL,
    line_srcid       VARCHAR2(50 BYTE) NOT NULL,
    line_desc        VARCHAR2(50 BYTE) NOT NULL,
    collection_srcid VARCHAR2(50 BYTE) NOT NULL,
    update_dt        DATE DEFAULT SYSDATE,
    CONSTRAINT line_id_pk PRIMARY KEY ( line_id ),
    CONSTRAINT line_srcid_unq UNIQUE ( line_srcid ),
    CONSTRAINT collection_srcid_fk FOREIGN KEY ( collection_srcid ) 
    REFERENCES ce_collections ( collection_srcid )
  );
  

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_lines/ce_lines_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
CREATE SEQUENCE ce_lines_seq
 START WITH     1
 INCREMENT BY   1
 NOCACHE
 NOCYCLE;

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_panty_size_grid/ce_panty_size_grid.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;

CREATE TABLE ce_panty_size_grid
  (
    panty_size_id    NUMBER(10) NOT NULL,
    panty_size_srcid NUMBER(10) NOT NULL,
    panty_size_uk    VARCHAR2(10 BYTE),
    panty_size_usa   VARCHAR2(10 BYTE),
    panty_size_eu    VARCHAR2(10 BYTE),
    panty_size_fr    VARCHAR2(10 BYTE),
    panty_size_uie   VARCHAR2(10 BYTE),
    CONSTRAINT panty_size_id_pk PRIMARY KEY ( panty_size_id ),
    CONSTRAINT panty_size_srcid_unq UNIQUE ( panty_size_srcid )
  );

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_panty_size_grid/ce_panty_size_grid_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
CREATE SEQUENCE ce_panty_size_grid_seq
 START WITH     1
 INCREMENT BY   1
 NOCACHE
 NOCYCLE;

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_payment_methods/ce_payment_methods.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;

CREATE TABLE ce_payment_methods
  (
    payment_method_id    NUMBER(10) NOT NULL,
    payment_method_srcid VARCHAR2(40 BYTE) NOT NULL,
    payment_method_desc  VARCHAR2(40 BYTE) NOT NULL,
    bank_desc            VARCHAR2(40 BYTE) DEFAULT '-99',
    start_dt             DATE DEFAULT '01-JAN-1990',
    end_dt               DATE DEFAULT '31-DEC-9999',
    is_active            VARCHAR2 ( 200 CHAR ) NOT NULL,
    CONSTRAINT payment_method_id_pk PRIMARY KEY ( payment_method_id ),
    CONSTRAINT payment_method_srcid_unq UNIQUE ( payment_method_srcid )
  );

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_payment_methods/ce_payment_methods_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
CREATE SEQUENCE ce_payment_methods_seq
 START WITH     1
 INCREMENT BY   1
 NOCACHE
 NOCYCLE;

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_position_grades/ce_position_grades.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;

CREATE TABLE ce_position_grades
  (
    position_grade_id    NUMBER(10) NOT NULL,
    position_grade_srcid VARCHAR2(40 BYTE) NOT NULL,
    position_grade_desc  VARCHAR2(40 BYTE) NOT NULL,
    work_experience      NUMBER(10) NOT NULL,
    CONSTRAINT position_grade_id_pk PRIMARY KEY ( position_grade_id ),
    CONSTRAINT position_grade_srcid_unq UNIQUE ( position_grade_srcid )
  );

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_position_grades/ce_position_grades_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
CREATE SEQUENCE ce_position_grades_seq
 START WITH     1
 INCREMENT BY   1
 NOCACHE
 NOCYCLE;

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_product_details/ce_product_details_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
CREATE SEQUENCE ce_product_details_seq
 START WITH     1
 INCREMENT BY   1
 NOCACHE
 NOCYCLE;

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_product_types/ce_product_types.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;

CREATE TABLE ce_product_types
  (
    product_type_id    NUMBER ( 38 ) NOT NULL,
    product_type_srcid VARCHAR2 ( 200 CHAR ) NOT NULL,
    product_type_desc  VARCHAR2 ( 200 CHAR ) NOT NULL,
    update_dt          DATE DEFAULT SYSDATE,
    CONSTRAINT product_type_id_pk PRIMARY KEY ( product_type_id ),
    CONSTRAINT product_type_srcid_unq UNIQUE ( product_type_srcid )
  );

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_product_types/ce_product_types_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
CREATE SEQUENCE ce_product_types_seq
 START WITH     1
 INCREMENT BY   1
 NOCACHE
 NOCYCLE;

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_products/ce_products.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;

CREATE TABLE ce_products
  (
    product_id         NUMBER(10) NOT NULL,
    product_srcid      VARCHAR2 ( 200 CHAR ) NOT NULL,
    product_desc       VARCHAR2(60 BYTE) NOT NULL,
    line_srcid         VARCHAR2 ( 200 CHAR ) NOT NULL,
    product_type_srcid VARCHAR2 ( 200 CHAR ) NOT NULL,
    start_dt           DATE DEFAULT '01-JAN-1990',
    end_dt             DATE DEFAULT '31-DEC-9999',
    is_active          VARCHAR2 ( 200 CHAR ) NOT NULL,
    CONSTRAINT product_id_pk PRIMARY KEY ( product_id ),
    CONSTRAINT product_srcid_unq UNIQUE ( product_srcid ),
    CONSTRAINT line_srcid_fk FOREIGN KEY ( line_srcid ) 
    REFERENCES ce_lines ( line_srcid ),
    CONSTRAINT product_type_srcid_fk FOREIGN KEY ( product_type_srcid ) 
    REFERENCES ce_product_types ( product_type_srcid )
  );

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_products/ce_products_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
CREATE SEQUENCE ce_products_seq
 START WITH     1
 INCREMENT BY   1
 NOCACHE
 NOCYCLE;

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_receipts/ce_receipts_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
CREATE SEQUENCE ce_receipts_seq
 START WITH     1
 INCREMENT BY   1
 NOCACHE
 NOCYCLE;

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_regions/ce_regions.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;

CREATE TABLE ce_regions
  (
    region_id       NUMBER(10) NOT NULL,
    region_srcid    NUMBER(10) NOT NULL,
    region_desc     VARCHAR2(50 BYTE) NOT NULL,
    continent_srcid NUMBER(10) NOT NULL,
    CONSTRAINT region_id_pk PRIMARY KEY ( region_id ),
    CONSTRAINT region_srcid_unq UNIQUE ( region_srcid ),
    CONSTRAINT continent_srcid_fk FOREIGN KEY ( continent_srcid ) 
    REFERENCES ce_continents (continent_srcid)
  ); 

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_regions/ce_regions_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
CREATE SEQUENCE ce_regions_seq
 START WITH     1
 INCREMENT BY   1
 NOCACHE
 NOCYCLE;

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_stores/ce_stores_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
CREATE SEQUENCE ce_stores_seq
 START WITH     1
 INCREMENT BY   1
 NOCACHE
 NOCYCLE;

-- Object: bl_dm/dwso/bl_dm/packages/pkg_drop_tables.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_dm;
CREATE OR REPLACE PACKAGE pkg_drop 
  AUTHID CURRENT_USER AS
  PROCEDURE drop_proc ( object_name IN VARCHAR2, object_type VARCHAR2);
END pkg_drop;
/
CREATE OR REPLACE PACKAGE BODY  pkg_drop AS 
  PROCEDURE drop_proc (object_name IN VARCHAR2, object_type VARCHAR2) IS
  ex_grants exception;
  ex_inv_table_name exception;
  ex_exist_syn_name exception;
  ex_table exception;
  ex_public_synonym exception;
  ex_synonym exception;
  pragma exception_init( ex_grants, -01031 );
  pragma exception_init( ex_inv_table_name, -00903 );
  pragma exception_init( ex_exist_syn_name, -00955 );
  pragma exception_init( ex_table, -00942 );
  pragma exception_init( ex_public_synonym, -01432 );
  pragma exception_init( ex_synonym, -01434 );
	BEGIN
	  IF object_type = 'TABLE' THEN
		EXECUTE IMMEDIATE 'drop ' || object_type || ' ' || object_name || ' cascade constraints';
	  ELSE
		EXECUTE IMMEDIATE 'drop ' || object_type || ' ' || object_name;
	  END IF;
	  
	  exception
	  WHEN ex_table THEN
		   dbms_output.put_line(object_type || ' ' || object_name ||' does not exist');
		   -- insert into log_table (error_message, error_code);
	  WHEN ex_grants  THEN
		   dbms_output.put_line('User has no grants');
	  WHEN ex_inv_table_name THEN
		   dbms_output.put_line('Invalid table name');
	  WHEN ex_exist_syn_name THEN
		   dbms_output.put_line('Name is already used by an existing object');
	  WHEN ex_public_synonym THEN
		   dbms_output.put_line(object_type || ' ' || object_name ||' does not exist');
	  WHEN ex_synonym THEN
		  dbms_output.put_line(object_type || ' ' || object_name ||' does not exist');
	  WHEN others THEN
		   raise;
	END;
END pkg_drop;
/

-- Object: bl_dm/dwso/bl_dm/packages/pkg_grants.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_dm;
CREATE OR REPLACE PACKAGE pkg_grants
AUTHID CURRENT_USER
AS
  PROCEDURE user_grant (grant_name  IN VARCHAR2,
						            schema_name IN VARCHAR2,
                        object_name IN VARCHAR2,
                        user_name   IN VARCHAR2);
						
  PROCEDURE user_grant (grant_name IN VARCHAR2,
                        user_name  IN VARCHAR2,
                        comments   IN boolean := FALSE);
END pkg_grants;
/


CREATE OR REPLACE PACKAGE BODY pkg_grants AS
  
  PROCEDURE user_grant (grant_name  IN VARCHAR2,
                        schema_name IN VARCHAR2,
                        object_name IN VARCHAR2,
                        user_name   IN VARCHAR2) 
  IS
  BEGIN
	  EXECUTE IMMEDIATE ('GRANT ' || grant_name || ' ON ' || schema_name || '.' || object_name || ' TO ' || user_name);
  END user_grant;
  
 PROCEDURE user_grant (grant_name VARCHAR2, 
                       user_name  VARCHAR2,
                       comments   IN boolean := FALSE)
   IS
  BEGIN
      IF comments THEN
        EXECUTE IMMEDIATE ('GRANT ' || grant_name || ' TO ' || user_name || ' WITH ADMIN OPTION');
      END IF;
        EXECUTE IMMEDIATE ('GRANT ' || grant_name || ' TO ' || user_name);
  END;
END pkg_grants;
/

-- Object: bl_dm/dwso/bl_dm/tables/dim_customers_scd/dim_customers_scd.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_dm;

CREATE TABLE dim_customers_scd (
    customer_surr_id   NUMBER(38) NOT NULL,
    customer_id        NUMBER(38) NOT NULL,
    first_name         VARCHAR2(100 BYTE) NOT NULL,
    last_name          VARCHAR2(100 BYTE) NOT NULL,
    age                NUMBER(38) NOT NULL,
    age_category       VARCHAR2(100 BYTE) NOT NULL,
    email              VARCHAR2(100 BYTE) NOT NULL,
    phone              VARCHAR2(100 BYTE) NOT NULL,
    address            VARCHAR2(100 BYTE) NOT NULL,
    city               VARCHAR2(100 BYTE) NOT NULL,
    country            VARCHAR2(100 BYTE) NOT NULL,
    region             VARCHAR2(100 BYTE) NOT NULL,
    start_dt           DATE DEFAULT '01-JAN-1990',
    end_dt             DATE DEFAULT '31-DEC-9999',
    is_active          VARCHAR2 ( 200 CHAR ) NOT NULL,
    CONSTRAINT customer_surr_id_pk PRIMARY KEY (customer_surr_id)
)
    PARTITION BY RANGE (start_dt) 
      SUBPARTITION BY LIST (region)
  ( PARTITION before_2017 VALUES LESS THAN (TO_DATE('1-1-2017', 'DD-MM-YYYY'))
         (SUBPARTITION America_b VALUES ('Central America', 'South America', 'Northern America'),
          SUBPARTITION Asia_b VALUES ('Central Asia', 'Western Asia', 'South-Eastern Asia', 'Eastern Asia'),
          SUBPARTITION Europe_b VALUES ('Western Europe', 'Southern Europe', 'Northern Europe', 'Eastern Europe'),
          SUBPARTITION Africa_b VALUES ('Southern Africa', 'Northern Africa', 'Eastern Africa', 'Middle Africa', 'Western Africa'),
          SUBPARTITION Australia_b VALUES ('Australia and New Zealand'),
          SUBPARTITION Other_regions_b VALUES ('Micronesia', 'Polynesia', 'Melanesia', 'Caribbean')   
),
    PARTITION year_2017 VALUES LESS THAN (TO_DATE('1-1-2018', 'DD-MM-YYYY'))
         (SUBPARTITION America_17 VALUES ('Central America', 'South America', 'Northern America'),
          SUBPARTITION Asia_17 VALUES ('Central Asia', 'Western Asia', 'South-Eastern Asia', 'Eastern Asia'),
          SUBPARTITION Europe_17 VALUES ('Western Europe', 'Southern Europe', 'Northern Europe', 'Eastern Europe'),
          SUBPARTITION Africa_17 VALUES ('Southern Africa', 'Northern Africa', 'Eastern Africa', 'Middle Africa', 'Western Africa'),
          SUBPARTITION Australia_17 VALUES ('Australia and New Zealand'),
          SUBPARTITION Other_regions_17 VALUES ('Micronesia', 'Polynesia', 'Melanesia', 'Caribbean')   
),
    PARTITION year_2018 VALUES LESS THAN (TO_DATE('1-1-2019', 'DD-MM-YYYY'))
         (SUBPARTITION America_18 VALUES ('Central America', 'South America', 'Northern America'),
          SUBPARTITION Asia_18 VALUES ('Central Asia', 'Western Asia', 'South-Eastern Asia', 'Eastern Asia'),
          SUBPARTITION Europe_18 VALUES ('Western Europe', 'Southern Europe', 'Northern Europe', 'Eastern Europe'),
          SUBPARTITION Africa_18 VALUES ('Southern Africa', 'Northern Africa', 'Eastern Africa', 'Middle Africa', 'Western Africa'),
          SUBPARTITION Australia_18 VALUES ('Australia and New Zealand'),
          SUBPARTITION Other_region_18 VALUES ('Micronesia', 'Polynesia', 'Melanesia', 'Caribbean')   
),
    PARTITION year_2019 VALUES LESS THAN (TO_DATE('1-1-2020', 'DD-MM-YYYY'))
         (SUBPARTITION America_19 VALUES ('Central America', 'South America', 'Northern America'),
          SUBPARTITION Asia_19 VALUES ('Central Asia', 'Western Asia', 'South-Eastern Asia', 'Eastern Asia'),
          SUBPARTITION Europe_19 VALUES ('Western Europe', 'Southern Europe', 'Northern Europe', 'Eastern Europe'),
          SUBPARTITION Africa_19 VALUES ('Southern Africa', 'Northern Africa', 'Eastern Africa', 'Middle Africa', 'Western Africa'),
          SUBPARTITION Australia_19 VALUES ('Australia and New Zealand'),
          SUBPARTITION Other_regions_19 VALUES ('Micronesia', 'Polynesia', 'Melanesia', 'Caribbean')   
),
    PARTITION year_2020 VALUES LESS THAN (TO_DATE('1-1-2021', 'DD-MM-YYYY'))
         (SUBPARTITION America_20 VALUES ('Central America', 'South America', 'Northern America'),
          SUBPARTITION Asia_20 VALUES ('Central Asia', 'Western Asia', 'South-Eastern Asia', 'Eastern Asia'),
          SUBPARTITION Europe_20 VALUES ('Western Europe', 'Southern Europe', 'Northern Europe', 'Eastern Europe'),
          SUBPARTITION Africa_20 VALUES ('Southern Africa', 'Northern Africa', 'Eastern Africa', 'Middle Africa', 'Western Africa'),
          SUBPARTITION Australia_20 VALUES ('Australia and New Zealand'),
          SUBPARTITION Other_regions_20 VALUES ('Micronesia', 'Polynesia', 'Melanesia', 'Caribbean')   
),
    PARTITION year_2021 VALUES LESS THAN (TO_DATE('1-1-2022', 'DD-MM-YYYY'))
         (SUBPARTITION America_21 VALUES ('Central America', 'South America', 'Northern America'),
          SUBPARTITION Asia_21 VALUES ('Central Asia', 'Western Asia', 'South-Eastern Asia', 'Eastern Asia'),
          SUBPARTITION Europe_21 VALUES ('Western Europe', 'Southern Europe', 'Northern Europe', 'Eastern Europe'),
          SUBPARTITION Africa_21 VALUES ('Southern Africa', 'Northern Africa', 'Eastern Africa', 'Middle Africa', 'Western Africa'),
          SUBPARTITION Australia_21 VALUES ('Australia and New Zealand'),
          SUBPARTITION Other_regions_21 VALUES ('Micronesia', 'Polynesia', 'Melanesia', 'Caribbean')   
),
    PARTITION year_2022 VALUES LESS THAN (TO_DATE('1-1-2023', 'DD-MM-YYYY'))
         (SUBPARTITION America_22 VALUES ('Central America', 'South America', 'Northern America'),
          SUBPARTITION Asia_22 VALUES ('Central Asia', 'Western Asia', 'South-Eastern Asia', 'Eastern Asia'),
          SUBPARTITION Europe_22 VALUES ('Western Europe', 'Southern Europe', 'Northern Europe', 'Eastern Europe'),
          SUBPARTITION Africa_22 VALUES ('Southern Africa', 'Northern Africa', 'Eastern Africa', 'Middle Africa', 'Western Africa'),
          SUBPARTITION Australia_22 VALUES ('Australia and New Zealand'),
          SUBPARTITION Other_regions_22 VALUES ('Micronesia', 'Polynesia', 'Melanesia', 'Caribbean')   
),
    PARTITION year_2023 VALUES LESS THAN (TO_DATE('1-1-2024', 'DD-MM-YYYY'))
         (SUBPARTITION America_23 VALUES ('Central America', 'South America', 'Northern America'),
          SUBPARTITION Asia_23 VALUES ('Central Asia', 'Western Asia', 'South-Eastern Asia', 'Eastern Asia'),
          SUBPARTITION Europe_23 VALUES ('Western Europe', 'Southern Europe', 'Northern Europe', 'Eastern Europe'),
          SUBPARTITION Africa_23 VALUES ('Southern Africa', 'Northern Africa', 'Eastern Africa', 'Middle Africa', 'Western Africa'),
          SUBPARTITION Australia_23 VALUES ('Australia and New Zealand'),
          SUBPARTITION Other_regions_23 VALUES ('Micronesia', 'Polynesia', 'Melanesia', 'Caribbean')   
),
    PARTITION year_2024 VALUES LESS THAN (TO_DATE('1-1-2025', 'DD-MM-YYYY'))
         (SUBPARTITION America_24 VALUES ('Central America', 'South America', 'Northern America'),
          SUBPARTITION Asia_24 VALUES ('Central Asia', 'Western Asia', 'South-Eastern Asia', 'Eastern Asia'),
          SUBPARTITION Europe_24 VALUES ('Western Europe', 'Southern Europe', 'Northern Europe', 'Eastern Europe'),
          SUBPARTITION Africa_24 VALUES ('Southern Africa', 'Northern Africa', 'Eastern Africa', 'Middle Africa', 'Western Africa'),
          SUBPARTITION Australia_24 VALUES ('Australia and New Zealand'),
          SUBPARTITION Other_regions_24 VALUES ('Micronesia', 'Polynesia', 'Melanesia', 'Caribbean')   
),
    PARTITION year_2025 VALUES LESS THAN (TO_DATE('1-1-2026', 'DD-MM-YYYY'))
         (SUBPARTITION America_25 VALUES ('Central America', 'South America', 'Northern America'),
          SUBPARTITION Asia_25 VALUES ('Central Asia', 'Western Asia', 'South-Eastern Asia', 'Eastern Asia'),
          SUBPARTITION Europe_25 VALUES ('Western Europe', 'Southern Europe', 'Northern Europe', 'Eastern Europe'),
          SUBPARTITION Africa_25 VALUES ('Southern Africa', 'Northern Africa', 'Eastern Africa', 'Middle Africa', 'Western Africa'),
          SUBPARTITION Australia_25 VALUES ('Australia and New Zealand'),
          SUBPARTITION Other_regions_25 VALUES ('Micronesia', 'Polynesia', 'Melanesia', 'Caribbean')   
),
    PARTITION after_2025 VALUES LESS THAN (MAXVALUE)
         (SUBPARTITION America_a VALUES ('Central America', 'South America', 'Northern America'),
          SUBPARTITION Asia_a VALUES ('Central Asia', 'Western Asia', 'South-Eastern Asia', 'Eastern Asia'),
          SUBPARTITION Europe_a VALUES ('Western Europe', 'Southern Europe', 'Northern Europe', 'Eastern Europe'),
          SUBPARTITION Africa_a VALUES ('Southern Africa', 'Northern Africa', 'Eastern Africa', 'Middle Africa', 'Western Africa'),
          SUBPARTITION Australia_a VALUES ('Australia and New Zealand'),
          SUBPARTITION Other_regions_a VALUES ('Micronesia', 'Polynesia', 'Melanesia', 'Caribbean')   
)
  );

-- Object: bl_dm/dwso/bl_dm/tables/dim_customers_scd/dim_customers_scd_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_dm;
CREATE SEQUENCE dim_customers_seq
 START WITH     1
 INCREMENT BY   1
 NOCACHE
 NOCYCLE;

-- Object: bl_dm/dwso/bl_dm/tables/dim_employees_scd/dim_employees_scd.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_dm;

CREATE TABLE dim_employees_scd
  (
    employee_surr_id NUMBER(38) NOT NULL,
    employee_id      NUMBER(38) NOT NULL,
    first_name       VARCHAR2(50 BYTE) NOT NULL,
    last_name        VARCHAR2(50 BYTE) NOT NULL,
    store_number     VARCHAR2(50 BYTE) NOT NULL,
    position_name    VARCHAR2(50 BYTE) NOT NULL,
    position_grade   VARCHAR2(50 BYTE) NOT NULL,
    work_experience  NUMBER(10) NOT NULL,
    email            VARCHAR2(50 BYTE) NOT NULL,
    phone            VARCHAR2(50 BYTE) NOT NULL,
    start_dt         DATE DEFAULT '01-JAN-1990',
    end_dt           DATE DEFAULT '31-DEC-9999',
    is_active        VARCHAR2 ( 200 CHAR ) NOT NULL,
    CONSTRAINT employee_surr_id_pk PRIMARY KEY (employee_surr_id)
)
    PARTITION BY LIST (position_grade)
(
    PARTITION novice VALUES ('novice'),
    PARTITION middle VALUES ('middle'),
    PARTITION experienced VALUES ('experienced'),
    PARTITION expert VALUES ('expert'))
;

-- Object: bl_dm/dwso/bl_dm/tables/dim_employees_scd/dim_employees_scd_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_dm;
CREATE SEQUENCE dim_employees_seq
 START WITH     1
 INCREMENT BY   1
 NOCACHE
 NOCYCLE;

-- Object: bl_dm/dwso/bl_dm/tables/dim_payment_methods_scd/dim_payment_methods_scd.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_dm;

CREATE TABLE dim_payment_methods_scd
  (
    payment_method_surr_id NUMBER(38) NOT NULL,
    payment_method_id      NUMBER(38) NOT NULL,
    payment_method_desc    VARCHAR2(40 BYTE) NOT NULL,
    bank_name              VARCHAR2(40 BYTE),
    start_dt               DATE DEFAULT '01-JAN-1990',
    end_dt                 DATE DEFAULT '31-DEC-9999',
    is_active              VARCHAR2 ( 200 CHAR ) NOT NULL,
    CONSTRAINT payment_method_id_pk PRIMARY KEY (payment_method_id)
  );

-- Object: bl_dm/dwso/bl_dm/tables/dim_payment_methods_scd/dim_payment_methods_scd_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_dm;
CREATE SEQUENCE dim_payment_methods_seq
 START WITH     1
 INCREMENT BY   1
 NOCACHE
 NOCYCLE;

-- Object: bl_dm/dwso/bl_dm/tables/dim_products_scd/dim_products_scd.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_dm;

CREATE TABLE dim_products_scd (
    product_surr_id     NUMBER(38) NOT NULL,
    product_id          NUMBER(38) NOT NULL,
    product_desc        VARCHAR2(100 BYTE) NOT NULL,
    line_name           VARCHAR2(100 BYTE) NOT NULL,
    collection_name     VARCHAR2(100 BYTE) NOT NULL,
    product_type        VARCHAR2(100 BYTE) NOT NULL,
    bra_size_uk         VARCHAR2(100 BYTE) DEFAULT '0',
    bra_size_usa        VARCHAR2(100 BYTE) DEFAULT '0',
    bra_size_eu         VARCHAR2(100 BYTE) DEFAULT '0',
    bra_size_fr         VARCHAR2(100 BYTE) DEFAULT '0',
    bra_size_uie        VARCHAR2(100 BYTE) DEFAULT '0',
    panties_size_uk     VARCHAR2(100 BYTE) DEFAULT '0',
    panties_size_usa    VARCHAR2(100 BYTE) DEFAULT '0',
    panties_size_eu     VARCHAR2(100 BYTE) DEFAULT '0',
    panties_size_fr     VARCHAR2(100 BYTE) DEFAULT '0',
    panties_size_uie    VARCHAR2(100 BYTE) DEFAULT '0',
    color               VARCHAR2(100 BYTE),
    price               NUMBER(38),
    start_dt            DATE DEFAULT '01-JAN-1990',
    end_dt              DATE DEFAULT '31-DEC-9999',
    is_active           VARCHAR2 ( 200 CHAR ) NOT NULL,
    CONSTRAINT product_surr_id_pk PRIMARY KEY (product_surr_id)
)
    PARTITION BY LIST (collection_name)
        SUBPARTITION BY LIST (product_type)
(
    PARTITION swimwear VALUES ('swimwear')
     (SUBPARTITION bra_s VALUES ('bra'),
      SUBPARTITION panties_s VALUES ('panty')) 
,
    PARTITION fashion VALUES ('fashion')
     (SUBPARTITION bra_f VALUES ('bra'),
      SUBPARTITION panties_f VALUES ('panty')) 
,
    PARTITION classic VALUES ('classic')
     (SUBPARTITION bra_c VALUES ('bra'),
      SUBPARTITION panties_c VALUES ('panty'))   
);

-- Object: bl_dm/dwso/bl_dm/tables/dim_products_scd/dim_products_scd_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_dm;
CREATE SEQUENCE dim_products_seq
 START WITH     1
 INCREMENT BY   1
 NOCACHE
 NOCYCLE;

-- Object: bl_dm/dwso/bl_dm/tables/dim_stores_scd/dim_stores_scd.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_dm;

CREATE TABLE dim_stores_scd
  (
    store_surr_id NUMBER(38) NOT NULL,
    store_id      NUMBER(38) NOT NULL,
    store_desc    VARCHAR2(50 BYTE) NOT NULL,
    phone         VARCHAR2(50 BYTE) NOT NULL,
    address       VARCHAR2(50 BYTE) NOT NULL,
    city          VARCHAR2(100 BYTE) NOT NULL,
    country       VARCHAR2(100 BYTE) NOT NULL,
    region        VARCHAR2(100 BYTE) NOT NULL,
    insert_dt     DATE DEFAULT '01-JAN-1990',
    update_dt     DATE DEFAULT SYSDATE,
    CONSTRAINT store_surr_id_pk PRIMARY KEY (store_surr_id)
  )
    PARTITION BY LIST (region)
  (
    PARTITION America VALUES ('Central America', 'South America', 'Northern America'),
    PARTITION Asia VALUES ('Central Asia', 'Western Asia', 'South-Eastern Asia', 'Eastern Asia'),
    PARTITION Europe VALUES ('Western Europe', 'Southern Europe', 'Northern Europe', 'Eastern Europe'),
    PARTITION Africa VALUES ('Southern Africa', 'Northern Africa', 'Eastern Africa', 'Middle Africa', 'Western Africa'),
    PARTITION Australia VALUES ('Australia and New Zealand'),
    PARTITION Other_regions VALUES ('Micronesia', 'Polynesia', 'Melanesia', 'Caribbean')   
  ) 
;

-- Object: bl_dm/dwso/bl_dm/tables/dim_stores_scd/dim_stores_scd_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_dm;
CREATE SEQUENCE dim_stores_seq
 START WITH     1
 INCREMENT BY   1
 NOCACHE
 NOCYCLE;

-- Object: bl_dm/dwso/bl_dm/tables/dim_time_day/dim_time_day.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_dm;

CREATE TABLE dim_time_day (
    date_dt                  DATE NOT NULL,
    week_day_full_name       VARCHAR2(10) NOT NULL,
    week_day_short_name      VARCHAR2(10) NOT NULL,
    day_number_of_week       NUMBER(10) NOT NULL,
    day_number_of_month      NUMBER(10) NOT NULL,
    day_number_of_year       NUMBER(10) NOT NULL,
    month_year               VARCHAR2(10) NOT NULL,
    month_full_name          VARCHAR2(10) NOT NULL,
    month_short_name         VARCHAR2(10) NOT NULL,
    month_number_of_year     NUMBER(10) NOT NULL,
    quarter_year             VARCHAR2(10) NOT NULL,
    quarter_number_of_year   VARCHAR2(10) NOT NULL,
    half_year_number         VARCHAR2(10) NOT NULL,
    half_year                VARCHAR2(10) NOT NULL,
    year                     VARCHAR2(10) NOT NULL,
    CONSTRAINT date_dt_pk PRIMARY KEY (date_dt)
);

-- Object: bl_dm/dwso/bl_dm/tables/fct_retail_sales_dd/fct_retail_sales_dd.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_dm;

CREATE TABLE fct_retail_sales_dd (
    sale_id                  NUMBER(38) NOT NULL,
    receipt_id               NUMBER(38) NOT NULL,
    event_dt                 DATE NOT NULL,
    employee_surr_id         NUMBER(38) NOT NULL,
    customer_surr_id         NUMBER(38) NOT NULL,
    store_surr_id            NUMBER(38) NOT NULL,
    payment_method_id        NUMBER(38) NOT NULL,
    product_surr_id          NUMBER(38) NOT NULL,
    tot_sale_sum             NUMBER(38) NOT NULL,
    tot_sale_amount          NUMBER(38) NOT NULL,
    insert_dt                DATE NOT NULL,
    update_dt                DATE NOT NULL,
    CONSTRAINT product_surr_id_fk FOREIGN KEY (product_surr_id)
    REFERENCES dim_products_scd (product_surr_id),
    CONSTRAINT employee_surr_id_fk FOREIGN KEY (employee_surr_id)
    REFERENCES dim_employees_scd (employee_surr_id),
    CONSTRAINT customer_surr_id_fk FOREIGN KEY (customer_surr_id)
    REFERENCES dim_customers_scd (customer_surr_id),
    CONSTRAINT payment_method_surr_id_fk FOREIGN KEY (payment_method_id)
    REFERENCES dim_payment_methods_scd (payment_method_id),
    CONSTRAINT store_id_fk FOREIGN KEY (store_surr_id)
    REFERENCES dim_stores_scd (store_surr_id),
    CONSTRAINT event_dt_fk FOREIGN KEY (event_dt)
    REFERENCES dim_time_day (date_dt)
)
    PARTITION BY RANGE (event_dt) 
  ( PARTITION before_2017 VALUES LESS THAN (TO_DATE('1-1-2017', 'DD-MM-YYYY')),
    PARTITION year_2017 VALUES LESS THAN (TO_DATE('1-1-2018', 'DD-MM-YYYY')),
    PARTITION year_2018 VALUES LESS THAN (TO_DATE('1-1-2019', 'DD-MM-YYYY')),
    PARTITION year_2019 VALUES LESS THAN (TO_DATE('1-1-2020', 'DD-MM-YYYY')),
    PARTITION year_2020 VALUES LESS THAN (TO_DATE('1-1-2021', 'DD-MM-YYYY')),
    PARTITION year_2021 VALUES LESS THAN (TO_DATE('1-1-2022', 'DD-MM-YYYY')),
    PARTITION year_2022 VALUES LESS THAN (TO_DATE('1-1-2023', 'DD-MM-YYYY')),
    PARTITION year_2023 VALUES LESS THAN (TO_DATE('1-1-2024', 'DD-MM-YYYY')),
    PARTITION year_2024 VALUES LESS THAN (TO_DATE('1-1-2025', 'DD-MM-YYYY')),
    PARTITION year_2025 VALUES LESS THAN (TO_DATE('1-1-2026', 'DD-MM-YYYY')),
    PARTITION after_2025 VALUES LESS THAN (MAXVALUE)
  );

-- Object: bl_dm/dwso/bl_dm/tables/fct_retail_sales_dd/fct_retail_sales_dd_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_dm;
CREATE SEQUENCE fct_retail_sales_dd_seq
 START WITH     1
 INCREMENT BY   1
 NOCACHE
 NOCYCLE;

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_countries/ce_countries.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;

CREATE TABLE ce_countries
  (
    country_id    NUMBER(10) NOT NULL,
    country_srcid NUMBER(10) NOT NULL,
    region_srcid  NUMBER(10) NOT NULL,
    country_desc  VARCHAR2(60 BYTE) NOT NULL,
    CONSTRAINT country_id_pk PRIMARY KEY ( country_id ),
    CONSTRAINT country_srcid_unq UNIQUE ( country_srcid ),
    CONSTRAINT region_srcid_fk FOREIGN KEY ( region_srcid ) 
    REFERENCES ce_regions ( region_srcid )
  );

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_product_details/ce_product_details.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;

CREATE TABLE ce_product_details
  (
    product_details_id    NUMBER(10) NOT NULL,
    product_details_srcid VARCHAR2 ( 200 CHAR ) NOT NULL,
    product_srcid         VARCHAR2 ( 200 CHAR ) NOT NULL,
    bra_size_srcid        NUMBER(10) DEFAULT 0,
    panty_size_srcid      NUMBER(10) DEFAULT 0,
    color                 VARCHAR2(40 BYTE) NOT NULL,
    price                 NUMBER(10,2) NOT NULL,
    product_balance       NUMBER(10) NOT NULL,
    insert_dt             DATE DEFAULT '01-JAN-1990',
    update_dt             DATE DEFAULT '31-DEC-9999',
    CONSTRAINT product_details_id_pk PRIMARY KEY ( product_details_id ),
    CONSTRAINT product_details_srcid_unq UNIQUE ( product_details_srcid ),
    CONSTRAINT product_srcid_fk FOREIGN KEY ( product_srcid ) 
    REFERENCES ce_products ( product_srcid ),
    CONSTRAINT bra_size_srcid_fk FOREIGN KEY ( bra_size_srcid ) 
    REFERENCES ce_bra_size_grid ( bra_size_srcid ),
    CONSTRAINT panty_size_srcid_fk FOREIGN KEY ( panty_size_srcid ) 
    REFERENCES ce_panty_size_grid ( panty_size_srcid )
  );

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_cities/ce_cities.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;

CREATE TABLE ce_cities
  (
    city_id       NUMBER(10) NOT NULL,
    city_srcid    VARCHAR2(100 BYTE) NOT NULL,
    country_srcid NUMBER(10) NOT NULL,
    city_desc     VARCHAR2(60 BYTE) NOT NULL,
    CONSTRAINT city_id_pk PRIMARY KEY ( city_id ),
    CONSTRAINT city_srcid_unq UNIQUE ( city_srcid ),
    CONSTRAINT country_srcid_fk FOREIGN KEY ( country_srcid ) 
    REFERENCES ce_countries ( country_srcid )
  );

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_customers/ce_customers.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;

CREATE TABLE ce_customers
  (
    customer_id        NUMBER ( 38 ) NOT NULL,
    customer_srcid     VARCHAR2 ( 200 CHAR ) NOT NULL,
    first_name         VARCHAR2 ( 200 CHAR ) NOT NULL,
    last_name          VARCHAR2 ( 200 CHAR ) NOT NULL,
    age                NUMBER ( 38 ) NOT NULL,
    age_category_srcid NUMBER ( 38 ) NOT NULL,
    email              VARCHAR2 ( 200 CHAR ) NOT NULL,
    phone              VARCHAR2 ( 200 CHAR ) NOT NULL,
    address            VARCHAR2 ( 200 CHAR ) NOT NULL,
    city_srcid         VARCHAR2 ( 200 CHAR ) NOT NULL,
    start_dt           DATE DEFAULT '01-JAN-1990',
    end_dt             DATE DEFAULT '31-DEC-9999',
    is_active          VARCHAR2 ( 200 CHAR ) NOT NULL,
    CONSTRAINT customer_id_pk PRIMARY KEY ( customer_id ),
    CONSTRAINT customer_scrid_unq UNIQUE ( customer_srcid ),
    CONSTRAINT city_srcid_fk FOREIGN KEY ( city_srcid ) 
    REFERENCES ce_cities ( city_srcid ),
    CONSTRAINT age_category_srcid_fk FOREIGN KEY ( age_category_srcid ) 
    REFERENCES ce_age_categories ( age_category_srcid )
  );

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_stores/ce_stores.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;

CREATE TABLE ce_stores
  (
    store_id       NUMBER(10) NOT NULL,
    store_srcid    VARCHAR2(100 BYTE) NOT NULL,
    store_code     VARCHAR2(100 BYTE) NOT NULL,
    store_desc     VARCHAR2(100 BYTE) NOT NULL,
    manager_number VARCHAR2(100 BYTE) NOT NULL,
    phone          VARCHAR2(100 BYTE) NOT NULL,
    address        VARCHAR2(100 BYTE) NOT NULL,
    city_srcid     VARCHAR2(100 BYTE) NOT NULL,
    insert_dt      DATE DEFAULT '01-JAN-1990',
    update_dt      DATE DEFAULT '31-DEC-9999',
    CONSTRAINT store_id_pk PRIMARY KEY ( store_id ),
    CONSTRAINT store_srcid_unq UNIQUE ( store_srcid ),
     CONSTRAINT st_city_srcid_fk FOREIGN KEY ( city_srcid ) 
    REFERENCES ce_cities ( city_srcid )
  );

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_employees/ce_employees.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;

CREATE TABLE ce_employees
  (
    employee_id          NUMBER(10) NOT NULL,
    employee_srcid       VARCHAR2(40 BYTE) NOT NULL,
    first_name           VARCHAR2(40 BYTE) NOT NULL,
    last_name            VARCHAR2(40 BYTE) NOT NULL,
    store_srcid          VARCHAR2(40 BYTE) NOT NULL,
    position_name        VARCHAR2(40 BYTE) NOT NULL,
    position_grade_srcid VARCHAR2(40 BYTE) NOT NULL,
    work_experience      NUMBER(10) NOT NULL,
    email                VARCHAR2(50 BYTE) NOT NULL,
    phone                VARCHAR2(40 BYTE) NOT NULL,
    start_dt             DATE DEFAULT '01-JAN-1990',
    end_dt               DATE DEFAULT '31-DEC-9999',
    is_active            VARCHAR2 ( 200 CHAR ) NOT NULL,
    CONSTRAINT employee_id_pk PRIMARY KEY ( employee_id ),
    CONSTRAINT employee_srcid_unq UNIQUE ( employee_srcid ),
    CONSTRAINT position_grade_srcid_fk FOREIGN KEY ( position_grade_srcid ) 
    REFERENCES ce_position_grades ( position_grade_srcid ),
    CONSTRAINT store_srcid_fk FOREIGN KEY ( store_srcid ) 
    REFERENCES ce_stores ( store_srcid )
  );

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_receipts/ce_receipts.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;

CREATE TABLE ce_receipts
  (
    receipt_id           NUMBER(38) NOT NULL,
    receipt_dt           DATE NOT NULL,
    store_id             NUMBER(38) NOT NULL,
    employee_id          NUMBER(38) NOT NULL,
    customer_id          NUMBER(38) NOT NULL,
    payment_method_id    NUMBER(38) NOT NULL,
    product_detail_id    NUMBER(38) NOT NULL,
    receipt_sum_usd      NUMBER(38,2) NOT NULL,
    insert_dt            DATE DEFAULT SYSDATE,
    CONSTRAINT rc_store_id_fk FOREIGN KEY ( store_id ) 
    REFERENCES ce_stores ( store_id ),
    CONSTRAINT rc_employee_id_fk FOREIGN KEY ( employee_id ) 
    REFERENCES ce_employees ( employee_id ),
    CONSTRAINT rc_customer_id_fk FOREIGN KEY ( customer_id ) 
    REFERENCES ce_customers ( customer_id ),
    CONSTRAINT payment_method_id_fk FOREIGN KEY ( payment_method_id ) 
    REFERENCES ce_payment_methods ( payment_method_id ),
    CONSTRAINT product_detail_id_fk FOREIGN KEY ( product_detail_id ) 
    REFERENCES ce_product_details ( product_details_id )
  );

-- Cross-schema grants: additional_grants
ALTER SESSION SET CURRENT_SCHEMA = sa_src;
BEGIN
  pkg_grants.user_grant(grant_name => 'CREATE ANY DIRECTORY', user_name => 'SA_SRC');
  pkg_grants.USER_GRANT(GRANT_NAME => 'READ ON DIRECTORY external_geo_tables', USER_NAME => 'SA_SRC');
  pkg_grants.USER_GRANT(GRANT_NAME => 'READ ON DIRECTORY external_cust_tables', USER_NAME => 'SA_SRC');
  pkg_grants.USER_GRANT(GRANT_NAME => 'READ ON DIRECTORY external_emp_tables', USER_NAME => 'SA_SRC');
  pkg_grants.USER_GRANT(GRANT_NAME => 'READ ON DIRECTORY external_ext_tables', USER_NAME => 'SA_SRC');
  pkg_grants.USER_GRANT(GRANT_NAME => 'UNLIMITED TABLESPACE', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'UNLIMITED TABLESPACE', USER_NAME => 'BL_3NF');
  pkg_grants.USER_GRANT(GRANT_NAME => 'UNLIMITED TABLESPACE', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'UNLIMITED TABLESPACE', USER_NAME => 'BL_DM');
END;
/

-- Cross-schema grants: grants_to_bl_cl_1st
ALTER SESSION SET CURRENT_SCHEMA = sa_src;
BEGIN
  pkg_grants.USER_GRANT(GRANT_NAME => 'READ, WRITE ON DIRECTORY EXTERNAL_GEO_TABLES', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'READ, WRITE ON DIRECTORY EXTERNAL_CUST_TABLES', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'READ, WRITE ON DIRECTORY EXTERNAL_EMP_TABLES', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'READ, WRITE ON DIRECTORY EXTERNAL_EXT_TABLES', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'READ, WRITE ON DIRECTORY EXTERNAL_PROD_TABLES', USER_NAME => 'BL_CL_1ST');
  pkg_grants.user_grant(grant_name => 'SELECT', schema_name => 'SA_SRC', object_name => 'EXT_COUNTRIES', user_name => 'BL_CL_1ST');
  pkg_grants.user_grant(grant_name => 'SELECT', schema_name => 'SA_SRC', object_name => 'EXT_STRUCTURES', user_name => 'BL_CL_1ST');
  pkg_grants.user_grant(grant_name => 'SELECT', schema_name => 'SA_SRC', object_name => 'EXT_FULL_DATA', user_name => 'BL_CL_1ST');
  pkg_grants.user_grant(grant_name => 'SELECT', schema_name => 'SA_SRC', object_name => 'EXT_BRA_SIZES', user_name => 'BL_CL_1ST');
  pkg_grants.user_grant(grant_name => 'SELECT', schema_name => 'SA_SRC', object_name => 'EXT_PANTY_SIZES', user_name => 'BL_CL_1ST');
  pkg_grants.user_grant(grant_name => 'SELECT', schema_name => 'SA_SRC', object_name => 'EXT_CUSTOMERS', user_name => 'BL_CL_1ST');
  pkg_grants.user_grant(grant_name => 'SELECT', schema_name => 'SA_SRC', object_name => 'EXT_EMPLOYEES', user_name => 'BL_CL_1ST');
  pkg_grants.user_grant(grant_name => 'SELECT', schema_name => 'SA_SRC', object_name => 'EXT_STORES', user_name => 'BL_CL_1ST');
  pkg_grants.user_grant(grant_name => 'SELECT', schema_name => 'SA_SRC', object_name => 'EXT_PAYMENT_METHODS', user_name => 'BL_CL_1ST');
  pkg_grants.user_grant(grant_name => 'SELECT', schema_name => 'SA_SRC', object_name => 'EXT_PRODUCTS', user_name => 'BL_CL_1ST');
END;
/

-- Cross-schema grants: bl_3nf/grant_to_bl_cl_1st.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
BEGIN
  pkg_grants.USER_GRANT(GRANT_NAME => 'INSERT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_CONTINENTS', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_CONTINENTS', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_CONTINENTS_SEQ', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'UPDATE', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_CONTINENTS', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'INSERT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_REGIONS', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_REGIONS', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_REGIONS_SEQ', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'UPDATE', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_REGIONS', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'INSERT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_COUNTRIES', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_COUNTRIES', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_COUNTRIES_SEQ', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'UPDATE', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_COUNTRIES', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'INSERT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_CITIES', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_CITIES', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_CITIES_SEQ', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'UPDATE', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_CITIES', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'INSERT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_AGE_CATEGORIES', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_AGE_CATEGORIES', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_AGE_CATEGORIES_SEQ', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'UPDATE', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_AGE_CATEGORIES', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'INSERT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_POSITION_GRADES', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_POSITION_GRADES', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_POSITION_GRADES_SEQ', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'UPDATE', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_POSITION_GRADES', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'INSERT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_BRA_SIZE_GRID', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_BRA_SIZE_GRID', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_BRA_SIZE_GRID_SEQ', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'UPDATE', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_BRA_SIZE_GRID', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'INSERT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_PANTY_SIZE_GRID', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_PANTY_SIZE_GRID', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_PANTY_SIZE_GRID_SEQ', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'UPDATE', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_PANTY_SIZE_GRID', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'INSERT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_COLLECTIONS', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_COLLECTIONS', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_COLLECTIONS_SEQ', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'UPDATE', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_COLLECTIONS', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'INSERT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_LINES', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_LINES', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_LINES_SEQ', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'UPDATE', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_LINES', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'INSERT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_PRODUCT_TYPES', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_PRODUCT_TYPES', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_PRODUCT_TYPES_SEQ', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'UPDATE', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_PRODUCT_TYPES', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'INSERT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_PRODUCTS', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_PRODUCTS', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_PRODUCTS_SEQ', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'UPDATE', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_PRODUCTS', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'INSERT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_PRODUCT_DETAILS', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_PRODUCT_DETAILS', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_PRODUCT_DETAILS_SEQ', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'UPDATE', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_PRODUCT_DETAILS', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'INSERT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_CUSTOMERS', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_CUSTOMERS', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_CUSTOMERS_SEQ', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'UPDATE', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_CUSTOMERS', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'INSERT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_STORES', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_STORES', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_STORES_SEQ', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'UPDATE', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_STORES', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'INSERT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_EMPLOYEES', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_EMPLOYEES', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_EMPLOYEES_SEQ', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'UPDATE', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_EMPLOYEES', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'INSERT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_PAYMENT_METHODS', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_PAYMENT_METHODS', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_PAYMENT_METHODS_SEQ', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'UPDATE', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_PAYMENT_METHODS', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'INSERT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_RECEIPTS', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_RECEIPTS', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_RECEIPTS_SEQ', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'UPDATE', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_RECEIPTS', USER_NAME => 'BL_CL_1ST');
END;
/
---------------------------------------------------------------------------------------------------------------------------------------

-- Cross-schema grants: bl_3nf/grant_to_bl_cl_2nd.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
BEGIN
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_CONTINENTS', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_REGIONS', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_COUNTRIES', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_CITIES', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_AGE_CATEGORIES', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_POSITION_GRADES', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_BRA_SIZE_GRID', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_PANTY_SIZE_GRID', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_COLLECTIONS', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_LINES', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_PRODUCT_TYPES', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_PRODUCTS', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_PRODUCT_DETAILS', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_CUSTOMERS', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_STORES', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_EMPLOYEES', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_PAYMENT_METHODS', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_3NF', OBJECT_NAME => 'CE_RECEIPTS', USER_NAME => 'BL_CL_2ND');
END;
/
---------------------------------------------------------------------------------------------------------------------------------------

-- Cross-schema grants: bl_dm/grant_to_bl_cl_2nd.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_dm;
BEGIN
  pkg_grants.USER_GRANT(GRANT_NAME => 'INSERT', SCHEMA_NAME => 'BL_DM', OBJECT_NAME => 'DIM_CUSTOMERS_SCD', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_DM', OBJECT_NAME => 'DIM_CUSTOMERS_SCD', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'UPDATE', SCHEMA_NAME => 'BL_DM', OBJECT_NAME => 'DIM_CUSTOMERS_SCD', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_DM', OBJECT_NAME => 'DIM_CUSTOMERS_SEQ', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_DM', OBJECT_NAME => 'DIM_EMPLOYEES_SCD', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'INSERT', SCHEMA_NAME => 'BL_DM', OBJECT_NAME => 'DIM_EMPLOYEES_SCD', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'UPDATE', SCHEMA_NAME => 'BL_DM', OBJECT_NAME => 'DIM_EMPLOYEES_SCD', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_DM', OBJECT_NAME => 'DIM_EMPLOYEES_SEQ', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'INSERT', SCHEMA_NAME => 'BL_DM', OBJECT_NAME => 'DIM_PAYMENT_METHODS_SCD', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_DM', OBJECT_NAME => 'DIM_PAYMENT_METHODS_SCD', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'UPDATE', SCHEMA_NAME => 'BL_DM', OBJECT_NAME => 'DIM_PAYMENT_METHODS_SCD', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_DM', OBJECT_NAME => 'DIM_PAYMENT_METHODS_SEQ', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'INSERT', SCHEMA_NAME => 'BL_DM', OBJECT_NAME => 'DIM_PRODUCTS_SCD', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_DM', OBJECT_NAME => 'DIM_PRODUCTS_SCD', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'UPDATE', SCHEMA_NAME => 'BL_DM', OBJECT_NAME => 'DIM_PRODUCTS_SCD', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_DM', OBJECT_NAME => 'DIM_PRODUCTS_SEQ', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'INSERT', SCHEMA_NAME => 'BL_DM', OBJECT_NAME => 'DIM_STORES_SCD', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_DM', OBJECT_NAME => 'DIM_STORES_SCD', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'UPDATE', SCHEMA_NAME => 'BL_DM', OBJECT_NAME => 'DIM_STORES_SCD', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_DM', OBJECT_NAME => 'DIM_STORES_SEQ', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'INSERT', SCHEMA_NAME => 'BL_DM', OBJECT_NAME => 'DIM_TIME_DAY', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_DM', OBJECT_NAME => 'DIM_TIME_DAY', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'UPDATE', SCHEMA_NAME => 'BL_DM', OBJECT_NAME => 'DIM_TIME_DAY', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'INSERT', SCHEMA_NAME => 'BL_DM', OBJECT_NAME => 'FCT_RETAIL_SALES_DD', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_DM', OBJECT_NAME => 'FCT_RETAIL_SALES_DD', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'UPDATE', SCHEMA_NAME => 'BL_DM', OBJECT_NAME => 'FCT_RETAIL_SALES_DD', USER_NAME => 'BL_CL_2ND');
  pkg_grants.USER_GRANT(GRANT_NAME => 'SELECT', SCHEMA_NAME => 'BL_DM', OBJECT_NAME => 'FCT_RETAIL_SALES_DD_SEQ', USER_NAME => 'BL_CL_2ND');
END;
/
---------------------------------------------------------------------------------------------------------------------------------------

-- data_mart: SALES
--------------------------------------------------------
--  File created - Saturday-December-02-2017   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Table SALES
--------------------------------------------------------

  CREATE TABLE "DATA_MART"."SALES" 
   (	"YEAR_MONTH" VARCHAR2(11 BYTE), 
	"POSITION_GRADE" VARCHAR2(50 BYTE), 
	"REGION" VARCHAR2(100 BYTE), 
	"MAX_SALES$" VARCHAR2(40 BYTE), 
	"MIN_SALES$" VARCHAR2(40 BYTE), 
	"SALES$" VARCHAR2(21 BYTE)
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS NOLOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "TBS_PDB_DWH" ;
REM INSERTING into DATA_MART.SALES
SET DEFINE OFF;
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','expert','Caribbean','99,961','144','84,698');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','expert','Melanesia','99,990','139','13,862');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','expert','Polynesia','99,908','262','23,633');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','expert','Micronesia','99,665','132','10,406');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','expert','Central Asia','99,103','434','86,279');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','expert','Eastern Asia','99,791','191','43,584');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','expert','Western Asia','99,899','191','39,275');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','expert','Middle Africa','99,934','114','36,392');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','expert','South America','99,960','141','47,183');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','expert','Eastern Africa','99,932','250','47,376');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','expert','Eastern Europe','99,878','348','26,024');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','expert','Western Africa','99,952','290','46,029');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','expert','Western Europe','99,562','454','20,127');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','expert','Central America','99,763','179','31,572');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','expert','Northern Africa','99,956','674','21,484');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','expert','Northern Europe','99,919','201','49,844');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','expert','Southern Africa','99,950','175','12,520');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','expert','Southern Europe','99,731','132','39,364');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','expert','Northern America','99,899','449','21,722');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','expert','South-Eastern Asia','99,511','109','25,596');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','expert','Australia and New Zealand','98,283','588','67,021');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','expert','Sales Total by experts','99,990','109','65,991');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','novice','Caribbean','99,967','172','88,460');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','novice','Melanesia','99,980','517','12,827');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','novice','Polynesia','99,865','205','24,996');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','novice','Micronesia','99,692','537','11,963');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','novice','Central Asia','99,459','331','89,176');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','novice','Eastern Asia','99,801','173','42,113');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','novice','Western Asia','99,835','119','38,513');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','novice','Middle Africa','99,961','486','39,283');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','novice','South America','99,942','101','50,577');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','novice','Eastern Africa','99,953','151','52,233');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','novice','Eastern Europe','99,976','530','25,489');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','novice','Western Africa','99,931','155','47,921');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','novice','Western Europe','99,750','163','23,145');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','novice','Central America','99,962','370','27,371');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','novice','Northern Africa','99,629','286','20,266');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','novice','Northern Europe','99,764','543','52,033');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','novice','Southern Africa','99,633','176','10,452');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','novice','Southern Europe','99,846','200','37,382');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','novice','Northern America','99,822','434','22,671');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','novice','South-Eastern Asia','99,629','238','23,786');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','novice','Australia and New Zealand','99,133','12,267','67,817');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','novice','Sales Total by novices','99,980','101','66,474');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2017-12','Total by employees',' ','99,990','101','13,465');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','expert','Caribbean','99,989','191','98,029');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','expert','Melanesia','99,613','273','15,627');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','expert','Polynesia','99,850','228','27,674');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','expert','Micronesia','99,977','225','13,705');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','expert','Central Asia','99,572','580','98,475');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','expert','Eastern Asia','99,954','245','47,653');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','expert','Western Asia','99,911','187','44,702');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','expert','Middle Africa','99,966','124','45,940');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','expert','South America','99,968','237','54,092');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','expert','Eastern Africa','99,896','371','60,283');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','expert','Eastern Europe','99,957','227','29,889');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','expert','Western Africa','99,806','125','57,284');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','expert','Western Europe','99,823','167','26,514');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','expert','Central America','99,994','207','30,137');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','expert','Northern Africa','99,927','224','22,881');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','expert','Northern Europe','99,992','163','61,296');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','expert','Southern Africa','99,903','352','16,057');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','expert','Southern Europe','99,981','136','45,713');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','expert','Northern America','99,946','124','23,737');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','expert','South-Eastern Asia','99,910','101','27,278');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','expert','Australia and New Zealand','98,477','456','76,221');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','expert','Sales Total by experts','99,994','101','76,187');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','novice','Caribbean','99,974','118','99,473');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','novice','Melanesia','99,564','499','14,496');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','novice','Polynesia','99,452','357','24,230');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','novice','Micronesia','99,610','665','15,068');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','novice','Central Asia','99,868','252','10,657');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','novice','Eastern Asia','99,973','118','48,050');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','novice','Western Asia','99,847','131','45,042');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','novice','Middle Africa','99,966','212','46,092');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','novice','South America','99,963','112','62,695');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','novice','Eastern Africa','99,939','192','59,853');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','novice','Eastern Europe','99,888','117','30,606');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','novice','Western Africa','99,932','129','55,750');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','novice','Western Europe','99,557','187','27,822');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','novice','Central America','99,674','111','32,804');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','novice','Northern Africa','99,909','359','24,575');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','novice','Northern Europe','99,961','122','56,630');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','novice','Southern Africa','99,835','789','15,964');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','novice','Southern Europe','99,958','217','48,219');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','novice','Northern America','99,540','11,176','25,301');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','novice','South-Eastern Asia','99,808','195','29,097');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','novice','Australia and New Zealand','99,994','21,118','65,240');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','novice','Sales Total by novices','99,994','111','77,664');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-01','Total by employees',' ','99,994','101','15,851');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','expert','Caribbean','99,990','114','88,475');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','expert','Melanesia','99,698','423','13,949');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','expert','Polynesia','99,996','106','23,556');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','expert','Micronesia','99,617','694','12,298');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','expert','Central Asia','99,611','193','10,924');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','expert','Eastern Asia','99,864','341','43,923');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','expert','Western Asia','99,957','196','43,769');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','expert','Middle Africa','99,868','211','38,334');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','expert','South America','99,931','407','52,978');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','expert','Eastern Africa','99,996','159','53,424');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','expert','Eastern Europe','99,437','151','26,021');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','expert','Western Africa','99,850','141','53,572');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','expert','Western Europe','99,868','432','23,662');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','expert','Central America','99,845','112','29,678');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','expert','Northern Africa','99,714','145','20,854');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','expert','Northern Europe','99,964','106','50,701');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','expert','Southern Africa','99,909','139','13,630');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','expert','Southern Europe','99,985','181','43,595');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','expert','Northern America','99,815','140','23,876');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','expert','South-Eastern Asia','99,935','155','26,519');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','expert','Australia and New Zealand','99,352','10,058','75,548');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','expert','Sales Total by experts','99,996','106','69,286');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','novice','Caribbean','99,850','139','91,565');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','novice','Melanesia','99,583','272','13,318');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','novice','Polynesia','99,419','362','23,380');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','novice','Micronesia','99,789','813','14,208');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','novice','Central Asia','99,828','282','99,366');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','novice','Eastern Asia','99,717','205','46,098');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','novice','Western Asia','99,949','112','41,750');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','novice','Middle Africa','99,911','107','42,273');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','novice','South America','99,915','182','55,343');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','novice','Eastern Africa','99,889','137','54,116');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','novice','Eastern Europe','99,770','103','24,690');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','novice','Western Africa','99,996','102','53,210');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','novice','Western Europe','99,875','203','25,338');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','novice','Central America','99,805','167','28,380');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','novice','Northern Africa','97,546','282','20,114');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','novice','Northern Europe','99,900','415','52,402');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','novice','Southern Africa','99,440','516','13,498');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','novice','Southern Europe','99,999','142','43,056');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','novice','Northern America','99,871','311','20,053');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','novice','South-Eastern Asia','99,948','104','25,901');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','novice','Australia and New Zealand','99,539','39,950','66,405');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','novice','Sales Total by novices','99,999','102','70,464');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-02','Total by employees',' ','99,999','102','14,750');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','expert','Caribbean','99,923','203','10,313');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','expert','Melanesia','99,989','487','15,941');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','expert','Polynesia','99,967','126','23,037');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','expert','Micronesia','99,831','567','15,811');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','expert','Central Asia','99,524','219','94,781');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','expert','Eastern Asia','99,887','271','49,617');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','expert','Western Asia','99,906','207','44,306');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','expert','Middle Africa','99,893','112','45,346');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','expert','South America','99,671','408','59,668');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','expert','Eastern Africa','99,997','186','61,154');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','expert','Eastern Europe','99,830','185','31,563');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','expert','Western Africa','99,970','360','54,832');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','expert','Western Europe','99,760','117','24,560');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','expert','Central America','99,332','194','32,165');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','expert','Northern Africa','99,819','119','22,131');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','expert','Northern Europe','99,813','122','56,204');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','expert','Southern Africa','99,840','204','14,194');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','expert','Southern Europe','99,737','114','49,537');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','expert','Northern America','99,825','217','22,173');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','expert','South-Eastern Asia','99,896','193','29,261');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','expert','Australia and New Zealand','99,094','796','70,271');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','expert','Sales Total by experts','99,997','112','77,865');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','novice','Caribbean','99,887','173','99,964');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','novice','Melanesia','99,956','309','15,838');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','novice','Polynesia','99,969','221','27,928');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','novice','Micronesia','99,587','343','14,827');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','novice','Central Asia','99,782','383','98,311');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','novice','Eastern Asia','99,933','144','53,917');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','novice','Western Asia','99,754','239','43,927');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','novice','Middle Africa','99,871','183','44,867');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','novice','South America','99,837','107','61,345');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','novice','Eastern Africa','99,955','108','60,316');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','novice','Eastern Europe','99,632','184','27,183');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','novice','Western Africa','99,983','109','60,733');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','novice','Western Europe','99,983','362','27,966');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','novice','Central America','99,970','323','32,568');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','novice','Northern Africa','99,421','224','22,757');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','novice','Northern Europe','99,923','114','59,287');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','novice','Southern Africa','98,465','388','15,998');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','novice','Southern Europe','99,891','144','45,742');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','novice','Northern America','99,751','263','25,228');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','novice','South-Eastern Asia','99,844','135','30,941');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','novice','Australia and New Zealand','99,804','549','75,322');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','novice','Sales Total by novices','99,983','107','78,965');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-03','Total by employees',' ','99,997','107','15,830');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','expert','Caribbean','99,954','105','93,019');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','expert','Melanesia','98,784','102','13,541');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','expert','Polynesia','99,709','319','26,609');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','expert','Micronesia','99,925','397','13,870');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','expert','Central Asia','99,727','204','10,637');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','expert','Eastern Asia','99,861','205','48,359');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','expert','Western Asia','99,932','109','45,015');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','expert','Middle Africa','99,928','281','45,787');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','expert','South America','99,853','404','53,096');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','expert','Eastern Africa','99,980','327','53,205');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','expert','Eastern Europe','99,996','268','25,731');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','expert','Western Africa','99,987','167','56,404');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','expert','Western Europe','99,821','360','22,475');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','expert','Central America','99,970','387','31,508');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','expert','Northern Africa','99,531','442','23,003');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','expert','Northern Europe','99,983','157','55,170');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','expert','Southern Africa','99,925','780','13,907');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','expert','Southern Europe','99,988','403','48,741');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','expert','Northern America','99,522','127','22,190');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','expert','South-Eastern Asia','99,779','211','27,985');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','expert','Australia and New Zealand','98,271','24,445','68,776');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','expert','Sales Total by experts','99,996','102','73,028');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','novice','Caribbean','99,960','157','94,371');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','novice','Melanesia','99,837','30,004','16,284');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','novice','Polynesia','99,662','674','27,851');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','novice','Micronesia','99,830','187','13,281');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','novice','Central Asia','99,018','21,109','86,310');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','novice','Eastern Asia','99,893','121','48,274');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','novice','Western Asia','99,800','120','45,461');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','novice','Middle Africa','99,712','222','46,709');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','novice','South America','99,652','154','56,229');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','novice','Eastern Africa','99,907','105','56,272');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','novice','Eastern Europe','99,917','252','27,819');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','novice','Western Africa','99,811','311','55,439');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','novice','Western Europe','99,919','129','23,771');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','novice','Central America','99,930','248','31,774');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','novice','Northern Africa','99,994','318','21,535');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','novice','Northern Europe','99,888','153','59,065');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','novice','Southern Africa','99,994','711','14,716');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','novice','Southern Europe','99,791','152','45,636');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','novice','Northern America','99,763','430','23,680');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','novice','South-Eastern Asia','99,919','189','28,626');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','novice','Australia and New Zealand','99,308','648','70,048');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','novice','Sales Total by novices','99,994','105','74,151');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-04','Total by employees',' ','99,996','102','14,179');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','expert','Caribbean','99,959','130','94,181');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','expert','Melanesia','99,537','11,100','14,415');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','expert','Polynesia','99,549','151','25,198');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','expert','Micronesia','99,704','334','13,744');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','expert','Central Asia','99,863','116','96,639');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','expert','Eastern Asia','99,879','117','49,859');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','expert','Western Asia','99,931','162','42,992');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','expert','Middle Africa','99,960','439','44,377');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','expert','South America','99,663','171','54,615');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','expert','Eastern Africa','99,982','211','58,126');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','expert','Eastern Europe','99,696','342','30,319');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','expert','Western Africa','99,916','147','58,526');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','expert','Western Europe','99,313','126','26,415');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','expert','Central America','99,837','168','30,773');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','expert','Northern Africa','99,770','147','22,828');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','expert','Northern Europe','99,935','175','61,456');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','expert','Southern Africa','99,775','767','14,700');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','expert','Southern Europe','99,933','166','44,871');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','expert','Northern America','99,669','186','22,927');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','expert','South-Eastern Asia','99,689','110','27,541');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','expert','Australia and New Zealand','99,962','528','82,078');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','expert','Sales Total by experts','99,982','110','75,580');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','novice','Caribbean','99,926','163','10,745');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','novice','Melanesia','99,846','991','14,568');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','novice','Polynesia','99,794','126','26,034');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','novice','Micronesia','99,708','175','13,589');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','novice','Central Asia','99,948','511','99,529');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','novice','Eastern Asia','99,995','198','46,445');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','novice','Western Asia','99,956','150','46,264');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','novice','Middle Africa','99,996','143','47,865');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','novice','South America','99,962','261','59,920');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','novice','Eastern Africa','99,932','151','58,716');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','novice','Eastern Europe','99,932','177','32,484');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','novice','Western Africa','99,924','176','55,177');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','novice','Western Europe','99,767','452','25,744');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','novice','Central America','99,987','150','33,382');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','novice','Northern Africa','99,996','396','24,734');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','novice','Northern Europe','99,984','107','60,003');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','novice','Southern Africa','99,857','859','13,292');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','novice','Southern Europe','99,917','263','49,681');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','novice','Northern America','99,762','186','24,693');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','novice','South-Eastern Asia','99,932','188','29,821');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','novice','Australia and New Zealand','99,840','458','79,082');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','novice','Sales Total by novices','99,996','107','78,768');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-05','Total by employees',' ','99,996','107','15,348');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','expert','Caribbean','99,959','183','93,120');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','expert','Melanesia','99,917','504','14,457');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','expert','Polynesia','99,814','212','23,324');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','expert','Micronesia','99,696','127','12,583');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','expert','Central Asia','99,919','967','84,975');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','expert','Eastern Asia','99,885','277','50,733');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','expert','Western Asia','99,984','181','45,303');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','expert','Middle Africa','99,978','263','45,325');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','expert','South America','99,975','317','55,078');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','expert','Eastern Africa','99,704','241','61,052');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','expert','Eastern Europe','99,957','290','29,058');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','expert','Western Africa','99,925','118','59,686');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','expert','Western Europe','99,516','166','25,453');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','expert','Central America','99,996','683','30,311');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','expert','Northern Africa','99,983','326','21,707');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','expert','Northern Europe','99,956','115','55,088');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','expert','Southern Africa','99,938','514','13,833');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','expert','Southern Europe','99,945','203','47,177');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','expert','Northern America','99,943','297','26,272');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','expert','South-Eastern Asia','99,699','341','28,983');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','expert','Australia and New Zealand','98,975','19,906','73,142');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','expert','Sales Total by experts','99,996','115','75,660');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','novice','Caribbean','99,995','145','95,083');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','novice','Melanesia','99,451','374','14,427');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','novice','Polynesia','99,815','177','26,429');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','novice','Micronesia','99,687','336','15,313');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','novice','Central Asia','99,547','14,445','78,111');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','novice','Eastern Asia','99,959','324','48,493');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','novice','Western Asia','99,757','131','43,366');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','novice','Middle Africa','99,968','254','46,194');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','novice','South America','99,991','149','53,737');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','novice','Eastern Africa','99,991','171','54,110');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','novice','Eastern Europe','99,915','911','27,633');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','novice','Western Africa','99,957','122','55,041');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','novice','Western Europe','99,846','160','22,599');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','novice','Central America','99,993','281','32,998');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','novice','Northern Africa','99,282','488','23,745');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','novice','Northern Europe','99,795','147','57,110');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','novice','Southern Africa','99,943','10,086','13,549');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','novice','Southern Europe','99,890','213','43,108');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','novice','Northern America','99,942','122','22,386');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','novice','South-Eastern Asia','99,705','726','27,734');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','novice','Australia and New Zealand','98,614','585','75,743');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','novice','Sales Total by novices','99,995','122','74,909');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-06','Total by employees',' ','99,996','115','15,569');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','expert','Caribbean','99,898','103','96,240');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','expert','Melanesia','99,762','396','14,215');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','expert','Polynesia','99,941','118','25,732');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','expert','Micronesia','99,683','116','14,951');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','expert','Central Asia','99,776','482','10,787');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','expert','Eastern Asia','99,793','238','50,587');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','expert','Western Asia','99,975','130','46,732');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','expert','Middle Africa','99,883','155','47,350');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','expert','South America','99,821','436','57,737');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','expert','Eastern Africa','99,853','208','62,949');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','expert','Eastern Europe','99,963','110','27,215');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','expert','Western Africa','99,925','166','55,770');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','expert','Western Europe','99,854','244','28,781');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','expert','Central America','99,761','468','31,717');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','expert','Northern Africa','99,510','296','24,946');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','expert','Northern Europe','99,884','283','61,141');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','expert','Southern Africa','99,952','548','14,961');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','expert','Southern Europe','99,719','356','46,280');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','expert','Northern America','99,503','134','23,094');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','expert','South-Eastern Asia','99,978','238','27,210');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','expert','Australia and New Zealand','99,987','101','72,318');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','expert','Sales Total by experts','99,987','101','77,713');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','novice','Caribbean','99,994','104','98,560');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','novice','Melanesia','99,875','112','15,109');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','novice','Polynesia','99,776','349','25,895');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','novice','Micronesia','99,790','116','13,272');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','novice','Central Asia','99,867','656','98,920');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','novice','Eastern Asia','99,919','468','51,352');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','novice','Western Asia','99,900','349','46,701');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','novice','Middle Africa','99,819','212','44,225');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','novice','South America','99,837','167','56,065');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','novice','Eastern Africa','99,966','147','57,738');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','novice','Eastern Europe','99,995','100','29,361');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','novice','Western Africa','99,879','276','61,672');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','novice','Western Europe','99,914','143','25,356');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','novice','Central America','99,932','177','31,239');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','novice','Northern Africa','99,983','253','27,368');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','novice','Northern Europe','99,875','168','62,698');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','novice','Southern Africa','99,887','181','13,978');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','novice','Southern Europe','99,997','169','48,571');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','novice','Northern America','99,701','411','24,184');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','novice','South-Eastern Asia','99,959','362','29,441');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','novice','Australia and New Zealand','99,750','14,436','83,711');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','novice','Sales Total by novices','99,997','100','78,416');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-07','Total by employees',' ','99,997','100','15,129');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','expert','Caribbean','99,923','174','95,431');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','expert','Melanesia','99,997','930','13,567');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','expert','Polynesia','99,869','386','26,605');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','expert','Micronesia','99,864','256','12,040');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','expert','Central Asia','99,594','427','89,325');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','expert','Eastern Asia','99,847','117','49,164');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','expert','Western Asia','99,936','131','46,724');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','expert','Middle Africa','99,950','107','47,463');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','expert','South America','99,996','243','55,604');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','expert','Eastern Africa','99,989','312','58,789');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','expert','Eastern Europe','99,860','322','29,021');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','expert','Western Africa','99,786','238','56,606');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','expert','Western Europe','99,942','146','24,651');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','expert','Central America','99,956','209','35,151');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','expert','Northern Africa','99,930','288','25,651');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','expert','Northern Europe','99,913','112','58,156');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','expert','Southern Africa','99,874','11,161','13,007');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','expert','Southern Europe','99,984','154','47,269');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','expert','Northern America','99,805','447','23,287');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','expert','South-Eastern Asia','99,877','461','29,488');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','expert','Australia and New Zealand','99,520','281','70,265');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','expert','Sales Total by experts','99,997','107','76,264');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','novice','Caribbean','99,997','129','10,304');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','novice','Melanesia','99,541','973','13,152');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','novice','Polynesia','99,893','241','27,159');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','novice','Micronesia','99,813','112','15,190');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','novice','Central Asia','99,156','186','11,423');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','novice','Eastern Asia','99,990','148','53,986');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','novice','Western Asia','99,929','591','45,675');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','novice','Middle Africa','99,937','101','46,327');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','novice','South America','99,949','168','60,949');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','novice','Eastern Africa','99,887','218','57,964');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','novice','Eastern Europe','99,957','180','30,779');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','novice','Western Africa','99,995','114','56,247');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','novice','Western Europe','99,969','796','26,851');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','novice','Central America','99,808','234','31,366');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','novice','Northern Africa','99,778','471','24,695');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','novice','Northern Europe','99,960','205','56,170');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','novice','Southern Africa','99,535','131','14,129');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','novice','Southern Europe','99,958','198','49,372');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','novice','Northern America','99,870','167','23,046');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','novice','South-Eastern Asia','99,862','348','28,827');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','novice','Australia and New Zealand','99,577','15,524','80,109');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','novice','Sales Total by novices','99,997','101','78,720');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-08','Total by employees',' ','99,997','101','15,984');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','expert','Caribbean','99,915','127','93,216');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','expert','Melanesia','99,801','235','13,955');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','expert','Polynesia','99,927','294','25,808');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','expert','Micronesia','99,746','227','14,824');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','expert','Central Asia','99,965','864','10,101');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','expert','Eastern Asia','99,875','330','47,255');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','expert','Western Asia','99,777','206','41,716');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','expert','Middle Africa','99,921','307','45,113');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','expert','South America','99,894','215','56,166');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','expert','Eastern Africa','99,959','174','57,345');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','expert','Eastern Europe','99,884','197','26,824');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','expert','Western Africa','99,888','198','55,945');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','expert','Western Europe','99,749','225','24,855');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','expert','Central America','99,518','178','31,371');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','expert','Northern Africa','99,931','138','24,080');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','expert','Northern Europe','99,976','176','57,236');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','expert','Southern Africa','99,967','514','12,007');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','expert','Southern Europe','99,783','142','45,580');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','expert','Northern America','99,478','609','22,405');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','expert','South-Eastern Asia','99,783','367','26,085');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','expert','Australia and New Zealand','99,893','217','76,408');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','expert','Sales Total by experts','99,976','127','74,295');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','novice','Caribbean','99,946','176','95,197');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','novice','Melanesia','99,867','10,086','13,530');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','novice','Polynesia','99,766','313','26,628');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','novice','Micronesia','99,936','580','15,202');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','novice','Central Asia','99,775','13,315','97,099');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','novice','Eastern Asia','99,907','310','49,292');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','novice','Western Asia','99,940','290','45,802');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','novice','Middle Africa','99,795','166','43,605');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','novice','South America','99,996','125','56,335');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','novice','Eastern Africa','99,958','289','53,288');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','novice','Eastern Europe','99,854','212','27,151');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','novice','Western Africa','99,708','103','58,796');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','novice','Western Europe','99,912','103','25,862');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','novice','Central America','99,970','105','30,809');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','novice','Northern Africa','99,947','308','24,890');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','novice','Northern Europe','99,879','187','58,389');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','novice','Southern Africa','99,929','217','13,949');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','novice','Southern Europe','99,942','232','45,325');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','novice','Northern America','99,958','119','21,700');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','novice','South-Eastern Asia','99,855','367','27,283');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','novice','Australia and New Zealand','99,858','558','78,873');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','novice','Sales Total by novices','99,996','103','75,005');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-09','Total by employees',' ','99,996','103','14,300');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','expert','Caribbean','99,970','114','97,367');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','expert','Melanesia','99,674','279','15,259');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','expert','Polynesia','99,804','131','27,253');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','expert','Micronesia','99,864','362','14,692');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','expert','Central Asia','99,907','690','89,339');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','expert','Eastern Asia','99,857','123','51,574');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','expert','Western Asia','99,958','108','47,799');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','expert','Middle Africa','99,862','124','45,980');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','expert','South America','99,957','109','55,798');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','expert','Eastern Africa','99,963','312','58,359');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','expert','Eastern Europe','99,460','103','28,218');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','expert','Western Africa','99,995','110','60,527');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','expert','Western Europe','99,697','254','25,739');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','expert','Central America','99,871','537','32,830');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','expert','Northern Africa','99,916','107','25,802');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','expert','Northern Europe','99,909','141','58,928');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','expert','Southern Africa','99,511','757','15,756');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','expert','Southern Europe','99,906','182','46,198');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','expert','Northern America','99,441','697','23,224');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','expert','South-Eastern Asia','99,907','129','29,710');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','expert','Australia and New Zealand','99,947','179','80,120');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','expert','Sales Total by experts','99,995','103','77,472');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','novice','Caribbean','99,934','103','97,533');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','novice','Melanesia','99,844','296','14,045');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','novice','Polynesia','99,908','298','26,934');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','novice','Micronesia','99,918','335','14,097');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','novice','Central Asia','99,986','493','10,519');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','novice','Eastern Asia','99,986','114','50,696');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','novice','Western Asia','99,756','139','44,437');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','novice','Middle Africa','99,993','621','46,996');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','novice','South America','99,979','109','58,568');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','novice','Eastern Africa','99,951','289','59,075');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','novice','Eastern Europe','99,583','199','30,278');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','novice','Western Africa','99,948','101','55,722');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','novice','Western Europe','99,984','281','26,334');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','novice','Central America','99,773','129','29,998');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','novice','Northern Africa','99,688','190','23,068');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','novice','Northern Europe','99,996','111','58,622');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','novice','Southern Africa','99,992','128','13,279');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','novice','Southern Europe','99,724','286','47,686');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','novice','Northern America','99,717','180','23,031');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','novice','South-Eastern Asia','99,536','184','31,584');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','novice','Australia and New Zealand','99,982','253','72,722');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','novice','Sales Total by novices','99,996','101','77,224');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-10','Total by employees',' ','99,996','101','15,696');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','expert','Caribbean','99,948','194','96,680');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','expert','Melanesia','99,549','356','15,590');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','expert','Polynesia','99,906','336','25,447');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','expert','Micronesia','99,064','683','12,256');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','expert','Central Asia','99,323','837','96,505');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','expert','Eastern Asia','99,964','153','50,411');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','expert','Western Asia','99,874','160','41,249');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','expert','Middle Africa','99,974','152','44,713');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','expert','South America','99,943','112','54,836');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','expert','Eastern Africa','99,889','132','56,711');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','expert','Eastern Europe','99,979','150','28,974');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','expert','Western Africa','99,932','183','56,991');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','expert','Western Europe','99,977','136','24,259');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','expert','Central America','99,745','218','31,687');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','expert','Northern Africa','99,779','296','21,182');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','expert','Northern Europe','99,971','152','57,631');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','expert','Southern Africa','99,378','116','13,643');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','expert','Southern Europe','99,626','107','47,189');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','expert','Northern America','99,461','327','22,432');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','expert','South-Eastern Asia','99,862','236','27,123');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','expert','Australia and New Zealand','99,504','966','75,561');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','expert','Sales Total by experts','99,979','107','74,070');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','novice','Caribbean','99,993','115','96,603');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','novice','Melanesia','99,866','162','15,956');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','novice','Polynesia','99,253','140','27,458');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','novice','Micronesia','99,393','235','13,082');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','novice','Central Asia','99,867','158','11,108');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','novice','Eastern Asia','99,943','154','48,249');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','novice','Western Asia','99,854','234','46,115');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','novice','Middle Africa','99,998','191','42,945');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','novice','South America','99,930','117','56,945');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','novice','Eastern Africa','99,807','469','59,269');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','novice','Eastern Europe','99,884','120','28,590');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','novice','Western Africa','99,898','189','59,910');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','novice','Western Europe','99,859','248','26,767');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','novice','Central America','99,814','310','31,569');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','novice','Northern Africa','99,879','261','25,503');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','novice','Northern Europe','99,962','376','57,399');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','novice','Southern Africa','98,813','507','14,897');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','novice','Southern Europe','99,903','106','48,141');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','novice','Northern America','99,971','139','23,588');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','novice','South-Eastern Asia','99,660','219','27,049');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','novice','Australia and New Zealand','99,910','304','76,031');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','novice','Sales Total by novices','99,998','106','77,174');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-11','Total by employees',' ','99,998','106','15,244');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','expert','Caribbean','99,906','146','96,303');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','expert','Melanesia','99,829','103','12,513');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','expert','Polynesia','99,914','537','27,497');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','expert','Micronesia','99,765','389','12,628');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','expert','Central Asia','98,730','11,116','80,577');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','expert','Eastern Asia','99,955','131','52,487');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','expert','Western Asia','99,690','303','43,712');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','expert','Middle Africa','99,741','153','44,021');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','expert','South America','99,944','104','59,882');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','expert','Eastern Africa','99,980','113','57,979');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','expert','Eastern Europe','99,870','275','29,456');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','expert','Western Africa','99,994','112','54,295');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','expert','Western Europe','99,879','146','25,026');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','expert','Central America','99,922','438','31,096');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','expert','Northern Africa','99,983','267','22,349');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','expert','Northern Europe','99,869','116','57,224');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','expert','Southern Africa','98,943','230','13,324');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','expert','Southern Europe','99,985','181','49,818');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','expert','Northern America','99,640','228','22,435');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','expert','South-Eastern Asia','99,866','117','30,104');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','expert','Australia and New Zealand','98,999','100','68,205');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','expert','Sales Total by experts','99,994','100','76,931');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','novice','Caribbean','99,941','136','95,412');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','novice','Melanesia','99,926','375','15,928');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','novice','Polynesia','99,782','560','27,783');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','novice','Micronesia','99,947','160','12,123');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','novice','Central Asia','99,724','601','92,602');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','novice','Eastern Asia','99,966','184','51,083');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','novice','Western Asia','99,944','110','46,717');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','novice','Middle Africa','99,465','179','45,088');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','novice','South America','99,968','178','60,956');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','novice','Eastern Africa','99,977','159','60,819');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','novice','Eastern Europe','99,799','277','29,434');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','novice','Western Africa','99,981','236','61,502');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','novice','Western Europe','99,916','163','26,104');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','novice','Central America','99,814','761','31,579');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','novice','Northern Africa','99,020','299','23,666');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','novice','Northern Europe','99,990','127','60,475');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','novice','Southern Africa','99,548','105','14,970');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','novice','Southern Europe','99,937','136','48,584');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','novice','Northern America','99,951','129','25,186');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','novice','South-Eastern Asia','99,954','205','29,477');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','novice','Australia and New Zealand','99,834','464','69,807');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','novice','Sales Total by novices','99,990','105','78,295');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2018-12','Total by employees',' ','99,994','100','15,226');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','expert','Caribbean','99,883','124','97,764');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','expert','Melanesia','99,837','571','13,129');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','expert','Polynesia','99,809','161','25,059');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','expert','Micronesia','99,980','487','13,606');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','expert','Central Asia','97,040','792','96,676');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','expert','Eastern Asia','99,950','125','47,291');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','expert','Western Asia','99,977','238','45,274');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','expert','Middle Africa','99,893','198','42,437');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','expert','South America','99,993','111','57,380');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','expert','Eastern Africa','99,728','231','58,914');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','expert','Eastern Europe','99,814','443','31,508');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','expert','Western Africa','99,935','174','59,506');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','expert','Western Europe','99,912','323','25,725');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','expert','Central America','99,974','102','33,845');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','expert','Northern Africa','99,699','242','23,581');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','expert','Northern Europe','99,845','127','58,308');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','expert','Southern Africa','99,998','398','16,232');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','expert','Southern Europe','99,972','126','45,864');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','expert','Northern America','99,602','243','23,536');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','expert','South-Eastern Asia','99,813','191','31,710');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','expert','Australia and New Zealand','96,579','662','70,495');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','expert','Sales Total by experts','99,998','102','76,840');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','novice','Caribbean','99,991','113','99,196');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','novice','Melanesia','99,962','445','14,610');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','novice','Polynesia','99,863','128','23,576');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','novice','Micronesia','99,800','267','14,083');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','novice','Central Asia','99,152','671','10,442');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','novice','Eastern Asia','99,898','126','54,980');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','novice','Western Asia','99,995','125','45,108');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','novice','Middle Africa','99,987','515','47,023');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','novice','South America','99,920','105','54,923');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','novice','Eastern Africa','99,994','258','60,186');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','novice','Eastern Europe','99,878','223','27,645');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','novice','Western Africa','99,909','126','61,993');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','novice','Western Europe','99,992','123','27,935');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','novice','Central America','99,463','415','33,456');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','novice','Northern Africa','99,480','151','24,188');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','novice','Northern Europe','99,931','320','58,554');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','novice','Southern Africa','99,743','255','13,074');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','novice','Southern Europe','99,922','256','47,288');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','novice','Northern America','99,964','350','23,892');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','novice','South-Eastern Asia','99,968','279','30,190');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','novice','Australia and New Zealand','99,885','281','86,633');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','novice','Sales Total by novices','99,995','105','78,975');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-01','Total by employees',' ','99,998','102','15,815');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','expert','Caribbean','99,994','117','91,778');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','expert','Melanesia','99,751','355','11,092');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','expert','Polynesia','99,888','144','23,737');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','expert','Micronesia','98,872','219','12,357');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','expert','Central Asia','99,995','412','10,756');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','expert','Eastern Asia','99,996','186','46,143');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','expert','Western Asia','99,959','239','41,129');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','expert','Middle Africa','99,993','237','40,931');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','expert','South America','99,967','104','52,969');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','expert','Eastern Africa','99,906','163','54,034');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','expert','Eastern Europe','99,612','435','27,158');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','expert','Western Africa','99,917','226','50,008');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','expert','Western Europe','99,917','124','24,896');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','expert','Central America','99,774','144','28,564');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','expert','Northern Africa','99,743','729','18,065');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','expert','Northern Europe','99,929','229','56,612');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','expert','Southern Africa','99,414','508','13,597');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','expert','Southern Europe','99,506','235','40,181');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','expert','Northern America','99,951','138','19,854');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','expert','South-Eastern Asia','99,968','243','25,226');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','expert','Australia and New Zealand','99,553','752','57,270');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','expert','Sales Total by experts','99,996','104','69,357');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','novice','Caribbean','99,972','102','91,871');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','novice','Melanesia','99,478','294','11,369');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','novice','Polynesia','99,998','102','23,925');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','novice','Micronesia','99,778','256','12,407');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','novice','Central Asia','99,838','168','98,757');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','novice','Eastern Asia','99,901','155','46,307');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','novice','Western Asia','99,836','488','43,633');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','novice','Middle Africa','99,989','107','41,956');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','novice','South America','99,868','117','53,908');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','novice','Eastern Africa','99,883','197','50,839');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','novice','Eastern Europe','99,997','655','27,414');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','novice','Western Africa','99,928','358','54,735');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','novice','Western Europe','98,533','371','23,338');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','novice','Central America','99,923','119','29,591');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','novice','Northern Africa','99,746','133','19,689');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','novice','Northern Europe','99,953','126','55,386');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','novice','Southern Africa','99,684','696','14,544');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','novice','Southern Europe','99,978','205','40,231');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','novice','Northern America','99,976','181','22,022');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','novice','South-Eastern Asia','99,547','256','25,574');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','novice','Australia and New Zealand','96,584','13,389','72,404');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','novice','Sales Total by novices','99,998','102','70,900');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-02','Total by employees',' ','99,998','102','14,257');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','expert','Caribbean','99,991','304','10,774');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','expert','Melanesia','99,438','307','14,679');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','expert','Polynesia','99,475','294','27,126');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','expert','Micronesia','99,861','712','12,101');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','expert','Central Asia','99,856','824','10,113');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','expert','Eastern Asia','99,957','277','51,959');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','expert','Western Asia','99,515','465','46,707');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','expert','Middle Africa','99,800','104','46,366');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','expert','South America','99,969','201','60,285');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','expert','Eastern Africa','99,930','172','62,361');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','expert','Eastern Europe','99,997','301','29,292');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','expert','Western Africa','99,921','106','56,324');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','expert','Western Europe','99,714','111','24,416');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','expert','Central America','99,999','182','28,185');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','expert','Northern Africa','99,873','280','22,996');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','expert','Northern Europe','99,997','103','58,402');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','expert','Southern Africa','99,953','373','13,614');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','expert','Southern Europe','99,991','103','42,821');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','expert','Northern America','99,898','164','24,771');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','expert','South-Eastern Asia','99,945','579','29,360');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','expert','Australia and New Zealand','99,422','18,888','71,122');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','expert','Sales Total by experts','99,999','103','77,774');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','novice','Caribbean','99,951','177','99,119');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','novice','Melanesia','99,834','298','15,784');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','novice','Polynesia','99,951','814','28,818');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','novice','Micronesia','99,851','11,117','14,757');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','novice','Central Asia','99,988','796','10,109');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','novice','Eastern Asia','99,960','332','49,141');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','novice','Western Asia','99,910','142','47,941');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','novice','Middle Africa','99,917','110','43,709');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','novice','South America','99,857','365','58,284');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','novice','Eastern Africa','99,990','107','59,977');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','novice','Eastern Europe','99,765','386','29,342');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','novice','Western Africa','99,988','147','55,177');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','novice','Western Europe','99,887','133','24,267');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','novice','Central America','99,738','287','30,348');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','novice','Northern Africa','99,908','172','24,377');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','novice','Northern Europe','99,886','152','59,379');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','novice','Southern Africa','99,762','191','15,503');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','novice','Southern Europe','99,934','167','46,675');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','novice','Northern America','99,607','224','23,567');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','novice','South-Eastern Asia','99,576','436','30,788');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','novice','Australia and New Zealand','99,405','706','71,028');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','novice','Sales Total by novices','99,990','107','77,090');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-03','Total by employees',' ','99,999','103','15,864');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','expert','Caribbean','99,822','171','94,154');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','expert','Melanesia','99,607','280','13,535');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','expert','Polynesia','99,834','349','25,122');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','expert','Micronesia','99,734','258','13,257');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','expert','Central Asia','99,254','323','89,570');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','expert','Eastern Asia','99,992','214','47,958');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','expert','Western Asia','99,976','395','42,246');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','expert','Middle Africa','99,631','375','41,086');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','expert','South America','99,914','101','53,985');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','expert','Eastern Africa','99,976','100','58,807');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','expert','Eastern Europe','99,983','269','27,429');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','expert','Western Africa','99,961','204','57,210');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','expert','Western Europe','99,978','586','26,773');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','expert','Central America','99,864','195','28,091');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','expert','Northern Africa','99,617','201','22,319');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','expert','Northern Europe','99,836','172','58,225');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','expert','Southern Africa','99,634','488','14,860');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','expert','Southern Europe','99,842','199','44,248');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','expert','Northern America','99,966','437','24,352');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','expert','South-Eastern Asia','99,853','384','25,157');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','expert','Australia and New Zealand','97,222','125','68,334');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','expert','Sales Total by experts','99,992','100','73,718');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','novice','Caribbean','99,920','114','91,443');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','novice','Melanesia','99,891','179','14,877');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','novice','Polynesia','99,946','298','25,089');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','novice','Micronesia','99,386','295','14,217');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','novice','Central Asia','99,458','272','87,332');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','novice','Eastern Asia','99,988','125','48,182');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','novice','Western Asia','99,952','149','44,951');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','novice','Middle Africa','99,537','194','42,499');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','novice','South America','99,931','205','55,428');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','novice','Eastern Africa','99,973','121','58,737');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','novice','Eastern Europe','99,927','165','29,884');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','novice','Western Africa','99,997','106','54,368');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','novice','Western Europe','99,879','279','25,173');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','novice','Central America','98,949','147','29,939');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','novice','Northern Africa','99,556','329','23,132');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','novice','Northern Europe','99,768','125','55,479');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','novice','Southern Africa','99,683','579','13,661');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','novice','Southern Europe','99,925','185','45,312');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','novice','Northern America','99,955','505','23,239');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','novice','South-Eastern Asia','99,868','581','29,526');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','novice','Australia and New Zealand','98,658','25,504','78,658');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','novice','Sales Total by novices','99,997','106','74,126');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-04','Total by employees',' ','99,997','100','14,844');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','expert','Caribbean','99,972','131','99,412');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','expert','Melanesia','99,987','408','14,507');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','expert','Polynesia','99,941','323','27,092');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','expert','Micronesia','99,783','508','14,101');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','expert','Central Asia','99,852','334','95,117');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','expert','Eastern Asia','99,974','104','50,962');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','expert','Western Asia','99,910','144','47,288');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','expert','Middle Africa','99,930','151','45,739');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','expert','South America','99,959','120','54,073');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','expert','Eastern Africa','99,692','104','61,821');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','expert','Eastern Europe','99,683','177','30,577');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','expert','Western Africa','99,831','193','58,432');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','expert','Western Europe','99,992','163','26,949');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','expert','Central America','99,810','183','33,015');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','expert','Northern Africa','99,861','181','22,308');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','expert','Northern Europe','99,781','101','61,884');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','expert','Southern Africa','99,718','128','13,144');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','expert','Southern Europe','99,874','224','48,559');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','expert','Northern America','99,984','220','23,953');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','expert','South-Eastern Asia','99,998','157','27,649');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','expert','Australia and New Zealand','99,860','10,026','73,144');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','expert','Sales Total by experts','99,998','101','77,726');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','novice','Caribbean','99,940','257','97,351');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','novice','Melanesia','99,750','206','14,807');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','novice','Polynesia','99,808','192','29,685');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','novice','Micronesia','99,891','506','14,936');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','novice','Central Asia','99,622','11,113','10,787');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','novice','Eastern Asia','99,919','379','48,180');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','novice','Western Asia','99,867','153','45,617');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','novice','Middle Africa','99,957','261','49,117');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','novice','South America','99,976','201','58,415');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','novice','Eastern Africa','99,915','175','58,489');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','novice','Eastern Europe','99,982','229','28,722');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','novice','Western Africa','99,558','204','56,829');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','novice','Western Europe','99,995','162','24,285');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','novice','Central America','99,850','149','30,574');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','novice','Northern Africa','99,945','149','24,614');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','novice','Northern Europe','99,994','149','61,953');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','novice','Southern Africa','99,993','118','13,556');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','novice','Southern Europe','99,922','109','48,992');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','novice','Northern America','99,956','138','23,965');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','novice','South-Eastern Asia','99,897','263','27,524');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','novice','Australia and New Zealand','99,667','229','78,254');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','novice','Sales Total by novices','99,995','109','77,652');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-05','Total by employees',' ','99,998','101','15,378');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','expert','Caribbean','99,981','108','98,927');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','expert','Melanesia','99,939','340','13,414');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','expert','Polynesia','99,946','350','26,823');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','expert','Micronesia','99,900','312','13,232');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','expert','Central Asia','99,819','105','95,451');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','expert','Eastern Asia','99,301','268','47,424');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','expert','Western Asia','99,924','218','41,582');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','expert','Middle Africa','99,905','396','44,004');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','expert','South America','99,803','265','57,245');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','expert','Eastern Africa','99,943','116','57,770');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','expert','Eastern Europe','99,955','105','30,825');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','expert','Western Africa','99,950','314','53,134');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','expert','Western Europe','99,225','221','24,100');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','expert','Central America','99,985','427','30,435');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','expert','Northern Africa','99,469','323','24,362');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','expert','Northern Europe','99,966','118','56,492');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','expert','Southern Africa','99,948','383','13,945');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','expert','Southern Europe','99,945','379','47,058');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','expert','Northern America','99,753','190','23,315');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','expert','South-Eastern Asia','99,521','168','27,394');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','expert','Australia and New Zealand','99,120','550','71,467');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','expert','Sales Total by experts','99,985','105','74,399');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','novice','Caribbean','99,998','118','97,952');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','novice','Melanesia','99,337','224','13,775');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','novice','Polynesia','99,941','161','26,630');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','novice','Micronesia','99,339','262','13,541');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','novice','Central Asia','99,543','185','81,317');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','novice','Eastern Asia','99,939','183','48,910');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','novice','Western Asia','99,829','273','45,368');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','novice','Middle Africa','99,797','240','42,587');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','novice','South America','99,961','131','56,122');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','novice','Eastern Africa','99,971','258','53,120');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','novice','Eastern Europe','99,852','470','27,735');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','novice','Western Africa','99,965','103','54,529');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','novice','Western Europe','99,788','155','23,837');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','novice','Central America','99,975','169','31,382');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','novice','Northern Africa','99,769','709','24,014');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','novice','Northern Europe','99,920','188','59,521');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','novice','Southern Africa','99,362','293','13,368');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','novice','Southern Europe','99,888','110','48,677');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','novice','Northern America','99,967','254','22,390');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','novice','South-Eastern Asia','99,969','295','27,197');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','novice','Australia and New Zealand','99,818','308','77,957');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','novice','Sales Total by novices','99,998','103','74,929');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-06','Total by employees',' ','99,998','103','14,328');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','expert','Caribbean','99,985','142','94,774');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','expert','Melanesia','99,799','671','14,737');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','expert','Polynesia','99,845','312','29,744');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','expert','Micronesia','99,673','12,212','14,393');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','expert','Central Asia','99,526','28,857','11,418');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','expert','Eastern Asia','99,568','203','51,881');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','expert','Western Asia','99,802','344','45,549');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','expert','Middle Africa','99,736','269','43,595');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','expert','South America','99,955','172','60,541');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','expert','Eastern Africa','99,961','202','59,372');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','expert','Eastern Europe','99,827','129','27,880');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','expert','Western Africa','99,995','159','53,054');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','expert','Western Europe','99,964','206','28,239');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','expert','Central America','99,845','125','32,603');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','expert','Northern Africa','99,946','479','22,633');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','expert','Northern Europe','99,911','304','58,746');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','expert','Southern Africa','99,739','408','13,804');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','expert','Southern Europe','99,978','184','48,325');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','expert','Northern America','99,762','306','23,574');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','expert','South-Eastern Asia','99,936','312','29,427');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','expert','Australia and New Zealand','99,658','382','76,924');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','expert','Sales Total by experts','99,995','125','77,213');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','novice','Caribbean','99,959','184','97,508');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','novice','Melanesia','99,934','114','14,571');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','novice','Polynesia','99,671','312','26,407');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','novice','Micronesia','99,385','216','15,758');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','novice','Central Asia','99,384','433','10,286');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','novice','Eastern Asia','99,929','274','49,626');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','novice','Western Asia','99,989','322','48,125');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','novice','Middle Africa','99,918','428','46,291');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','novice','South America','99,962','564','59,532');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','novice','Eastern Africa','99,949','150','57,301');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','novice','Eastern Europe','99,273','144','29,523');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','novice','Western Africa','99,995','147','54,074');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','novice','Western Europe','99,889','192','28,495');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','novice','Central America','99,903','213','30,386');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','novice','Northern Africa','99,609','116','24,652');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','novice','Northern Europe','99,984','129','59,964');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','novice','Southern Africa','99,577','16,694','15,832');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','novice','Southern Europe','99,910','218','46,970');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','novice','Northern America','99,523','246','24,197');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','novice','South-Eastern Asia','99,839','404','27,354');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','novice','Australia and New Zealand','99,953','20,039','82,246');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','novice','Sales Total by novices','99,995','114','77,098');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-07','Total by employees',' ','99,995','114','15,311');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','expert','Caribbean','99,953','169','96,507');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','expert','Melanesia','99,873','737','16,473');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','expert','Polynesia','99,949','169','26,462');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','expert','Micronesia','99,447','274','15,559');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','expert','Central Asia','97,877','376','10,212');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','expert','Eastern Asia','99,771','136','51,291');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','expert','Western Asia','99,793','147','44,152');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','expert','Middle Africa','99,895','254','42,848');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','expert','South America','99,981','295','57,130');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','expert','Eastern Africa','99,991','113','57,701');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','expert','Eastern Europe','99,983','341','28,918');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','expert','Western Africa','99,925','101','58,483');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','expert','Western Europe','99,761','324','27,098');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','expert','Central America','99,821','274','29,548');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','expert','Northern Africa','99,971','281','23,667');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','expert','Northern Europe','99,991','130','55,083');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','expert','Southern Africa','99,795','170','15,879');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','expert','Southern Europe','99,980','390','51,010');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','expert','Northern America','99,957','376','25,967');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','expert','South-Eastern Asia','99,991','204','28,477');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','expert','Australia and New Zealand','99,107','118','87,767');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','expert','Sales Total by experts','99,991','101','77,232');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','novice','Caribbean','99,988','140','10,284');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','novice','Melanesia','99,557','943','12,112');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','novice','Polynesia','99,190','713','26,695');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','novice','Micronesia','99,903','769','13,631');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','novice','Central Asia','99,604','173','99,678');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','novice','Eastern Asia','99,765','125','54,359');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','novice','Western Asia','99,811','103','45,120');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','novice','Middle Africa','99,965','111','49,444');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','novice','South America','99,883','164','58,952');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','novice','Eastern Africa','99,974','137','56,165');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','novice','Eastern Europe','99,970','185','30,294');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','novice','Western Africa','99,995','114','56,666');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','novice','Western Europe','99,915','506','25,723');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','novice','Central America','99,967','306','30,645');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','novice','Northern Africa','99,876','189','22,004');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','novice','Northern Europe','99,722','156','60,226');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','novice','Southern Africa','99,562','570','14,193');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','novice','Southern Europe','99,851','105','47,027');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','novice','Northern America','99,633','416','23,190');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','novice','South-Eastern Asia','99,691','180','28,548');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','novice','Australia and New Zealand','99,782','730','79,903');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','novice','Sales Total by novices','99,995','103','77,859');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-08','Total by employees',' ','99,995','101','15,091');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','expert','Caribbean','99,953','117','94,509');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','expert','Melanesia','99,274','101','12,312');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','expert','Polynesia','99,938','125','25,928');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','expert','Micronesia','99,800','299','13,075');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','expert','Central Asia','99,808','522','89,404');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','expert','Eastern Asia','99,890','245','47,775');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','expert','Western Asia','99,887','240','43,522');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','expert','Middle Africa','99,970','179','46,986');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','expert','South America','99,941','128','58,772');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','expert','Eastern Africa','99,873','167','57,642');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','expert','Eastern Europe','99,995','292','27,397');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','expert','Western Africa','99,917','124','56,889');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','expert','Western Europe','99,739','469','23,139');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','expert','Central America','99,957','108','31,201');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','expert','Northern Africa','99,940','711','21,744');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','expert','Northern Europe','99,910','175','56,950');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','expert','Southern Africa','99,352','311','13,575');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','expert','Southern Europe','99,856','134','46,846');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','expert','Northern America','98,655','232','22,172');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','expert','South-Eastern Asia','99,961','224','28,872');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','expert','Australia and New Zealand','99,187','250','62,608');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','expert','Sales Total by experts','99,995','101','74,318');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','novice','Caribbean','99,899','159','95,473');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','novice','Melanesia','99,593','696','14,127');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','novice','Polynesia','99,755','322','26,623');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','novice','Micronesia','99,287','357','14,219');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','novice','Central Asia','99,765','396','10,308');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','novice','Eastern Asia','99,912','138','47,461');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','novice','Western Asia','99,854','150','43,070');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','novice','Middle Africa','99,989','199','42,854');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','novice','South America','99,834','271','57,944');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','novice','Eastern Africa','99,940','130','59,672');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','novice','Eastern Europe','99,909','376','27,616');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','novice','Western Africa','99,796','172','57,587');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','novice','Western Europe','99,874','311','28,949');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','novice','Central America','99,869','400','29,851');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','novice','Northern Africa','99,976','498','22,673');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','novice','Northern Europe','99,999','180','57,953');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','novice','Southern Africa','99,290','421','15,430');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','novice','Southern Europe','99,827','271','45,847');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','novice','Northern America','99,978','204','22,356');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','novice','South-Eastern Asia','99,898','322','26,515');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','novice','Australia and New Zealand','99,072','420','93,978');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','novice','Sales Total by novices','99,999','130','75,506');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-09','Total by employees',' ','99,999','101','14,824');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','expert','Caribbean','99,928','145','93,154');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','expert','Melanesia','99,366','393','14,707');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','expert','Polynesia','99,635','408','23,298');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','expert','Micronesia','99,790','326','14,627');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','expert','Central Asia','99,233','10,028','84,219');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','expert','Eastern Asia','99,857','509','47,291');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','expert','Western Asia','99,986','601','46,719');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','expert','Middle Africa','99,990','117','43,275');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','expert','South America','99,881','131','56,085');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','expert','Eastern Africa','99,985','105','59,718');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','expert','Eastern Europe','98,911','216','28,789');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','expert','Western Africa','99,961','109','58,850');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','expert','Western Europe','99,996','774','24,307');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','expert','Central America','99,742','139','29,177');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','expert','Northern Africa','99,352','329','24,947');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','expert','Northern Europe','99,960','161','61,250');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','expert','Southern Africa','99,472','175','13,265');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','expert','Southern Europe','99,986','108','45,098');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','expert','Northern America','99,954','209','24,409');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','expert','South-Eastern Asia','99,825','628','27,196');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','expert','Australia and New Zealand','99,576','24,419','80,596');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','expert','Sales Total by experts','99,996','105','75,977');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','novice','Caribbean','99,984','117','10,309');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','novice','Melanesia','99,862','376','15,941');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','novice','Polynesia','99,923','215','27,140');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','novice','Micronesia','98,538','12,252','12,550');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','novice','Central Asia','99,914','129','11,640');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','novice','Eastern Asia','99,943','263','52,787');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','novice','Western Asia','99,852','146','44,514');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','novice','Middle Africa','99,904','194','47,404');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','novice','South America','99,980','114','56,230');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','novice','Eastern Africa','99,958','274','58,807');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','novice','Eastern Europe','99,974','184','28,772');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','novice','Western Africa','99,979','198','59,329');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','novice','Western Europe','99,367','135','24,700');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','novice','Central America','99,924','401','33,314');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','novice','Northern Africa','99,859','156','22,724');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','novice','Northern Europe','99,965','157','59,136');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','novice','Southern Africa','99,885','215','14,574');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','novice','Southern Europe','99,857','160','46,908');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','novice','Northern America','99,650','125','23,117');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','novice','South-Eastern Asia','99,969','365','32,836');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','novice','Australia and New Zealand','99,755','11,181','79,779');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','novice','Sales Total by novices','99,984','114','77,511');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-10','Total by employees',' ','99,996','105','15,488');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','expert','Caribbean','99,972','121','92,610');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','expert','Melanesia','99,730','118','13,627');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','expert','Polynesia','99,985','115','25,310');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','expert','Micronesia','97,234','164','12,613');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','expert','Central Asia','99,622','231','11,863');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','expert','Eastern Asia','99,615','144','49,279');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','expert','Western Asia','99,968','170','42,536');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','expert','Middle Africa','99,885','188','44,909');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','expert','South America','99,844','178','57,744');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','expert','Eastern Africa','99,945','210','57,678');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','expert','Eastern Europe','99,818','204','28,194');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','expert','Western Africa','99,894','114','58,991');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','expert','Western Europe','99,958','237','26,265');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','expert','Central America','99,933','117','29,122');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','expert','Northern Africa','99,896','976','20,071');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','expert','Northern Europe','99,881','105','58,740');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','expert','Southern Africa','99,277','114','13,134');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','expert','Southern Europe','99,987','109','47,773');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','expert','Northern America','99,762','382','25,793');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','expert','South-Eastern Asia','99,808','302','28,029');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','expert','Australia and New Zealand','99,044','224','71,807');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','expert','Sales Total by experts','99,987','105','74,088');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','novice','Caribbean','99,976','149','99,156');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','novice','Melanesia','99,529','500','15,699');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','novice','Polynesia','99,732','209','26,158');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','novice','Micronesia','99,895','248','13,224');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','novice','Central Asia','99,989','167','87,126');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','novice','Eastern Asia','99,939','303','49,027');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','novice','Western Asia','99,927','297','45,939');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','novice','Middle Africa','99,940','211','43,770');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','novice','South America','99,828','103','58,971');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','novice','Eastern Africa','99,937','140','59,483');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','novice','Eastern Europe','99,559','318','27,483');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','novice','Western Africa','99,881','126','54,993');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','novice','Western Europe','99,868','157','27,816');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','novice','Central America','99,847','138','28,386');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','novice','Northern Africa','99,935','322','24,427');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','novice','Northern Europe','99,777','250','57,042');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','novice','Southern Africa','99,589','180','14,820');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','novice','Southern Europe','99,947','113','47,070');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','novice','Northern America','99,998','356','23,533');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','novice','South-Eastern Asia','99,829','259','27,206');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','novice','Australia and New Zealand','99,164','656','84,617');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','novice','Sales Total by novices','99,998','103','76,946');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-11','Total by employees',' ','99,998','103','15,034');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','expert','Caribbean','99,994','135','94,268');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','expert','Melanesia','99,504','406','16,058');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','expert','Polynesia','99,976','577','23,114');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','expert','Micronesia','99,998','208','15,918');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','expert','Central Asia','99,474','597','10,322');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','expert','Eastern Asia','99,958','141','49,141');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','expert','Western Asia','99,968','104','46,256');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','expert','Middle Africa','99,853','171','47,796');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','expert','South America','99,978','127','56,978');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','expert','Eastern Africa','99,932','143','58,678');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','expert','Eastern Europe','99,883','303','29,228');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','expert','Western Africa','99,925','120','58,187');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','expert','Western Europe','99,422','314','25,341');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','expert','Central America','99,800','126','34,398');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','expert','Northern Africa','99,505','370','23,715');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','expert','Northern Europe','99,993','101','62,153');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','expert','Southern Africa','99,727','936','14,318');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','expert','Southern Europe','99,896','129','46,101');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','expert','Northern America','99,549','277','24,288');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','expert','South-Eastern Asia','99,872','114','29,891');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','expert','Australia and New Zealand','99,510','17,771','78,843');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','expert','Sales Total by experts','99,998','101','77,992');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','novice','Caribbean','99,958','162','98,100');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','novice','Melanesia','99,905','111','13,728');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','novice','Polynesia','99,849','681','24,210');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','novice','Micronesia','99,841','822','13,269');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','novice','Central Asia','99,085','296','10,141');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','novice','Eastern Asia','99,862','217','51,265');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','novice','Western Asia','99,755','207','45,713');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','novice','Middle Africa','99,980','228','45,114');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','novice','South America','99,946','104','57,319');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','novice','Eastern Africa','99,773','192','60,056');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','novice','Eastern Europe','99,815','208','28,982');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','novice','Western Africa','99,894','336','56,713');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','novice','Western Europe','99,968','312','26,336');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','novice','Central America','99,962','435','32,264');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','novice','Northern Africa','99,959','107','25,658');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','novice','Northern Europe','99,944','345','59,990');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','novice','Southern Africa','99,708','480','14,917');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','novice','Southern Europe','99,976','208','46,772');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','novice','Northern America','99,836','148','23,079');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','novice','South-Eastern Asia','99,876','221','28,007');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','novice','Australia and New Zealand','96,996','125','73,513');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','novice','Sales Total by novices','99,980','104','77,146');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2019-12','Total by employees',' ','99,998','101','15,138');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','expert','Caribbean','99,967','199','10,551');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','expert','Melanesia','99,737','412','14,834');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','expert','Polynesia','99,636','288','24,132');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','expert','Micronesia','99,928','161','13,148');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','expert','Central Asia','99,536','404','97,812');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','expert','Eastern Asia','99,919','152','50,184');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','expert','Western Asia','99,931','218','46,062');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','expert','Middle Africa','99,960','141','42,772');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','expert','South America','99,855','109','55,065');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','expert','Eastern Africa','99,950','120','58,042');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','expert','Eastern Europe','99,915','614','29,853');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','expert','Western Africa','99,899','136','58,593');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','expert','Western Europe','99,988','546','27,022');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','expert','Central America','99,581','138','29,262');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','expert','Northern Africa','99,995','556','22,369');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','expert','Northern Europe','99,638','262','60,359');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','expert','Southern Africa','99,971','396','15,915');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','expert','Southern Europe','99,938','257','48,721');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','expert','Northern America','99,781','124','23,503');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','expert','South-Eastern Asia','99,965','145','29,070');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','expert','Australia and New Zealand','97,406','297','79,683');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','expert','Sales Total by experts','99,995','109','76,952');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','novice','Caribbean','99,992','215','97,155');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','novice','Melanesia','99,169','282','13,775');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','novice','Polynesia','99,988','281','25,846');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','novice','Micronesia','99,860','159','12,746');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','novice','Central Asia','99,541','687','94,229');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','novice','Eastern Asia','99,900','213','53,275');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','novice','Western Asia','99,996','285','43,050');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','novice','Middle Africa','99,859','211','46,584');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','novice','South America','99,799','248','55,115');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','novice','Eastern Africa','99,987','137','59,408');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','novice','Eastern Europe','99,810','176','29,125');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','novice','Western Africa','99,908','103','60,836');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','novice','Western Europe','99,965','157','25,962');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','novice','Central America','99,847','290','32,941');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','novice','Northern Africa','99,777','343','24,399');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','novice','Northern Europe','99,995','120','60,177');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','novice','Southern Africa','99,680','299','16,138');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','novice','Southern Europe','99,980','305','49,402');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','novice','Northern America','99,622','103','25,925');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','novice','South-Eastern Asia','99,540','266','31,334');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','novice','Australia and New Zealand','99,886','418','68,517');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','novice','Sales Total by novices','99,996','103','77,939');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-01','Total by employees',' ','99,996','103','15,891');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','expert','Caribbean','99,869','179','91,217');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','expert','Melanesia','99,864','532','14,483');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','expert','Polynesia','99,984','115','25,558');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','expert','Micronesia','99,976','873','12,184');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','expert','Central Asia','99,707','724','95,051');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','expert','Eastern Asia','99,944','334','46,231');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','expert','Western Asia','99,892','259','40,960');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','expert','Middle Africa','99,856','555','43,407');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','expert','South America','99,958','179','54,974');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','expert','Eastern Africa','99,919','135','58,192');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','expert','Eastern Europe','99,977','130','28,138');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','expert','Western Africa','99,944','116','54,089');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','expert','Western Europe','99,795','159','24,423');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','expert','Central America','99,912','240','29,253');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','expert','Northern Africa','99,942','404','22,751');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','expert','Northern Europe','99,950','305','57,973');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','expert','Southern Africa','99,873','213','14,107');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','expert','Southern Europe','99,867','148','41,690');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','expert','Northern America','99,574','573','21,279');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','expert','South-Eastern Asia','99,813','103','29,258');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','expert','Australia and New Zealand','97,364','14,492','68,018');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','expert','Sales Total by experts','99,984','103','72,236');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','novice','Caribbean','99,990','172','91,008');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','novice','Melanesia','99,919','10,002','11,684');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','novice','Polynesia','99,976','460','25,088');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','novice','Micronesia','98,391','312','13,041');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','novice','Central Asia','98,954','11,107','96,319');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','novice','Eastern Asia','99,916','229','43,396');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','novice','Western Asia','99,931','137','41,001');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','novice','Middle Africa','99,953','111','43,752');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','novice','South America','99,729','167','52,125');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','novice','Eastern Africa','99,905','133','58,286');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','novice','Eastern Europe','99,964','155','26,578');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','novice','Western Africa','99,897','114','53,527');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','novice','Western Europe','99,702','396','22,360');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','novice','Central America','99,734','210','28,540');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','novice','Northern Africa','99,730','150','22,807');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','novice','Northern Europe','99,955','153','52,866');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','novice','Southern Africa','99,573','914','14,743');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','novice','Southern Europe','99,947','120','46,152');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','novice','Northern America','99,782','338','24,870');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','novice','South-Eastern Asia','99,578','223','25,742');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','novice','Australia and New Zealand','99,275','306','79,151');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','novice','Sales Total by novices','99,990','111','71,036');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-02','Total by employees',' ','99,990','103','14,272');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','expert','Caribbean','99,973','183','99,892');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','expert','Melanesia','99,565','493','14,521');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','expert','Polynesia','99,766','563','27,652');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','expert','Micronesia','99,513','444','13,704');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','expert','Central Asia','99,470','319','93,005');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','expert','Eastern Asia','99,695','129','48,373');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','expert','Western Asia','99,941','425','45,109');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','expert','Middle Africa','99,973','274','42,226');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','expert','South America','99,687','280','54,706');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','expert','Eastern Africa','99,922','321','59,785');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','expert','Eastern Europe','99,975','120','28,350');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','expert','Western Africa','99,911','111','53,885');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','expert','Western Europe','99,925','244','27,054');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','expert','Central America','99,634','139','31,265');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','expert','Northern Africa','99,992','356','22,223');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','expert','Northern Europe','99,847','117','60,954');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','expert','Southern Africa','99,162','510','15,206');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','expert','Southern Europe','99,895','134','48,980');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','expert','Northern America','99,907','115','24,948');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','expert','South-Eastern Asia','99,973','157','27,450');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','expert','Australia and New Zealand','99,699','183','78,357');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','expert','Sales Total by experts','99,992','111','76,645');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','novice','Caribbean','99,953','124','10,079');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','novice','Melanesia','99,998','250','13,716');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','novice','Polynesia','99,935','214','28,211');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','novice','Micronesia','99,875','539','12,076');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','novice','Central Asia','98,862','517','86,534');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','novice','Eastern Asia','99,917','105','51,703');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','novice','Western Asia','99,778','215','46,604');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','novice','Middle Africa','99,961','117','45,746');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','novice','South America','99,966','102','57,463');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','novice','Eastern Africa','99,760','118','57,488');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','novice','Eastern Europe','99,914','188','30,240');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','novice','Western Africa','99,952','395','60,882');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','novice','Western Europe','99,984','324','28,194');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','novice','Central America','99,882','282','31,910');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','novice','Northern Africa','99,646','449','23,401');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','novice','Northern Europe','99,970','331','61,141');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','novice','Southern Africa','99,537','546','15,348');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','novice','Southern Europe','99,928','196','48,341');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','novice','Northern America','99,942','119','24,197');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','novice','South-Eastern Asia','99,803','352','27,662');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','novice','Australia and New Zealand','99,839','14,403','81,058');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','novice','Sales Total by novices','99,998','102','78,994');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-03','Total by employees',' ','99,998','102','15,639');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','expert','Caribbean','99,991','137','97,595');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','expert','Melanesia','99,891','182','14,000');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','expert','Polynesia','99,868','550','25,087');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','expert','Micronesia','99,987','277','14,837');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','expert','Central Asia','98,993','180','87,277');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','expert','Eastern Asia','99,949','217','49,110');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','expert','Western Asia','99,881','219','40,958');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','expert','Middle Africa','99,983','491','43,190');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','expert','South America','99,974','149','54,317');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','expert','Eastern Africa','99,943','566','57,005');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','expert','Eastern Europe','99,666','102','29,753');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','expert','Western Africa','99,869','149','54,841');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','expert','Western Europe','99,814','440','25,377');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','expert','Central America','99,512','195','28,601');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','expert','Northern Africa','99,952','316','24,105');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','expert','Northern Europe','99,990','137','58,602');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','expert','Southern Africa','99,794','333','14,153');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','expert','Southern Europe','99,979','198','46,121');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','expert','Northern America','99,038','291','22,782');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','expert','South-Eastern Asia','99,938','203','25,715');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','expert','Australia and New Zealand','98,970','968','62,062');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','expert','Sales Total by experts','99,991','102','74,488');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','novice','Caribbean','99,996','198','98,893');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','novice','Melanesia','99,496','278','14,284');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','novice','Polynesia','99,944','248','26,542');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','novice','Micronesia','99,979','304','13,623');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','novice','Central Asia','98,850','264','99,418');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','novice','Eastern Asia','99,942','655','47,624');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','novice','Western Asia','99,843','131','41,530');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','novice','Middle Africa','99,991','296','43,466');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','novice','South America','99,925','166','56,882');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','novice','Eastern Africa','99,989','258','57,458');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','novice','Eastern Europe','99,838','142','26,984');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','novice','Western Africa','99,894','156','57,660');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','novice','Western Europe','99,524','156','23,555');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','novice','Central America','99,746','494','31,138');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','novice','Northern Africa','99,922','304','23,018');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','novice','Northern Europe','99,990','385','57,506');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','novice','Southern Africa','99,787','337','15,430');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','novice','Southern Europe','99,969','165','44,347');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','novice','Northern America','99,911','405','23,033');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','novice','South-Eastern Asia','99,957','178','25,692');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','novice','Australia and New Zealand','97,808','681','82,008');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','novice','Sales Total by novices','99,996','131','74,091');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-04','Total by employees',' ','99,996','102','14,579');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','expert','Caribbean','99,939','137','96,444');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','expert','Melanesia','99,838','102','13,339');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','expert','Polynesia','99,709','313','27,003');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','expert','Micronesia','99,699','242','14,168');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','expert','Central Asia','99,493','761','99,476');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','expert','Eastern Asia','99,904','101','49,611');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','expert','Western Asia','99,984','161','47,474');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','expert','Middle Africa','99,843','260','44,195');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','expert','South America','99,961','371','55,554');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','expert','Eastern Africa','99,946','115','60,589');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','expert','Eastern Europe','99,977','124','28,642');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','expert','Western Africa','99,869','101','58,314');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','expert','Western Europe','99,585','248','23,455');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','expert','Central America','99,881','168','32,951');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','expert','Northern Africa','99,428','186','23,424');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','expert','Northern Europe','99,981','333','60,454');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','expert','Southern Africa','99,951','139','13,854');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','expert','Southern Europe','99,955','122','47,406');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','expert','Northern America','99,727','267','23,554');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','expert','South-Eastern Asia','99,967','155','28,447');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','expert','Australia and New Zealand','99,459','575','74,104');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','expert','Sales Total by experts','99,984','101','76,458');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','novice','Caribbean','99,956','145','95,536');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','novice','Melanesia','99,679','489','15,997');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','novice','Polynesia','99,941','293','24,281');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','novice','Micronesia','98,563','483','13,262');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','novice','Central Asia','99,689','387','98,319');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','novice','Eastern Asia','99,781','166','53,993');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','novice','Western Asia','99,891','268','47,443');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','novice','Middle Africa','99,906','322','44,682');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','novice','South America','99,988','306','60,103');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','novice','Eastern Africa','99,999','219','58,171');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','novice','Eastern Europe','99,866','139','30,182');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','novice','Western Africa','99,977','204','56,948');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','novice','Western Europe','99,870','241','27,479');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','novice','Central America','99,936','388','30,812');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','novice','Northern Africa','99,791','228','23,330');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','novice','Northern Europe','99,963','251','62,057');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','novice','Southern Africa','99,351','109','15,303');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','novice','Southern Europe','99,995','310','49,281');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','novice','Northern America','99,721','163','26,835');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','novice','South-Eastern Asia','99,970','174','28,741');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','novice','Australia and New Zealand','96,898','773','73,645');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','novice','Sales Total by novices','99,999','109','78,400');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-05','Total by employees',' ','99,999','101','15,858');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','expert','Caribbean','99,816','184','95,434');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','expert','Melanesia','99,635','104','16,736');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','expert','Polynesia','99,544','158','24,781');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','expert','Micronesia','99,986','625','13,587');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','expert','Central Asia','99,850','823','11,329');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','expert','Eastern Asia','99,985','209','48,064');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','expert','Western Asia','99,890','127','44,037');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','expert','Middle Africa','99,908','106','43,072');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','expert','South America','99,776','109','58,665');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','expert','Eastern Africa','99,973','257','54,377');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','expert','Eastern Europe','99,770','109','29,263');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','expert','Western Africa','99,942','116','53,655');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','expert','Western Europe','99,913','574','24,650');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','expert','Central America','99,689','450','30,139');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','expert','Northern Africa','99,811','127','21,402');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','expert','Northern Europe','99,978','240','59,949');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','expert','Southern Africa','98,495','179','13,312');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','expert','Southern Europe','99,910','457','49,427');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','expert','Northern America','99,645','359','23,040');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','expert','South-Eastern Asia','99,943','130','27,591');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','expert','Australia and New Zealand','98,849','19,958','69,078');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','expert','Sales Total by experts','99,986','104','74,588');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','novice','Caribbean','99,853','111','93,724');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','novice','Melanesia','99,369','820','12,760');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','novice','Polynesia','99,909','148','25,471');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','novice','Micronesia','98,637','137','13,284');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','novice','Central Asia','99,931','805','82,964');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','novice','Eastern Asia','99,992','140','49,375');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','novice','Western Asia','99,893','139','44,455');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','novice','Middle Africa','99,844','304','47,341');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','novice','South America','99,997','190','54,308');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','novice','Eastern Africa','99,901','124','56,775');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','novice','Eastern Europe','99,481','284','27,341');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','novice','Western Africa','99,933','251','58,587');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','novice','Western Europe','99,664','12,247','26,863');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','novice','Central America','99,913','163','31,515');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','novice','Northern Africa','99,987','236','22,176');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','novice','Northern Europe','99,986','144','61,000');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','novice','Southern Africa','99,696','356','13,560');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','novice','Southern Europe','99,875','159','42,233');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','novice','Northern America','99,978','317','22,271');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','novice','South-Eastern Asia','99,823','144','25,710');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','novice','Australia and New Zealand','99,775','749','75,982');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','novice','Sales Total by novices','99,997','111','74,695');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-06','Total by employees',' ','99,997','104','14,283');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','expert','Caribbean','99,995','150','96,801');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','expert','Melanesia','99,367','503','15,880');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','expert','Polynesia','99,644','256','25,091');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','expert','Micronesia','99,818','670','13,685');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','expert','Central Asia','99,895','124','10,965');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','expert','Eastern Asia','99,969','151','51,062');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','expert','Western Asia','99,656','177','43,283');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','expert','Middle Africa','99,473','121','44,571');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','expert','South America','99,958','224','54,447');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','expert','Eastern Africa','99,922','197','65,301');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','expert','Eastern Europe','99,986','102','29,718');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','expert','Western Africa','99,935','125','55,486');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','expert','Western Europe','99,899','421','25,000');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','expert','Central America','99,705','658','31,827');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','expert','Northern Africa','99,727','141','22,952');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','expert','Northern Europe','99,995','269','56,055');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','expert','Southern Africa','99,887','287','14,890');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','expert','Southern Europe','99,859','143','44,818');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','expert','Northern America','99,235','210','23,261');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','expert','South-Eastern Asia','99,994','232','28,514');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','expert','Australia and New Zealand','98,794','11,196','91,912');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','expert','Sales Total by experts','99,995','102','76,519');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','novice','Caribbean','99,996','145','10,194');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','novice','Melanesia','99,563','291','12,133');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','novice','Polynesia','99,995','532','25,878');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','novice','Micronesia','99,890','284','15,270');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','novice','Central Asia','97,839','10,089','87,398');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','novice','Eastern Asia','99,895','203','49,875');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','novice','Western Asia','99,995','193','46,348');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','novice','Middle Africa','99,896','152','44,538');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','novice','South America','99,970','148','61,650');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','novice','Eastern Africa','99,913','132','61,118');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','novice','Eastern Europe','99,970','263','29,959');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','novice','Western Africa','99,945','209','57,384');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','novice','Western Europe','99,926','261','25,818');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','novice','Central America','99,959','126','30,622');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','novice','Northern Africa','99,890','177','23,881');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','novice','Northern Europe','99,983','102','57,330');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','novice','Southern Africa','99,963','106','16,306');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','novice','Southern Europe','99,970','597','48,781');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','novice','Northern America','99,571','102','24,207');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','novice','South-Eastern Asia','99,817','193','28,061');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','novice','Australia and New Zealand','99,951','407','75,380');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','novice','Sales Total by novices','99,996','102','78,131');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-07','Total by employees',' ','99,996','102','15,650');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','expert','Caribbean','99,988','441','90,940');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','expert','Melanesia','99,065','213','13,578');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','expert','Polynesia','99,188','130','24,857');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','expert','Micronesia','99,882','559','12,235');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','expert','Central Asia','99,909','290','10,342');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','expert','Eastern Asia','99,834','368','48,139');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','expert','Western Asia','99,921','352','43,951');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','expert','Middle Africa','99,903','144','41,344');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','expert','South America','99,977','452','54,107');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','expert','Eastern Africa','99,995','273','55,489');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','expert','Eastern Europe','99,730','224','27,095');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','expert','Western Africa','99,980','111','57,068');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','expert','Western Europe','99,695','132','24,357');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','expert','Central America','99,773','139','34,081');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','expert','Northern Africa','99,877','532','23,520');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','expert','Northern Europe','99,949','126','57,240');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','expert','Southern Africa','99,798','364','15,648');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','expert','Southern Europe','99,869','247','45,887');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','expert','Northern America','99,876','122','22,191');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','expert','South-Eastern Asia','99,698','178','27,624');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','expert','Australia and New Zealand','96,818','10,068','54,162');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','expert','Sales Total by experts','99,995','111','73,855');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','novice','Caribbean','99,985','127','96,825');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','novice','Melanesia','99,860','578','14,401');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','novice','Polynesia','99,964','403','25,674');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','novice','Micronesia','99,942','194','13,973');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','novice','Central Asia','99,713','128','88,360');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','novice','Eastern Asia','99,995','150','45,929');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','novice','Western Asia','99,954','194','44,300');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','novice','Middle Africa','99,731','118','42,195');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','novice','South America','99,923','114','51,270');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','novice','Eastern Africa','99,706','103','52,187');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','novice','Eastern Europe','99,916','585','28,175');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','novice','Western Africa','99,922','117','53,949');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','novice','Western Europe','99,952','146','24,107');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','novice','Central America','99,977','272','29,745');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','novice','Northern Africa','99,942','130','20,785');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','novice','Northern Europe','99,866','103','54,822');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','novice','Southern Africa','99,478','20,007','12,964');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','novice','Southern Europe','99,985','336','44,900');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','novice','Northern America','99,971','119','23,690');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','novice','South-Eastern Asia','99,921','124','25,463');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','novice','Australia and New Zealand','99,104','35,572','91,674');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','novice','Sales Total by novices','99,995','103','72,388');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('2020-08','Total by employees',' ','99,995','103','14,243');
Insert into DATA_MART.SALES (YEAR_MONTH,POSITION_GRADE,REGION,MAX_SALES$,MIN_SALES$,SALES$) values ('GRAND TOTAL',' ',' ','99,999','100','49,358');

EXIT
