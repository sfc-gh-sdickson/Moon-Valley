# Snowflake Intelligence Agent Project Template

## Purpose
Retail Nursery Sales, Inventory & Planting-Operations Intelligence at Moon Valley Nursery

Moon Valley Nursery is a vertically integrated, family-owned "farm-to-yard" tree and plant nursery. It grows its own trees on large farms, sells through 100+ retail nursery locations across Arizona, California, Nevada, Texas and Florida, and delivers design and professional planting services. The business is highly seasonal (spring and fall peaks, summer heat dips in the desert Southwest) and is still opening stores in new markets.

Today the data warehouse is an on-premises Microsoft SQL Server built on a Kimball star schema. Reporting runs on SSRS (standard reports) and Power BI (dashboards). Tableau is being phased out because the team lacks the staff to support it. The data lead's 2027 plan adds a separate semantic-layer database, a cube for interactive access, Power BI for field users, and an MCP connection to Claude so executives can ask questions in natural language.

This project builds a natural-language intelligence agent on synthetic Moon Valley data. It shows that **one Snowflake semantic view + one Cortex Agent + a Snowflake-managed MCP server** delivers that whole 2027 plan now, with governed, role-aware answers that match Power BI and nothing new for a small team to host.

## Customer details
About Moon Valley Nursery
Moon Valley Nursery is one of the largest privately owned tree and plant nurseries in the U.S. It is known for large, mature box trees, plus palms, fruit trees, flowering trees, shrubs, groundcover, fertilizer and soil products, and professional design and planting services.

Vertically integrated "farm-to-yard" operations
Moon Valley controls the chain end to end: farms (growing inventory) → transfer to retail nurseries → sale → delivery and planting by field crews → warranty and aftercare. Each stage produces data in a different system, which is both the quality advantage and the integration challenge.

Business dynamics
- 100+ retail locations across AZ, CA, NV, TX and FL; newer FL/TX stores are still ramping.
- Strong spring (Mar–May) and fall (Oct–Nov) peaks; summer dip in AZ/NV heat.
- Large box trees (24in / 36in / 48in+) drive ticket size and margin.
- Professional planting is a key attach service; planted jobs are tracked in a field services app.
- Inventory is living product with long grow cycles, so stockouts of popular items (e.g., palms) lose sales.

The data reality (from customer discovery, October 2026, with Catherine Digua, data lead, and Bill Serva, CTO)
- **Warehouse:** on-prem SQL Server with a Kimball star schema. The team prefers on-prem for now; a move to Microsoft Fabric is the eventual direction but "not anytime soon."
- **Sales model:** a constellation of three fact tables: sales by day by location; sales by day by location by transaction; and sales by line.
- **Sources:** Oracle POS; a field services solution tracking planted jobs; legacy sales back to 2015 (near sign-off); inventory data next; a marketing data warehouse being brought in.
- **Reporting:** SSRS for standard reports; Power BI for dashboards; Tableau being phased out because they lack staff to support it.
- **2027 plan:** a semantic layer in its own database in front of the warehouse; a cube for interactive access (customer said "SSIS cube"; likely SSAS, so confirm); Power BI-style reporting for field users; an MCP connection to Claude for executive natural-language questions.
- **Constraint:** a small data team. Every new system adds maintenance load.

Strategic direction
Moon Valley wants to grow the business and put AI in the hands of the business. This agent is the first proof point: a mock agent on synthetic nursery data that shows the 2027 semantic layer + Claude experience delivered today, without a migration and without new infrastructure.

### Demo story (what we are proving)
1. **One semantic view replaces the separate semantic database and the cube.** Business definitions live in one place.
2. **Claude connects through a Snowflake-managed MCP server** that exposes only the Cortex Agent. No raw SQL, no self-hosted server.
3. **Governance is automatic.** Each question runs as the signed-in user; an Arizona store manager sees only Arizona, and executives see everything.
4. **Answers match Power BI.** Power BI reads the same semantic view and returns the same number as Claude.
5. **Their Kimball model carries over unchanged.** The three-fact constellation is reproduced as-is.

