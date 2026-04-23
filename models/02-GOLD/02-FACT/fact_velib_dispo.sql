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
            where _loaded_at > (      SELECT CONVERT_TIMEZONE('UTC', MAX(_loaded_at)) from {{ this }})
        {% endif %}
    ),

    station as (select * from {{ ref("dim_station") }}),

    meteo as (select * from {{ ref("dim_meteo") }})

select
    -- Clés
    s.station_id,
    to_char(s.last_reported, 'YYYYMMDDHH24MI')::int as date_id,
    m.meteo_id,

    -- Métriques vélos
    s.num_bikes_available,
    s.num_bikes_mechanical,
    s.num_bikes_ebike,
    s.num_docks_available,

    -- Métriques calculées
    round(
        s.num_bikes_available / nullif(st.capacity, 0) * 100, 1
    ) as taux_remplissage_pct,
    iff(s.num_bikes_available = 0, 1, 0) as is_vide,
    iff(s.num_docks_available = 0, 1, 0) as is_sature,
    s.is_renting,
    s.is_installed,
    s.last_reported,
    s._loaded_at

from status s
left join station st on s.station_id = st.station_id
left join
    meteo m
    on st.arrondissement = m.arrondissement
    and m.time <= date_trunc('hour', s.last_reported)

qualify
    row_number() over (partition by s.station_id, s.last_reported order by m.time desc)
    = 1
