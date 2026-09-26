SYSTEM
=====================================================================
CREATE TABLESPACE tbs_pdb_dwh DATAFILE
    'TBS_PDB_DWH.DBF' SIZE 104857600
        AUTOEXTEND ON NEXT 20971520
NOLOGGING SEGMENT SPACE MANAGEMENT AUTO EXTENT MANAGEMENT LOCAL AUTOALLOCATE;
---------------------------------------------------------------------
CREATE USER sa_src IDENTIFIED BY "123" DEFAULT TABLESPACE tbs_pdb_dwh;
GRANT CONNECT TO sa_src;
GRANT RESOURCE TO sa_src;
CREATE USER bl_cl_1st IDENTIFIED BY "123" DEFAULT TABLESPACE tbs_pdb_dwh;
GRANT CONNECT TO bl_cl_1st;
GRANT RESOURCE TO bl_cl_1st;
CREATE USER bl_3nf IDENTIFIED BY "123" DEFAULT TABLESPACE tbs_pdb_dwh;
GRANT CONNECT TO bl_3nf;
GRANT RESOURCE TO bl_3nf;
CREATE USER bl_cl_2nd IDENTIFIED BY "123" DEFAULT TABLESPACE tbs_pdb_dwh;
GRANT CONNECT TO bl_cl_2nd;
GRANT RESOURCE TO bl_cl_2nd;
CREATE USER bl_dm IDENTIFIED BY "123" DEFAULT TABLESPACE tbs_pdb_dwh;
GRANT CONNECT TO bl_dm;
GRANT RESOURCE TO bl_dm;
---------------------------------------------------------------------
CREATE PACKAGES FROM SA SRC FOLDER
---------------------------------------------------------------------
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
---------------------------------------------------------------------
SA_SRC
=====================================================================
CREATE PACKAGES FROM SA SRC FOLDER
---------------------------------------------------------------------
CREATE OR REPLACE DIRECTORY external_geo_tables AS '/media/sf_Valeryia_Lupanava/Project/dwso/sa_src/sources/geography';
CREATE OR REPLACE DIRECTORY external_cust_tables AS '/media/sf_Valeryia_Lupanava/Project/dwso/sa_src/sources/customers';
CREATE OR REPLACE DIRECTORY external_emp_tables AS '/media/sf_Valeryia_Lupanava/Project/dwso/sa_src/sources/employees';
CREATE OR REPLACE DIRECTORY external_ext_tables AS '/media/sf_Valeryia_Lupanava/Project/dwso/sa_src/sources';
CREATE OR REPLACE DIRECTORY external_prod_tables AS '/media/sf_Valeryia_Lupanava/Project/dwso/sa_src/sources/products';
---------------------------------------------------------------------
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
---------------------------------------------------------------------
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
---------------------------------------------------------------------
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
---------------------------------------------------------------------
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
---------------------------------------------------------------------
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
---------------------------------------------------------------------
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
---------------------------------------------------------------------
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
---------------------------------------------------------------------
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
---------------------------------------------------------------------
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
---------------------------------------------------------------------
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
---------------------------------------------------------------------
BEGIN
  pkg_grants.USER_GRANT(GRANT_NAME => 'READ, WRITE ON DIRECTORY EXTERNAL_GEO_TABLES', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'READ, WRITE ON DIRECTORY EXTERNAL_CUST_TABLES', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'READ, WRITE ON DIRECTORY EXTERNAL_EMP_TABLES', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'READ, WRITE ON DIRECTORY EXTERNAL_EXP_TABLES', USER_NAME => 'BL_CL_1ST');
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
---------------------------------------------------------------------
COMMIT;
---------------------------------------------------------------------
BL_CL_1ST
=====================================================================
CREATE DDL OBJECTS WRK AND CLS FROM BL CL 1ST FOLDER
---------------------------------------------------------------------
BL_3NF
=====================================================================
CREATE DDL OBJECTS WRK AND CLS FROM BL 3NF FOLDER
---------------------------------------------------------------------
CREATE PACKAGES FROM SA SRC FOLDER
---------------------------------------------------------------------
BL_CL_1ST
=====================================================================
-- Filling WRK tables.
---------------------------------------------------------------------
BEGIN
  pkg_etl_insert_wrk.insert_table(table_name_to => 'WRK_STRUCTURES', table_name_from => 'SA_SRC.EXT_STRUCTURES');
  pkg_etl_insert_wrk.insert_table(table_name_to => 'WRK_STORES', table_name_from => 'SA_SRC.EXT_STORES');
  pkg_etl_insert_wrk.insert_table(table_name_to => 'WRK_PRODUCTS', table_name_from => 'SA_SRC.EXT_PRODUCTS');
  pkg_etl_insert_wrk.insert_table(table_name_to => 'WRK_PAYMENT_METHODS', table_name_from => 'SA_SRC.EXT_PAYMENT_METHODS');
  pkg_etl_insert_wrk.insert_table(table_name_to => 'WRK_PANTY_SIZES', table_name_from => 'SA_SRC.EXT_PANTY_SIZES');
  pkg_etl_insert_wrk.insert_table(table_name_to => 'WRK_FULL_DATA', table_name_from => 'SA_SRC.EXT_FULL_DATA');
  pkg_etl_insert_wrk.insert_table(table_name_to => 'WRK_EMPLOYEES', table_name_from => 'SA_SRC.EXT_EMPLOYEES');
  pkg_etl_insert_wrk.insert_table(table_name_to => 'WRK_CUSTOMERS', table_name_from => 'SA_SRC.EXT_CUSTOMERS');
  pkg_etl_insert_wrk.insert_table(table_name_to => 'WRK_COUNTRIES', table_name_from => 'SA_SRC.EXT_COUNTRIES');
  pkg_etl_insert_wrk.insert_table(table_name_to => 'WRK_BRA_SIZES', table_name_from => 'SA_SRC.EXT_BRA_SIZES');  
