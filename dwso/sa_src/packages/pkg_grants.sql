CREATE OR REPLACE PACKAGE pkg_grants
AUTHID CURRENT_USER
AS
  PROCEDURE user_grant (grant_name  IN VARCHAR2,
						            schema_name IN VARCHAR2,
                        object_name IN VARCHAR2,
                        user_name   IN VARCHAR2);
						
  PROCEDURE user_grant (grant_name IN VARCHAR2,
                        user_name  IN VARCHAR2,
                        comments   IN boolean := FALSE);
END pkg_grants;
/


CREATE OR REPLACE PACKAGE BODY pkg_grants AS
  
  PROCEDURE user_grant (grant_name  IN VARCHAR2,
                        schema_name IN VARCHAR2,
                        object_name IN VARCHAR2,
                        user_name   IN VARCHAR2) 
  IS
  BEGIN
	  EXECUTE IMMEDIATE ('GRANT ' || grant_name || ' ON ' || schema_name || '.' || object_name || ' TO ' || user_name);
  END user_grant;
  
 PROCEDURE user_grant (grant_name VARCHAR2, 
                       user_name  VARCHAR2,
                       comments   IN boolean := FALSE)
   IS
  BEGIN
      IF comments THEN
        EXECUTE IMMEDIATE ('GRANT ' || grant_name || ' TO ' || user_name || ' WITH ADMIN OPTION');
      END IF;
        EXECUTE IMMEDIATE ('GRANT ' || grant_name || ' TO ' || user_name);
  END;
END pkg_grants;
/
