BEGIN
  pkg_etl_insert_wrk.insert_table(table_name_to => 'WRK_CUSTOMERS', table_name_from => 'SA_SRC.EXT_CUSTOMERS');
END;
/