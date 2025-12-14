-- stg_trades.sql
-- Bronze layer: type casting, side normalization, basic cleaning

with source as (
    select * from {{ source('raw', 'trades_raw') }}
),

cleaned as (
    select
        -- Keys
        trade_id,
        account_id,
        client_external_id,
        
        -- Dimensions
        platform,
        symbol,
        case upper(side)
            when 'BUY' then 'BUY'
            when 'B' then 'BUY'
            when 'SELL' then 'SELL'
            when 'S' then 'SELL'
            else upper(side)
        end as side,
        status,
        book_flag,
        counterparty,
        quote_currency,
        
        -- Measures
        cast(volume as decimal(18,4)) as volume,
        cast(open_price as decimal(18,6)) as open_price,
        cast(close_price as decimal(18,6)) as close_price,
        cast(commission as decimal(18,4)) as commission,
        cast(realized_pnl as decimal(18,4)) as realized_pnl,
        
        -- Timestamps
        cast(open_time as timestamp) as open_time,
        cast(close_time as timestamp) as close_time,
        
        -- Derived
        cast(open_time as date) as trade_date
        
    from source
    where trade_id is not null
)

select * from cleaned
