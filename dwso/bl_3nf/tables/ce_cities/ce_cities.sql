
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