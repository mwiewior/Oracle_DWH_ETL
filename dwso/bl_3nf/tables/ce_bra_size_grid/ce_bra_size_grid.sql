
CREATE TABLE ce_bra_size_grid
  (
    bra_size_id    NUMBER(10) NOT NULL,
    bra_size_srcid NUMBER(10) NOT NULL,
    bra_size_uk    VARCHAR2(10 BYTE),
    bra_size_usa   VARCHAR2(10 BYTE),
    bra_size_eu    VARCHAR2(10 BYTE),
    bra_size_fr    VARCHAR2(10 BYTE),
    bra_size_uie   VARCHAR2(10 BYTE),
    CONSTRAINT bra_size_id_pk PRIMARY KEY ( bra_size_id ),
    CONSTRAINT bra_size_srcid_unq UNIQUE ( bra_size_srcid )
  );