---

## Customer Configuration

**To create a new project, replace these variables throughout:**

| Variable | Description | Value (Moon Valley Nursery) |
|----------|-------------|-------------------|
| `{CUSTOMER_NAME}` | Customer name | Moon Valley Nursery |
| `{CUSTOMER_NAME_UPPER}` | Uppercase for SQL objects | MOONVALLEY |
| `{DATABASE_NAME}` | Main database name | MVN_INTELLIGENCE |
| `{WAREHOUSE_NAME}` | Warehouse name | MOON_VALLEY_WH |
| `{AGENT_NAME}` | Agent identifier | MOON_VALLEY_AGENT |
| `{MCP_SERVER_NAME}` | Managed MCP server | MOON_VALLEY_MCP |
| `{BUSINESS_DOMAIN}` | Customer's business focus | Vertically Integrated Tree & Plant Nursery Retail, Planting Services & Inventory |
| `{WEB_PRESENCE}` | Web Address | https://www.moonvalleynurseries.com/ |

---

## Project Instructions

```Build a complete Snowflake Intelligence architecture and implementation plan for Moon Valley Nursery.

The proposed architecture is a governed analytics and AI platform that reproduces Moon Valley's existing Kimball star schema (three sales fact tables plus conformed dimensions) in Snowflake. It adds planted-jobs, inventory and marketing data, then exposes everything through semantic views that are used by a Cortex Agent, Snowflake Intelligence, Power BI and Claude (via a Snowflake-managed MCP server). Executives, store managers and analysts ask natural-language questions about sales, margin, planting attach, inventory/stockouts, store ramp and seasonality, with role-based row access and masking applied automatically. This demo should have a minimum of 3 semantic views, 3 cortex searches, 3 ML Models.

Use SYNTHETIC data only. No Moon Valley data is required.

(Note: All project images should be SVG graphics)
 This Project should encompass all aspects of the details identified on their website. The Agent Project Structure directories should be created in the root github repo directory.

## Agent Project Structure

```
/
├── README.md                           # Project overview and setup instructions
├── docs/
│   ├── AGENT_SETUP.md                 # Step-by-step agent configuration guide
│   ├── MCP_CLAUDE_SETUP.md            # Managed MCP server + Claude.ai connector guide
│   ├── POWER_BI_SETUP.md              # Connecting Power BI to the semantic view
│   ├── DEMO_SCRIPT.md                 # 7–10 minute demo script for Catherine & Bill
│   ├── DEPLOYMENT_SUMMARY.md          # Current deployment status
│   ├── questions.md                   # 30+ complex test questions
│   └── images/
│       ├── architecture.svg           # System architecture diagram
│       ├── deployment_flow.svg        # Deployment workflow diagram
│       ├── kimball_model.svg          # Star schema / fact constellation
│       ├── governance_roles.svg       # Same question, different role results
│       └── ml_models.svg              # ML pipeline visualization
├── notebooks/
│   └── 07_ml_models.ipynb             # ML model training
└── sql/
    ├── setup/
    │   ├── 01_database_and_schema.sql # Database, schemas (RAW, ANALYTICS, REFERENCE), warehouse
    │   └── 02_create_tables.sql       # Dimensions, facts, reference tables
    ├── data/
    │   ├── 03_generate_synthetic_data.sql # Synthetic nursery data
    ├── views/
    │   ├── 04_create_views.sql        # Analytical views
    │   └── 05_create_semantic_views.sql # Semantic view for Cortex Analyst / Power BI / MCP
    ├── search/
    │   └── 06_create_cortex_search.sql # Planting-job notes, care guides, warranty policy text
    ├── models/
    │   └── 08_ml_model_functions.sql  # ML prediction UDFs calling registered models
    ├── agent/
    │   └── 09_create_agent.sql        # Agent creation script
    ├── governance/
    │   └── 10_roles_and_policies.sql  # EXEC_ROLE, AZ_STORE_MGR_ROLE, row access, masking
    └── mcp/
        └── 11_create_mcp_server.sql   # Snowflake-managed MCP server exposing ONLY the agent
