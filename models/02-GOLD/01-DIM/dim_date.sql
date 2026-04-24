/*
Description :  POC ingestion données Velib et météo à Paris dans Snowflake
               Table dim date
-------------------------------------------------------------------------------------
Author      : Said HOUSSEINE   
Created     : 2026-04-22
-------------------------------------------------------------------------------------
*/
{{ config(materialized="table", schema="GOLD") }}

with
    dates as (
        select dateadd(day, seq4(), '2000-01-01'::date) as date
        from table(generator(rowcount => 36525))
    )

select
    to_char(date, 'YYYYMMDD')::int as date_id,
    date,
    year(date) as annee,
    month(date) as mois,
    day(date) as jour,
    dayname(date) as jour_semaine,
    iff(dayofweek(date) in (0, 6), 1, 0) as est_weekend

from dates
where date <= '2100-12-31'
