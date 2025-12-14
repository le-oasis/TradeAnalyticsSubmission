# Assumptions & Design Decisions

## Sign Conventions

| Field | Convention |
|-------|------------|
| `realized_pnl` | Positive = profit, Negative = loss |
| `commission` | Always negative (cost to trader) |
| `net_pnl` | `realized_pnl + commission` |
| `drawdown_pct` | Negative value (0% = at peak, -50% = 50% below peak) |

## Data Quality Decisions

### Side Normalization
Raw values `BUY`, `buy`, `B` → `'BUY'`
Raw values `SELL`, `sell`, `S` → `'SELL'`

### Segment Normalization
All segments lowercased and trimmed.
Valid values: `retail`, `pro`, `vip`

### Jurisdiction Validation
Valid codes: `MU`, `CY`, `SC`, `XX`
Invalid/null → preserved as null (not imputed)

### Symbol Standardization
- Platform-specific symbols (e.g., `XAUUSD.m` on MT5) mapped to standard symbols (`XAUUSD`) via `symbols_ref`
- Unmapped symbols retain original value

## Filtering Logic

### Excluded from Analysis
1. **Cancelled trades**: `status = 'CANCELLED'`
2. **System accounts**: `is_system = true`

### Included but Flagged
1. **Deleted accounts with trades**: `is_deleted = true` - flagged for risk review
2. **Orphan trades**: Trades without client linkage - flagged for data quality

## Client Resolution

```
trades_raw.account_id 
  → accounts_raw.account_id 
  → accounts_raw.client_id 
  → clients_raw.client_id
```

Note: `client_external_id` in trades_raw is inconsistent; we resolve via account linkage instead.

## Incremental Strategy

For production at scale:
- `fact_trades`: Incremental by `trade_date`
- `fact_account_eod`: Incremental by `snapshot_date`
- Dimensions: Full refresh (small tables)

## Cost Optimization Patterns

1. **Early filtering**: Remove cancelled/system rows in staging
2. **Columnar design**: Measures separate from dimensions
3. **Pre-aggregation**: `f_client_performance_daily` for common queries
4. **Partitioning**: Date-based partitions for time-series facts
