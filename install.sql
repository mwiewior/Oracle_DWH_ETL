-- Install script for the lupanava-dwh corpus: the tablespace, the six users, their grants and
-- every table, sequence and package, in dependency order. Replaces the original load guides
-- (docs/original/), which mixed narrative prose with SQL and used absolute VM paths.
--
-- Run it from the repository root as a DBA user (e.g. SYSTEM), then reports.sql:
--   cd <repo> && sqlplus system/<password>@<pdb> @install.sql
-- ALTER SESSION SET CURRENT_SCHEMA is used instead of connecting as each schema user.
-- The corpus is the data model and the ETL code only: it ships no data and loads none.
SET DEFINE OFF
WHENEVER SQLERROR CONTINUE

-- Tablespace
@dwso/system/tablespace.sql

-- User: sa_src
@dwso/system/sa_src/sa_src_user.sql

-- User: bl_cl_1st
@dwso/system/bl_cl_1st/bl_cl_1st_user.sql

-- User: bl_cl_2nd
@dwso/system/bl_cl_2nd/bl_cl_2nd_user.sql

-- User: bl_3nf
@dwso/system/bl_3nf/bl_3nf_user.sql

-- User: bl_dm
@dwso/system/bl_dm/bl_dm_user.sql

-- User: data_mart
@dwso/system/data_mart/data_mart_user.sql

-- Base grants: sa_src
@dwso/system/sa_src/sa_src_grants.sql

-- Base grants: bl_cl_1st
@dwso/system/bl_cl_1st/bl_cl_1st_grants.sql

-- Base grants: bl_cl_2nd
@dwso/system/bl_cl_2nd/bl_cl_2nd_grants.sql

-- Base grants: bl_3nf
@dwso/system/bl_3nf/bl_3nf_grants.sql

-- Base grants: bl_dm
@dwso/system/bl_dm/bl_dm_grants.sql

-- Base grants: data_mart
@dwso/system/data_mart/data_mart_grants.sql

-- Inherit privileges (all schemas)
@dwso/system/0_inherit_privileges.sql

-- Directories
@dwso/sa_src/create_directory.sql

-- Object: sa_src/dwso/sa_src/packages/pkg_grants.sql
ALTER SESSION SET CURRENT_SCHEMA = sa_src;
@dwso/sa_src/packages/pkg_grants.sql

-- Object: sa_src/dwso/sa_src/tables/ext_bra_sizes.sql
ALTER SESSION SET CURRENT_SCHEMA = sa_src;
@dwso/sa_src/tables/ext_bra_sizes.sql

-- Object: sa_src/dwso/sa_src/tables/ext_countries.sql
ALTER SESSION SET CURRENT_SCHEMA = sa_src;
@dwso/sa_src/tables/ext_countries.sql

-- Object: sa_src/dwso/sa_src/tables/ext_customers.sql
ALTER SESSION SET CURRENT_SCHEMA = sa_src;
@dwso/sa_src/tables/ext_customers.sql

-- Object: sa_src/dwso/sa_src/tables/ext_employees.sql
ALTER SESSION SET CURRENT_SCHEMA = sa_src;
@dwso/sa_src/tables/ext_employees.sql

-- Object: sa_src/dwso/sa_src/tables/ext_full_data.sql
ALTER SESSION SET CURRENT_SCHEMA = sa_src;
@dwso/sa_src/tables/ext_full_data.sql

-- Object: sa_src/dwso/sa_src/tables/ext_panty_sizes.sql
ALTER SESSION SET CURRENT_SCHEMA = sa_src;
@dwso/sa_src/tables/ext_panty_sizes.sql

-- Object: sa_src/dwso/sa_src/tables/ext_payment_methods.sql
ALTER SESSION SET CURRENT_SCHEMA = sa_src;
@dwso/sa_src/tables/ext_payment_methods.sql

