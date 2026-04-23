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
        materialized='incremental',
        unique_key=['station_id', 'last_reported']
    )
}}

with raw as (

select {{ parse_json( source('raw', 'STATION_STATUS'), "_raw")}},
_loaded_at
from {{source('raw', 'STATION_STATUS')}}


    {% if is_incremental() %}
        where _loaded_at > (      SELECT CONVERT_TIMEZONE('UTC', MAX(_loaded_at)) from {{ this }})
    {% endif %}
),

deduped as (
    select *
    from raw
    qualify row_number() over (
        partition by station_id, last_reported
        order by _loaded_at desc
    ) = 1
)

select * from deduped