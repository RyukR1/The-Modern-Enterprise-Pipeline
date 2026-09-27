{% snapshot snap_users %}

{{
    config(
      target_schema='GOLD',
      unique_key='user_id',
      strategy='timestamp',
      updated_at='updated_at',
    )
}}

select
    user_id,
    full_name,
    username,
    email,
    city,
    company_name,
    updated_at
from {{ ref('stg_users') }}

{% endsnapshot %}
