-- dim_symbol.sql
-- Gold layer: Symbol dimension

with symbols as (
    select * from {{ ref('stg_symbols') }}
)

select
    symbol_key,
    platform,
    platform_symbol,
    std_symbol,
    asset_class,
    quote_currency,
    tick_value

from symbols