-- Object: sa_src/dwso/sa_src/tables/ext_products.sql
ALTER SESSION SET CURRENT_SCHEMA = sa_src;
@dwso/sa_src/tables/ext_products.sql

-- Object: sa_src/dwso/sa_src/tables/ext_stores.sql
ALTER SESSION SET CURRENT_SCHEMA = sa_src;
@dwso/sa_src/tables/ext_stores.sql

-- Object: sa_src/dwso/sa_src/tables/ext_structures.sql
ALTER SESSION SET CURRENT_SCHEMA = sa_src;
@dwso/sa_src/tables/ext_structures.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/packages/pkg_drop_tables.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/packages/pkg_drop_tables.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/packages/pkg_etl_insert_age_categories.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/packages/pkg_etl_insert_age_categories.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/packages/pkg_etl_insert_customers.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/packages/pkg_etl_insert_customers.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/packages/pkg_etl_insert_employees.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/packages/pkg_etl_insert_employees.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/packages/pkg_etl_insert_geography.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/packages/pkg_etl_insert_geography.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/packages/pkg_etl_insert_payment_methods.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/packages/pkg_etl_insert_payment_methods.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/packages/pkg_etl_insert_products.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/packages/pkg_etl_insert_products.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/packages/pkg_etl_insert_receipts.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/packages/pkg_etl_insert_receipts.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/packages/pkg_etl_insert_sizes.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/packages/pkg_etl_insert_sizes.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/packages/pkg_etl_insert_stores.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/packages/pkg_etl_insert_stores.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/packages/pkg_etl_insert_wrk.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/packages/pkg_etl_insert_wrk.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/packages/pkg_etl_update_ce.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/packages/pkg_etl_update_ce.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/cls_age_categories/cls_age_categories.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/tables/cls_age_categories/cls_age_categories.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/cls_bra_sizes/cls_bra_sizes.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/tables/cls_bra_sizes/cls_bra_sizes.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/cls_cities/cls_cities.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/tables/cls_cities/cls_cities.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/cls_collections/cls_collections.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/tables/cls_collections/cls_collections.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/cls_continents/cls_continents.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/tables/cls_continents/cls_continents.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/cls_countries/cls_countries.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/tables/cls_countries/cls_countries.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/cls_customers/cls_customers.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/tables/cls_customers/cls_customers.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/cls_employees/cls_employees.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/tables/cls_employees/cls_employees.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/cls_lines/cls_lines.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/tables/cls_lines/cls_lines.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/cls_panty_sizes/cls_panty_sizes.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/tables/cls_panty_sizes/cls_panty_sizes.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/cls_payment_methods/cls_payment_methods.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/tables/cls_payment_methods/cls_payment_methods.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/cls_position_grade/cls_position_grade.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/tables/cls_position_grade/cls_position_grade.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/cls_product_details/cls_product_details.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/tables/cls_product_details/cls_product_details.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/cls_product_types/cls_product_types.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/tables/cls_product_types/cls_product_types.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/cls_products/cls_products.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/tables/cls_products/cls_products.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/cls_receipts/cls_receipts.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/tables/cls_receipts/cls_receipts.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/cls_regions/cls_regions.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/tables/cls_regions/cls_regions.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/cls_stores/cls_stores.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/tables/cls_stores/cls_stores.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/wrk_bra_sizes/wrk_bra_sizes.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/tables/wrk_bra_sizes/wrk_bra_sizes.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/wrk_cities/wrk_cities.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/tables/wrk_cities/wrk_cities.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/wrk_countries/wrk_countries.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/tables/wrk_countries/wrk_countries.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/wrk_customers/wrk_customers.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/tables/wrk_customers/wrk_customers.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/wrk_employees/wrk_employees.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/tables/wrk_employees/wrk_employees.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/wrk_full_data/wrk_full_data.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/tables/wrk_full_data/wrk_full_data.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/wrk_panty_sizes/wrk_panty_sizes.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/tables/wrk_panty_sizes/wrk_panty_sizes.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/wrk_payment_methods/wrk_payment_methods.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/tables/wrk_payment_methods/wrk_payment_methods.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/wrk_products/wrk_products.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/tables/wrk_products/wrk_products.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/wrk_stores/wrk_stores.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/tables/wrk_stores/wrk_stores.sql

