BEGIN
  pkg_etl_insert_wrk.insert_table(table_name_to => 'WRK_FULL_DATA', table_name_from => 'SA_SRC.EXT_FULL_DATA');
END;
/
