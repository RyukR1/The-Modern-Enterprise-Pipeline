{% macro date_to_key(date_column) %}
    {# Formats a date column into an integer YYYYMMDD surrogate key #}
    {% if target.type == 'snowflake' %}
        cast(to_char({{ date_column }}, 'YYYYMMDD') as integer)
    {% else %}
        cast(strftime({{ date_column }}, '%Y%m%d') as integer)
    {% endif %}
{% endmacro %}

{% macro month_name(date_column) %}
    {# Formats a date column into full month name #}
    {% if target.type == 'snowflake' %}
        to_char({{ date_column }}, 'MMMM')
    {% else %}
        strftime({{ date_column }}, '%B')
    {% endif %}
{% endmacro %}
