
CREATE TABLE cls_collections
  (
    collection_id   VARCHAR2 ( 200 CHAR ) NOT NULL,
    collection_name VARCHAR2 ( 200 CHAR ) NOT NULL,
    start_dt        DATE DEFAULT '01-JAN-1990',
    end_dt          DATE DEFAULT '31-DEC-9999',
    is_active       VARCHAR2 ( 200 CHAR ) NOT NULL
  );