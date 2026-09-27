with cleaned_events as (
    select * from {{ ref('int_events_cleaned') }}
),

staged_users as (
    select * from {{ ref('stg_users') }}
),

joined_events as (
    select
        e.event_id,
        e.user_id,
        u.full_name as user_full_name,
        u.email as user_email,
        u.company_name as user_company_name,
        e.event_title,
        e.event_body,
        e.event_timestamp,
        cast(e.event_timestamp as date) as event_date
    from cleaned_events e
    left join staged_users u
        on e.user_id = u.user_id
)

select * from joined_events
