
CREATE TABLE fct_retail_sales_dd (
    sale_id                  NUMBER(38) NOT NULL,
    receipt_id               NUMBER(38) NOT NULL,
    event_dt                 DATE NOT NULL,
    employee_surr_id         NUMBER(38) NOT NULL,
    customer_surr_id         NUMBER(38) NOT NULL,
    store_surr_id            NUMBER(38) NOT NULL,
    payment_method_id        NUMBER(38) NOT NULL,
    product_surr_id          NUMBER(38) NOT NULL,
    tot_sale_sum             NUMBER(38) NOT NULL,
    tot_sale_amount          NUMBER(38) NOT NULL,
    insert_dt                DATE NOT NULL,
    update_dt                DATE NOT NULL,
    CONSTRAINT product_surr_id_fk FOREIGN KEY (product_surr_id)
    REFERENCES dim_products_scd (product_surr_id),
    CONSTRAINT employee_surr_id_fk FOREIGN KEY (employee_surr_id)
    REFERENCES dim_employees_scd (employee_surr_id),
    CONSTRAINT customer_surr_id_fk FOREIGN KEY (customer_surr_id)
    REFERENCES dim_customers_scd (customer_surr_id),
    CONSTRAINT payment_method_surr_id_fk FOREIGN KEY (payment_method_id)
    REFERENCES dim_payment_methods_scd (payment_method_id),
    CONSTRAINT store_id_fk FOREIGN KEY (store_surr_id)
    REFERENCES dim_stores_scd (store_surr_id),
    CONSTRAINT event_dt_fk FOREIGN KEY (event_dt)
    REFERENCES dim_time_day (date_dt)
)
    PARTITION BY RANGE (event_dt) 
  ( PARTITION before_2017 VALUES LESS THAN (TO_DATE('1-1-2017', 'DD-MM-YYYY')),
    PARTITION year_2017 VALUES LESS THAN (TO_DATE('1-1-2018', 'DD-MM-YYYY')),
    PARTITION year_2018 VALUES LESS THAN (TO_DATE('1-1-2019', 'DD-MM-YYYY')),
    PARTITION year_2019 VALUES LESS THAN (TO_DATE('1-1-2020', 'DD-MM-YYYY')),
    PARTITION year_2020 VALUES LESS THAN (TO_DATE('1-1-2021', 'DD-MM-YYYY')),
    PARTITION year_2021 VALUES LESS THAN (TO_DATE('1-1-2022', 'DD-MM-YYYY')),
    PARTITION year_2022 VALUES LESS THAN (TO_DATE('1-1-2023', 'DD-MM-YYYY')),
    PARTITION year_2023 VALUES LESS THAN (TO_DATE('1-1-2024', 'DD-MM-YYYY')),
    PARTITION year_2024 VALUES LESS THAN (TO_DATE('1-1-2025', 'DD-MM-YYYY')),
    PARTITION year_2025 VALUES LESS THAN (TO_DATE('1-1-2026', 'DD-MM-YYYY')),
    PARTITION after_2025 VALUES LESS THAN (MAXVALUE)
  );