```

---

## File Execution Order

**MUST be executed in this exact order:**

1. `sql/setup/01_database_and_schema.sql`
2. `sql/setup/02_create_tables.sql`
3. `sql/data/03_generate_synthetic_data.sql`
3b. `sql/data/03b_seed_reference_data.sql`
4. `sql/views/04_create_views.sql`
5. `sql/views/05_create_semantic_views.sql`
6. `sql/search/06_create_cortex_search.sql`
7. `notebooks/07_ml_models.ipynb`
8. `sql/models/08_ml_model_functions.sql`
9. `sql/agent/09_create_agent.sql`
10. `sql/governance/10_roles_and_policies.sql`
11. `sql/mcp/11_create_mcp_server.sql`

The documentation should include an SVG image showing this flow.

---

## Suggested Data Model (Kimball, mirroring the customer)

Model Moon Valley's actual design: conformed dimensions plus a **constellation of three sales fact tables**, with supporting planted-jobs, inventory and marketing facts. Land in RAW, surface through ANALYTICS views.

### Dimensions

| Table | Grain | Key fields |
|-------|-------|-----------|
| `DIM_DATE` | one row per day (2015-01-01 → today) | date_key, date, week, month, quarter, year (fiscal = calendar), season (Spring/Summer/Fall/Winter), is_holiday, is_peak_season |
| `DIM_LOCATION` | one row per nursery (~100) | location_id, location_name, city, state, region, market, open_date, sq_ft, hardiness_zone, is_new_market |
| `DIM_FARM` | one row per growing farm | farm_id, farm_name, state, acres |
| `DIM_PRODUCT` | one row per SKU (~400) | product_id, sku, product_name, category (Shade Trees, Palms, Fruit Trees, Flowering Trees, Shrubs, Groundcover, Fertilizer & Soil, Services), container_size (15 gal / 24in box / 36in box / 48in box+), unit_price, unit_cost, water_use, plant_symbol |
| `DIM_CUSTOMER` | one row per customer (~50k) | customer_id, customer_type (Homeowner, Landscaper, Builder/Commercial), zip, state, first_purchase_date, email (masked), phone (masked) |
| `DIM_SALESPERSON` | one row per salesperson (~400) | salesperson_id, name, location_id, hire_date |
| `DIM_CREW` | one row per planting crew | crew_id, location_id, crew_size |
| `DIM_CAMPAIGN` | one row per marketing campaign | campaign_id, channel, start_date, end_date, region |

### Sales fact constellation (same three grains as the customer)

| Table | Grain | Key fields |
|-------|-------|-----------|
| `FACT_SALES_DAILY_LOCATION` | date × location | date_key, location_id, gross_sales, net_sales, discounts, units, transactions, gross_margin |
| `FACT_SALES_TRANSACTION` | date × location × transaction | transaction_id, date_key, location_id, customer_id, salesperson_id, campaign_id, net_sales, units, includes_planting_flag |
| `FACT_SALES_LINE` | transaction × line | transaction_id, line_no, product_id, qty, unit_price, discount, extended_price, unit_cost |

**Consistency rule:** `FACT_SALES_DAILY_LOCATION` MUST equal the aggregate of `FACT_SALES_LINE` by date and location (so the agent and Power BI reconcile).

### Supporting facts

| Table | Grain | Key fields |
|-------|-------|-----------|
| `FACT_PLANTED_JOBS` | one row per planting job | job_id, transaction_id, location_id, crew_id, sold_date, scheduled_date, completed_date, status (Scheduled/Completed/Rescheduled/Cancelled), warranty_flag, notes_id |
| `FACT_INVENTORY_DAILY` | date × location × product | date_key, location_id, product_id, on_hand_units, on_order_units, stockout_flag |
| `FACT_FARM_TRANSFERS` | one row per transfer | transfer_id, farm_id, location_id, product_id, ship_date, units |
| `FACT_MARKETING_LEADS` | one row per lead | lead_id, campaign_id, location_id, lead_date, converted_transaction_id |

### Realism rules for synthetic data
- Spring and fall peaks; summer dip in AZ/NV; milder seasonality in FL.
- FL/TX stores opened recently and ramping (lower same-store base, faster growth).
- Box trees: fewer units, much higher ticket and margin.
- ~35% of tree transactions include planting; attach rate varies by store (some clearly low).
- A handful of underperforming AZ stores this fall vs. last fall (demo storyline).
- Recurring palm stockouts at specific locations in peak weeks, with lost-sales impact.
- Planting lead time (sold → completed) longer in peak season; a few crews with high reschedule rates.
- Sales history back to 2015 (matches the legacy load nearing sign-off); denser detail 2023+.

### Reference tables (REFERENCE schema)

| Table | Grain | Key fields | Source standard |
|-------|-------|-----------|-----------------|
| `HARDINESS_ZONE_DIM` | one row per zone | zone, min_temp_f_low, min_temp_f_high | USDA Plant Hardiness Zone Map |
| `PLANT_TAXONOMY_DIM` | one row per species | plant_symbol, scientific_name, common_name, family, growth_habit | USDA PLANTS Database |
| `WATER_USE_DIM` | one row per class | water_use_class (Very Low/Low/Moderate/High), description | Regional low-water-use plant lists (representative) |
| `GS1_IDENTIFIERS` | product / location | gtin, gln, product_id, location_id | GS1 (GTIN / GLN) |
| `PRODUCT_TAXONOMY_MAP` | SKU × species | product_id, plant_symbol, hardiness_min_zone, hardiness_max_zone, water_use_class | Internal crosswalk |

**Why include this:** it lets the agent answer "which trees we sell are suited to this store's zone and are low-water-use" (relevant in desert markets), and it standardizes product naming across POS, inventory and farm systems. *These are external public standards. Seed representative reference data; do not fabricate regulatory or agronomic text as fact.*

---

## Governance Layer (CRITICAL for this demo)

`10_roles_and_policies.sql` must create:
- `MVN_EXEC_ROLE`: sees all locations and all metrics.
- `MVN_AZ_STORE_MGR_ROLE`: row access policy limiting all location-keyed facts to `state = 'AZ'`.
- Masking policy on `DIM_CUSTOMER.email` and `DIM_CUSTOMER.phone`: masked for the store-manager role, clear for exec.
- Grants so both roles can use the semantic view, the agent and the MCP server.

**Demo moment:** ask the same question as each role and show different, correct results.

---

## Managed MCP Server (CRITICAL for this demo)

`11_create_mcp_server.sql` must create a Snowflake-managed MCP server that exposes **only the Cortex Agent** (type `CORTEX_AGENT_RUN`), so Claude gets one governed interface. **Do NOT expose `SYSTEM_EXECUTE_SQL`.** Use OAuth.

```sql
CREATE OR REPLACE MCP SERVER MVN_INTELLIGENCE.ANALYTICS.MOON_VALLEY_MCP
  FROM SPECIFICATION
  $$
  tools:
    - title: "Moon Valley Business Assistant"
      name: "moon_valley_business_agent"
      type: "CORTEX_AGENT_RUN"
      identifier: "MVN_INTELLIGENCE.ANALYTICS.MOON_VALLEY_AGENT"
      description: "Governed answers about Moon Valley sales, margin, planting, inventory and store performance."
  $$;