END;
/
---------------------------------------------------------------------
TRUNCATE table wrk_cities;

INSERT INTO wrk_cities (
                        city_id,
                        city_desc,
                        country_id                        
                        )
SELECT country_id || ' ' || SUBSTR(city_desc,1,6) AS city_id,       
       city_desc,
       country_id
FROM (SELECT DISTINCT city AS city_desc,
                      country_id
      FROM sa_src.ext_customers);
---------------------------------------------------------------------
-- Filling CLS tables.
---------------------------------------------------------------------
BEGIN
  pkg_etl_insert_geography.insert_table_continents;
  pkg_etl_insert_geography.insert_table_regions;
  pkg_etl_insert_geography.insert_table_countries;
  pkg_etl_insert_geography.insert_table_cities;
  pkg_etl_insert_stores.insert_table_stores;
  pkg_etl_insert_sizes.insert_table_bras;
  pkg_etl_insert_sizes.insert_table_panties;
  pkg_etl_insert_customers.insert_table_customers;
  pkg_etl_insert_age_categories.insert_table_age_categories;
  pkg_etl_insert_employees.insert_table_position_grade;
  pkg_etl_insert_employees.insert_table_employees;
  pkg_etl_insert_payment_methods.insert_table_payment_methods;
  pkg_etl_insert_products.insert_table_collections;
  pkg_etl_insert_products.insert_table_lines;
  pkg_etl_insert_products.insert_table_product_types;
  pkg_etl_insert_products.insert_table_products;
  pkg_etl_insert_products.insert_table_product_details;
