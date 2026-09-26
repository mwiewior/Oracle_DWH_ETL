
CREATE TABLE dim_customers_scd (
    customer_surr_id   NUMBER(38) NOT NULL,
    customer_id        NUMBER(38) NOT NULL,
    first_name         VARCHAR2(100 BYTE) NOT NULL,
    last_name          VARCHAR2(100 BYTE) NOT NULL,
    age                NUMBER(38) NOT NULL,
    age_category       VARCHAR2(100 BYTE) NOT NULL,
    email              VARCHAR2(100 BYTE) NOT NULL,
    phone              VARCHAR2(100 BYTE) NOT NULL,
    address            VARCHAR2(100 BYTE) NOT NULL,
    city               VARCHAR2(100 BYTE) NOT NULL,
    country            VARCHAR2(100 BYTE) NOT NULL,
    region             VARCHAR2(100 BYTE) NOT NULL,
    start_dt           DATE DEFAULT '01-JAN-1990',
    end_dt             DATE DEFAULT '31-DEC-9999',
    is_active          VARCHAR2 ( 200 CHAR ) NOT NULL,
    CONSTRAINT customer_surr_id_pk PRIMARY KEY (customer_surr_id)
)
    PARTITION BY RANGE (start_dt) 
      SUBPARTITION BY LIST (region)
  ( PARTITION before_2017 VALUES LESS THAN (TO_DATE('1-1-2017', 'DD-MM-YYYY'))
         (SUBPARTITION America_b VALUES ('Central America', 'South America', 'Northern America'),
          SUBPARTITION Asia_b VALUES ('Central Asia', 'Western Asia', 'South-Eastern Asia', 'Eastern Asia'),
          SUBPARTITION Europe_b VALUES ('Western Europe', 'Southern Europe', 'Northern Europe', 'Eastern Europe'),
          SUBPARTITION Africa_b VALUES ('Southern Africa', 'Northern Africa', 'Eastern Africa', 'Middle Africa', 'Western Africa'),
          SUBPARTITION Australia_b VALUES ('Australia and New Zealand'),
          SUBPARTITION Other_regions_b VALUES ('Micronesia', 'Polynesia', 'Melanesia', 'Caribbean')   
),
    PARTITION year_2017 VALUES LESS THAN (TO_DATE('1-1-2018', 'DD-MM-YYYY'))
         (SUBPARTITION America_17 VALUES ('Central America', 'South America', 'Northern America'),
          SUBPARTITION Asia_17 VALUES ('Central Asia', 'Western Asia', 'South-Eastern Asia', 'Eastern Asia'),
          SUBPARTITION Europe_17 VALUES ('Western Europe', 'Southern Europe', 'Northern Europe', 'Eastern Europe'),
          SUBPARTITION Africa_17 VALUES ('Southern Africa', 'Northern Africa', 'Eastern Africa', 'Middle Africa', 'Western Africa'),
          SUBPARTITION Australia_17 VALUES ('Australia and New Zealand'),
          SUBPARTITION Other_regions_17 VALUES ('Micronesia', 'Polynesia', 'Melanesia', 'Caribbean')   
),
    PARTITION year_2018 VALUES LESS THAN (TO_DATE('1-1-2019', 'DD-MM-YYYY'))
         (SUBPARTITION America_18 VALUES ('Central America', 'South America', 'Northern America'),
          SUBPARTITION Asia_18 VALUES ('Central Asia', 'Western Asia', 'South-Eastern Asia', 'Eastern Asia'),
          SUBPARTITION Europe_18 VALUES ('Western Europe', 'Southern Europe', 'Northern Europe', 'Eastern Europe'),
          SUBPARTITION Africa_18 VALUES ('Southern Africa', 'Northern Africa', 'Eastern Africa', 'Middle Africa', 'Western Africa'),
          SUBPARTITION Australia_18 VALUES ('Australia and New Zealand'),
          SUBPARTITION Other_region_18 VALUES ('Micronesia', 'Polynesia', 'Melanesia', 'Caribbean')   
),
    PARTITION year_2019 VALUES LESS THAN (TO_DATE('1-1-2020', 'DD-MM-YYYY'))
         (SUBPARTITION America_19 VALUES ('Central America', 'South America', 'Northern America'),
          SUBPARTITION Asia_19 VALUES ('Central Asia', 'Western Asia', 'South-Eastern Asia', 'Eastern Asia'),
          SUBPARTITION Europe_19 VALUES ('Western Europe', 'Southern Europe', 'Northern Europe', 'Eastern Europe'),
          SUBPARTITION Africa_19 VALUES ('Southern Africa', 'Northern Africa', 'Eastern Africa', 'Middle Africa', 'Western Africa'),
          SUBPARTITION Australia_19 VALUES ('Australia and New Zealand'),
          SUBPARTITION Other_regions_19 VALUES ('Micronesia', 'Polynesia', 'Melanesia', 'Caribbean')   
),
    PARTITION year_2020 VALUES LESS THAN (TO_DATE('1-1-2021', 'DD-MM-YYYY'))
         (SUBPARTITION America_20 VALUES ('Central America', 'South America', 'Northern America'),
          SUBPARTITION Asia_20 VALUES ('Central Asia', 'Western Asia', 'South-Eastern Asia', 'Eastern Asia'),
          SUBPARTITION Europe_20 VALUES ('Western Europe', 'Southern Europe', 'Northern Europe', 'Eastern Europe'),
          SUBPARTITION Africa_20 VALUES ('Southern Africa', 'Northern Africa', 'Eastern Africa', 'Middle Africa', 'Western Africa'),
          SUBPARTITION Australia_20 VALUES ('Australia and New Zealand'),
          SUBPARTITION Other_regions_20 VALUES ('Micronesia', 'Polynesia', 'Melanesia', 'Caribbean')   
),
    PARTITION year_2021 VALUES LESS THAN (TO_DATE('1-1-2022', 'DD-MM-YYYY'))
         (SUBPARTITION America_21 VALUES ('Central America', 'South America', 'Northern America'),
          SUBPARTITION Asia_21 VALUES ('Central Asia', 'Western Asia', 'South-Eastern Asia', 'Eastern Asia'),
          SUBPARTITION Europe_21 VALUES ('Western Europe', 'Southern Europe', 'Northern Europe', 'Eastern Europe'),
          SUBPARTITION Africa_21 VALUES ('Southern Africa', 'Northern Africa', 'Eastern Africa', 'Middle Africa', 'Western Africa'),
          SUBPARTITION Australia_21 VALUES ('Australia and New Zealand'),
          SUBPARTITION Other_regions_21 VALUES ('Micronesia', 'Polynesia', 'Melanesia', 'Caribbean')   
),
    PARTITION year_2022 VALUES LESS THAN (TO_DATE('1-1-2023', 'DD-MM-YYYY'))
         (SUBPARTITION America_22 VALUES ('Central America', 'South America', 'Northern America'),
          SUBPARTITION Asia_22 VALUES ('Central Asia', 'Western Asia', 'South-Eastern Asia', 'Eastern Asia'),
          SUBPARTITION Europe_22 VALUES ('Western Europe', 'Southern Europe', 'Northern Europe', 'Eastern Europe'),
          SUBPARTITION Africa_22 VALUES ('Southern Africa', 'Northern Africa', 'Eastern Africa', 'Middle Africa', 'Western Africa'),
          SUBPARTITION Australia_22 VALUES ('Australia and New Zealand'),
          SUBPARTITION Other_regions_22 VALUES ('Micronesia', 'Polynesia', 'Melanesia', 'Caribbean')   
),
    PARTITION year_2023 VALUES LESS THAN (TO_DATE('1-1-2024', 'DD-MM-YYYY'))
         (SUBPARTITION America_23 VALUES ('Central America', 'South America', 'Northern America'),
          SUBPARTITION Asia_23 VALUES ('Central Asia', 'Western Asia', 'South-Eastern Asia', 'Eastern Asia'),
          SUBPARTITION Europe_23 VALUES ('Western Europe', 'Southern Europe', 'Northern Europe', 'Eastern Europe'),
          SUBPARTITION Africa_23 VALUES ('Southern Africa', 'Northern Africa', 'Eastern Africa', 'Middle Africa', 'Western Africa'),
          SUBPARTITION Australia_23 VALUES ('Australia and New Zealand'),
          SUBPARTITION Other_regions_23 VALUES ('Micronesia', 'Polynesia', 'Melanesia', 'Caribbean')   
),
    PARTITION year_2024 VALUES LESS THAN (TO_DATE('1-1-2025', 'DD-MM-YYYY'))
         (SUBPARTITION America_24 VALUES ('Central America', 'South America', 'Northern America'),
          SUBPARTITION Asia_24 VALUES ('Central Asia', 'Western Asia', 'South-Eastern Asia', 'Eastern Asia'),
          SUBPARTITION Europe_24 VALUES ('Western Europe', 'Southern Europe', 'Northern Europe', 'Eastern Europe'),
          SUBPARTITION Africa_24 VALUES ('Southern Africa', 'Northern Africa', 'Eastern Africa', 'Middle Africa', 'Western Africa'),
          SUBPARTITION Australia_24 VALUES ('Australia and New Zealand'),
          SUBPARTITION Other_regions_24 VALUES ('Micronesia', 'Polynesia', 'Melanesia', 'Caribbean')   
),
    PARTITION year_2025 VALUES LESS THAN (TO_DATE('1-1-2026', 'DD-MM-YYYY'))
         (SUBPARTITION America_25 VALUES ('Central America', 'South America', 'Northern America'),
          SUBPARTITION Asia_25 VALUES ('Central Asia', 'Western Asia', 'South-Eastern Asia', 'Eastern Asia'),
          SUBPARTITION Europe_25 VALUES ('Western Europe', 'Southern Europe', 'Northern Europe', 'Eastern Europe'),
          SUBPARTITION Africa_25 VALUES ('Southern Africa', 'Northern Africa', 'Eastern Africa', 'Middle Africa', 'Western Africa'),
          SUBPARTITION Australia_25 VALUES ('Australia and New Zealand'),
          SUBPARTITION Other_regions_25 VALUES ('Micronesia', 'Polynesia', 'Melanesia', 'Caribbean')   
),
    PARTITION after_2025 VALUES LESS THAN (MAXVALUE)
         (SUBPARTITION America_a VALUES ('Central America', 'South America', 'Northern America'),
          SUBPARTITION Asia_a VALUES ('Central Asia', 'Western Asia', 'South-Eastern Asia', 'Eastern Asia'),
          SUBPARTITION Europe_a VALUES ('Western Europe', 'Southern Europe', 'Northern Europe', 'Eastern Europe'),
          SUBPARTITION Africa_a VALUES ('Southern Africa', 'Northern Africa', 'Eastern Africa', 'Middle Africa', 'Western Africa'),
          SUBPARTITION Australia_a VALUES ('Australia and New Zealand'),
          SUBPARTITION Other_regions_a VALUES ('Micronesia', 'Polynesia', 'Melanesia', 'Caribbean')   
)
  );