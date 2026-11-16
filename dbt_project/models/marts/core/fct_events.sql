{{
    config(
        materialized='incremental',
        unique_key='event_key',
        on_schema_change='append_new_columns',
        cluster_by=['event_date', 'user_id']
    )
}}

with joined_events as (
    select * from {{ ref('int_events_joined') }}
    {% if is_incremental() %}
        {% if target.type == 'snowflake' %}
            where event_timestamp >= (select dateadd('day', -3, coalesce(max(event_timestamp), '1970-01-01'::timestamp)) from {{ this }})
        {% else %}
            where event_timestamp >= (select coalesce(max(event_timestamp), timestamp '1970-01-01') - interval '3 days' from {{ this }})
        {% endif %}
    {% endif %}
),

final_fct_events as (
    select
        {{ generate_surrogate_key(['e.event_id']) }} as event_key,
        e.event_id,
        {{ generate_surrogate_key(['e.user_id']) }} as user_key,
        e.user_id,
        {{ date_to_key('e.event_date') }} as date_key,
        e.event_title,
        e.event_body,
        e.event_timestamp,
        e.event_date,
        current_timestamp() as _inserted_at
    from joined_events e
)

select * from final_fct_events
