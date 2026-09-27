with source_data as (
    select * from {{ source('raw_api', 'raw_events') }}
),

parsed_events as (
    select
        cast(raw_payload:id as varchar) as event_id,
        cast(raw_payload:userId as varchar) as user_id,
        cast(raw_payload:title as varchar) as event_title,
        cast(raw_payload:body as varchar) as event_body,
        coalesce(
            cast(raw_payload:created_at as timestamp),
            ingested_at
        ) as event_timestamp,
        {{ insert_audit_metadata() }}
    from source_data
)

select * from parsed_events
