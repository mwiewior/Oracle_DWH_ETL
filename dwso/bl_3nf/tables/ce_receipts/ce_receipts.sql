
CREATE TABLE ce_receipts
  (
    receipt_id           NUMBER(38) NOT NULL,
    receipt_dt           DATE NOT NULL,
    store_id             NUMBER(38) NOT NULL,
    employee_id          NUMBER(38) NOT NULL,
    customer_id          NUMBER(38) NOT NULL,
    payment_method_id    NUMBER(38) NOT NULL,
    product_detail_id    NUMBER(38) NOT NULL,
    receipt_sum_usd      NUMBER(38,2) NOT NULL,
    insert_dt            DATE DEFAULT SYSDATE,
    CONSTRAINT rc_store_id_fk FOREIGN KEY ( store_id ) 
    REFERENCES ce_stores ( store_id ),
    CONSTRAINT rc_employee_id_fk FOREIGN KEY ( employee_id ) 
    REFERENCES ce_employees ( employee_id ),
    CONSTRAINT rc_customer_id_fk FOREIGN KEY ( customer_id ) 
    REFERENCES ce_customers ( customer_id ),
    CONSTRAINT payment_method_id_fk FOREIGN KEY ( payment_method_id ) 
    REFERENCES ce_payment_methods ( payment_method_id ),
    CONSTRAINT product_detail_id_fk FOREIGN KEY ( product_detail_id ) 
    REFERENCES ce_product_details ( product_details_id )
  );