END;
/
---------------------------------------------------------------------
BL_3NF
=====================================================================
CREATE SEQUENCES FROM BL 3NF FOLDER
CREATE PACKAGES FROM BL 3NF FOLDER FOR DROP AND GRANTS
---------------------------------------------------------------------
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
---------------------------------------------------------------------
BL_CL_1ST
===================================================================== 
-- Filling CE tables.
---------------------------------------------------------------------
BEGIN
  pkg_etl_insert_geography.merge_table_ce_continents;
  pkg_etl_insert_geography.merge_table_ce_regions;
  pkg_etl_insert_geography.merge_table_ce_countries;
  pkg_etl_insert_geography.merge_table_ce_cities;
  pkg_etl_insert_stores.merge_table_ce_stores;
  pkg_etl_insert_sizes.merge_table_ce_bra_size_grid;
  pkg_etl_insert_sizes.merge_table_ce_panty_size_grid;  
  pkg_etl_insert_age_categories.merge_table_ce_age_categories;
  pkg_etl_insert_customers.merge_table_customers_second;
  pkg_etl_insert_employees.merge_table_ce_position_grades;
  pkg_etl_insert_employees.merge_table_employees_second;
  pkg_etl_insert_payment_methods.merge_table_ce_pm_second;
  pkg_etl_insert_products.merge_table_ce_collections;
  pkg_etl_insert_products.merge_table_ce_lines;
  pkg_etl_insert_products.merge_table_ce_product_types;
  pkg_etl_insert_products.merge_table_ce_products_second;
  pkg_etl_insert_products.merge_table_ce_product_details;  
END;
/
---------------------------------------------------------------------
-- Updating CE tables.
---------------------------------------------------------------------
BEGIN
  pkg_etl_update_tables.update_table_customers;
  pkg_etl_update_tables.update_table_employees;
  pkg_etl_update_tables.update_table_payment_methods;
  pkg_etl_update_tables.update_table_products;
END;
/
---------------------------------------------------------------------
BL_3NF
=====================================================================
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
---------------------------------------------------------------------
BL_CL_2ND
=====================================================================
CREATE DDL OBJECTS FROM BL CL 2ND FOLDER
CREATE PACKAGES FROM BL CL 2ND FOLDER
---------------------------------------------------------------------
BEGIN
  pkg_etl_insert_customers.insert_table_customers;
  pkg_etl_insert_employees.insert_table_employees;
  pkg_etl_insert_payment_methods.insert_table_payment_methods;
  pkg_etl_insert_products.insert_table_products;
  pkg_etl_insert_stores.insert_table_stores;  
END;
/
---------------------------------------------------------------------
TRUNCATE TABLE cls_time_day;

INSERT INTO cls_time_day (
    date_dt,
    week_day_full_name,
    week_day_short_name,
    day_number_of_week,
    day_number_of_month,
    day_number_of_year,
    month_year,
    month_full_name,
    month_short_name,
    month_number_of_year,
    quarter_year,
    quarter_number_of_year,
    half_year_number,
    half_year,
    year
) SELECT
    date_dt,
    TO_CHAR(date_dt,'Day'),
    TO_CHAR(date_dt,'DY'),
    to_number(TRIM(LEADING '0' FROM TO_CHAR(date_dt,'D') ) ),
    to_number(TRIM(LEADING '0' FROM TO_CHAR(date_dt,'DD') ) ),
    to_number(TRIM(LEADING '0' FROM TO_CHAR(date_dt,'DDD') ) ),
    upper(TO_CHAR(date_dt,'YYYY') || '-' || TO_CHAR(date_dt,'Mon') ),
    TO_CHAR(date_dt,'Month'),
    TO_CHAR(date_dt,'Mon'),
    to_number(TRIM(LEADING '0' FROM TO_CHAR(date_dt,'MM') ) ),
    upper(TO_CHAR(date_dt,'YYYY')) || '-' || 'Q' || TO_CHAR(date_dt,'Q'),
    TO_CHAR(date_dt,'Q'),
    (CASE
     WHEN to_number(TO_CHAR(date_dt,'Q') ) <= 2 
     THEN 1
     ELSE 2 END),
    (CASE WHEN to_number(TO_CHAR(date_dt,'Q') ) <= 2 
     THEN TO_CHAR(date_dt,'YYYY') || '-' ||  'H' || 1 
     ELSE TO_CHAR(date_dt,'YYYY') || '-' || 'H' || 2 END),
     TO_CHAR(date_dt,'YYYY')