```
*(Verify current syntax with `snowflake_product_docs` → "Snowflake-managed MCP server" before running. Hostnames must use hyphens, not underscores.)*

`docs/MCP_CLAUDE_SETUP.md` must document adding the server in Claude.ai as an organization custom connector and authenticating via OAuth.

---

## Critical Syntax Reference

### Snowflake Agent YAML Specification (VERIFIED WORKING)

```yaml
CREATE OR REPLACE AGENT MOON_VALLEY_AGENT
  COMMENT = 'Moon Valley Nursery intelligence agent'
  PROFILE = '{"display_name": "Moon Valley Business Assistant", "color": "green"}'
  FROM SPECIFICATION
  $$
  models:
    orchestration: auto

  orchestration:
    budget:
      seconds: 60
      tokens: 32000

  instructions:
    response: "Answer for executives in plain business language. Lead with the number, then a short explanation. Always state the time period, filters and locations included. Never invent data; if data is unavailable, say so."
    orchestration: "Use SalesAnalyst for any quantitative question on sales, margin, planting, inventory, stores or campaigns. Use OperationsSearch for planting-job notes, care guides and warranty policy text. Use ML functions for forecasts, stockout risk and planting-delay risk."
    system: "You are the Moon Valley Nursery Business Assistant, helping executives, store managers and analysts understand sales, planting operations and inventory across Moon Valley's nurseries."
    sample_questions:
      - question: "Which Arizona stores are behind last year on tree sales this fall, and why?"
        answer: "List the stores with YoY variance, then drivers (traffic, ticket, category mix, stockouts)."

  tools:
    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "SalesAnalyst"
        description: "Governed sales, margin, planting, inventory, store and campaign metrics from the Moon Valley semantic view."
    - tool_spec:
        type: "cortex_search"
        name: "OperationsSearch"
        description: "Search planting-job notes, plant care guides and warranty policy text."
    - tool_spec:
        type: "generic"
        name: "StockoutRisk"
        description: "Predicted stockout risk by location and product for the next 14 days."

  tool_resources:
    SalesAnalyst:
      semantic_view: "MVN_INTELLIGENCE.ANALYTICS.SV_MOON_VALLEY_SALES"
    OperationsSearch:
      name: "MVN_INTELLIGENCE.ANALYTICS.MVN_OPERATIONS_SEARCH"
      max_results: "10"
      title_column: "title"
      id_column: "doc_id"
    StockoutRisk:
      type: "function"
      identifier: "MVN_INTELLIGENCE.ANALYTICS.AGENT_STOCKOUT_RISK"
      execution_environment:
        type: "warehouse"
        warehouse: "MOON_VALLEY_WH"
  $$;
