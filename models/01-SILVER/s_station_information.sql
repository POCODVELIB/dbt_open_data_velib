/*
Description :  POC ingestion données Velib et météo à Paris dans Snowflake
               Table Silver information station velib 
-------------------------------------------------------------------------------------
Author      : Said HOUSSEINE   
Created     : 2026-04-22
-------------------------------------------------------------------------------------
*/
{{ config(materialized="incremental", unique_key=["station_id"]) }}

with
    raw as (
        select {{ parse_json(source("raw", "STATION_INFORMATION"), "_raw") }},
        _loaded_at 

        from {{ source("raw", "STATION_INFORMATION") }}

        {% if is_incremental() %}
            where _loaded_at > (select max(_loaded_at) from {{ this }})
        {% endif %}

    ),

    deduped as (
        select *
        from raw
        qualify row_number() over (partition by station_id order by _loaded_at desc) = 1
    )

select *
from deduped
