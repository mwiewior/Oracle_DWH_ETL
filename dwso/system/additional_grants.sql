BEGIN
  sa_src.pkg_grants.user_grant(grant_name => 'CREATE ANY DIRECTORY', user_name => 'SA_SRC');
  sa_src.pkg_grants.USER_GRANT(GRANT_NAME => 'READ ON DIRECTORY external_geo_tables', USER_NAME => 'SA_SRC');
  sa_src.pkg_grants.USER_GRANT(GRANT_NAME => 'READ ON DIRECTORY external_cust_tables', USER_NAME => 'SA_SRC');
  sa_src.pkg_grants.USER_GRANT(GRANT_NAME => 'READ ON DIRECTORY external_emp_tables', USER_NAME => 'SA_SRC');
  sa_src.pkg_grants.USER_GRANT(GRANT_NAME => 'READ ON DIRECTORY external_ext_tables', USER_NAME => 'SA_SRC');
  sa_src.pkg_grants.USER_GRANT(GRANT_NAME => 'UNLIMITED TABLESPACE', USER_NAME => 'BL_CL_1ST');
  sa_src.pkg_grants.USER_GRANT(GRANT_NAME => 'UNLIMITED TABLESPACE', USER_NAME => 'BL_3NF');
  sa_src.pkg_grants.USER_GRANT(GRANT_NAME => 'UNLIMITED TABLESPACE', USER_NAME => 'BL_CL_2ND');
  sa_src.pkg_grants.USER_GRANT(GRANT_NAME => 'UNLIMITED TABLESPACE', USER_NAME => 'BL_DM');
END;
/