```

### SQL UDF Return Types (VERIFIED)

| Function Returns | Correct Return Type |
|------------------|---------------------|
| `ARRAY_AGG(...)` | `RETURNS ARRAY` |
| `OBJECT_CONSTRUCT(...)` | `RETURNS OBJECT` |
| Single scalar value | `RETURNS VARCHAR/NUMBER/etc` |

**DO NOT USE:**
- `RETURNS VARIANT` for `ARRAY_AGG` or `OBJECT_CONSTRUCT`
- `LANGUAGE SQL` clause in SQL UDFs

### SQL UDF Syntax (VERIFIED)

```sql
CREATE OR REPLACE FUNCTION AGENT_GET_DATA()
RETURNS ARRAY
AS
$$
SELECT ARRAY_AGG(OBJECT_CONSTRUCT(
    'key1', COLUMN1,
    'key2', COLUMN2
)) FROM (SELECT * FROM TABLE LIMIT 50)
$$;

CREATE OR REPLACE FUNCTION AGENT_GET_SUMMARY()
RETURNS OBJECT
AS
$$
SELECT OBJECT_CONSTRUCT(
    'metric1', (SELECT COUNT(*) FROM TABLE1),
    'metric2', (SELECT AVG(COLUMN) FROM TABLE2)
)
$$;
```

---

## Lessons Learned (CRITICAL)

### 1. ALWAYS VERIFY SNOWFLAKE SYNTAX BEFORE WRITING CODE
- Use `snowflake_product_docs` to look up syntax BEFORE writing any SQL
- Use `system_instructions` for Cortex Agent, Analyst, MCP server and other Snowflake products
- Past errors: `RETURNS VARIANT` instead of `ARRAY`/`OBJECT`; `LANGUAGE SQL` in SQL UDFs; `type: "procedure"` instead of `type: "function"` for agent tools; `search_service:` instead of `name:` for Cortex Search resources; JSON instead of YAML for agent specs

### 2. COMPLETE ALL FILES BEFORE STOPPING
- Review ALL files at the start, create a TODO list for every file, and verify each compiles/runs before moving on

### 3. NEVER GUESS - ASK OR RESEARCH
- Verify agent YAML, UDF return types, naming conventions, tool resources and MCP server spec against docs

### 4. ASK QUESTIONS WHEN UNCLEAR
- Confirm: the five executive questions Bill cares about most; whether "SSIS cube" means SSAS; which roles to demo

### 5. SEMANTIC VIEWS USE TABLES/DIMENSIONS/METRICS — NOT SELECT...FROM
- Declare tables as `alias AS fully.qualified.table PRIMARY KEY (...)`
- Column synonyms use `WITH SYNONYMS = (...)`; table synonyms use `WITH SYNONYMS (...)`
- Define RELATIONSHIPS between the three sales facts and conformed dimensions
- Required synonyms: "store" = location; "revenue" = net sales; "tree sales" = tree categories; "attach rate" = planting attach rate; "comp" / "same-store" = same-store sales
- Required metrics: net sales, gross margin, gross margin %, units, transactions, average ticket, planting attach rate, YoY growth, same-store sales, stockout days, lost sales estimate, days sold-to-planted, lead conversion rate
- Add verified queries for every demo question

### 6. SNOWFLAKE NOTEBOOKS — SESSION AND SQL CELL RULES
- ALWAYS `get_active_session()`; NEVER `Session.builder`
- ALWAYS dedicated SQL cells with `result_variable_name`; NEVER `session.sql()` for standard queries
- Do NOT call `.to_pandas()` on SQL cell results
- ALWAYS call `get_notebook_guide` before writing notebook code

### 7. VERIFY GIT MERGE CONFLICTS
- Search for `<<<<<<<`, `=======`, `>>>>>>>` before marking files complete

### 8. ML MODELS MUST BE REGISTERED IN MODEL REGISTRY AND CALLED BY UDFs — NO EXCEPTIONS

Relevant models for Moon Valley:
- **Store × category weekly sales forecast** (seasonality-aware)
- **Stockout risk classifier** (location × product, next 14 days)
- **Planting attach propensity** (transaction-level)
- **Planting delay risk** (job likely to miss scheduled date)

Mandatory pipeline: notebook trains → `registry.log_model()` → `mv.set_metric()` → SQL UDF calls `MODEL(name, version)!PREDICT(...)` → agent tool references UDF → end-to-end verified. NEVER substitute hardcoded thresholds for a trained model.

---

## Component Templates

### Database Setup (01_database_and_schema.sql)

```sql
CREATE DATABASE IF NOT EXISTS MVN_INTELLIGENCE;
USE DATABASE MVN_INTELLIGENCE;

CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS ANALYTICS;
CREATE SCHEMA IF NOT EXISTS REFERENCE;

CREATE OR REPLACE WAREHOUSE MOON_VALLEY_WH WITH
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Warehouse for Moon Valley Nursery Intelligence Agent';

USE WAREHOUSE MOON_VALLEY_WH;
```

### Cortex Search Service

```sql
CREATE OR REPLACE CORTEX SEARCH SERVICE MVN_OPERATIONS_SEARCH
  ON content
  ATTRIBUTES doc_type, location_id, state
  WAREHOUSE = MOON_VALLEY_WH
  TARGET_LAG = '1 hour'
  COMMENT = 'Planting-job notes, plant care guides and warranty policy text'
AS
  SELECT doc_id, title, content, doc_type, location_id, state
  FROM MVN_INTELLIGENCE.RAW.OPERATIONS_DOCUMENTS;
```
Content: synthetic crew notes (access issues, reschedules, soil/irrigation observations), care guides by category and zone, warranty and replacement policy text (representative, clearly synthetic).

### Semantic View

```sql
CREATE OR REPLACE SEMANTIC VIEW SV_MOON_VALLEY_SALES

  TABLES (
    {alias} AS MVN_INTELLIGENCE.ANALYTICS.{table}
      PRIMARY KEY ({primary_key_column})
      WITH SYNONYMS ('{synonym1}', '{synonym2}')
      COMMENT = '{Table description}'
  )

  RELATIONSHIPS (
    {fact_alias}({fk}) REFERENCES {dim_alias}({pk})
  )

  DIMENSIONS (
    {alias}.{column} AS {COLUMN_NAME}
      WITH SYNONYMS = ('{synonym1}', '{synonym2}')
      COMMENT = '{Column description}'
  )

  METRICS (
    {alias}.{metric_name} AS {AGG_FUNC}({column})
      WITH SYNONYMS = ('{synonym1}', '{synonym2}')
      COMMENT = '{Metric description}'
  )

  COMMENT = 'Moon Valley governed sales, planting and inventory model. Single source for Cortex Agent, Power BI and Claude via MCP.';
