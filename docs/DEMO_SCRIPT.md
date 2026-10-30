<img src="Snowflake_Logo.svg" width="200">

# Moon Valley Nursery — 7–10 Minute Executive Demo Script

**Audience:** CTO & Data Lead, Moon Valley Nursery  
**Presenter:** Snowflake Principal Solution Engineer  
**Duration:** 7–10 Minutes  
**Objective:** Prove that **Snowflake Semantic Views + Cortex Agent + a Snowflake-Managed MCP Server** deliver Moon Valley's entire 2027 semantic database + SSAS cube + Power BI + Claude MCP roadmap **today**, with zero extra infrastructure for the Data Lead's lean team to host.

---

## The CTO's Top 5 Executive Questions Featured in This Demo

1. *"Which Arizona stores are behind last year on tree sales this fall, and why?"* (Multi-tool: Kimball Sales SV + Inventory SV + Field Crew Notes Search)
2. *"Where are we running out of palms most often, and what did it cost us in sales?"* (Inventory SV + 14-Day Stockout Risk ML UDF + Warranty Policy Search)
3. *"What is our planting attach rate by state, which stores are lowest, and which scheduled jobs are at risk of delay?"* (Sales SV + Planting Ops SV + Planting Delay Risk ML UDF)
4. *"How are the new Florida stores ramping vs. the Texas stores in their first 12 months?"* (Sales SV + Cohort Visualization)
5. *"Forecast next spring's tree sales by store and category."* (Weekly Sales Forecast ML Registry Model)

---

## Minute-by-Minute Walkthrough

### Act 1: Their 2027 Plan vs. One Governed Platform (1 Minute)

**What to Show:** Open `README.md` and display `docs/images/architecture.svg`.

**Talk Track:**
> "when we spoke in October, you shared a clear vision for 2027: put AI in the hands of the business so executives can ask natural-language questions in Claude and store leaders get fast interactive reporting in Power BI.  
> Right now, doing that on-prem means building and maintaining three new layers on top of your Kimball SQL Server warehouse: a separate semantic-layer database, an interactive SSAS cube (what came up as the 'SSIS/SSAS cube'), and a self-hosted MCP server for Claude. For a lean data team, every new tier is another system to synchronize and troubleshoot.  
> What you're looking at today is your exact three-fact Kimball sales constellation—daily by location, transaction header, and sales line—plus planted jobs, inventory, and marketing, running on synthetic Moon Valley data. We're going to show that **governed Snowflake Semantic Views + one Cortex Agent + a Snowflake-managed MCP server** give you that entire 2027 experience right now."

---

### Act 2: Reproducing the Kimball Constellation & Semantic Views (1 Minute)

**What to Show:** Open `docs/images/kimball_model.svg` and `sql/views/05_create_semantic_views.sql`.

**Talk Track:**
> "We didn't ask you to redesign your data model. Your three sales facts—`FACT_SALES_DAILY_LOCATION`, `FACT_SALES_TRANSACTION`, and `FACT_SALES_LINE`—carry over as-is and reconcile 100% to the penny.  
> On top of those tables, `SV_MOON_VALLEY_SALES`, `SV_MOON_VALLEY_PLANTING_OPS`, and `SV_MOON_VALLEY_INVENTORY_SUPPLY` define your business vocabulary once: 'store' maps to `DIM_LOCATION`, 'revenue' maps to `net_sales`, 'box-tree mix' maps to 24in/36in/48in+ specimen trees, and 'attach rate' maps to professional planting attach. There is no separate semantic database and no separate SSAS cube to process overnight."

---

### Act 3: Snowflake Intelligence — Answering the CTO's Flagship Questions (2 Minutes)

**What to Show:** Open **Snowflake Intelligence** and select **`Moon Valley Business Assistant` (`MOON_VALLEY_AGENT`)**.

**Prompt 1 (Sales + Unstructured Crew Notes):**
```text
Which Arizona stores are behind last year on tree sales this fall, and why? Also check field crew notes for any operational causes in Arizona this fall.
```
**What Happens:**
- `MOON_VALLEY_AGENT` invokes `SalesAnalyst` (`SV_MOON_VALLEY_SALES`) and identifies the 5 underperforming Arizona stores in Fall 2026 vs. Fall 2025: **Surprise Bell Rd (`LOC-AZ-004`)**, **Chandler Ocotillo (`LOC-AZ-007`)**, **Glendale Arrowhead (`LOC-AZ-011`)**, **Buckeye Verrado (`LOC-AZ-015`)**, and **Tucson Ina Rd (`LOC-AZ-019`)**, highlighting lower transaction volume and higher `Manager Price Match` discounting.
- It chains `PlantingNotesSearch` (`MVN_PLANTING_NOTES_SEARCH`) to surface field crew notes showing caliche hardpan excavation delays (requiring hydraulic rock breakers) and 811 Blue Stake utility marking backlogs at those locations.