-- Object: bl_cl_1st/dwso/bl_cl_1st/tables/wrk_structures/wrk_structures.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_1st;
@dwso/bl_cl_1st/tables/wrk_structures/wrk_structures.sql

-- Object: bl_cl_2nd/dwso/bl_cl_2nd/packages/pkg_drop.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_2nd;
@dwso/bl_cl_2nd/packages/pkg_drop.sql

-- Object: bl_cl_2nd/dwso/bl_cl_2nd/packages/pkg_etl_customers.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_2nd;
@dwso/bl_cl_2nd/packages/pkg_etl_customers.sql

-- Object: bl_cl_2nd/dwso/bl_cl_2nd/packages/pkg_etl_employees.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_2nd;
@dwso/bl_cl_2nd/packages/pkg_etl_employees.sql

-- Object: bl_cl_2nd/dwso/bl_cl_2nd/packages/pkg_etl_insert_retail_sales.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_2nd;
@dwso/bl_cl_2nd/packages/pkg_etl_insert_retail_sales.sql

-- Object: bl_cl_2nd/dwso/bl_cl_2nd/packages/pkg_etl_payment_methods.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_2nd;
@dwso/bl_cl_2nd/packages/pkg_etl_payment_methods.sql

-- Object: bl_cl_2nd/dwso/bl_cl_2nd/packages/pkg_etl_products.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_2nd;
@dwso/bl_cl_2nd/packages/pkg_etl_products.sql

-- Object: bl_cl_2nd/dwso/bl_cl_2nd/packages/pkg_etl_retail_sales.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_2nd;
@dwso/bl_cl_2nd/packages/pkg_etl_retail_sales.sql

-- Object: bl_cl_2nd/dwso/bl_cl_2nd/packages/pkg_etl_stores.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_2nd;
@dwso/bl_cl_2nd/packages/pkg_etl_stores.sql

-- Object: bl_cl_2nd/dwso/bl_cl_2nd/tables/cls_customers/cls_customers_scd.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_2nd;
@dwso/bl_cl_2nd/tables/cls_customers/cls_customers_scd.sql

-- Object: bl_cl_2nd/dwso/bl_cl_2nd/tables/cls_employees/cls_employees_scd.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_2nd;
@dwso/bl_cl_2nd/tables/cls_employees/cls_employees_scd.sql

-- Object: bl_cl_2nd/dwso/bl_cl_2nd/tables/cls_payment_methods/cls_payment_methods_scd.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_2nd;
@dwso/bl_cl_2nd/tables/cls_payment_methods/cls_payment_methods_scd.sql

-- Object: bl_cl_2nd/dwso/bl_cl_2nd/tables/cls_products/cls_products_scd.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_2nd;
@dwso/bl_cl_2nd/tables/cls_products/cls_products_scd.sql

-- Object: bl_cl_2nd/dwso/bl_cl_2nd/tables/cls_retail_sales_dd/cls_fact_retail_sales.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_2nd;
@dwso/bl_cl_2nd/tables/cls_retail_sales_dd/cls_fact_retail_sales.sql

-- Object: bl_cl_2nd/dwso/bl_cl_2nd/tables/cls_stores/cls_stores.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_2nd;
@dwso/bl_cl_2nd/tables/cls_stores/cls_stores.sql

-- Object: bl_cl_2nd/dwso/bl_cl_2nd/tables/cls_time_day/cls_time_day.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_cl_2nd;
@dwso/bl_cl_2nd/tables/cls_time_day/cls_time_day.sql

