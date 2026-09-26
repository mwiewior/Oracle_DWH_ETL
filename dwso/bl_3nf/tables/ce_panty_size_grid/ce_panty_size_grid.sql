
CREATE TABLE ce_panty_size_grid
  (
    panty_size_id    NUMBER(10) NOT NULL,
    panty_size_srcid NUMBER(10) NOT NULL,
    panty_size_uk    VARCHAR2(10 BYTE),
    panty_size_usa   VARCHAR2(10 BYTE),
    panty_size_eu    VARCHAR2(10 BYTE),
    panty_size_fr    VARCHAR2(10 BYTE),
    panty_size_uie   VARCHAR2(10 BYTE),
    CONSTRAINT panty_size_id_pk PRIMARY KEY ( panty_size_id ),
    CONSTRAINT panty_size_srcid_unq UNIQUE ( panty_size_srcid )
  );