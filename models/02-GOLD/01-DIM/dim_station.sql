/*
Description :  POC ingestion données Velib et météo à Paris dans Snowflake
               Table dimension station 
-------------------------------------------------------------------------------------
Author      : Said HOUSSEINE   
Created     : 2026-04-22
-------------------------------------------------------------------------------------
*/
{{
    config(
        materialized="table",
        schema="GOLD",
        unique_key="station_id",
    )
}}

with
    arrondissements as (
        select distinct nom as arrondissement, lat, lon from {{ ref("s_meteo_paris") }}
    ),

    latest as (
        select *
        from {{ ref("s_station_information") }}
        qualify row_number() over (partition by station_id order by _loaded_at desc) = 1
    ),

    joined as (
        select
            s.station_id,
            s.stationcode as station_code,
            s.name,
            s.lat::float as lat,
            s.lon::float as lon,
            s.capacity,
            a.arrondissement,
            sqrt(power(s.lat - a.lat, 2) + power(s.lon - a.lon, 2)) as distance
        from latest s
        join arrondissements a on true
    )

select station_id, station_code, name, lat, lon, capacity, arrondissement
from joined
qualify row_number() over (partition by station_id order by distance asc) = 1
