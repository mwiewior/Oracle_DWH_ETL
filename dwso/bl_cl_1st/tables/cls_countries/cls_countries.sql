
CREATE TABLE cls_countries
  (
    country_id   NUMBER ( 10 ) NOT NULL,
    country_desc VARCHAR2 ( 200 CHAR ) NOT NULL,
    country_code VARCHAR2 ( 3 ) Default 'NN',
    region_id    NUMBER ( 10 ) NOT NULL
  );