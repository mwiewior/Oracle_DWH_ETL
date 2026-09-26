-- Oracle 12c+ security requirement: an AUTHID CURRENT_USER procedure (e.g. PKG_GRANTS,
-- used throughout this schema to issue GRANT statements from within PL/SQL) needs the
-- invoking user's INHERIT PRIVILEGES grant on the procedure owner before the invoker's
-- real privileges are exercised inside the procedure body. This grants every schema owner
-- here permission to let SYSTEM's real privileges apply when SYSTEM invokes their
-- AUTHID CURRENT_USER packages (e.g. via ALTER SESSION SET CURRENT_SCHEMA).
GRANT INHERIT PRIVILEGES ON USER SYSTEM TO sa_src;
GRANT INHERIT PRIVILEGES ON USER SYSTEM TO bl_cl_1st;
GRANT INHERIT PRIVILEGES ON USER SYSTEM TO bl_cl_2nd;
GRANT INHERIT PRIVILEGES ON USER SYSTEM TO bl_3nf;
GRANT INHERIT PRIVILEGES ON USER SYSTEM TO bl_dm;
GRANT INHERIT PRIVILEGES ON USER SYSTEM TO data_mart;
