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
                            ACCESS PARAMETERS (fields terminated BY ',' OPTIONALLY ENCLOSED BY '"')
                            LOCATION ('payment_methods.csv')
    )
    REJECT LIMIT UNLIMITED;