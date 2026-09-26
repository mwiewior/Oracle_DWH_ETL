
CREATE TABLE dim_stores_scd
  (
    store_surr_id NUMBER(38) NOT NULL,
    store_id      NUMBER(38) NOT NULL,
    store_desc    VARCHAR2(50 BYTE) NOT NULL,
    phone         VARCHAR2(50 BYTE) NOT NULL,
    address       VARCHAR2(50 BYTE) NOT NULL,
    city          VARCHAR2(100 BYTE) NOT NULL,
    country       VARCHAR2(100 BYTE) NOT NULL,
    region        VARCHAR2(100 BYTE) NOT NULL,
    insert_dt     DATE DEFAULT '01-JAN-1990',
    update_dt     DATE DEFAULT SYSDATE,
    CONSTRAINT store_surr_id_pk PRIMARY KEY (store_surr_id)
  )
    PARTITION BY LIST (region)
  (
    PARTITION America VALUES ('Central America', 'South America', 'Northern America'),
    PARTITION Asia VALUES ('Central Asia', 'Western Asia', 'South-Eastern Asia', 'Eastern Asia'),
    PARTITION Europe VALUES ('Western Europe', 'Southern Europe', 'Northern Europe', 'Eastern Europe'),
    PARTITION Africa VALUES ('Southern Africa', 'Northern Africa', 'Eastern Africa', 'Middle Africa', 'Western Africa'),
    PARTITION Australia VALUES ('Australia and New Zealand'),
    PARTITION Other_regions VALUES ('Micronesia', 'Polynesia', 'Melanesia', 'Caribbean')   
  ) 
;