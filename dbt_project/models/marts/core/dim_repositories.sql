with raw_events as (
    select * from {{ ref('int_events_joined') }}
),

repo_metrics as (
    select
        company_name as repo_name,
        count(distinct event_id) as total_events_count,
        count(distinct user_id) as unique_contributors_count,
        min(event_timestamp) as first_seen_at,
        max(event_timestamp) as last_seen_at
    from raw_events
    where company_name is not null
    group by company_name
),

final_dim_repositories as (
    select
        {{ generate_surrogate_key(['repo_name']) }} as repo_key,
        repo_name,
        total_events_count,
        unique_contributors_count,
        first_seen_at,
        last_seen_at,
        current_timestamp() as _updated_at
    from repo_metrics
)

select * from final_dim_repositories
