-- stg_clients.sql
-- Bronze layer: segment normalization, jurisdiction validation

with source as (
    select * from {{ source('raw', 'clients_raw') }}
),

cleaned as (
    select
        client_id,
        client_external_id,
        
        -- Normalize segment to lowercase
        lower(trim(segment)) as segment,
        
        -- Validate jurisdiction (nullify invalid)
        case 
            when upper(jurisdiction) in ('MU', 'CY', 'SC', 'XX') 
            then upper(jurisdiction)
            else null 
        end as jurisdiction,
        
        cast(created_at as timestamp) as created_at
        
    from source
    where client_id is not null
)

select * from cleaned
