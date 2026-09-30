{#
  The few expressions Databricks SQL and DuckDB spell differently, so the same models build on the Databricks warehouse
  (target dev) and on a local DuckDB file (target ci, used by GitHub Actions).
#}

{% macro as_date(text) -%}
    {%- if target.type == 'duckdb' -%} cast('{{ text }}' as date) {%- else -%} to_date('{{ text }}') {%- endif -%}
{%- endmacro %}

{% macro today() -%}
    {%- if target.type == 'duckdb' -%} current_date {%- else -%} current_date() {%- endif -%}
{%- endmacro %}

{% macro days_between(start_date, end_date) -%}
    {%- if target.type == 'duckdb' -%} date_diff('day', {{ start_date }}, {{ end_date }})
    {%- else -%} datediff({{ end_date }}, {{ start_date }}) {%- endif -%}
{%- endmacro %}

{# One row per day from start to end, as a column named date_day. #}
{% macro date_spine(start_text, end_text) -%}
    {%- if target.type == 'duckdb' -%}
    select cast(range as date) as date_day
    from range({{ as_date(start_text) }}, {{ as_date(end_text) }} + interval 1 day, interval 1 day)
    {%- else -%}
    select explode(sequence({{ as_date(start_text) }}, {{ as_date(end_text) }}, interval 1 day)) as date_day
    {%- endif -%}
{%- endmacro %}

{# Day of week with Sunday = 1 and Saturday = 7 on both engines (DuckDB's dayofweek counts Sunday as 0). #}
{% macro day_of_week(date_col) -%}
    {%- if target.type == 'duckdb' -%} (dayofweek({{ date_col }}) + 1) {%- else -%} dayofweek({{ date_col }}) {%- endif -%}
{%- endmacro %}