-- Object: bl_3nf/dwso/bl_3nf/packages/pkg_drop_tables.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/packages/pkg_drop_tables.sql

-- Object: bl_3nf/dwso/bl_3nf/packages/pkg_grants.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/packages/pkg_grants.sql

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_age_categories/ce_age_categories.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/tables/ce_age_categories/ce_age_categories.sql

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_age_categories/ce_age_categories_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/tables/ce_age_categories/ce_age_categories_sequence.sql

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_bra_size_grid/ce_bra_size_grid.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/tables/ce_bra_size_grid/ce_bra_size_grid.sql

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_bra_size_grid/ce_bra_size_grid_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/tables/ce_bra_size_grid/ce_bra_size_grid_sequence.sql

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_cities/ce_cities_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/tables/ce_cities/ce_cities_sequence.sql

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_collections/ce_collections.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/tables/ce_collections/ce_collections.sql

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_collections/ce_collections_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/tables/ce_collections/ce_collections_sequence.sql

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_continents/ce_continents.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/tables/ce_continents/ce_continents.sql

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_continents/ce_continents_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/tables/ce_continents/ce_continents_sequence.sql

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_countries/ce_countries_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/tables/ce_countries/ce_countries_sequence.sql

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_customers/ce_customers_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/tables/ce_customers/ce_customers_sequence.sql

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_employees/ce_employees_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/tables/ce_employees/ce_employees_sequence.sql

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_lines/ce_lines.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/tables/ce_lines/ce_lines.sql

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_lines/ce_lines_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/tables/ce_lines/ce_lines_sequence.sql

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_panty_size_grid/ce_panty_size_grid.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/tables/ce_panty_size_grid/ce_panty_size_grid.sql

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_panty_size_grid/ce_panty_size_grid_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/tables/ce_panty_size_grid/ce_panty_size_grid_sequence.sql

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_payment_methods/ce_payment_methods.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/tables/ce_payment_methods/ce_payment_methods.sql

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_payment_methods/ce_payment_methods_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/tables/ce_payment_methods/ce_payment_methods_sequence.sql

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_position_grades/ce_position_grades.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/tables/ce_position_grades/ce_position_grades.sql

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_position_grades/ce_position_grades_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/tables/ce_position_grades/ce_position_grades_sequence.sql

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_product_details/ce_product_details_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/tables/ce_product_details/ce_product_details_sequence.sql

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_product_types/ce_product_types.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/tables/ce_product_types/ce_product_types.sql

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_product_types/ce_product_types_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/tables/ce_product_types/ce_product_types_sequence.sql

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_products/ce_products.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/tables/ce_products/ce_products.sql

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_products/ce_products_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/tables/ce_products/ce_products_sequence.sql

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_receipts/ce_receipts_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/tables/ce_receipts/ce_receipts_sequence.sql

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_regions/ce_regions.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/tables/ce_regions/ce_regions.sql

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_regions/ce_regions_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/tables/ce_regions/ce_regions_sequence.sql

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_stores/ce_stores_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/tables/ce_stores/ce_stores_sequence.sql

-- Object: bl_dm/dwso/bl_dm/packages/pkg_drop_tables.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_dm;
@dwso/bl_dm/packages/pkg_drop_tables.sql

-- Object: bl_dm/dwso/bl_dm/packages/pkg_grants.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_dm;
@dwso/bl_dm/packages/pkg_grants.sql

-- Object: bl_dm/dwso/bl_dm/tables/dim_customers_scd/dim_customers_scd.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_dm;
@dwso/bl_dm/tables/dim_customers_scd/dim_customers_scd.sql

-- Object: bl_dm/dwso/bl_dm/tables/dim_customers_scd/dim_customers_scd_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_dm;
@dwso/bl_dm/tables/dim_customers_scd/dim_customers_scd_sequence.sql

