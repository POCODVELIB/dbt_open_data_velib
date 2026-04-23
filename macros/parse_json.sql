/*
Description :  POC ingestion données Velib et météo à Paris dans Snowflake
               Cette macro prend un json en entree table et col_name) et 
               split le json pour construire une table tabulaire equiavalente 

-------------------------------------------------------------------------------------
Author      : Said HOUSSEINE   
Created     : 2026-04-22
-------------------------------------------------------------------------------------
*/


{% macro parse_json(source_table, json_col="_raw") %}

    {%- if execute -%}
        {%- set query %}
            SELECT f.key, MODE(TYPEOF(f.value)) AS dtype
            FROM {{ source_table }},
            LATERAL FLATTEN(input => PARSE_JSON({{ json_col }})) f
            WHERE {{ json_col }} IS NOT NULL
            AND TYPEOF(f.value) != 'NULL_VALUE'
            GROUP BY f.key
        {%- endset %}

        -- on lit 1000 lignes pour determiner tous les k:v du json et ainsi contruire la
        -- structure du json
        {%- set results = run_query(query) -%}
        {%- set columns = [] -%}

        {%- for row in results.rows -%}
            {%- do columns.append(
                "PARSE_JSON("
                ~ json_col
                ~ "):"
                ~ row[0]
                ~ "::"
                ~ row[1]
                ~ " AS "
                ~ row[0]
                | lower
            ) -%}
        {%- endfor -%}

        {{ columns | join(",\n    ") }}
    {%- endif -%}

{% endmacro %}