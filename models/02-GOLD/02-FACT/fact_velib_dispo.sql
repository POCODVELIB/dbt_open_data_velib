/*
Description :  POC ingestion données Velib et météo à Paris dans Snowflake
               Table fact : dispo, station et meteo
-------------------------------------------------------------------------------------
Author      : Said HOUSSEINE   
Created     : 2026-04-22
-------------------------------------------------------------------------------------
*/
{{ config(materialized="incremental", unique_key=["station_id", "last_reported"]) }}

with
    status as (
        select *
        from {{ ref("s_station_status") }}
        {% if is_incremental() %}
            where
                _loaded_at
                > (select convert_timezone('UTC', max(_loaded_at)) from {{ this }})
        {% endif %}
    ),

    station as (select * from {{ ref("dim_station") }}),

    meteo as (select * from {{ ref("dim_meteo") }})

select
    s.station_id,
    TO_CHAR(TO_TIMESTAMP(s.last_reported::INT), 'YYYYMMDDHH24MI')::INT AS date_id,
    m.meteo_id,

    s.num_bikes_available,
    -- ebike et mechanical extraits du tableau
    s.num_bikes_available_types[0]:mechanical::INT           AS num_bikes_mechanical,
    s.num_bikes_available_types[1]:ebike::INT                AS num_bikes_ebike,
    s.num_docks_available,
    s.is_installed,
    s.is_returning,

    -- KPIs calculés
    ROUND(s.num_bikes_available / NULLIF(st.capacity, 0) * 100, 1) AS taux_remplissage_pct,
    IFF(s.num_bikes_available = 0, 1, 0)                    AS is_vide,
    IFF(s.num_docks_available = 0, 1, 0)                    AS is_sature,
    TO_TIMESTAMP(s.last_reported::INT)   AS last_reported,
    s._loaded_at

FROM status s
LEFT JOIN station st ON s.station_id = st.station_id
LEFT JOIN meteo m
    ON st.arrondissement = m.arrondissement
    AND m.time <= TO_TIMESTAMP(s.last_reported::INT)
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY s.station_id, s.last_reported
    ORDER BY m.time DESC
) = 1