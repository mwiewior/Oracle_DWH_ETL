BEGIN
  pkg_grants.USER_GRANT(GRANT_NAME => 'READ, WRITE ON DIRECTORY EXTERNAL_GEO_TABLES', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'READ, WRITE ON DIRECTORY EXTERNAL_CUST_TABLES', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'READ, WRITE ON DIRECTORY EXTERNAL_EMP_TABLES', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'READ, WRITE ON DIRECTORY EXTERNAL_EXT_TABLES', USER_NAME => 'BL_CL_1ST');
  pkg_grants.USER_GRANT(GRANT_NAME => 'READ, WRITE ON DIRECTORY EXTERNAL_PROD_TABLES', USER_NAME => 'BL_CL_1ST');
  pkg_grants.user_grant(grant_name => 'SELECT', schema_name => 'SA_SRC', object_name => 'EXT_COUNTRIES', user_name => 'BL_CL_1ST');
  pkg_grants.user_grant(grant_name => 'SELECT', schema_name => 'SA_SRC', object_name => 'EXT_STRUCTURES', user_name => 'BL_CL_1ST');
  pkg_grants.user_grant(grant_name => 'SELECT', schema_name => 'SA_SRC', object_name => 'EXT_FULL_DATA', user_name => 'BL_CL_1ST');
  pkg_grants.user_grant(grant_name => 'SELECT', schema_name => 'SA_SRC', object_name => 'EXT_BRA_SIZES', user_name => 'BL_CL_1ST');
  pkg_grants.user_grant(grant_name => 'SELECT', schema_name => 'SA_SRC', object_name => 'EXT_PANTY_SIZES', user_name => 'BL_CL_1ST');
  pkg_grants.user_grant(grant_name => 'SELECT', schema_name => 'SA_SRC', object_name => 'EXT_CUSTOMERS', user_name => 'BL_CL_1ST');
  pkg_grants.user_grant(grant_name => 'SELECT', schema_name => 'SA_SRC', object_name => 'EXT_EMPLOYEES', user_name => 'BL_CL_1ST');
  pkg_grants.user_grant(grant_name => 'SELECT', schema_name => 'SA_SRC', object_name => 'EXT_STORES', user_name => 'BL_CL_1ST');
  pkg_grants.user_grant(grant_name => 'SELECT', schema_name => 'SA_SRC', object_name => 'EXT_PAYMENT_METHODS', user_name => 'BL_CL_1ST');
  pkg_grants.user_grant(grant_name => 'SELECT', schema_name => 'SA_SRC', object_name => 'EXT_PRODUCTS', user_name => 'BL_CL_1ST');
END;
/