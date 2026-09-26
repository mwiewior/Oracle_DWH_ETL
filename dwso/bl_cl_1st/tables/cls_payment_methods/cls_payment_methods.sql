
CREATE TABLE cls_payment_methods
  (
    payment_method_id VARCHAR2 ( 200 CHAR ) NOT NULL,
    payment_method    VARCHAR2 ( 200 CHAR ) NOT NULL,
    bank              VARCHAR2 ( 200 CHAR ) NOT NULL,
    start_dt          DATE DEFAULT '01-JAN-1990',
    end_dt            DATE DEFAULT '31-DEC-9999',
    is_active         VARCHAR2 ( 200 CHAR ) NOT NULL
  );