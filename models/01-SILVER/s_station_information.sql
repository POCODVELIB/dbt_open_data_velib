/*
Description :  POC ingestion données Velib et météo à Paris dans Snowflake
               Table Silver information station velib 
-------------------------------------------------------------------------------------
Author      : Said HOUSSEINE   
Created     : 2026-04-22
-------------------------------------------------------------------------------------
*/
{{
    config(
        materialized="incremental",
        schema="SILVER",
        unique_key="station_id",
        incremental_strategy="merge",
    )
}}

select
    parse_json(_raw):station_id::int as station_id,
    parse_json(_raw):stationcode::varchar as station_code,
    parse_json(_raw):name::varchar as name,
    parse_json(_raw):lat::float as lat,
    parse_json(_raw):lon::float as lon,
    parse_json(_raw):capacity::int as capacity,
    _loaded_at

from {{ source("raw", "STATION_INFORMATION") }}

{% if is_incremental() %}
    where _loaded_at > (select max(_loaded_at) from {{ this }})
{% endif %}
