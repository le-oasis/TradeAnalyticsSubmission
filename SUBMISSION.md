# Trading Analytics Submission

## Overview

This project implements a production-grade analytics pipeline for trading performance analysis using **Medallion Architecture** (Bronze → Silver → Gold) with dbt and DuckDB.

**Dataset**: 1,336 trades from 40 clients across 69 accounts (July 15 - August 14, 2025)

---

## Business Questions Answered

### 1. Performance Analysis

#### ✅ Top 10 Performers by Net PnL (Client Level)

**Where**: `analysis/trading_analysis.py` (lines 93-122) and `docs/INSIGHTS.md` (lines 18-24)

| Rank | Client | Segment | Net PnL | Trades |
|------|--------|---------|---------|--------|
| 1 | C0038 | retail | $251,400 | 31 |
| 2 | C0032 | retail | $211,269 | 62 |
| 3 | C0034 | pro | $151,426 | 34 |

**Key Insight**: VIP segment has highest average PnL ($992/trade) despite fewer total trades.

#### ✅ Bottom 10 Underperformers by Net PnL

**Where**: `analysis/trading_analysis.py` (lines 93-122) and `docs/INSIGHTS.md` (lines 27-33)

| Rank | Client | Segment | Net PnL | Trades |
|------|--------|---------|---------|--------|
| 1 | C0025 | retail | -$256,938 | 20 |
| 2 | C0033 | pro | -$161,314 | 52 |
| 3 | C0020 | retail | -$101,930 | 20 |

**Key Insight**: Top 2 underperformers account for 53% of total client losses.

#### ✅ Symbols Contributing Most to Losses

**Where**: `analysis/trading_analysis.py` (lines 108-115) and `docs/INSIGHTS.md` (lines 36-43)

| Symbol | Net PnL | Trades |
|--------|---------|--------|
| US500 | -$179,451 | 62 |
| WTI | -$175,734 | 69 |
| ETHUSD | -$78,787 | 91 |

**Recommendation**: Consider tightening risk limits on US500 and WTI positions.

---

### 2. Activity Analysis

#### ✅ Active Traders per Day/Week

**Where**: `analysis/trading_analysis.py` (lines 125-156) and `docs/INSIGHTS.md` (lines 49-53)

- **Average daily active clients**: 22
- **Peak day**: August 10 (23 clients, 53 trades)
- **Weekly tracking**: Available in `dbt_project/models/marts/fact/f_client_performance_daily.sql`

**Data Model**: Trade dates computed with week aggregation in `stg_trades.sql` (line 42)

#### ✅ Average Trade Size by Symbol

**Where**: `analysis/trading_analysis.py` (lines 143-144)

Top 3 by average volume:
- GER40: 65.8 lots
- FR40: 62.1 lots
- US500: 60.3 lots

#### ✅ Average Trade Size by Client Segment

**Where**: `analysis/trading_analysis.py` (lines 146-148) and `docs/INSIGHTS.md` (lines 55-61)

| Segment | Avg Volume | Median Volume |
|---------|------------|---------------|
| VIP | 52.7 lots | 5.0 lots |
| Retail | 50.1 lots | 5.0 lots |
| Pro | 41.1 lots | 5.0 lots |

**Key Insight**: VIP clients trade larger average sizes but similar median (driven by outliers).

---

### 3. Risk / Account Health

#### ✅ Largest Equity Drawdowns

**Where**: `analysis/trading_analysis.py` (lines 158-189) and `docs/INSIGHTS.md` (lines 67-73)

| Account | Client | Drawdown | Current Equity |
|---------|--------|----------|----------------|
| A12VJ99T2D | C0033 | -99.6% | $395 |
| A2DHYLURTP | C0018 | -94.4% | $1,912 |

**Critical**: Account A12VJ99T2D has essentially blown up (-99.6% drawdown).

**Data Model**: Drawdown calculation in `stg_balances.sql` (lines 22-24):
```sql
balances['peak_equity'] = balances.groupby(['account_id', 'platform'])['equity'].cummax()
balances['drawdown_pct'] = (balances['equity'] - balances['peak_equity']) / balances['peak_equity']
```

#### ✅ Deleted Accounts Still Trading

**Where**:
- `analysis/trading_analysis.py` (lines 176-184)
- `docs/INSIGHTS.md` (lines 76-84)
- **dbt Test**: `dbt_project/tests/assert_no_deleted_accounts_trading.sql`

**9 accounts** flagged with `is_deleted=true` but have recent trades:

| Account | Client | Trades | Net PnL |
|---------|--------|--------|---------|
| AZSJ49ITN7 | C0025 | 20 | -$256,938 |
| AC89K8YQK9 | C0029 | 23 | $141,880 |
| ANFHOLQC3O | C0013 | 24 | -$94,410 |

**Action Required**: Investigate data sync between trading platform and account registry.

---

