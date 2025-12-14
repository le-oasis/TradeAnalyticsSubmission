# Trading Analytics Platform

Production-grade analytics pipeline for trading performance analysis using **Medallion Architecture**.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        MEDALLION ARCHITECTURE                          │
├─────────────┬─────────────────────┬─────────────────────────────────────┤
│   BRONZE    │       SILVER        │              GOLD                   │
│  (staging)  │   (intermediate)    │             (marts)                 │
├─────────────┼─────────────────────┼─────────────────────────────────────┤
│ stg_trades  │ int_trades_enriched │ dim_client, dim_account, dim_symbol │
│ stg_accounts│ int_client_spine    │ fact_trades, fact_account_eod       │
│ stg_clients │                     │ f_client_performance_daily          │
│ stg_balances│                     │                                     │
│ stg_symbols │                     │                                     │
└─────────────┴─────────────────────┴─────────────────────────────────────┘
```

## 📁 Project Structure

```
trading_analytics/
├── dbt_project/
│   ├── models/
│   │   ├── staging/          # Bronze: source cleaning & typing
│   │   ├── intermediate/     # Silver: business logic & enrichment
│   │   └── marts/            # Gold: analytics-ready dimensions & facts
│   │       ├── dim/
│   │       └── fact/
│   ├── tests/                # Data quality tests
│   ├── macros/               # Reusable SQL functions
│   └── seeds/                # Reference data
├── analysis/                 # Python analysis & visualizations
└── docs/                     # Documentation & assumptions
```

## 🚀 Quick Start

```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Setup database and run pipeline
cd dbt_project
dbt seed
dbt run
dbt test

# 3. Run analysis
cd ../analysis
python trading_analysis.py
python create_dashboard.py  # Optional: creates Excel dashboard
```

## 📊 Business Questions Answered

| Category | Question | Location |
|----------|----------|----------|
| Performance | Top/Bottom 10 by Net PnL | `f_client_performance_daily` |
| Performance | Loss-driving symbols | `fact_trades` aggregations |
| Activity | Active traders daily/weekly | `fact_trades` + `dim_client` |
| Activity | Avg trade size by segment | `fact_trades` + `dim_client` |
| Risk | Largest equity drawdowns | `fact_account_eod` |
| Risk | Deleted accounts still trading | `int_trades_enriched` flags |

## 🔧 Key Design Decisions

### Sign Convention
- `realized_pnl`: Positive = profit, Negative = loss
- `commission`: Always negative (cost to trader)
- `net_pnl = realized_pnl + commission`

### Data Quality Handling
- **Side normalization**: BUY/buy/B → 'BUY', SELL/sell/S → 'SELL'
- **Segment normalization**: Lowercased, validated against ['retail','pro','vip']
- **Symbol mapping**: Platform-specific → standardized via `symbols_ref`
- **Client linkage**: `client_external_id` from trades → `accounts_raw` → `clients_raw`

### Cost-Optimized Patterns (for scale)
- Incremental models with `unique_key` for large fact tables
- Partitioning-ready date columns
- Columnar aggregations in intermediate layer
- Early filtering in staging to reduce downstream volume

## 🧪 Data Quality Tests

| Test | Model | Logic |
|------|-------|-------|
| Unique trade_id | `fact_trades` | No duplicate trades |
| Not null client_key | `fact_trades` | All trades linked to client |
| Accepted values: side | `fact_trades` | Only BUY/SELL allowed |
| Accepted values: segment | `dim_client` | Only retail/pro/vip |
| Custom: deleted trading | `int_trades_enriched` | Alert on deleted accounts with trades |

## 📝 Assumptions

1. `status = 'CANCELLED'` trades excluded from PnL calculations
2. `is_system = true` accounts excluded from client-facing metrics
3. Date range: July-August 2025 (sample data period)
4. Currency: All PnL reported in trade's quote_currency (no FX conversion)

## 👤 Author

Analytics Engineer Candidate Submission
