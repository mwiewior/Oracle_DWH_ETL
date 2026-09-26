
CREATE TABLE dim_employees_scd
  (
    employee_surr_id NUMBER(38) NOT NULL,
    employee_id      NUMBER(38) NOT NULL,
    first_name       VARCHAR2(50 BYTE) NOT NULL,
    last_name        VARCHAR2(50 BYTE) NOT NULL,
    store_number     VARCHAR2(50 BYTE) NOT NULL,
    position_name    VARCHAR2(50 BYTE) NOT NULL,
    position_grade   VARCHAR2(50 BYTE) NOT NULL,
    work_experience  NUMBER(10) NOT NULL,
    email            VARCHAR2(50 BYTE) NOT NULL,
    phone            VARCHAR2(50 BYTE) NOT NULL,
    start_dt         DATE DEFAULT '01-JAN-1990',
    end_dt           DATE DEFAULT '31-DEC-9999',
    is_active        VARCHAR2 ( 200 CHAR ) NOT NULL,
    CONSTRAINT employee_surr_id_pk PRIMARY KEY (employee_surr_id)
)
    PARTITION BY LIST (position_grade)
(
    PARTITION novice VALUES ('novice'),
    PARTITION middle VALUES ('middle'),
    PARTITION experienced VALUES ('experienced'),
    PARTITION expert VALUES ('expert'))
;