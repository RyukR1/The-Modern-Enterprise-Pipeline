with source_data as (
    select * from {{ source('raw_api', 'raw_users') }}
),

parsed_users as (
    select
        cast({{ json_extract('raw_payload', 'id') }} as varchar) as user_id,
        cast({{ json_extract('raw_payload', 'name') }} as varchar) as full_name,
        cast({{ json_extract('raw_payload', 'username') }} as varchar) as username,
        cast({{ json_extract('raw_payload', 'email') }} as varchar) as email,
        cast({{ json_extract('raw_payload', 'address.city') }} as varchar) as city,
        cast({{ json_extract('raw_payload', 'company.name') }} as varchar) as company_name,
        coalesce(
            cast({{ json_extract('raw_payload', 'updated_at') }} as timestamp),
            ingested_at
        ) as updated_at,
        {{ insert_audit_metadata() }}
    from source_data
)

select * from parsed_users
