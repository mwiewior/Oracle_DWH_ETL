-- Creating directories.
-- The directories the SA_SRC external tables are defined on. The source files themselves are
-- not part of this repository: put them under /opt/oracle/dwh/sources (or repoint these paths)
-- before querying the external tables.

CREATE OR REPLACE DIRECTORY external_geo_tables AS '/opt/oracle/dwh/sources/geography';

CREATE OR REPLACE DIRECTORY external_cust_tables AS '/opt/oracle/dwh/sources/customers';

CREATE OR REPLACE DIRECTORY external_emp_tables AS '/opt/oracle/dwh/sources/employees';

CREATE OR REPLACE DIRECTORY external_ext_tables AS '/opt/oracle/dwh/sources';

CREATE OR REPLACE DIRECTORY external_prod_tables AS '/opt/oracle/dwh/sources/products';
