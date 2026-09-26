
CREATE TABLE cls_time_day (
    date_dt                  DATE NOT NULL,
    week_day_full_name       VARCHAR2(10) NOT NULL,
    week_day_short_name      VARCHAR2(10) NOT NULL,
    day_number_of_week       NUMBER(10) NOT NULL,
    day_number_of_month      NUMBER(10) NOT NULL,
    day_number_of_year       NUMBER(10) NOT NULL,
    month_year               VARCHAR2(10) NOT NULL,
    month_full_name          VARCHAR2(10) NOT NULL,
    month_short_name         VARCHAR2(10) NOT NULL,
    month_number_of_year     NUMBER(10) NOT NULL,
    quarter_year             VARCHAR2(10) NOT NULL,
    quarter_number_of_year   VARCHAR2(10) NOT NULL,
    half_year_number         VARCHAR2(10) NOT NULL,
    half_year                VARCHAR2(10) NOT NULL,
    year                     VARCHAR2(10) NOT NULL
);