with staged_users as (
    select * from {{ ref('stg_users') }}
),

user_event_summary as (
    select
        user_id,
        count(event_id) as total_events_logged,
        min(event_timestamp) as first_event_at,
        max(event_timestamp) as last_event_at
    from {{ ref('int_events_cleaned') }}
    group by user_id
),

final_dim_users as (
    select
        {{ generate_surrogate_key(['u.user_id']) }} as user_key,
        u.user_id,
        u.full_name,
        u.username,
        u.email,
        u.city,
        u.company_name,
        coalesce(s.total_events_logged, 0) as total_events_logged,
        s.first_event_at,
        s.last_event_at,
        u.updated_at
    from staged_users u
    left join user_event_summary s
        on u.user_id = s.user_id
)

select * from final_dim_users
