/*=============================================================================
  Moon Valley Nursery Intelligence Agent
  09_create_agent.sql
  
  Creates the governed Cortex Agent MVN_INTELLIGENCE.ANALYTICS.MOON_VALLEY_AGENT
  with 11 tools:
    - 3 Cortex Analyst tools (SalesAnalyst, PlantingOpsAnalyst, InventorySupplyAnalyst)
    - 3 Cortex Search tools (PlantingNotesSearch, PlantCareSearch, WarrantyPolicySearch)
    - 4 ML UDF tools (ForecastWeeklySales, StockoutRisk, PlantingAttachPropensity,
      PlantingDelayRisk)
    - 1 Visualization tool (data_to_chart)
=============================================================================*/

USE DATABASE MVN_INTELLIGENCE;
USE SCHEMA ANALYTICS;
USE WAREHOUSE MOON_VALLEY_WH;

CREATE OR REPLACE AGENT MVN_INTELLIGENCE.ANALYTICS.MOON_VALLEY_AGENT
  COMMENT = 'Moon Valley Nursery intelligence agent for retail sales, planting operations, inventory, and ML forecasting'
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
    response: "Answer for executives and nursery managers in plain business language. Lead with the headline number or finding, followed by a concise explanation of drivers. Always state the time period, filters, and locations/states included. Format currency to 2 decimal places ($X,XXX.XX) and percentages to 1 or 2 decimal places. Never invent data; if data is unavailable or filtered by role-based access control, clearly explain what is visible."
    orchestration: "Route questions as follows: (1) Sales, revenue, margin, box-tree mix, discounts, same-store comp sales, store ramp, customers, salespeople, or marketing campaigns -> SalesAnalyst. (2) Planted jobs, crew reschedule rates, sale-to-planting lead time, or warranty attach -> PlantingOpsAnalyst. (3) Daily store inventory, palm stockouts, estimated lost sales, farm-to-store transfers, or USDA hardiness zone and low-water-use suitability -> InventorySupplyAnalyst. (4) Unstructured field crew notes on reschedules, caliche excavation, Blue Stake utility delays, crane access, or drip checks -> PlantingNotesSearch. (5) Plant care guides, watering frequency, or Moon Juice fertilizer instructions -> PlantCareSearch. (6) Warranty terms, palm replacement rules, or commercial/builder guarantees -> WarrantyPolicySearch. (7) Next spring/seasonal weekly sales forecast -> ForecastWeeklySales. (8) 14-day store x SKU stockout risk predictions -> StockoutRisk. (9) Transaction-level professional planting attach propensity -> PlantingAttachPropensity. (10) Scheduled planting jobs at risk of delay/reschedule -> PlantingDelayRisk. Use data_to_chart for trends and comparisons."
    system: "You are the Moon Valley Nursery Business Assistant, helping executives (such as the CTO and Data Lead), regional leaders, store managers, and analysts understand retail tree sales, gross margin, professional planting operations, farm-to-yard inventory, and agronomic suitability across Moon Valley's 100+ nurseries."
    sample_questions:
      - question: "Which Arizona stores are behind last year on tree sales this fall, and why?"
        answer: "Use SalesAnalyst to list the Arizona stores with negative YoY fall tree sales variance, then check InventorySupplyAnalyst and PlantingNotesSearch for palm stockouts, discount erosion, and caliche/utility reschedule drivers."
      - question: "Where are we running out of palms most often, and what did it cost us in sales?"
        answer: "Use InventorySupplyAnalyst to rank stores by palm stockout days and estimated lost sales."
      - question: "What is our planting attach rate by state, and which stores are lowest?"
        answer: "Use SalesAnalyst to compute planting_attach_rate by state and identify the lowest-attaching stores."
      - question: "How are the new Florida stores ramping vs. the Texas stores in their first 12 months?"
        answer: "Use SalesAnalyst to compare new expansion stores in FL vs TX."
      - question: "Which stores are at risk of stocking out of top sellers in the next two weeks?"
        answer: "Use StockoutRisk to return ML-predicted 14-day stockout risks by store and SKU."
      - question: "Which planting jobs are at risk of missing their scheduled date?"
        answer: "Use PlantingDelayRisk to return active scheduled planting jobs predicted to experience delays."
      - question: "Show a line chart of monthly net sales by state for 2025 and 2026."
        answer: "Use SalesAnalyst for monthly net sales by state, then data_to_chart to render a multi-series line chart showing Spring/Fall peaks and the AZ/NV summer dip."
      - question: "Show a stacked bar chart of net sales by product category for each state in 2026."
        answer: "Use SalesAnalyst for 2026 net sales by state and product category, then data_to_chart to render a stacked bar chart of category mix."
      - question: "Chart the top 10 stores by estimated lost sales from palm stockouts."
        answer: "Use InventorySupplyAnalyst to rank stores by palm estimated lost sales, then data_to_chart to render a ranked bar chart."
      - question: "Show a pie chart of planting reschedule reasons."
        answer: "Use PlantingOpsAnalyst to count rescheduled jobs by reschedule reason, then data_to_chart to render a pie chart of reason share."
      - question: "Plot average sale-to-planting lead time by season and region as a grouped bar chart."
        answer: "Use PlantingOpsAnalyst for average days sold-to-completed by season and region, then data_to_chart to render a grouped bar chart."

  tools:
    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "SalesAnalyst"
        description: "Governed sales, gross margin, box-tree mix, discounts, average ticket, planting attach rate, same-store sales, new store ramp, customer segments, salespeople, and marketing campaign conversion from the Moon Valley three-fact Kimball sales semantic view (SV_MOON_VALLEY_SALES)."

    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "PlantingOpsAnalyst"
        description: "Governed professional planting operations metrics including total planting jobs, sale-to-completed planting lead times by region and season, crew reschedule rates, reschedule reasons, and extended warranty attach rates (SV_MOON_VALLEY_PLANTING_OPS)."

    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "InventorySupplyAnalyst"
        description: "Governed daily store inventory, palm and tree stockout days, stockout rate %, estimated lost sales in USD, farm-to-store transfers, and USDA Plant Hardiness Zone / low-water-use botanical suitability (SV_MOON_VALLEY_INVENTORY_SUPPLY)."

    - tool_spec:
        type: "cortex_search"
        name: "PlantingNotesSearch"
        description: "Semantic search over unstructured field crew planting notes, including Arizona fall reschedule reasons (caliche rock-breaker excavation, 811 Blue Stake utility marking delays, crane/HOA gate access) and drip irrigation inspection logs."

    - tool_spec:
        type: "cortex_search"
        name: "PlantCareSearch"
        description: "Semantic search over Moon Valley plant care guides, desert summer watering schedules, USDA hardiness zone guidelines, and Moon Juice / Super Palm Juice fertilizer protocols."

    - tool_spec:
        type: "cortex_search"
        name: "WarrantyPolicySearch"
        description: "Semantic search over Moon Valley warranty and replacement policy documents covering palm replacement criteria, 24in/36in/48in+ specimen box-tree guarantees, professional planting requirements, and builder/commercial SLAs."

    - tool_spec:
        type: "generic"
        name: "ForecastWeeklySales"
        description: "ML regression model (WEEKLY_SALES_FORECAST_MODEL) predicting weekly and 12-week spring peak tree sales by store and product category."

    - tool_spec:
        type: "generic"
        name: "StockoutRisk"
        description: "ML classification model (STOCKOUT_RISK_MODEL) predicting 14-day stockout risk by store and product SKU, including days of supply and estimated revenue at risk."

    - tool_spec:
        type: "generic"
        name: "PlantingAttachPropensity"
        description: "ML classification model (PLANTING_ATTACH_MODEL) predicting which recent unattached tree transactions have the highest propensity to add professional planting and extended warranty."

    - tool_spec:
        type: "generic"
        name: "PlantingDelayRisk"
        description: "ML classification model (PLANTING_DELAY_RISK_MODEL) predicting which scheduled planting jobs are at risk of missing their scheduled installation date."

    - tool_spec:
        type: "data_to_chart"
        name: "data_to_chart"
        description: "Generates charts and visualizations from query results for executive trends and store comparisons."

  tool_resources:
    SalesAnalyst:
      semantic_view: "MVN_INTELLIGENCE.ANALYTICS.SV_MOON_VALLEY_SALES"
      execution_environment:
        type: "warehouse"
        warehouse: "MOON_VALLEY_WH"

    PlantingOpsAnalyst:
      semantic_view: "MVN_INTELLIGENCE.ANALYTICS.SV_MOON_VALLEY_PLANTING_OPS"
      execution_environment:
        type: "warehouse"
        warehouse: "MOON_VALLEY_WH"

    InventorySupplyAnalyst:
      semantic_view: "MVN_INTELLIGENCE.ANALYTICS.SV_MOON_VALLEY_INVENTORY_SUPPLY"
      execution_environment:
        type: "warehouse"
        warehouse: "MOON_VALLEY_WH"

    PlantingNotesSearch:
      name: "MVN_INTELLIGENCE.ANALYTICS.MVN_PLANTING_NOTES_SEARCH"
      max_results: "10"
      title_column: "TITLE"
      id_column: "NOTE_ID"

    PlantCareSearch:
      name: "MVN_INTELLIGENCE.ANALYTICS.MVN_PLANT_CARE_SEARCH"
      max_results: "10"
      title_column: "TITLE"
      id_column: "GUIDE_ID"

    WarrantyPolicySearch:
      name: "MVN_INTELLIGENCE.ANALYTICS.MVN_WARRANTY_POLICY_SEARCH"
      max_results: "10"
      title_column: "TITLE"
      id_column: "POLICY_ID"

    ForecastWeeklySales:
      type: "function"
      identifier: "MVN_INTELLIGENCE.ANALYTICS.AGENT_FORECAST_WEEKLY_SALES"
      execution_environment:
        type: "warehouse"
        warehouse: "MOON_VALLEY_WH"

    StockoutRisk:
      type: "function"
      identifier: "MVN_INTELLIGENCE.ANALYTICS.AGENT_STOCKOUT_RISK"
      execution_environment:
        type: "warehouse"
        warehouse: "MOON_VALLEY_WH"

    PlantingAttachPropensity:
      type: "function"
      identifier: "MVN_INTELLIGENCE.ANALYTICS.AGENT_PLANTING_ATTACH_PROPENSITY"
      execution_environment:
        type: "warehouse"
        warehouse: "MOON_VALLEY_WH"

    PlantingDelayRisk:
      type: "function"
      identifier: "MVN_INTELLIGENCE.ANALYTICS.AGENT_PLANTING_DELAY_RISK"
      execution_environment:
        type: "warehouse"
        warehouse: "MOON_VALLEY_WH"
  $$;

SHOW AGENTS IN SCHEMA MVN_INTELLIGENCE.ANALYTICS;
