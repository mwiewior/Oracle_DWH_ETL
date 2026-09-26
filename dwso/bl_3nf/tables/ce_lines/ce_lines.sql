
CREATE TABLE ce_lines
  (
    line_id          NUMBER(10) NOT NULL,
    line_srcid       VARCHAR2(50 BYTE) NOT NULL,
    line_desc        VARCHAR2(50 BYTE) NOT NULL,
    collection_srcid VARCHAR2(50 BYTE) NOT NULL,
    update_dt        DATE DEFAULT SYSDATE,
    CONSTRAINT line_id_pk PRIMARY KEY ( line_id ),
    CONSTRAINT line_srcid_unq UNIQUE ( line_srcid ),
    CONSTRAINT collection_srcid_fk FOREIGN KEY ( collection_srcid ) 
    REFERENCES ce_collections ( collection_srcid )
  );
  