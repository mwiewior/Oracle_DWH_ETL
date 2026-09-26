
CREATE TABLE ce_collections
  (
    collection_id    NUMBER ( 38 ) NOT NULL,
    collection_srcid VARCHAR2 ( 200 CHAR ) NOT NULL,
    collection_desc  VARCHAR2 ( 200 CHAR ) NOT NULL,
    update_dt        DATE DEFAULT SYSDATE,
    CONSTRAINT collection_id_pk PRIMARY KEY ( collection_id ),
    CONSTRAINT collection_srcid_unq UNIQUE ( collection_srcid )
  );