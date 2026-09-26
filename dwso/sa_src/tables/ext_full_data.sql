-- EXT_FULL_DATA.
    CREATE TABLE ext_full_data
          (country_id           NUMBER(10,0),
           county_desc          VARCHAR2(200 CHAR),
           structure_code       NUMBER(10,0),
           structure_desc       VARCHAR2(200 CHAR)
           )
    ORGANIZATION EXTERNAL (
        TYPE oracle_loader
        DEFAULT DIRECTORY external_geo_tables
         ACCESS PARAMETERS
            (records delimited BY newline
             nobadfile nodiscardfile nologfile fields terminated BY ';'
             missing field VALUES are NULL
                  (
                   country_id INTEGER EXTERNAL (4),
                   county_desc CHAR(200),
                   structure_code INTEGER EXTERNAL (4),
                   structure_desc CHAR(200) )
             )
        LOCATION ('iso_3166_geo_un_contries.tab')
    )
    REJECT LIMIT UNLIMITED;