### 4. Additional Insights

#### Segment Performance Analysis

**Where**: `docs/INSIGHTS.md` (lines 88-96)

| Segment | Clients | Trades | Total PnL | Avg PnL | Win Rate |
|---------|---------|--------|-----------|---------|----------|
| VIP | 7 (18%) | 206 | $204,308 (68%) | $992 | - |
| Pro | 12 | 499 | $70,928 | $142 | - |
| Retail | 21 | 631 | $27,042 | $43 | - |

**Strategic Insight**: VIP clients (18% of clients) generate 68% of total profits.

---

## Modeling Approach

### Medallion Architecture (Bronze → Silver → Gold)

**Bronze Layer** (`dbt_project/models/staging/`):
- `stg_trades.sql`: Side normalization (BUY/SELL standardization)
- `stg_clients.sql`: Segment normalization (lowercase, validated)
- `stg_accounts.sql`: Account flags and metadata
- `stg_balances.sql`: EOD snapshots with surrogate keys
- `stg_symbols.sql`: Symbol reference data

**Silver Layer** (`dbt_project/models/intermediate/`):
- `int_client_spine.sql`: Client-account relationship mapping
- `int_trades_enriched.sql`: Trades enriched with client data, symbol standardization, and flags

**Gold Layer** (`dbt_project/models/marts/`):
- **Dimensions**: `dim_client`, `dim_account`, `dim_symbol`
- **Facts**: `fact_trades`, `fact_account_eod`, `f_client_performance_daily`

### Key Modeling Decisions

✅ **Symbol Normalization**: Platform-specific symbols mapped to standard via `symbols_ref`
- Example: `XAUUSD.m` (MT5) → `XAUUSD`
- Implementation: `int_trades_enriched.sql` (lines 29-35)

✅ **Client Linkage**: Resolves missing `client_external_id` via account registry
```
trades_raw.account_id → accounts_raw.account_id → accounts_raw.client_id → clients_raw.client_id
```
- Implementation: `int_client_spine.sql` and `int_trades_enriched.sql`

✅ **Segment Standardization**: All segments lowercased and validated against `['retail', 'pro', 'vip']`
- Implementation: `stg_clients.sql` (line 17)
- Validation: `_staging.yml` accepted_values test

✅ **Sign Convention** (documented in `docs/ASSUMPTIONS.md`):
- `realized_pnl`: Positive = profit, Negative = loss
- `commission`: Always negative (cost)
- `net_pnl = realized_pnl + commission`

---

## Data Quality Tests

### Custom Business Logic Tests (3+)

1. **`assert_no_deleted_accounts_trading.sql`**
   - Detects deleted accounts with active trades
   - Result: FAIL (9 accounts flagged) ✓ Working as intended

2. **`assert_no_orphan_trades.sql`**
   - Validates all trades link to valid clients
   - Result: PASS ✓

3. **`assert_pnl_reasonable.sql`**
   - Flags trades with extreme PnL values
   - Result: FAIL (11 outliers flagged) ✓ Working as intended

### Schema Tests (27 tests via YAML)

**Staging Layer** (`models/staging/_staging.yml`):
- Unique/not null constraints on primary keys
- Accepted values: `side IN ('BUY', 'SELL')`
- Accepted values: `segment IN ('retail', 'pro', 'vip')`

**Marts Layer** (`models/marts/_marts.yml`):
- Unique/not null on all surrogate keys
- Segment validation in `dim_client`

**Total**: 30 data quality tests, 28 passing (2 intentional alerts)

---

## Deliverables Checklist

### ✅ 1. Data Marts (dbt) - REQUIRED

**Dimensions:**
- [x] `dim_client` - `dbt_project/models/marts/dim/dim_client.sql`
- [x] `dim_account` - `dbt_project/models/marts/dim/dim_account.sql`
- [x] `dim_symbol` - `dbt_project/models/marts/dim/dim_symbol.sql`

**Facts:**
- [x] `fact_trades` - `dbt_project/models/marts/fact/fact_trades.sql`
- [x] `fact_account_eod` - `dbt_project/models/marts/fact/fact_account_eod.sql`
- [x] `f_client_performance_daily` - `dbt_project/models/marts/fact/f_client_performance_daily.sql`

**Total: 6 models as required**

### ✅ 2. Analysis Output - REQUIRED (choose one)

- [x] **Python Script**: `analysis/trading_analysis.py`
  - Answers all performance, activity, and risk questions
  - Console output with formatted tables

- [x] **Excel Dashboard**: `analysis/create_dashboard.py` → `trading_dashboard.xlsx`
  - Executive summary with KPIs
  - Styled tables for all business questions

### ✅ 3. Data Quality Tests - REQUIRED (minimum 3)

