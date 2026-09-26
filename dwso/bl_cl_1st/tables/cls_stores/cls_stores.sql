
CREATE TABLE cls_stores
  (
    store_id     VARCHAR2 ( 200 CHAR ) NOT NULL,
    store_code   VARCHAR2 ( 200 CHAR ) NOT NULL,
    store_name   VARCHAR2 ( 200 CHAR ) NOT NULL,
    manager_id   VARCHAR2 ( 200 CHAR ) NOT NULL,
    phone        VARCHAR2 ( 200 CHAR ) NOT NULL,
    address      VARCHAR2 ( 200 CHAR ) NOT NULL,
    city_id      VARCHAR2 ( 200 CHAR ) NOT NULL,
    insert_dt    DATE DEFAULT '01-JAN-1990',
    update_dt    DATE DEFAULT '31-DEC-9999'
  );