FROM
    (SELECT level n,
            TO_DATE('31/12/2016','DD/MM/YYYY') + numtodsinterval(level,'DAY') date_dt
     FROM dual
     CONNECT BY level <= 10950)
ORDER BY date_dt;
---------------------------------------------------------------------
BL_DM
=====================================================================
CREATE DDL OBJECTS FROM BL DM FOLDER
CREATE PACKAGES FOR DROP AND GRANTS FROM BL DM FOLDER
CREATE SEQUENCES FROM BL DM FOLDER
---------------------------------------------------------------------
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
---------------------------------------------------------------------
BL_CL_2ND
=====================================================================
-- Filling DM tables.
---------------------------------------------------------------------
BEGIN
  pkg_etl_insert_customers.merge_table_customers;
  pkg_etl_insert_employees.merge_table_employees;
  pkg_etl_insert_payment_methods.merge_table_payment_methods;
  pkg_etl_insert_products.merge_table_products;
  pkg_etl_insert_stores.merge_table_dim_stores;  
END;
/
---------------------------------------------------------------------
INSERT INTO bl_dm.dim_time_day (
    date_dt,
    week_day_full_name,
    week_day_short_name,
    day_number_of_week,
    day_number_of_month,
    day_number_of_year,
    month_year,
    month_full_name,
    month_short_name,
    month_number_of_year,
    quarter_year,
    quarter_number_of_year,
    half_year_number,
    half_year,
    year
) SELECT
    date_dt,
    TO_CHAR(date_dt,'Day'),
    TO_CHAR(date_dt,'DY'),
    to_number(TRIM(LEADING '0' FROM TO_CHAR(date_dt,'D') ) ),
    to_number(TRIM(LEADING '0' FROM TO_CHAR(date_dt,'DD') ) ),
    to_number(TRIM(LEADING '0' FROM TO_CHAR(date_dt,'DDD') ) ),
    upper(TO_CHAR(date_dt,'YYYY') || '-' || TO_CHAR(date_dt,'Mon') ),
    TO_CHAR(date_dt,'Month'),
    TO_CHAR(date_dt,'Mon'),
    to_number(TRIM(LEADING '0' FROM TO_CHAR(date_dt,'MM') ) ),
    upper(TO_CHAR(date_dt,'YYYY')) || '-' || 'Q' || TO_CHAR(date_dt,'Q'),
    TO_CHAR(date_dt,'Q'),
    (CASE
     WHEN to_number(TO_CHAR(date_dt,'Q') ) <= 2 
     THEN 1
     ELSE 2 END),
    (CASE WHEN to_number(TO_CHAR(date_dt,'Q') ) <= 2 
     THEN TO_CHAR(date_dt,'YYYY') || '-' ||  'H' || 1 
     ELSE TO_CHAR(date_dt,'YYYY') || '-' || 'H' || 2 END),
     TO_CHAR(date_dt,'YYYY')
FROM
    (SELECT level n,
            TO_DATE('31/12/2016','DD/MM/YYYY') + numtodsinterval(level,'DAY') date_dt
     FROM dual
     CONNECT BY level <= 10950)
ORDER BY date_dt;
COMMIT;
---------------------------------------------------------------------
BL_CL_1ST
=====================================================================
-- Generating fact and inserting fact into CE.
BEGIN
  pkg_etl_insert_receipts.insert_table_receipts;
  pkg_etl_insert_receipts.merge_table_ce_receipts;
END;
/
---------------------------------------------------------------------
BL_CL_2ND
=====================================================================
BEGIN
  pkg_etl_insert_retail_sales.insert_table_retail_sales;
  pkg_etl_insert_retail_sales.insert_table_fct_retail_sales;
END;
/
---------------------------------------------------------------------