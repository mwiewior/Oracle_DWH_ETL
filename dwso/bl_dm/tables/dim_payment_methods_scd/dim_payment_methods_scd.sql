
CREATE TABLE dim_payment_methods_scd
  (
    payment_method_surr_id NUMBER(38) NOT NULL,
    payment_method_id      NUMBER(38) NOT NULL,
    payment_method_desc    VARCHAR2(40 BYTE) NOT NULL,
    bank_name              VARCHAR2(40 BYTE),
    start_dt               DATE DEFAULT '01-JAN-1990',
    end_dt                 DATE DEFAULT '31-DEC-9999',
    is_active              VARCHAR2 ( 200 CHAR ) NOT NULL,
    CONSTRAINT payment_method_id_pk PRIMARY KEY (payment_method_id)
  );