
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