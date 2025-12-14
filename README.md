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
│   │   ├── staging/          # Bronze: source cleaning & typing (5 models)
│   │   ├── intermediate/     # Silver: business logic & enrichment (2 models)
│   │   └── marts/            # Gold: analytics-ready dimensions & facts (6 models)
│   │       ├── dim/          # 3 dimensions: client, account, symbol
│   │       └── fact/         # 3 facts: trades, account_eod, client_performance_daily
│   ├── tests/                # 3 custom data quality tests
│   ├── seeds/                # Raw CSV data files
│   └── dbt_project.yml       # dbt configuration
├── analysis/                 # Python analysis & visualizations
├── docs/                     # Documentation & assumptions
├── trading_dashboard.xlsx    # Pre-generated Excel dashboard (BONUS)
├── SUBMISSION.md             # Answers to brief questions (START HERE)
├── README.md                 # This file
└── requirements.txt          # Python dependencies
```

## 🚀 Quick Start

**→ See `SUBMISSION.md` for detailed answers to all brief questions**

```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Setup database and run pipeline
cd dbt_project
dbt seed    # Load raw CSV data
dbt run     # Build all models (13 models)
dbt test    # Run data quality tests (30 tests, 28 passing, 2 alerts)

# 3. Run analysis
cd ../analysis
python trading_analysis.py          # Console output with all metrics
python create_dashboard.py          # Generates trading_dashboard.xlsx

# Note: A pre-generated dashboard is included in the repo root

# 4. View dbt documentation (optional)
cd ../dbt_project
dbt docs generate
dbt docs serve  # Opens at http://localhost:8080
```

**Expected Results**:
- 13 models built successfully (6 required marts + 7 supporting)
- 30 tests run (3 required custom + 27 schema tests)
  - 28 passing + 2 intentional alerts for data quality issues
- Analysis output shows 1,336 trades from 40 clients
- Excel dashboard available at: `trading_dashboard.xlsx` (pre-generated and included)

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
