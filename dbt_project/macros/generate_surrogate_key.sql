{% macro generate_surrogate_key(field_list) %}
    {# Delegates surrogate key generation to dbt_utils package #}
    {{ return(dbt_utils.generate_surrogate_key(field_list)) }}
{% endmacro %}
