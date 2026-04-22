/*
Description :  POC ingestion données Velib et météo à Paris dans Snowflake
               Table dim date
-------------------------------------------------------------------------------------
Author      : Said HOUSSEINE   
Created     : 2026-04-22
-------------------------------------------------------------------------------------
*/

{{
    config(
        materialized = 'table',
        schema       = 'GOLD'
    )
}}

WITH dates AS (
    SELECT DATEADD(day, seq4(), '2000-01-01'::DATE) AS date
    FROM TABLE(GENERATOR(ROWCOUNT => 36525))
)

SELECT
    TO_CHAR(date, 'YYYYMMDD')::INT      AS date_id,
    date,
    YEAR(date)                          AS annee,
    MONTH(date)                         AS mois,
    DAY(date)                           AS jour,
    DAYNAME(date)                       AS jour_semaine,
    IFF(DAYOFWEEK(date) IN (0,6), 1, 0) AS est_weekend

FROM dates
WHERE date <= '2100-12-31'