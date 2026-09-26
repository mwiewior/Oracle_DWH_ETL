
CREATE TABLE ce_age_categories
  (
    age_category_id    NUMBER(10) NOT NULL,
    age_category_srcid NUMBER(10) NOT NULL,
    age_category_desc  VARCHAR2(40 BYTE) NOT NULL,
    CONSTRAINT age_category_id_pk PRIMARY KEY ( age_category_id ),
    CONSTRAINT age_category_srcid_unq UNIQUE ( age_category_srcid )
  );