{% macro insert_audit_metadata() %}
    current_timestamp() as _loaded_at_utc,
    '{{ invocation_id }}' as _dbt_invocation_id
{% endmacro %}