**Custom Business Logic Tests:**
- [x] `assert_no_deleted_accounts_trading.sql` - Detects deleted accounts still trading (9 found)
- [x] `assert_no_orphan_trades.sql` - Validates all trades link to clients (0 found)
- [x] `assert_pnl_reasonable.sql` - Flags extreme PnL outliers (11 found)

**Total: 3 custom tests as required**

### ✅ 4. Documentation - REQUIRED

- [x] **README.md**: How to run, approach overview
- [x] **ASSUMPTIONS.md**: Sign conventions, design decisions
- [x] **SUBMISSION.md**: This file - maps questions to answers

### ✅ 5. Technical Requirements - REQUIRED

- [x] **dbt for transformations**: All 6 required marts built with dbt
- [x] **Documented assumptions**: See `docs/ASSUMPTIONS.md`
- [x] **Clean code structure**: Medallion architecture (staging/intermediate/marts)
- [x] **Git repository**: https://github.com/le-oasis/TradeAnalyticsSubmission

---

## How to Run

### Prerequisites

```bash
pip install -r requirements.txt
```

### Step 1: Build Data Pipeline

```bash
cd dbt_project
dbt seed    # Load raw CSV data
dbt run     # Build all models
dbt test    # Run data quality tests
```

**Expected Output**: 13 models built, 28 tests passing, 2 alerts for data quality issues

### Step 2: Run Analysis

```bash
cd ../analysis
python trading_analysis.py          # Console output with all metrics
python create_dashboard.py          # Generates trading_dashboard.xlsx
```

### Step 3: View Documentation (Optional)

```bash
cd dbt_project
dbt docs generate
dbt docs serve    # Opens at http://localhost:8080
```

---

## Repository Structure

```
trading_analytics/
├── dbt_project/
│   ├── models/
│   │   ├── staging/          # Bronze: source cleaning
│   │   ├── intermediate/     # Silver: business logic
│   │   └── marts/            # Gold: analytics-ready
│   ├── tests/                # Custom data quality tests
│   ├── seeds/                # Raw CSV data
│   └── dbt_project.yml       # Configuration
├── analysis/
│   ├── trading_analysis.py   # Python analysis script
│   └── create_dashboard.py   # Excel dashboard generator
├── docs/
│   ├── ASSUMPTIONS.md        # Design decisions
│   └── INSIGHTS.md           # Executive findings
├── data/                     # Original CSV files
├── README.md                 # Quick start guide
├── SUBMISSION.md             # This file
└── requirements.txt          # Python dependencies
```

---

## Challenges Faced & Solutions

### Challenge 1: Missing Client IDs in Trades

**Issue**: Some trades have null `client_external_id`

**Solution**: Built `int_client_spine` to resolve via account registry:
```
trades → accounts → clients
```
Implementation: `int_trades_enriched.sql` joins on `account_id` + `platform`

### Challenge 2: Inconsistent Symbol Names

**Issue**: Platform-specific symbols (e.g., `XAUUSD.m` vs `XAUUSD`)

**Solution**: Symbol normalization via `symbols_ref` lookup table with fallback to original value

### Challenge 3: Data Quality Alerting

**Issue**: Need to flag anomalies without breaking pipeline

**Solution**: Custom dbt tests that intentionally "fail" to surface issues:
- Deleted accounts trading (9 found)
- Extreme PnL values (11 found)

These are expected results documenting real data issues.

---

## Key Findings Summary

1. **VIP Opportunity**: 7 VIP clients (18%) drive 68% of profits → Potential to replicate success patterns
2. **Risk Alert**: Account A12VJ99T2D has -99.6% drawdown → Immediate review required
3. **Data Quality**: 9 deleted accounts still trading → System sync issue to investigate
4. **Symbol Risk**: US500 and WTI driving majority of losses → Consider position limits
5. **Underperformer Concentration**: 2 clients account for 53% of losses → Targeted intervention needed

---

## Summary

### Required Deliverables: ✅ All Met

| Requirement | Required | Delivered | Status |
|-------------|----------|-----------|--------|
| Data Marts (dbt) | 6 models | 6 models | ✅ |
| Data Quality Tests | 3 minimum | 3 custom tests | ✅ |
| Analysis Output | 1 (any format) | Python + Excel | ✅ |
| Documentation | README + assumptions | Complete | ✅ |
| Version Control | Git repo | GitHub | ✅ |

### Additional Engineering (Not Required)

To build the 6 required marts, supporting models were created:
- **Staging layer** (5 models): Data cleaning and normalization
- **Intermediate layer** (2 models): Business logic and enrichment
- **Schema tests** (27 tests): Additional data quality validation

These follow dbt best practices for production pipelines but were not explicitly required.

---

## Technologies Used

- **dbt** v1.10+ with DuckDB adapter
- **DuckDB** - Embedded analytical database
- **Python** - pandas, openpyxl for analysis
- **Git** - Version control

---

## Author

Analytics Engineer Candidate Submission
Submitted: December 14, 2025
