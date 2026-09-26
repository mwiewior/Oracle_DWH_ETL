
CREATE TABLE ce_continents
  (
    continent_id    NUMBER ( 10 ) NOT NULL,
    continent_srcid NUMBER ( 10 ) NOT NULL,
    continent_desc  VARCHAR2 ( 200 CHAR ) NOT NULL,
    CONSTRAINT continent_id_pk PRIMARY KEY ( continent_id ),
    CONSTRAINT continent_srcid_unq UNIQUE ( continent_srcid )
  );
