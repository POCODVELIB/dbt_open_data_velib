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
        materialized="incremental",
        unique_key=["nom", "time"],
    )
}}

select {{ parse_json_to_columns(source("raw", "METEO_PARIS"), "_raw") }},
_loaded_at

from {{ source("raw", "METEO_PARIS") }}

{% if is_incremental() %}
    where _loaded_at > (select max(_loaded_at) from {{ this }})
{% endif %}
