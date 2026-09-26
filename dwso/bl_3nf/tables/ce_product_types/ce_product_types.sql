
CREATE TABLE ce_product_types
  (
    product_type_id    NUMBER ( 38 ) NOT NULL,
    product_type_srcid VARCHAR2 ( 200 CHAR ) NOT NULL,
    product_type_desc  VARCHAR2 ( 200 CHAR ) NOT NULL,
    update_dt          DATE DEFAULT SYSDATE,
    CONSTRAINT product_type_id_pk PRIMARY KEY ( product_type_id ),
    CONSTRAINT product_type_srcid_unq UNIQUE ( product_type_srcid )
  );