```

**IMPORTANT: Semantic views do NOT use SELECT...FROM syntax.**

### Snowflake Notebook (07_ml_models.ipynb)

```python
from snowflake.snowpark.context import get_active_session
session = get_active_session()
```
```sql
-- SQL cell, result_variable_name: "df_sales"
SELECT * FROM MVN_INTELLIGENCE.ANALYTICS.V_WEEKLY_SALES_STORE_CATEGORY
```
```python
print(f'Rows: {len(df_sales)}')
```

---

## Sample Questions the Agent Should Answer

Sales & store performance:
- Which Arizona stores are behind last year on tree sales this fall, and why?
- Compare same-store sales this spring vs. last spring by state.
- How are the new Florida stores ramping vs. the Texas stores in their first 12 months?
- What's our average ticket by customer type, and how has it changed YoY?
- Which salespeople have the highest box-tree mix?

Margin & product mix:
- Which product categories drive the most gross margin this year?
- How does gross margin % differ for 24in vs. 36in vs. 48in+ box trees?
- Which discounts are eroding margin the most, and at which stores?

Planting operations:
- What is our planting attach rate by state, and which stores are lowest?
- What's the average time from sale to completed planting by region and season?
- Which crews have the highest reschedule rate this month?
- Which planting jobs are at risk of missing their scheduled date? (ML)

Inventory & farm-to-store:
- Where are we running out of palms most often, and what did it cost us in sales?
- Which stores are at risk of stocking out of top sellers in the next two weeks? (ML)
- Which farms supply the stores with the highest sell-through?

Forecasting & seasonality:
- Forecast next spring's tree sales by store. (ML)
- How much of annual sales comes in the spring and fall peaks by state?

Marketing:
- Which campaigns produced the most converted sales last quarter?
- What's the lead-to-sale conversion rate by channel and region?

Reference / suitability:
- Which trees we sell are low-water-use and suited to Phoenix-area hardiness zones?
- Map our SKUs to scientific names and hardiness ranges.

Search (unstructured):
- What are the most common reasons planting jobs were rescheduled in Arizona this fall?
- What does our warranty policy say about replacing palms?

Governance (run as two roles):
- "Show net sales by state this quarter" as EXEC_ROLE vs. AZ_STORE_MGR_ROLE (AZ only, customer contacts masked).

---

## Demo Script Outline (docs/DEMO_SCRIPT.md, 7–10 minutes)

1. **Their plan (1 min):** semantic database + cube + Claude MCP in 2027 means three builds for a small team.
2. **One semantic view (1 min):** show the Kimball constellation reproduced and the business definitions in one place.
3. **Snowflake Intelligence (2 min):** ask the AZ fall tree-sales question and the palm-stockout question.
4. **Claude via MCP (2 min):** ask the same question in Claude.ai; same answer, same governance, nothing hosted.
5. **Governance (1 min):** same question as exec vs. AZ store manager.
6. **Power BI (1 min):** Power BI on the same semantic view returns the same number.
7. **Close (1 min):** propose a 30-day pilot on their 2015+ sales facts. Success = Bill asks five real questions and trusts the answers.

---

## Checklist for New Projects

### Before Starting
- [ ] Confirm customer name and business domain
- [ ] Synthetic data only, mirroring the three-fact Kimball constellation
- [ ] Confirm ML models (sales forecast, stockout risk, planting attach, planting delay)
- [ ] Collect Bill's top five executive questions (if available)
- [ ] Confirm "SSIS cube" = SSAS

### During Development
- [ ] Verify ALL SQL, semantic view, agent and MCP syntax against Snowflake docs
- [ ] Daily fact reconciles to line fact
- [ ] Test each SQL file compiles before moving on
- [ ] Check for merge conflicts

### Before Delivery
- [ ] Run all files in order (01–11)
- [ ] Agent answers every sample question correctly
- [ ] Role-based results verified (exec vs. AZ store manager)
- [ ] MCP server works from Claude.ai with OAuth; no raw SQL tool exposed
- [ ] Power BI returns the same numbers as the agent
- [ ] Documentation and SVGs complete; no placeholders
- [ ] Teardown script provided

---

## Reference Links

- Snowflake Agent Docs: `snowflake_product_docs` → "Cortex Agent"
- Snowflake-managed MCP server: `snowflake_product_docs` → "Snowflake-managed MCP server"
- SQL UDF Reference: `snowflake_product_docs` → "CREATE FUNCTION SQL"
- Cortex Search: `snowflake_product_docs` → "CREATE CORTEX SEARCH SERVICE"
- Semantic Views: `snowflake_product_docs` → "CREATE SEMANTIC VIEW"
- Row access / masking policies: `snowflake_product_docs` → "CREATE ROW ACCESS POLICY", "CREATE MASKING POLICY"

---

## Version History

- **v1.0**: Moon Valley Nursery retail, planting and inventory agent, adapted from the Foster Farms v2 template
- **Created:** October 2026
- **Lessons Learned:** Carried forward from previous projects

---

## DO NOT:
1. Guess at syntax - VERIFY FIRST
2. Use `RETURNS VARIANT` for `ARRAY_AGG` or `OBJECT_CONSTRUCT`
3. Use `LANGUAGE SQL` in SQL UDFs
4. Use JSON format for Agent specification (use YAML)
5. Leave merge conflicts in files
6. Mark tasks complete before verifying they work
7. Assume you know Snowflake syntax without checking
8. Use text based graphics
9. Use `SELECT ... FROM` syntax in `CREATE SEMANTIC VIEW`
10. Use `Session.builder.configs(...).create()` in Snowflake Notebooks
11. Use `session.sql()` in Snowflake Notebooks for standard queries
12. Call `.to_pandas()` on SQL cell results
13. Train ML models without registering them in the Model Registry
14. Use hardcoded thresholds in UDFs when a trained model exists
15. Mark ML tasks complete without verifying train → register → UDF → agent
16. Expose `SYSTEM_EXECUTE_SQL` on the MCP server
17. Use real Moon Valley data or fabricate agronomic/regulatory text as fact

## DO:
1. Use `snowflake_product_docs` before writing SQL
2. Use `system_instructions` for Cortex products
3. Reference working examples
4. Ask questions when requirements are unclear
5. Test each file compiles before moving on
6. Complete ALL files before stopping
7. Verify no merge conflicts exist
8. Always generate documentation
9. Always generate SVG images for the documentation
10. Always generate all files and never placeholders
11. Always put this line at the top of all documentation files: <img src="Snowflake_Logo.svg" width="200">
12. In Snowflake Notebooks, ALWAYS use `get_active_session()` and dedicated SQL cells
13. ALWAYS call `get_notebook_guide` before writing notebook code
14. Expose ONLY the Cortex Agent through the MCP server
15. Keep the daily, transaction and line sales facts reconciled
