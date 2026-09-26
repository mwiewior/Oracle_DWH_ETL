
CREATE TABLE ce_employees
  (
    employee_id          NUMBER(10) NOT NULL,
    employee_srcid       VARCHAR2(40 BYTE) NOT NULL,
    first_name           VARCHAR2(40 BYTE) NOT NULL,
    last_name            VARCHAR2(40 BYTE) NOT NULL,
    store_srcid          VARCHAR2(40 BYTE) NOT NULL,
    position_name        VARCHAR2(40 BYTE) NOT NULL,
    position_grade_srcid VARCHAR2(40 BYTE) NOT NULL,
    work_experience      NUMBER(10) NOT NULL,
    email                VARCHAR2(50 BYTE) NOT NULL,
    phone                VARCHAR2(40 BYTE) NOT NULL,
    start_dt             DATE DEFAULT '01-JAN-1990',
    end_dt               DATE DEFAULT '31-DEC-9999',
    is_active            VARCHAR2 ( 200 CHAR ) NOT NULL,
    CONSTRAINT employee_id_pk PRIMARY KEY ( employee_id ),
    CONSTRAINT employee_srcid_unq UNIQUE ( employee_srcid ),
    CONSTRAINT position_grade_srcid_fk FOREIGN KEY ( position_grade_srcid ) 
    REFERENCES ce_position_grades ( position_grade_srcid ),
    CONSTRAINT store_srcid_fk FOREIGN KEY ( store_srcid ) 
    REFERENCES ce_stores ( store_srcid )
  );