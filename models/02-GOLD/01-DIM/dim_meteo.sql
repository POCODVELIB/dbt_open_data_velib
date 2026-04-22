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
        materialized="incremental",
        schema="GOLD",
         unique_key= ['arrondissement', 'time'],
        incremental_strategy="merge",
    )
}}

select
    {{ dbt_utils.generate_surrogate_key(["arrondissement", "time"]) }} as meteo_id,
    arrondissement,
    lat,
    lon,
    time,
    temperature_c,
    precipitation_mm,
    windspeed_kmh,
    humidity_pct,
    weathercode,

    -- code WMO
    case
        when weathercode = 0
        then 'Ensoleillé'
        when weathercode in (1, 2, 3)
        then 'Nuageux'
        when weathercode in (45, 48)
        then 'Brouillard'
        when weathercode in (51, 53, 55)
        then 'Bruine'
        when weathercode in (61, 63, 65)
        then 'Pluie'
        when weathercode in (71, 73, 75)
        then 'Neige'
        when weathercode in (80, 81, 82)
        then 'Averses'
        when weathercode in (95, 96, 99)
        then 'Orage'
        else 'Inconnu'
    end as condition_label,

    -- temperature 
    case
        when temperature_c < 5
        then 'Froid'
        when temperature_c between 5 and 15
        then 'Frais'
        when temperature_c between 15 and 25
        then 'Agreable'
        else 'Chaud'
    end as temperature_label,

    _loaded_at

from {{ ref("s_meteo_paris") }}

{% if is_incremental() %}
    where _loaded_at > (select max(_loaded_at) from {{ this }})
{% endif %}
