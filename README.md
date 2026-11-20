# ☕ Cafe Sales Data Analysis & BI Project

An end-to-end data analytics project investigating **10,000 retail transactions** from an urban cafe in 2023. This project demonstrates realistic data cleaning, deterministic mathematical recovery, exploratory data analysis (EDA), statistical hypothesis testing, SQL database modeling, and an interactive business intelligence dashboard.

---

## 🌐 Live Interactive Dashboard

Explore the deployed dashboard with glassmorphism UI, real-time KPI aggregations, and responsive filtering:

👉 **[Open the Cafe Sales Dashboard (Live on Netlify)](https://cafe-sales-dashboard8.netlify.app/)**

---

## 📊 Executive Summary & Verified Metrics

All figures below are grounded directly in the cleaned dataset (`data/processed/cafe_sales_cleaned.csv`):

| Metric | Verified Value | Notes / Business Context |
| :--- | :--- | :--- |
| **Total Raw Transactions** | **10,000** | Full transaction log spanning calendar year 2023 |
| **Priced / Analyzable Orders** | **9,977** (99.77%) | 23 rows had unrecoverable pricing/quantity data |
| **Total Gross Revenue** | **$89,096.00** | Total realized sales across all priced orders |
| **Total Units Sold** | **30,170** | Total individual menu items purchased |
| **Average Order Value (AOV)** | **$8.93** | Average spend per customer order |
| **Top Revenue Contributor** | **Salad ($19,095.00)** | **21.4%** of total revenue ($5.00 unit price) |
| **Top Volume Contributor** | **Coffee (1,286 orders)** | **3,904 units**, but only **8.8%** of revenue ($7,808.00) |
| **High-Quantity Basket Share** | **61.1%** | Orders with 4 or 5 units account for $54,420 of revenue |
| **Undated Revenue Leakage** | **$4,173.50** (460 txns) | 4.6% of orders lack timestamps, requiring POS telemetry fixes |

---

## 🔍 Key Business Findings

1. **Price, Not Volume, Dictates Revenue Performance**:
   - **Salad** generated the highest revenue ($19,095; 21.4% share), followed by **Sandwich** ($13,716; 15.4%) and **Smoothie** ($13,344; 15.0%).
   - **Coffee** was the most frequently purchased item (1,286 orders; 3,904 units) yet contributed only 8.8% ($7,808) due to its $2.00 price point.
   - Menu unit volumes remain remarkably flat across all items (ranging between 3,336 units for Smoothies and 3,904 units for Coffee), suggesting price inelasticity for core staples like Coffee, Cookie, and Tea.
2. **Basket Size Concentration**:
   - Customers buying 4 units ($19,968) and 5 units ($34,452) make up **61.1%** of total revenue. Strategic bundling (e.g., Beverage + Pastry combos) offers immediate upsell potential.
3. **Channel & Payment Method Uniformity**:
   - Transactions split evenly across Payment Methods (Cash: 24.3%, Credit Card: 24.5%, Digital Wallet: 19.4%, Unknown: 31.8%).
   - A non-parametric **Kruskal-Wallis statistical test** yielded $p \approx 0.79$, confirming no statistically significant difference in customer spending across payment channels.
4. **Data Hygiene & POS Telemetry Deficiencies**:
   - 31.8% of transactions omitted Payment Method, 39.6% omitted Location, and 4.6% omitted Transaction Date. Addressing POS validation rules will significantly improve ongoing telemetry and cohort tracking.

---

## 🛠️ Data Cleaning & Recovery Methodology

The raw dataset (`data/raw/cafe_sales_dirty.csv`) contained significant anomalies, empty string tokens, and calculation gaps. Cleaning was implemented consistently across both **Python (Pandas)** and **T-SQL (SQL Server)**:

1. **Token Standardization**:
   - Stripped whitespace and replaced placeholder strings (`''`, `'ERROR'`, `'UNKNOWN'`) with true `NULL` values.
2. **Mathematical & Deterministic Imputation**:
   - **Menu Reference Pricing**: Imputed missing unit prices using known fixed menu items (`Cookie` = $1.00, `Tea` = $1.50, `Coffee` = $2.00, `Cake` = $3.00, `Juice` = $3.00, `Sandwich` = $4.00, `Smoothie` = $4.00, `Salad` = $5.00).
   - **Two-Pass Bidirectional Recovery**: Leveraged the relational constraint $\text{Total} = \text{Quantity} \times \text{Price}$:
     - If `Total` was missing $\rightarrow$ Calculated as $\text{Quantity} \times \text{Price}$.
     - If `Quantity` was missing $\rightarrow$ Calculated as $\text{Total} / \text{Price}$.
     - If `Price` was missing $\rightarrow$ Calculated as $\text{Total} / \text{Quantity}$.
   - **Unique Price Back-Mapping**: Where items were missing but unit price was unique ($1.00 $\rightarrow$ Cookie, $1.50 $\rightarrow$ Tea, $2.00 $\rightarrow$ Coffee, $5.00 $\rightarrow$ Salad), the item name was recovered. Ambiguous price points ($3.00 and $4.00) were safely assigned `'Unknown'` to avoid false attribution.
3. **Categorical Imputation**:
   - Unassigned categorical values (`Item`, `Payment Method`, `Location`) were standardized to `'Unknown'`.

---

## 📁 Project Structure

```text
data_analyst_proj/
├── .gitignore                             # Git exclusion rules for analytics artifacts
├── README.md                              # Project documentation and audit summary
├── requirements.txt                       # Python dependencies (pandas, scipy, matplotlib, etc.)
│
├── dashboards/                            # Interactive BI Dashboards
│   ├── cafe_sales_dashboard.html          # Lightweight, self-contained interactive dashboard
│   └── cafe_sales_dashboard_source.html   # Formatted source dashboard code
│
├── data/                                  # Data storage layer
│   ├── raw/
│   │   └── cafe_sales_dirty.csv           # Original 10,000-row unprocessed dataset
│   └── processed/
│       ├── cafe_sales_cleaned.csv         # Cleaned, imputed, and typed dataset
│       └── cafe_sales_analysis.xlsx       # Multi-tab Excel workbook with pivot models
│
├── notebooks/                             # Exploratory Data Analysis & Modeling
│   ├── cafe_sales_analysis.ipynb          # Python data cleaning, EDA, and statistical tests
│   └── dirty_cafe_sales.csv               # Input copy referenced by the notebook
│
└── sql/                                   # SQL Server (T-SQL) Scripts
    ├── cafe_sales_cleaning.sql            # Menu table & dbo.cafe_clean view definitions
    ├── cafe_sales_kpis.sql                # KPI aggregation queries and revenue breakdowns
    └── cafe_sales_full_analysis.sql       # End-to-end ingestion, staging, cleaning, and checks
```

---

## 🚀 How to Reproduce

### 1. Python Environment Setup
```bash
# Clone the repository (once hosted on GitHub)
git clone https://github.com/<your-username>/<repo-name>.git
cd data_analyst_proj

# Create and activate virtual environment
python -m venv .venv
source .venv/bin/activate       # On Linux/macOS
# or: .\.venv\Scripts\Activate.ps1 # On Windows PowerShell

# Install dependencies
pip install -r requirements.txt

# Run the Jupyter Notebook
jupyter notebook notebooks/cafe_sales_analysis.ipynb
```

### 2. SQL Server Pipeline Execution
To execute the pipeline in SQL Server Management Studio (SSMS) or Azure Data Studio:
1. Load `data/raw/cafe_sales_dirty.csv` into table `dbo.raw_cafe_sales`.
2. Run `sql/cafe_sales_full_analysis.sql` to generate:
   - Scalar function `dbo.fn_clean_txt`
   - Staging typed view `dbo.stg_typed`
   - Master reference table `dbo.menu`
   - Cleaned analytics view `dbo.cafe_clean`
3. Execute `sql/cafe_sales_kpis.sql` to produce executive metrics and window function revenue shares.

### 3. Interactive Dashboard
Open `dashboards/cafe_sales_dashboard.html` in any modern web browser or visit the [Live Netlify Dashboard](https://cafe-sales-dashboard8.netlify.app/).

---

## 🛡️ Data Governance & Audit Notes

- **Zero Sensitive Data**: All customer transaction identifiers (`TXN_xxxxxxx`) and sales amounts are anonymized/synthetic. No PII, passwords, connection strings, or cloud access keys exist within this workspace.
- **Data Integrity**: Verified identical MD5 checksum between raw CSV inputs (`data/raw/cafe_sales_dirty.csv` and `notebooks/dirty_cafe_sales.csv`).
- **Reproducibility**: All statistical assertions (e.g., Kruskal-Wallis test, AOV calculations) are directly verifiable through the included Jupyter Notebook and SQL queries.
