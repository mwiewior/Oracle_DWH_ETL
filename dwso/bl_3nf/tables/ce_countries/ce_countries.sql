
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