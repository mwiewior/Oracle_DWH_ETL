
CREATE TABLE cls_employees
  (
    employee_id       VARCHAR2 ( 100 CHAR ) NOT NULL,
    first_name        VARCHAR2 ( 100 CHAR ) NOT NULL,
    last_name         VARCHAR2 ( 100 CHAR ) NOT NULL,
    store_id          VARCHAR2 ( 100 CHAR ) NOT NULL,
    position_name     VARCHAR2 ( 100 CHAR ) NOT NULL,
    position_grade_id VARCHAR2 ( 100 CHAR ) NOT NULL,
    work_experience   NUMBER ( 38 ) NOT NULL,
    email             VARCHAR2 ( 100 CHAR ) NOT NULL,
    phone             VARCHAR2 ( 100 CHAR ) NOT NULL,
    start_dt          DATE DEFAULT '01-JAN-1990',
    end_dt            DATE DEFAULT '31-DEC-9999',
    is_active         VARCHAR2 ( 200 CHAR ) NOT NULL
  );