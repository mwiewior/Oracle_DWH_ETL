# BI-Lab-2017

A layered Oracle data warehouse (SA_SRC → BL_CL_1ST → BL_3NF → BL_CL_2ND → BL_DM, plus
DATA_MART): its data model (tables, external tables, sequences, constraints, partitioning)
and its ETL code (the PL/SQL packages that move data from layer to layer), under
`dwso/<schema>/`. It ships no data and loads none.

## Installing it

Run the drivers from the repository root, as a DBA user (e.g. SYSTEM):

```sh
cd <repo>
sqlplus system/<password>@<pdb> @install.sql   # tablespace, users, grants, tables, packages
sqlplus system/<password>@<pdb> @reports.sql   # sales report queries, partition exchange demo
```

SQL*Plus resolves the drivers' `@dwso/...` includes against its working directory, so start it
from the repository root.

The SA_SRC external tables are defined on the directories of
`dwso/sa_src/create_directory.sql`; querying them needs the source files there.

## Original notes

`user guide.txt` and `docs/original/` keep the author's original load guides
(`first load.txt`, `reload data.txt`): they describe how the ETL packages were run, in which
order, to load the warehouse.
