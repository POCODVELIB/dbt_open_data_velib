/*
Description :  POC ingestion données Velib et météo à Paris dans Snowflake
               Table Silver meteo Paris
-------------------------------------------------------------------------------------
Author      : Said HOUSSEINE   
Created     : 2026-04-22
-------------------------------------------------------------------------------------
*/

{{
    config(
        materialized  = 'incremental',
        schema        = 'SILVER',
        unique_key    = ['nom', 'time'],
        incremental_strategy = 'merge'
    )
}}

SELECT
    PARSE_JSON(_raw):nom::VARCHAR               AS arrondissement,
    PARSE_JSON(_raw):lat::FLOAT                 AS lat,
    PARSE_JSON(_raw):lon::FLOAT                 AS lon,
    PARSE_JSON(_raw):time::TIMESTAMP_NTZ        AS time,
    PARSE_JSON(_raw):temperature_2m::FLOAT      AS temperature_c,
    PARSE_JSON(_raw):precipitation::FLOAT       AS precipitation_mm,
    PARSE_JSON(_raw):windspeed_10m::FLOAT       AS windspeed_kmh,
    PARSE_JSON(_raw):weathercode::INT           AS weathercode,
    PARSE_JSON(_raw):relativehumidity_2m::INT   AS humidity_pct,
    _loaded_at

FROM {{ source('raw', 'METEO_PARIS') }}

{% if is_incremental() %}
    WHERE _loaded_at > (SELECT MAX(_loaded_at) FROM {{ this }})
{% endif %}