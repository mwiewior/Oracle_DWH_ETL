CREATE OR REPLACE PACKAGE pkg_etl_insert_employees
AUTHID CURRENT_USER
AS
  PROCEDURE insert_table_employees;
  PROCEDURE insert_table_position_grade;
  PROCEDURE merge_table_ce_position_grades;
  PROCEDURE merge_table_employees_first;
  PROCEDURE merge_table_employees_second;
						
END pkg_etl_insert_employees;
/

CREATE OR REPLACE PACKAGE BODY pkg_etl_insert_employees
AS
---------------------------------------------------  
PROCEDURE insert_table_employees
IS
BEGIN
  EXECUTE IMMEDIATE ('TRUNCATE TABLE cls_employees');
  INSERT INTO cls_employees (
                              employee_id,
                              first_name,
                              last_name,
                              store_id,
                              position_name,
                              position_grade_id,
                              work_experience,
                              email,
                              phone,
                              start_dt,
                              end_dt,
                              is_active
                            )
  SELECT employee_code AS employee_id,
         first_name,
         last_name,
         store_srcid,
         position_name,
         cpg.position_grade_id,
         we.work_experience,
         email,
         phone,
         start_dt,
         end_dt,
         is_active
  FROM wrk_employees we left join cls_position_grade cpg
                               on we.position_grade_srcid = cpg.position_grade;

  COMMIT;
  
EXCEPTION
  WHEN OTHERS THEN
  RAISE;

END insert_table_employees;
---------------------------------------------------  
PROCEDURE insert_table_position_grade
IS
BEGIN
  EXECUTE IMMEDIATE ('TRUNCATE TABLE cls_position_grade');
  INSERT INTO cls_position_grade (
                                   position_grade_id,
                                   position_grade,
                                   work_experience
                            )
  SELECT work_experience || ' ' || SUBSTR(position_grade,1,2) as position_grade_id,
         position_grade,
         work_experience
  FROM   (
  SELECT DISTINCT position_grade_srcid AS position_grade,
         (case when position_grade_srcid = 'novice' then 3
               when position_grade_srcid = 'middle' then 5
               when position_grade_srcid = 'experienced' then 10
               when position_grade_srcid = 'expert' then 15
          end) as work_experience
  FROM wrk_employees
         );

  COMMIT;
  
EXCEPTION
  WHEN OTHERS THEN
  RAISE;

END insert_table_position_grade;
---------------------------------------------------  
---------------------------------------------------
PROCEDURE merge_table_ce_position_grades
IS
BEGIN

MERGE INTO bl_3nf.ce_position_grades t USING
    ( SELECT position_grade_id,
             position_grade,
             work_experience
      FROM   cls_position_grade
    MINUS
      SELECT position_grade_srcid AS position_grade_id,
             position_grade_desc  AS position_grade,
             work_experience
      FROM   bl_3nf.ce_position_grades
    ) c ON ( c.position_grade = t.position_grade_desc
       AND   t.position_grade_srcid = c.position_grade_id
       AND   c.work_experience = t.work_experience)
    WHEN NOT matched THEN
    INSERT
      (
        position_grade_id ,
        position_grade_srcid ,
        position_grade_desc,
        work_experience
      )
      VALUES
      (
        bl_3nf.ce_position_grades_seq.NEXTVAL,
        c.position_grade_id ,
        c.position_grade,
        c.work_experience
      ) ;
    COMMIT;
EXCEPTION
WHEN OTHERS THEN
    RAISE;
END merge_table_ce_position_grades;
---------------------------------------------------
PROCEDURE merge_table_employees_first
IS
BEGIN

MERGE INTO bl_3nf.ce_employees t USING
    ( SELECT employee_id,
             first_name,
             last_name,
             store_id,
             position_name,
             position_grade_id,
             work_experience,
             email,
             phone,
             start_dt,
             end_dt,
             is_active
      FROM   cls_employees
    MINUS
      SELECT 
             employee_srcid AS employee_id,
             first_name,
             last_name,
             store_srcid AS store_id,
             position_name,
             position_grade_srcid AS position_grade_id,
             work_experience,
             email,
             phone,
             start_dt,
             end_dt,
             is_active
      FROM   bl_3nf.ce_employees
    ) c ON ( c.employee_id = t.employee_srcid
       AND   c.first_name = t.first_name
       AND   c.last_name = t.last_name
       AND   c.position_name = t.position_name
       AND   t.position_grade_srcid = c.position_grade_id
       AND   c.work_experience = t.work_experience
       AND   t.store_srcid = c.store_id
       AND   c.email = t.email
       AND   c.phone = t.phone
       )
    WHEN MATCHED THEN
    UPDATE SET 
               t.end_dt  = c.end_dt,
               t.is_active = c.is_active
    WHEN NOT matched THEN
    INSERT
      (
        employee_id,
        employee_srcid,
        first_name,
        last_name,
        store_srcid,
        position_name,
        position_grade_srcid,
        work_experience,
        email,
        phone,
        start_dt,
        end_dt,
        is_active
      )
      VALUES
      (
        bl_3nf.ce_employees_seq.NEXTVAL,
        c.employee_id,
        c.first_name,
        c.last_name,
        c.store_id,
        c.position_name,
        c.position_grade_id,
        c.work_experience,
        c.email,
        c.phone,
        c.start_dt,
        c.end_dt,
        c.is_active
      ) ;
    COMMIT;
EXCEPTION
WHEN OTHERS THEN
    RAISE;
END merge_table_employees_first;
---------------------------------------------------
PROCEDURE merge_table_employees_second
IS
BEGIN

MERGE INTO bl_3nf.ce_employees t USING
    ( SELECT employee_id,
             first_name,
             last_name,
             store_id,
             position_name,
             position_grade_id,
             work_experience,
             email,
             phone,
             start_dt,
             end_dt,
             is_active
      FROM   cls_employees
    MINUS
      SELECT 
             employee_srcid AS employee_id,
             first_name,
             last_name,
             store_srcid AS store_id,
             position_name,
             position_grade_srcid AS position_grade_id,
             work_experience,
             email,
             phone,
             start_dt,
             end_dt,
             is_active
      FROM   bl_3nf.ce_employees
    ) c ON ( c.employee_id = t.employee_srcid
       AND   c.first_name = t.first_name
       AND   c.last_name = t.last_name
       AND   c.position_name = t.position_name
       AND   t.position_grade_srcid = c.position_grade_id
       AND   c.work_experience = t.work_experience
       AND   t.store_srcid = c.store_id
       AND   c.email = t.email
       AND   c.phone = t.phone
       )
    WHEN MATCHED THEN
    UPDATE SET 
               t.end_dt  = c.end_dt,
               t.is_active = c.is_active
    WHEN NOT matched THEN
    INSERT
      (
        employee_id,
        employee_srcid,
        first_name,
        last_name,
        store_srcid,
        position_name,
        position_grade_srcid,
        work_experience,
        email,
        phone,
        start_dt,
        end_dt,
        is_active
      )
      VALUES
      (
        bl_3nf.ce_employees_seq.NEXTVAL,
        c.employee_id,
        c.first_name,
        c.last_name,
        c.store_id,
        c.position_name,
        c.position_grade_id,
        c.work_experience,
        c.email,
        c.phone,
        sysdate,
        c.end_dt,
        c.is_active
      ) ;
    COMMIT;
EXCEPTION
WHEN OTHERS THEN
    RAISE;
END merge_table_employees_second;
---------------------------------------------------
END pkg_etl_insert_employees;
/