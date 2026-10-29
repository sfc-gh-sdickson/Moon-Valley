<img src="Snowflake_Logo.svg" width="200">

# Moon Valley Nursery — 32 Complex Test Questions for `MOON_VALLEY_AGENT`

These 32 test questions validate all **3 Semantic Views**, **3 Cortex Search services**, **4 registered ML Model UDFs**, **multi-tool chaining**, and **role-based governance (`MVN_EXEC_ROLE` vs. `MVN_AZ_STORE_MGR_ROLE`)**.

---

## 1. Sales & Store Performance (`SalesAnalyst` -> `SV_MOON_VALLEY_SALES`)

1. **Flagship Demo Question #1:** *"Which Arizona stores are behind last year on tree sales this fall, and why?"*
   - **Tools Invoked:** `SalesAnalyst` + `InventorySupplyAnalyst` + `PlantingNotesSearch`
   - **Expected Insight:** Identifies the 5 Arizona stores with negative YoY Fall 2026 vs. Fall 2025 tree sales (`LOC-AZ-004` Surprise Bell Rd, `LOC-AZ-007` Chandler Ocotillo, `LOC-AZ-011` Glendale Arrowhead, `LOC-AZ-015` Buckeye Verrado, `LOC-AZ-019` Tucson Ina Rd) and explains the drivers: recurring peak palm stockouts, higher `Manager Price Match` discounting, and caliche/utility planting reschedule bottlenecks.
2. *"Compare same-store sales this spring vs. last spring by state."*
   - **Tool Invoked:** `SalesAnalyst` (`daily_sales.same_store_sales`, `dates.season = 'Spring'`, `dates.year IN (2025, 2026)`)
3. **Flagship Demo Question #4:** *"How are the new Florida stores ramping vs. the Texas stores in their first 12 months?"*
   - **Tools Invoked:** `SalesAnalyst` (`locations.is_new_market = TRUE`) + `data_to_chart`
4. *"What is our average ticket by customer type (Homeowner, Landscaper, Builder/Commercial), and how has it changed YoY from 2025 to 2026?"*
   - **Tool Invoked:** `SalesAnalyst` (`transactions.average_ticket`, `customers.customer_type`)
5. *"Which salespeople have the highest box-tree mix percentage and total box-tree sales?"*
   - **Tool Invoked:** `SalesAnalyst` (`sales_lines.box_tree_mix_pct`, `sales_lines.box_tree_sales`, `salespeople.salesperson_name`)
6. *"How much of annual net sales comes during the Spring and Fall peak seasons by state?"*
   - **Tool Invoked:** `SalesAnalyst` (`dates.is_peak_season`, `locations.state`, `sales_lines.net_sales`)

---

## 2. Gross Margin & Product Mix (`SalesAnalyst` -> `SV_MOON_VALLEY_SALES`)

7. *"Which product categories drive the most gross margin dollars and highest gross margin percentage this year?"*
   - **Tool Invoked:** `SalesAnalyst` (`products.category`, `sales_lines.gross_margin`, `sales_lines.gross_margin_pct`)
8. *"How does gross margin % differ for 24in box vs. 36in box vs. 48in+ box trees?"*
   - **Tool Invoked:** `SalesAnalyst` (Verified Query `box_tree_margin_by_size`: `48in box+` highest margin %, followed by `36in box`, then `24in box`)
9. *"Which discount promotion types are eroding gross margin the most, and at which stores?"*
   - **Tool Invoked:** `SalesAnalyst` (`sales_lines.discount_promo_type`, `sales_lines.total_discounts`, `sales_lines.discount_rate_pct`, `locations.location_name`)
10. *"What is our attach revenue from Fertilizer & Soil (Moon Juice, Moon Green, Super Palm Juice) on transactions that include trees?"*
    - **Tool Invoked:** `SalesAnalyst` (`products.category = 'Fertilizer & Soil'`)

---

## 3. Professional Planting Operations (`PlantingOpsAnalyst` -> `SV_MOON_VALLEY_PLANTING_OPS`)

11. **Flagship Demo Question #3:** *"What is our planting attach rate by state, and which stores have the lowest planting attach rate?"*
    - **Tool Invoked:** `SalesAnalyst` (`transactions.planting_attach_rate` by `locations.state` and `locations.location_name`)
12. *"What is the average time from sale to completed planting by region and season?"*
    - **Tool Invoked:** `PlantingOpsAnalyst` (Verified Query `lead_time_by_region_season`: `planted_jobs.avg_days_sold_to_planted`)
13. *"Which planting crews have the highest reschedule rate, and what are their primary reschedule reasons?"*
    - **Tool Invoked:** `PlantingOpsAnalyst` (Verified Query `top_reschedule_crews`: `planted_jobs.reschedule_rate_pct`, `planted_jobs.reschedule_reason`)
14. *"What percentage of planted jobs include the Extended Tree Warranty Plan by container size and state?"*
    - **Tool Invoked:** `PlantingOpsAnalyst` (`planted_jobs.warranty_attach_rate_pct`)

---

## 4. Inventory, Palm Stockouts & Farm-to-Store Supply (`InventorySupplyAnalyst` -> `SV_MOON_VALLEY_INVENTORY_SUPPLY`)

15. **Flagship Demo Question #2:** *"Where are we running out of palms most often, and what did it cost us in sales?"*
    - **Tool Invoked:** `InventorySupplyAnalyst` (Verified Query `palm_stockouts_by_store`: `inventory.stockout_days`, `inventory.lost_sales_estimate`)
16. *"Which growing farms supply the retail stores with the highest daily sell-through velocity?"*
    - **Tool Invoked:** `InventorySupplyAnalyst` (`farms.farm_name`, `farm_transfers.total_transferred_units`, `inventory.avg_daily_sell_rate`)
