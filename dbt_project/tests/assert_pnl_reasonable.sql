-- tests/assert_pnl_reasonable.sql
-- Custom test: Flag unreasonably large PnL (potential data errors)

with extreme_pnl as (
    select
        trade_id,
        client_id,
        std_symbol,
        volume,
        net_pnl,
        abs(net_pnl / nullif(volume, 0)) as pnl_per_lot
    from {{ ref('fact_trades') }}
    where abs(net_pnl) > 100000  -- Flag trades > 100k PnL
      or abs(net_pnl / nullif(volume, 0)) > 10000  -- Flag > 10k per lot
)

-- Test warns if any extreme values found
select * from extreme_pnl
