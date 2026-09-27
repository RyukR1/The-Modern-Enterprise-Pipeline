{{
    config(
        materialized='incremental',
        unique_key='event_key',
        on_schema_change='append_new_columns'
    )
}}

with joined_events as (
    select * from {{ ref('int_events_joined') }}
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

{% if is_incremental() %}
    where event_timestamp > (select max(event_timestamp) from {{ this }})
{% endif %}
