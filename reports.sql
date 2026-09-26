-- Reports and demos of the lupanava-dwh corpus: sales reports on BL_3NF and BL_DM, and the
-- partition exchange demo of BL_DM. Run it from the repository root as a DBA user, after
-- install.sql:
--   cd <repo> && sqlplus system/<password>@<pdb> @reports.sql
SET DEFINE OFF
WHENEVER SQLERROR CONTINUE

-- BL_3NF: sales report
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/data_mart/bl_3nf_sales.sql

-- BL_DM: sales report
ALTER SESSION SET CURRENT_SCHEMA = bl_dm;
@dwso/data_mart/bl_dm_sales.sql

-- BL_DM: partition exchange demo
ALTER SESSION SET CURRENT_SCHEMA = bl_dm;
@dwso/data_mart/advanced_loading.sql

EXIT
