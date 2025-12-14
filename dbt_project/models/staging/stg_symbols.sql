-- stg_symbols.sql
-- Bronze layer: Symbol reference mapping

with source as (
    select * from {{ source('raw', 'symbols_ref') }}
),

cleaned as (
    select
        -- Surrogate key
        {{ dbt_utils.generate_surrogate_key(['platform', 'platform_symbol']) }} as symbol_key,
        
        platform,
        platform_symbol,
        std_symbol,
        asset_class,
        quote_currency,
        cast(tick_value as decimal(18,4)) as tick_value
        
    from source
)

select * from cleaned
