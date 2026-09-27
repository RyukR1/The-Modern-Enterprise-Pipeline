{% macro json_extract(column_name, json_path) %}
    {# Cross-database JSON extraction macro supporting both Snowflake and DuckDB #}
    {% if target.type == 'snowflake' %}
        {{ column_name }}:{{ json_path }}
    {% else %}
        json_extract_string({{ column_name }}, '$.{{ json_path }}')
    {% endif %}
{% endmacro %}
