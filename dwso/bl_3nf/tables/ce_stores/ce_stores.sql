
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