/*
Description :  POC ingestion données Velib et météo à Paris dans Snowflake
               Cette macro prend un json en entree table et col_name) et 
               split le json pour construire une table tabulaire equiavalente 

-------------------------------------------------------------------------------------
Author      : Said HOUSSEINE   
Created     : 2026-04-22
-------------------------------------------------------------------------------------
*/
{% macro parse_json_to_columns(source_table, json_col="_raw") %}

    {%- if execute -%}
        {%- set query %}
            SELECT
                f.key,
                COALESCE(
                    MODE(CASE WHEN TYPEOF(f.value) != 'NULL_VALUE'
                         THEN TYPEOF(f.value) END),
                    'TEXT'
                ) AS dtype
            FROM {{ source_table }},
            LATERAL FLATTEN(input => PARSE_JSON({{ json_col }})) f
            WHERE {{ json_col }} IS NOT NULL
            GROUP BY f.key
        {%- endset %}

        {%- set type_map = {
            "INTEGER": "INT",
            "DOUBLE": "FLOAT",
            "REAL": "FLOAT",
            "BOOLEAN": "BOOLEAN",
            "ARRAY": "VARIANT",
            "OBJECT": "VARIANT",
            "TEXT": "VARCHAR",
        } -%}

        {%- set results = run_query(query) -%}
        {%- set columns = [] -%}

        {%- for row in results.rows -%}
            {%- set dtype = type_map.get(row[1], "VARCHAR") -%}
            {%- do columns.append(
                "PARSE_JSON("
                ~ json_col
                ~ "):"
                ~ row[0]
                ~ "::"
                ~ dtype
                ~ " AS "
                ~ row[0]
                | lower
            ) -%}
        {%- endfor -%}

        {{ columns | join(",\n    ") }}
    {%- endif -%}

{% endmacro %}
