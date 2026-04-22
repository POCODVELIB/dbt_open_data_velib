/*
Description :  POC ingestion données Velib et météo à Paris dans Snowflake
               Table Silver status station velib Paris
-------------------------------------------------------------------------------------
Author      : Said HOUSSEINE   
Created     : 2026-04-22
-------------------------------------------------------------------------------------
*/
{{
    config(
        materialized="incremental",
        schema="SILVER",
        unique_key=["station_id", "last_reported"],
        incremental_strategy="merge",
    )
}}

select
    parse_json(_raw):station_id::int as station_id,
    parse_json(_raw)['stationCode']::varchar as station_code,
    parse_json(_raw):num_bikes_available::int as num_bikes_available,
    parse_json(_raw):num_bikes_available_types[0]:mechanical::int
    as num_bikes_mechanical,
    parse_json(_raw):num_bikes_available_types[1]:ebike::int as num_bikes_ebike,
    parse_json(_raw):num_docks_available::int as num_docks_available,
    parse_json(_raw):is_installed::int as is_installed,
    parse_json(_raw):is_renting::int as is_renting,
    parse_json(_raw):is_returning::int as is_returning,
    to_timestamp(parse_json(_raw):last_reported::int) as last_reported,
    _loaded_at

from {{ source("raw", "STATION_STATUS") }}

{% if is_incremental() %}
    where _loaded_at > (select max(_loaded_at) from {{ this }})
{% endif %}