-- Object: bl_dm/dwso/bl_dm/tables/dim_employees_scd/dim_employees_scd.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_dm;
@dwso/bl_dm/tables/dim_employees_scd/dim_employees_scd.sql

-- Object: bl_dm/dwso/bl_dm/tables/dim_employees_scd/dim_employees_scd_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_dm;
@dwso/bl_dm/tables/dim_employees_scd/dim_employees_scd_sequence.sql

-- Object: bl_dm/dwso/bl_dm/tables/dim_payment_methods_scd/dim_payment_methods_scd.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_dm;
@dwso/bl_dm/tables/dim_payment_methods_scd/dim_payment_methods_scd.sql

-- Object: bl_dm/dwso/bl_dm/tables/dim_payment_methods_scd/dim_payment_methods_scd_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_dm;
@dwso/bl_dm/tables/dim_payment_methods_scd/dim_payment_methods_scd_sequence.sql

-- Object: bl_dm/dwso/bl_dm/tables/dim_products_scd/dim_products_scd.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_dm;
@dwso/bl_dm/tables/dim_products_scd/dim_products_scd.sql

-- Object: bl_dm/dwso/bl_dm/tables/dim_products_scd/dim_products_scd_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_dm;
@dwso/bl_dm/tables/dim_products_scd/dim_products_scd_sequence.sql

-- Object: bl_dm/dwso/bl_dm/tables/dim_stores_scd/dim_stores_scd.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_dm;
@dwso/bl_dm/tables/dim_stores_scd/dim_stores_scd.sql

-- Object: bl_dm/dwso/bl_dm/tables/dim_stores_scd/dim_stores_scd_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_dm;
@dwso/bl_dm/tables/dim_stores_scd/dim_stores_scd_sequence.sql

-- Object: bl_dm/dwso/bl_dm/tables/dim_time_day/dim_time_day.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_dm;
@dwso/bl_dm/tables/dim_time_day/dim_time_day.sql

-- Object: bl_dm/dwso/bl_dm/tables/fct_retail_sales_dd/fct_retail_sales_dd.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_dm;
@dwso/bl_dm/tables/fct_retail_sales_dd/fct_retail_sales_dd.sql

-- Object: bl_dm/dwso/bl_dm/tables/fct_retail_sales_dd/fct_retail_sales_dd_sequence.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_dm;
@dwso/bl_dm/tables/fct_retail_sales_dd/fct_retail_sales_dd_sequence.sql

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_countries/ce_countries.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/tables/ce_countries/ce_countries.sql

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_product_details/ce_product_details.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/tables/ce_product_details/ce_product_details.sql

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_cities/ce_cities.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/tables/ce_cities/ce_cities.sql

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_customers/ce_customers.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/tables/ce_customers/ce_customers.sql

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_stores/ce_stores.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/tables/ce_stores/ce_stores.sql

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_employees/ce_employees.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/tables/ce_employees/ce_employees.sql

-- Object: bl_3nf/dwso/bl_3nf/tables/ce_receipts/ce_receipts.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/tables/ce_receipts/ce_receipts.sql

-- Cross-schema grants: additional_grants (DBA grants)
@dwso/system/additional_grants.sql

-- Cross-schema grants: grants_to_bl_cl_1st (DBA grants)
@dwso/sa_src/grants_to_bl_cl_1st.sql

-- Cross-schema grants: bl_3nf/grant_to_bl_cl_1st.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/grants/grant_to_bl_cl_1st.sql

-- Cross-schema grants: bl_3nf/grant_to_bl_cl_2nd.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_3nf;
@dwso/bl_3nf/grants/grant_to_bl_cl_2nd.sql

-- Cross-schema grants: bl_dm/grant_to_bl_cl_2nd.sql
ALTER SESSION SET CURRENT_SCHEMA = bl_dm;
@dwso/bl_dm/grants/grant_to_bl_cl_2nd.sql

-- data_mart: SALES
@dwso/data_mart/sales_report.sql

EXIT
