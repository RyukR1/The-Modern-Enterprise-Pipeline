{% macro generate_surrogate_key(field_list) %}
    {# Wraps dbt_utils surrogate key generator with fallback to MD5 concat #}
    {% if execute and adapter.get_compiler() %}
        {{ return(dbt_utils.generate_surrogate_key(field_list)) }}
    {% else %}
        md5(
            {% for field in field_list %}
                coalesce(cast({{ field }} as varchar), '')
                {% if not loop.last %} || '-' || {% endif %}
            {% endfor %}
        )
    {% endif %}
{% endmacro %}
