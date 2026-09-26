
CREATE TABLE ce_position_grades
  (
    position_grade_id    NUMBER(10) NOT NULL,
    position_grade_srcid VARCHAR2(40 BYTE) NOT NULL,
    position_grade_desc  VARCHAR2(40 BYTE) NOT NULL,
    work_experience      NUMBER(10) NOT NULL,
    CONSTRAINT position_grade_id_pk PRIMARY KEY ( position_grade_id ),
    CONSTRAINT position_grade_srcid_unq UNIQUE ( position_grade_srcid )
  );