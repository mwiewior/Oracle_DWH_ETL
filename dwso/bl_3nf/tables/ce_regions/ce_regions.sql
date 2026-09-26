
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