
CREATE TABLE wrk_employees
(
 employee_code        VARCHAR2 ( 100 CHAR ),
 first_name           VARCHAR2 ( 100 CHAR ),
 last_name            VARCHAR2 ( 100 CHAR ),
 age                  NUMBER ( 38 ),
 store_srcid          VARCHAR2 ( 100 CHAR ),
 position_name        VARCHAR2 ( 100 CHAR ),
 position_grade_srcid VARCHAR2 ( 100 CHAR ),
 work_experience      NUMBER ( 38 ),
 email                VARCHAR2 ( 100 CHAR ),
 phone                VARCHAR2 ( 100 CHAR ),
 personal_address     VARCHAR2 ( 100 CHAR ),
 currency             VARCHAR2 ( 100 CHAR ),
 currency_code        VARCHAR2 ( 100 CHAR ),
 month_salary         NUMBER ( 38,3 ),
 credit_card          NUMBER ( 38 ),
 start_dt             DATE,
 end_dt               DATE,
 is_active            VARCHAR2 ( 100 CHAR )
);