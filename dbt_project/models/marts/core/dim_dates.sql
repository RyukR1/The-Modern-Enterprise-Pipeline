with date_spine as (
    select
        cast('2024-01-01' as date) + interval (seq - 1) day as date_day
    from (
        select row_number() over () as seq
        from (
            select 1 union all select 2 union all select 3 union all select 4 union all select 5
        ) a
        cross join (
            select 1 union all select 2 union all select 3 union all select 4 union all select 5
        ) b
        cross join (
            select 1 union all select 2 union all select 3 union all select 4 union all select 5
        ) c
        cross join (
            select 1 union all select 2 union all select 3 union all select 4 union all select 5
        ) d
    ) numbers
    limit 1000
),

calculated_date_dimensions as (
    select
        cast(strftime(date_day, '%Y%m%d') as integer) as date_key,
        date_day,
        extract(year from date_day) as year,
        extract(quarter from date_day) as quarter,
        extract(month from date_day) as month,
        strftime(date_day, '%B') as month_name,
        extract(day from date_day) as day_of_month,
        extract(dayofweek from date_day) as day_of_week,
        case when extract(dayofweek from date_day) in (0, 6) then true else false end as is_weekend
    from date_spine
)

select * from calculated_date_dimensions
