INSERT INTO dim_time_day (
    date_dt,
    week_day_full_name,
    week_day_short_name,
    day_number_of_week,
    day_number_of_month,
    day_number_of_year,
    month_year,
    month_full_name,
    month_short_name,
    month_number_of_year,
    quarter_year,
    quarter_number_of_year,
    half_year_number,
    half_year,
    year
) SELECT
    start_date,
    TO_CHAR(date_dt,'Day'),
    TO_CHAR(date_dt,'DY'),
    to_number(TRIM(LEADING '0' FROM TO_CHAR(date_dt,'D') ) ),
    to_number(TRIM(LEADING '0' FROM TO_CHAR(date_dt,'DD') ) ),
    to_number(TRIM(LEADING '0' FROM TO_CHAR(date_dt,'DDD') ) ),
    upper(TO_CHAR(date_dt,'YYYY') || '-' || TO_CHAR(date_dt,'Mon') ),
    TO_CHAR(date_dt,'Month'),
    TO_CHAR(date_dt,'Mon'),
    to_number(TRIM(LEADING '0' FROM TO_CHAR(date_dt,'MM') ) ),
    upper(TO_CHAR(date_dt,'YYYY')) || '-' || 'Q' || TO_CHAR(date_dt,'Q'),
    TO_CHAR(date_dt,'Q'),
    (CASE
     WHEN to_number(TO_CHAR(date_dt,'Q') ) <= 2 
     THEN 1
     ELSE 2 END),
    (CASE WHEN to_number(TO_CHAR(date_dt,'Q') ) <= 2 
     THEN TO_CHAR(date_dt,'YYYY') || '-' ||  'H' || 1 
     ELSE TO_CHAR(date_dt,'YYYY') || '-' || 'H' || 2 END),
     TO_CHAR(date_dt,'YYYY')
FROM
    (SELECT level n,
            TO_DATE('31/12/2016','DD/MM/YYYY') + numtodsinterval(level,'DAY') date_dt
     FROM dual
     CONNECT BY level <= 10950)
ORDER BY date_dt;