17. *"What is the average transit time and freight cost from each growing farm to our Texas and Florida stores?"*
    - **Tool Invoked:** `InventorySupplyAnalyst` (`farms.farm_name`, `farm_transfers.avg_transit_days`)
18. *"Which Shade Tree and Palm SKUs currently have fewer than 7 days of supply on hand in Arizona?"*
    - **Tool Invoked:** `InventorySupplyAnalyst` (`inventory.avg_days_of_supply`, `locations.state = 'AZ'`)

---

## 5. Marketing Campaigns & Lead Conversion (`SalesAnalyst` -> `SV_MOON_VALLEY_SALES`)

19. *"Which marketing campaigns produced the most converted sales and highest attributed revenue in 2026?"*
    - **Tool Invoked:** `SalesAnalyst` (`campaigns.campaign_name`, `marketing_leads.converted_leads`, `sales_lines.net_sales`)
20. *"What is the lead-to-sale conversion rate by marketing channel and customer segment?"*
    - **Tool Invoked:** `SalesAnalyst` (`campaigns.campaign_channel`, `marketing_leads.lead_conversion_rate`)

---

## 6. Agronomic Reference & Standards (`InventorySupplyAnalyst` -> `SV_MOON_VALLEY_INVENTORY_SUPPLY`)

21. *"Which trees we sell are low-water-use and suited to Phoenix-area hardiness zones (Zone 9b) and full desert sun?"*
    - **Tool Invoked:** `InventorySupplyAnalyst` (Verified Query `phoenix_low_water_trees`: Museum Palo Verde `PAFL6`, Chilean Mesquite `PRCH`, Desert Ironwood `OLTE`, Swan Hill Fruitless Olive `OLEU`, Bubba Desert Willow `CHLI2`, etc.)
22. *"Map our top tree and palm SKUs to their USDA PLANTS scientific names, botanical families, and survivable hardiness zone ranges."*
    - **Tool Invoked:** `InventorySupplyAnalyst` (`botanical_taxonomy.plant_symbol`, `botanical_taxonomy.scientific_name`, `taxonomy_map.hardiness_min_zone`, `taxonomy_map.hardiness_max_zone`)

---

## 7. Machine Learning Predictions (4 Model Registry UDFs)

23. **Flagship Demo Question #5:** *"Forecast next spring's weekly and 12-week tree sales by store and category."*
    - **Tool Invoked:** `ForecastWeeklySales` -> `AGENT_FORECAST_WEEKLY_SALES()` (`WEEKLY_SALES_FORECAST_MODEL/V1`)
24. *"Which stores and SKUs are at risk of stocking out of top sellers in the next two weeks, and how much revenue is at risk?"*
    - **Tool Invoked:** `StockoutRisk` -> `AGENT_STOCKOUT_RISK()` (`STOCKOUT_RISK_MODEL/V1`)
25. *"Which recent unattached tree transactions have the highest propensity to add professional planting and an extended warranty?"*
    - **Tool Invoked:** `PlantingAttachPropensity` -> `AGENT_PLANTING_ATTACH_PROPENSITY()` (`PLANTING_ATTACH_MODEL/V1`)
26. *"Which scheduled planting jobs are currently at risk of missing their scheduled installation date?"*
    - **Tool Invoked:** `PlantingDelayRisk` -> `AGENT_PLANTING_DELAY_RISK()` (`PLANTING_DELAY_RISK_MODEL/V1`)

---

## 8. Unstructured Search (3 Cortex Search Services)

27. *"What are the most common reasons planting jobs were rescheduled in Arizona this fall according to field crew notes?"*
    - **Tool Invoked:** `PlantingNotesSearch` (`MVN_PLANTING_NOTES_SEARCH` — surfaces cemented caliche hardpan requiring hydraulic rock breakers, 811 Blue Stake utility marking delays, and HOA/crane gate clearance logs)
28. *"What does our warranty policy say about replacing palms, including central spear-leaf failure and crane mobilization coverage?"*
    - **Tool Invoked:** `WarrantyPolicySearch` (`MVN_WARRANTY_POLICY_SEARCH`)
29. *"What is the recommended desert summer watering schedule and Moon Juice fertilization protocol for newly transplanted specimen box trees?"*
    - **Tool Invoked:** `PlantCareSearch` (`MVN_PLANT_CARE_SEARCH`)
30. *"What are the warranty replacement SLA terms for commercial landscaper and homebuilder accounts?"*
    - **Tool Invoked:** `WarrantyPolicySearch` (`MVN_WARRANTY_POLICY_SEARCH`)

---

## 9. Role-Based Governance Verification (`MVN_EXEC_ROLE` vs. `MVN_AZ_STORE_MGR_ROLE`)

31. **Executive Role (`MVN_EXEC_ROLE`):** *"Show net sales, gross margin %, and store count by state this quarter, along with 5 sample Arizona customer email and phone records."*
    - **Expected Behavior:** Returns all 5 states (`AZ`, `CA`, `TX`, `NV`, `FL` = 100 stores) and clear-text customer email and phone values.
32. **Arizona Store Manager Role (`MVN_AZ_STORE_MGR_ROLE`):** *"Show net sales, gross margin %, and store count by state this quarter, along with 5 sample Arizona customer email and phone records."*
    - **Expected Behavior:** `MVN_STATE_ROW_ACCESS_POLICY` restricts output to `AZ` only (35 stores, matching the Executive `AZ` total to the penny), and `MVN_EMAIL_MASKING_POLICY` / `MVN_PHONE_MASKING_POLICY` mask email (`***MASKED***@...`) and phone (`(***) ***-XXXX`).