**Prompt 2 (Inventory + ML Stockout Risk + Warranty Policy):**
```text
Where are we running out of palms most often, what did it cost us in sales, which stores are at risk of stocking out in the next 14 days, and what does our warranty policy say about replacing palms?
```
**What Happens:**
- `InventorySupplyAnalyst` ranks the top stores by palm stockout days and estimated lost sales ($).
- `StockoutRisk` calls `AGENT_STOCKOUT_RISK()` (`MODEL(STOCKOUT_RISK_MODEL, V1)!PREDICT(...)`) to flag stores with <7 days of palm supply and high 14-day stockout probability.
- `WarrantyPolicySearch` retrieves the exact synthetic policy criteria for palm replacements (central spear-leaf test, 90-day standard vs. 1-year Extended Warranty Plan, and 50% crane coverage on 48in+ specimen palms).

---

### Act 4: Claude.ai via Snowflake-Managed MCP Server (2 Minutes)

**What to Show:** Switch to **Claude.ai** connected to `MOON_VALLEY_MCP`. Show the connector settings (`docs/MCP_CLAUDE_SETUP.md`).

**Talk Track:**
> "Now let's switch to Claude.ai—the exact executive experience the CTO asked for. Notice how Claude connects: it points directly to Snowflake's managed MCP endpoint (`MOON_VALLEY_MCP`) using OAuth. The Data Lead's team didn't deploy a single server. And critically, look at the exposed tool list: Claude sees **only** `moon_valley_business_agent`. We do **not** expose `SYSTEM_EXECUTE_SQL`, so Claude can never hallucinate raw SQL or bypass your semantic definitions."

**Prompt in Claude.ai:**
```text
How does gross margin % differ for 24in vs 36in vs 48in+ box trees, and which planting jobs are currently at risk of missing their scheduled date?
```
**What Happens:**
- Claude invokes `moon_valley_business_agent` over MCP.
- Returns the exact box-tree margin ladder (~54% on 24in box, ~61% on 36in box, ~66% on 48in box+ minus promotional discounts) and calls the registered `PLANTING_DELAY_RISK_MODEL` (`V1`) to list active scheduled jobs at risk of delay.

---

### Act 5: Automatic Role-Based Governance — Executive vs. AZ Store Manager (1.5 Minutes)

**What to Show:** Open `docs/images/governance_roles.svg` and run the same prompt/query under `MVN_EXEC_ROLE` vs. `MVN_AZ_STORE_MGR_ROLE`.

**Prompt:**
```text
Show net sales by state this quarter and sample customer contact details.
```
**What Happens:**
- **As `MVN_EXEC_ROLE` (CTO)**: Returns all 5 states (`AZ`, `CA`, `TX`, `NV`, `FL`) across all 100 stores, with clear customer email and phone numbers.
- **As `MVN_AZ_STORE_MGR_ROLE` (Arizona Store Manager)**: `MVN_STATE_ROW_ACCESS_POLICY` automatically restricts the result to **Arizona (`AZ`) only (35 stores)**—and the Arizona total matches the CTO's Arizona row to the penny. Customer emails (`***MASKED***@...`) and phone numbers (`(***) ***-XXXX`) are dynamically masked.

---

### Act 6: Power BI Reconciliation (1 Minute)

**What to Show:** Open `docs/POWER_BI_SETUP.md` / Power BI connected to `SV_MOON_VALLEY_SALES`.

**Talk Track:**
> "When a field leader opens Power BI on Monday morning, Power BI queries `SV_MOON_VALLEY_SALES`—the exact same Semantic View that just answered the CTO's question in Claude. Because `FACT_SALES_DAILY_LOCATION` and `FACT_SALES_LINE` are reconciled in Snowflake and share one metric definition, Power BI and Claude never disagree."

---

### Act 7: Close — Proposed 30-Day Pilot (1 Minute)

**Talk Track:**
> "you don't have to wait until 2027 or stand up a separate semantic database, an SSAS cube, and a self-hosted MCP server.  
> Let's run a focused **30-day pilot** using your 2015+ legacy and POS sales facts that are nearing sign-off:
> - **Week 1:** Land your 3 Kimball sales facts and conformed dimensions in Snowflake.
> - **Week 2:** Stand up `SV_MOON_VALLEY_SALES` and connect Power BI side-by-side.
> - **Week 3:** Turn on `MOON_VALLEY_AGENT` and the managed Claude MCP connector with `MVN_EXEC_ROLE` and store-manager row access.
> - **Success Criteria:** The CTO asks their top five real business questions in Claude, verifies the numbers match Power BI to the penny, and the Data Lead's team has zero new servers to maintain."
