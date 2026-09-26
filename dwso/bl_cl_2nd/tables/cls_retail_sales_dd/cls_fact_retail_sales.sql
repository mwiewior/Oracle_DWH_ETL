
CREATE TABLE cls_fct_retail_sales_dd (
    receipt_id               NUMBER(38) NOT NULL,
    event_dt                 DATE NOT NULL,
    employee_surr_id         NUMBER(38) NOT NULL,
    customer_surr_id         NUMBER(38) NOT NULL,
    store_surr_id            NUMBER(38) NOT NULL,
    payment_method_surr_id   NUMBER(38) NOT NULL,
    product_surr_id          NUMBER(38) NOT NULL,
    tot_sale_sum             NUMBER(38) NOT NULL,
    tot_sale_amount          NUMBER(38) NOT NULL,
    insert_dt                DATE NOT NULL,
    update_dt                DATE NOT NULL
);