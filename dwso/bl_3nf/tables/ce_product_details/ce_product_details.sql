
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