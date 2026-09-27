with raw_staged_events as (
    select * from {{ ref('stg_events') }}
),

deduplicated as (
    select
        event_id,
        user_id,
        trim(event_title) as event_title,
        trim(event_body) as event_body,
        event_timestamp,
        row_number() over (
            partition by event_id
            order by event_timestamp desc, _loaded_at_utc desc
        ) as row_num
    from raw_staged_events
)

select
    event_id,
    user_id,
    event_title,
    event_body,
    event_timestamp
from deduplicated
where row_num = 1
