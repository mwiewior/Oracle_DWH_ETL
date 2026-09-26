CREATE TABLE copy_dim_employees_scd
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
    CONSTRAINT copy_employee_surr_id_fk FOREIGN KEY (employee_surr_id)
    REFERENCES dim_employees_scd(employee_surr_id)
)
    PARTITION BY REFERENCE (copy_employee_surr_id_fk)
;
-- ====================================================================

SELECT partition_name, num_rows 
FROM user_tab_partitions
WHERE table_name = UPPER('dim_employees_scd');

-- ====================================================================

CREATE TABLE copy_dim_employees_scd_exch
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
    is_active        VARCHAR2 ( 200 CHAR ) NOT NULL
);

-- ====================================================================
INSERT INTO copy_dim_employees_scd
SELECT * FROM dim_employees_scd PARTITION (expert);

-- ====================================================================
INSERT INTO copy_dim_employees_scd_exch
SELECT * FROM dim_employees_scd PARTITION (novice);

-- ====================================================================
ALTER TABLE copy_dim_employees_scd EXCHANGE PARTITION novice WITH TABLE copy_dim_employees_scd_exch;

-- ====================================================================

SELECT employee_surr_id, position_grade FROM copy_dim_employees_scd;

SELECT employee_surr_id, position_grade FROM copy_dim_employees_scd_exch;
-- ====================================================================
INSERT INTO copy_dim_employees_scd_exch
SELECT * FROM dim_employees_scd PARTITION (experienced);

-- ====================================================================

SELECT employee_surr_id, position_grade FROM copy_dim_employees_scd_exch;
-- ====================================================================
ALTER TABLE copy_dim_employees_scd EXCHANGE PARTITION experienced WITH TABLE copy_dim_employees_scd_exch;

-- ====================================================================

SELECT employee_surr_id, position_grade FROM copy_dim_employees_scd
WHERE position_grade = 'experienced';

SELECT employee_surr_id, position_grade FROM copy_dim_employees_scd_exch;
-- ====================================================================