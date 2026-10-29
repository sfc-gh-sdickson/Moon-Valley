/*=============================================================================
  Moon Valley Nursery Intelligence Agent
  05_create_semantic_views.sql
  
  Creates three governed Semantic Views in MVN_INTELLIGENCE.ANALYTICS
  replacing the separate 2027 semantic-layer database and SSAS cube:
    1. SV_MOON_VALLEY_SALES
       - Reproduces the 3-fact Kimball sales constellation
         (FACT_SALES_DAILY_LOCATION, FACT_SALES_TRANSACTION, FACT_SALES_LINE)
         + conformed dimensions + marketing leads
    2. SV_MOON_VALLEY_PLANTING_OPS
       - Covers professional planting jobs, crews, lead times, reschedules,
         and warranty attach
    3. SV_MOON_VALLEY_INVENTORY_SUPPLY
       - Covers daily store inventory, palm stockouts, lost sales, farm-to-store
         transfers, and USDA hardiness / water-use / GS1 standards
=============================================================================*/

USE DATABASE MVN_INTELLIGENCE;
USE SCHEMA ANALYTICS;
USE WAREHOUSE MOON_VALLEY_WH;

-- =============================================================================
-- 1. SV_MOON_VALLEY_SALES
--    Three-Fact Kimball Sales Constellation + Conformed Dimensions + Marketing
-- =============================================================================

CREATE OR REPLACE SEMANTIC VIEW ANALYTICS.SV_MOON_VALLEY_SALES

  TABLES (
    daily_sales AS MVN_INTELLIGENCE.RAW.FACT_SALES_DAILY_LOCATION
      PRIMARY KEY (date_key, location_id)
      WITH SYNONYMS ('daily store sales', 'store daily summary', 'location daily sales')
      COMMENT = 'Daily store-level sales summary fact table (date x location grain), 100% reconciled to transaction and line facts',

    transactions AS MVN_INTELLIGENCE.RAW.FACT_SALES_TRANSACTION
      PRIMARY KEY (transaction_id)
      WITH SYNONYMS ('pos transactions', 'orders', 'tickets', 'sales transactions')
      COMMENT = 'Transaction-level POS sales header fact table (date x location x transaction grain)',

    sales_lines AS MVN_INTELLIGENCE.RAW.FACT_SALES_LINE
      PRIMARY KEY (transaction_id, line_no)
      WITH SYNONYMS ('line items', 'sales lines', 'pos lines', 'product sales', 'tree sales')
      COMMENT = 'Line-item POS sales fact table (transaction x line grain) with product, container size, and discount detail',

    dates AS MVN_INTELLIGENCE.RAW.DIM_DATE
      PRIMARY KEY (date_key)
      WITH SYNONYMS ('calendar', 'date', 'time', 'seasonality')
      COMMENT = 'Conformed calendar and fiscal date dimension (2015-2026) with nursery seasons and peak planting flags',

    locations AS MVN_INTELLIGENCE.RAW.DIM_LOCATION
      PRIMARY KEY (location_id)
      WITH SYNONYMS ('store', 'stores', 'nursery', 'nurseries', 'yard', 'branch', 'site')
      COMMENT = 'Conformed retail nursery location dimension across AZ, CA, NV, TX, and FL',

    products AS MVN_INTELLIGENCE.RAW.DIM_PRODUCT
      PRIMARY KEY (product_id)
      WITH SYNONYMS ('product', 'sku', 'trees', 'plants', 'item', 'box tree')
      COMMENT = 'Conformed product dimension across Shade Trees, Palms, Fruit Trees, Flowering Trees, Shrubs, Groundcover, Fertilizer & Soil, and Services',

    customers AS MVN_INTELLIGENCE.RAW.DIM_CUSTOMER
      PRIMARY KEY (customer_id)
      WITH SYNONYMS ('customer', 'buyer', 'client', 'account', 'homeowner', 'landscaper', 'builder')
      COMMENT = 'Conformed customer dimension (Homeowner, Landscaper, Builder/Commercial) with masked PII columns',

    salespeople AS MVN_INTELLIGENCE.RAW.DIM_SALESPERSON
      PRIMARY KEY (salesperson_id)
      WITH SYNONYMS ('salesperson', 'nursery pro', 'designer', 'sales rep', 'consultant')
      COMMENT = 'Conformed salesperson and nursery tree designer dimension',

    campaigns AS MVN_INTELLIGENCE.RAW.DIM_CAMPAIGN
      PRIMARY KEY (campaign_id)
      WITH SYNONYMS ('campaign', 'marketing campaign', 'promotion', 'ad campaign')
      COMMENT = 'Conformed marketing campaign dimension',

    marketing_leads AS MVN_INTELLIGENCE.RAW.FACT_MARKETING_LEADS
      PRIMARY KEY (lead_id)
      WITH SYNONYMS ('leads', 'marketing leads', 'inquiries', 'consultations')
      COMMENT = 'Marketing leads and POS conversion tracking fact table'
  )

  RELATIONSHIPS (
    daily_to_date AS
      daily_sales (date_key) REFERENCES dates,
    daily_to_location AS
      daily_sales (location_id) REFERENCES locations,
    txn_to_date AS
      transactions (date_key) REFERENCES dates,
    txn_to_location AS
      transactions (location_id) REFERENCES locations,
    txn_to_customer AS
      transactions (customer_id) REFERENCES customers,
    txn_to_salesperson AS
      transactions (salesperson_id) REFERENCES salespeople,
    txn_to_campaign AS
      transactions (campaign_id) REFERENCES campaigns,
    line_to_txn AS
      sales_lines (transaction_id) REFERENCES transactions,
    line_to_product AS
      sales_lines (product_id) REFERENCES products,
    lead_to_campaign AS
      marketing_leads (campaign_id) REFERENCES campaigns
  )

  FACTS (
    sales_lines.line_gross_amount AS qty * unit_price
      COMMENT = 'Gross line revenue before discount',
    sales_lines.tree_line_sales AS CASE WHEN products.is_tree THEN extended_price ELSE 0 END
      COMMENT = 'Net sales on tree categories (Shade Trees, Palms, Fruit Trees, Flowering Trees)',
    sales_lines.box_tree_line_sales AS CASE WHEN products.is_box_tree THEN extended_price ELSE 0 END
      COMMENT = 'Net sales on 24in, 36in, and 48in+ specimen box trees',
    daily_sales.same_store_net_sales AS CASE WHEN DATEDIFF('month', locations.open_date, dates.calendar_date) >= 12 THEN net_sales ELSE 0 END
      WITH SYNONYMS = ('comp sales', 'same-store sales', 'comparable store sales')
      COMMENT = 'Net sales for stores open at least 12 months',
    transactions.planting_txn_int AS CASE WHEN includes_planting_flag THEN 1 ELSE 0 END
      COMMENT = '1 if transaction includes professional planting service, else 0',
    transactions.tree_txn_int AS CASE WHEN tree_units > 0 THEN 1 ELSE 0 END
      COMMENT = '1 if transaction contains at least one tree, else 0',
    marketing_leads.converted_lead_int AS CASE WHEN converted_flag THEN 1 ELSE 0 END
      COMMENT = '1 if marketing lead converted to a POS transaction, else 0'
  )

  DIMENSIONS (
    dates.calendar_date AS calendar_date
      WITH SYNONYMS = ('date', 'sale date', 'transaction date', 'day')
      COMMENT = 'Calendar date of sale',
    dates.week AS week
      WITH SYNONYMS = ('week number', 'iso week')
      COMMENT = 'Week number of year (1-53)',
    dates.month AS month
      WITH SYNONYMS = ('month number')
      COMMENT = 'Calendar month number (1-12)',
    dates.month_name AS month_name
      WITH SYNONYMS = ('month')
      COMMENT = 'Calendar month name',
    dates.quarter AS quarter
      COMMENT = 'Fiscal/calendar quarter number (1-4)',
    dates.quarter_name AS quarter_name
      WITH SYNONYMS = ('quarter', 'fiscal quarter')
      COMMENT = 'Quarter name (Q1, Q2, Q3, Q4)'
      SAMPLE_VALUES ('Q1', 'Q2', 'Q3', 'Q4')
      IS_ENUM,
    dates.year AS year
      WITH SYNONYMS = ('fiscal year', 'calendar year', 'yr')
      COMMENT = 'Calendar and fiscal year (2015-2026)',
    dates.season AS season
      WITH SYNONYMS = ('nursery season', 'planting season')
      COMMENT = 'Nursery season (Spring, Summer, Fall, Winter)'
      SAMPLE_VALUES ('Spring', 'Summer', 'Fall', 'Winter')
      IS_ENUM,
    dates.is_peak_season AS is_peak_season
      WITH SYNONYMS = ('peak season', 'spring and fall peak')
      COMMENT = 'TRUE during Spring (Mar-May) and Fall (Oct-Nov) planting peaks',
    dates.is_holiday AS is_holiday
      COMMENT = 'TRUE on major nursery promotional holidays',

    locations.location_id AS location_id
      WITH SYNONYMS = ('store id', 'nursery id')
      COMMENT = 'Unique retail nursery store ID',
    locations.location_name AS location_name
      WITH SYNONYMS = ('store', 'store name', 'nursery', 'nursery name', 'yard name')
      COMMENT = 'Retail nursery store name',
    locations.city AS city
      WITH SYNONYMS = ('store city', 'municipality')
      COMMENT = 'City where nursery store is located',
    locations.state AS state
      WITH SYNONYMS = ('store state', 'state code')
      COMMENT = 'Two-letter state code (AZ, CA, NV, TX, FL)'
      SAMPLE_VALUES ('AZ', 'CA', 'NV', 'TX', 'FL')
      IS_ENUM,
    locations.region AS region
      WITH SYNONYMS = ('operating region', 'territory', 'geographic region')
      COMMENT = 'Operating region (Desert Southwest, Southern California, Texas, Florida)'
      SAMPLE_VALUES ('Desert Southwest', 'Southern California', 'Texas', 'Florida')
      IS_ENUM,
    locations.market AS market
      WITH SYNONYMS = ('metro area', 'metro market')
      COMMENT = 'Metropolitan market area',
    locations.open_date AS open_date
      WITH SYNONYMS = ('store open date', 'grand opening')
      COMMENT = 'Store opening date',
    locations.hardiness_zone AS hardiness_zone
      WITH SYNONYMS = ('usda zone', 'plant zone', 'zone')
      COMMENT = 'Store USDA Plant Hardiness Zone'
      SAMPLE_VALUES ('8a', '8b', '9a', '9b', '10a', '10b')
      IS_ENUM,
    locations.is_new_market AS is_new_market
      WITH SYNONYMS = ('new store', 'ramping store', 'expansion store')
      COMMENT = 'TRUE for new expansion stores in Florida and Texas opened 2024+',

    products.product_id AS product_id
      COMMENT = 'Unique product identifier',
    products.sku AS sku
      WITH SYNONYMS = ('item code', 'product code')
      COMMENT = 'Stock keeping unit code',
    products.product_name AS product_name
      WITH SYNONYMS = ('item name', 'tree name', 'plant name')
      COMMENT = 'Retail product name',
    products.category AS category
      WITH SYNONYMS = ('product category', 'tree category', 'department')
      COMMENT = 'Product category'
      SAMPLE_VALUES ('Shade Trees', 'Palms', 'Fruit Trees', 'Flowering Trees', 'Shrubs', 'Groundcover', 'Fertilizer & Soil', 'Services')
      IS_ENUM,
    products.container_size AS container_size
      WITH SYNONYMS = ('box size', 'tree size', 'pot size')
      COMMENT = 'Container or specimen box size'
      SAMPLE_VALUES ('15 gal', '24in box', '36in box', '48in box+', 'Bag/Bottle', 'Service')
      IS_ENUM,
    products.water_use AS water_use
      WITH SYNONYMS = ('water requirement', 'drought tolerance')
      COMMENT = 'Water use classification (Very Low, Low, Moderate, High, N/A)'
      SAMPLE_VALUES ('Very Low', 'Low', 'Moderate', 'High', 'N/A')
      IS_ENUM,
    products.is_tree AS is_tree
      WITH SYNONYMS = ('tree flag', 'tree categories')
      COMMENT = 'TRUE for Shade Trees, Palms, Fruit Trees, and Flowering Trees',
    products.is_box_tree AS is_box_tree
      WITH SYNONYMS = ('box tree', 'specimen box tree')
      COMMENT = 'TRUE for 24in box, 36in box, and 48in box+ trees',

    customers.customer_id AS customer_id
      COMMENT = 'Unique customer ID',
    customers.customer_name AS customer_name
      COMMENT = 'Customer or commercial account name',
    customers.customer_type AS customer_type
      WITH SYNONYMS = ('customer segment', 'buyer type', 'client type')
      COMMENT = 'Customer segment: Homeowner, Landscaper, Builder/Commercial'
      SAMPLE_VALUES ('Homeowner', 'Landscaper', 'Builder/Commercial')
      IS_ENUM,
    customers.customer_email AS email
      COMMENT = 'Customer email (masked for store manager role)',
    customers.customer_phone AS phone
      COMMENT = 'Customer phone (masked for store manager role)',

    salespeople.salesperson_id AS salesperson_id
      COMMENT = 'Salesperson identifier',
    salespeople.salesperson_name AS name
      WITH SYNONYMS = ('salesperson', 'nursery pro', 'designer name')
      COMMENT = 'Salesperson full name',
    salespeople.salesperson_role AS role_title
      COMMENT = 'Salesperson role title',

    campaigns.campaign_id AS campaign_id
      COMMENT = 'Marketing campaign ID',
    campaigns.campaign_name AS campaign_name
      WITH SYNONYMS = ('campaign', 'promotion name')
      COMMENT = 'Marketing campaign name',
    campaigns.campaign_channel AS channel
      WITH SYNONYMS = ('marketing channel', 'ad channel', 'lead source')
      COMMENT = 'Marketing channel'
      SAMPLE_VALUES ('Paid Search', 'Direct Mail', 'Billboard/OOH', 'Local TV & Radio', 'Social Media', 'HOA/Builder Events')
      IS_ENUM,

    sales_lines.discount_promo_type AS discount_promo_type
      WITH SYNONYMS = ('discount reason', 'promo type', 'discount type')
      COMMENT = 'Promotion or discount reason applied to sales line'
      SAMPLE_VALUES ('None', 'Multi-Tree Bundle', 'Summer Heat Clearance', 'Builder Volume', 'VIP Landscape Pass', 'Manager Price Match')
      IS_ENUM,

    transactions.includes_planting_flag AS includes_planting_flag
      WITH SYNONYMS = ('planted', 'with planting', 'professional planting attached')
      COMMENT = 'TRUE when transaction includes professional planting service'
  )

  METRICS (
    sales_lines.net_sales AS SUM(extended_price)
      WITH SYNONYMS = ('revenue', 'total sales', 'total net sales', 'sales revenue', 'line net sales')
      COMMENT = 'Total net sales revenue in USD after discounts',
    sales_lines.gross_sales AS SUM(sales_lines.line_gross_amount)
      WITH SYNONYMS = ('gross revenue', 'list sales')
      COMMENT = 'Total gross sales in USD before discounts',
    sales_lines.total_discounts AS SUM(discount)
      WITH SYNONYMS = ('discounts', 'discount dollars', 'markdown dollars')
      COMMENT = 'Total discount dollars applied',
    sales_lines.gross_margin AS SUM(line_margin)
      WITH SYNONYMS = ('margin', 'margin dollars', 'gross profit')
      COMMENT = 'Total gross margin dollars (net sales minus cost)',
    sales_lines.gross_margin_pct AS ROUND(DIV0(SUM(line_margin), SUM(extended_price)) * 100, 2)
      WITH SYNONYMS = ('margin %', 'gross margin percentage', 'profit margin %')
      COMMENT = 'Gross margin percentage of net sales',
    sales_lines.discount_rate_pct AS ROUND(DIV0(SUM(discount), SUM(sales_lines.line_gross_amount)) * 100, 2)
      WITH SYNONYMS = ('discount %', 'markdown rate', 'margin erosion rate')
      COMMENT = 'Discount dollars as a percentage of gross sales',
    sales_lines.total_units AS SUM(qty)
      WITH SYNONYMS = ('units', 'quantity sold', 'units sold', 'volume')
      COMMENT = 'Total units sold',
    sales_lines.tree_sales AS SUM(sales_lines.tree_line_sales)
      WITH SYNONYMS = ('tree revenue', 'tree net sales')
      COMMENT = 'Total net sales across tree categories (Shade Trees, Palms, Fruit Trees, Flowering Trees)',
    sales_lines.box_tree_sales AS SUM(sales_lines.box_tree_line_sales)
      WITH SYNONYMS = ('box tree revenue', 'specimen tree sales')
      COMMENT = 'Total net sales from 24in, 36in, and 48in+ box trees',
    sales_lines.box_tree_mix_pct AS ROUND(DIV0(SUM(sales_lines.box_tree_line_sales), SUM(extended_price)) * 100, 2)
      WITH SYNONYMS = ('box-tree mix', 'box tree share', 'specimen mix %')
      COMMENT = 'Percentage of net sales coming from 24in, 36in, and 48in+ box trees',

    transactions.transaction_count AS COUNT(transaction_id)
      WITH SYNONYMS = ('transactions', 'orders', 'tickets', 'order count')
      COMMENT = 'Total number of POS transactions',
    transactions.average_ticket AS ROUND(DIV0(SUM(net_sales), COUNT(transaction_id)), 2)
      WITH SYNONYMS = ('avg ticket', 'average order value', 'aov', 'ticket size')
      COMMENT = 'Average net sales per transaction in USD',
    transactions.planting_attach_rate AS ROUND(DIV0(SUM(transactions.planting_txn_int), NULLIF(SUM(transactions.tree_txn_int), 0)) * 100, 2)
      WITH SYNONYMS = ('attach rate', 'planting attach %', 'installation attach rate')
      COMMENT = 'Percentage of tree transactions that include professional planting service',

    daily_sales.daily_net_sales AS SUM(net_sales)
      WITH SYNONYMS = ('daily store revenue', 'daily summary sales')
      COMMENT = 'Total net sales from FACT_SALES_DAILY_LOCATION (reconciles 100% with sales_lines.net_sales)',
    daily_sales.same_store_sales AS SUM(daily_sales.same_store_net_sales)
      WITH SYNONYMS = ('comp', 'same-store', 'comp store sales', 'comparable sales')
      COMMENT = 'Total net sales for comparable stores open 12+ months',

    marketing_leads.total_leads AS COUNT(lead_id)
      WITH SYNONYMS = ('lead count', 'inquiries')
      COMMENT = 'Total marketing leads captured',
    marketing_leads.converted_leads AS SUM(marketing_leads.converted_lead_int)
      WITH SYNONYMS = ('converted sales count', 'lead conversions')
      COMMENT = 'Number of marketing leads converted into POS transactions',
    marketing_leads.lead_conversion_rate AS ROUND(DIV0(SUM(marketing_leads.converted_lead_int), COUNT(lead_id)) * 100, 2)
      WITH SYNONYMS = ('conversion rate', 'lead-to-sale conversion rate', 'close rate')
      COMMENT = 'Percentage of marketing leads that converted to a POS sale'
  )

  COMMENT = 'Moon Valley governed sales, margin, customer, salesperson, and campaign semantic view reproducing the 3-fact Kimball constellation. Single source of truth for Cortex Agent, Power BI, and Claude via MCP.'

  AI_SQL_GENERATION 'Always round currency and percentage outputs to 2 decimal places. When asked about "store" or "nursery", use locations.location_name. When asked about "revenue" or "sales", use sales_lines.net_sales (or daily_sales.daily_net_sales). When asked about "tree sales", filter products.is_tree = TRUE or use sales_lines.tree_sales. Current year is 2026 and Fall is season = ''Fall'' (months 9, 10, 11).'

  AI_VERIFIED_QUERIES (
    az_fall_tree_sales_yoy AS (
      QUESTION 'Which Arizona stores are behind last year on tree sales this fall?'
      VERIFIED_AT 1761753600
      ONBOARDING_QUESTION TRUE
      SQL 'SELECT
             l.location_id,
             l.location_name,
             ROUND(SUM(CASE WHEN d.year = 2025 THEN sl.extended_price ELSE 0 END), 2) AS fall_2025_tree_sales,
             ROUND(SUM(CASE WHEN d.year = 2026 THEN sl.extended_price ELSE 0 END), 2) AS fall_2026_tree_sales,
             ROUND(SUM(CASE WHEN d.year = 2026 THEN sl.extended_price ELSE 0 END)
                 - SUM(CASE WHEN d.year = 2025 THEN sl.extended_price ELSE 0 END), 2) AS yoy_dollar_variance,
             ROUND(DIV0(
               SUM(CASE WHEN d.year = 2026 THEN sl.extended_price ELSE 0 END)
               - SUM(CASE WHEN d.year = 2025 THEN sl.extended_price ELSE 0 END),
               SUM(CASE WHEN d.year = 2025 THEN sl.extended_price ELSE 0 END)
             ) * 100, 2) AS yoy_pct_change
           FROM MVN_INTELLIGENCE.RAW.FACT_SALES_LINE sl
           JOIN MVN_INTELLIGENCE.RAW.DIM_DATE d ON sl.date_key = d.date_key
           JOIN MVN_INTELLIGENCE.RAW.DIM_LOCATION l ON sl.location_id = l.location_id
           JOIN MVN_INTELLIGENCE.RAW.DIM_PRODUCT p ON sl.product_id = p.product_id
           WHERE l.state = ''AZ''
             AND d.season = ''Fall''
             AND d.year IN (2025, 2026)
             AND p.is_tree = TRUE
           GROUP BY l.location_id, l.location_name
           HAVING yoy_dollar_variance < 0
           ORDER BY yoy_dollar_variance ASC'
    ),
    box_tree_margin_by_size AS (
      QUESTION 'How does gross margin % differ for 24in vs 36in vs 48in+ box trees?'
      VERIFIED_AT 1761753600
      ONBOARDING_QUESTION TRUE
      SQL 'SELECT
             p.container_size,
             SUM(sl.qty) AS units_sold,
             ROUND(SUM(sl.extended_price), 2) AS net_sales,
             ROUND(SUM(sl.line_margin), 2) AS gross_margin,
             ROUND(DIV0(SUM(sl.line_margin), SUM(sl.extended_price)) * 100, 2) AS gross_margin_pct
           FROM MVN_INTELLIGENCE.RAW.FACT_SALES_LINE sl
           JOIN MVN_INTELLIGENCE.RAW.DIM_PRODUCT p ON sl.product_id = p.product_id
           WHERE p.container_size IN (''24in box'', ''36in box'', ''48in box+'')
           GROUP BY p.container_size
           ORDER BY gross_margin_pct DESC'
    ),
    net_sales_by_state_this_quarter AS (
      QUESTION 'Show net sales by state this quarter'
      VERIFIED_AT 1761753600
      ONBOARDING_QUESTION TRUE
      SQL 'SELECT
             l.state,
             COUNT(DISTINCT l.location_id) AS active_stores,
             SUM(ds.transactions) AS transactions,
             ROUND(SUM(ds.net_sales), 2) AS net_sales,
             ROUND(SUM(ds.gross_margin), 2) AS gross_margin,
             ROUND(DIV0(SUM(ds.gross_margin), SUM(ds.net_sales)) * 100, 2) AS gross_margin_pct
           FROM MVN_INTELLIGENCE.RAW.FACT_SALES_DAILY_LOCATION ds
           JOIN MVN_INTELLIGENCE.RAW.DIM_DATE d ON ds.date_key = d.date_key
           JOIN MVN_INTELLIGENCE.RAW.DIM_LOCATION l ON ds.location_id = l.location_id
           WHERE d.year = 2026 AND d.quarter = 4
           GROUP BY l.state
           ORDER BY net_sales DESC'
    )
  );


-- =============================================================================
-- 2. SV_MOON_VALLEY_PLANTING_OPS
--    Planting Operations, Crew Performance, Lead Times & Warranty Attach
-- =============================================================================

CREATE OR REPLACE SEMANTIC VIEW ANALYTICS.SV_MOON_VALLEY_PLANTING_OPS

  TABLES (
    planted_jobs AS MVN_INTELLIGENCE.RAW.FACT_PLANTED_JOBS
      PRIMARY KEY (job_id)
      WITH SYNONYMS ('planting jobs', 'installations', 'field jobs', 'planted trees')
      COMMENT = 'Field services professional planting jobs fact table',

    crews AS MVN_INTELLIGENCE.RAW.DIM_CREW
      PRIMARY KEY (crew_id)
      WITH SYNONYMS ('planting crew', 'field crew', 'installation team')
      COMMENT = 'Professional planting crew dimension',

    locations AS MVN_INTELLIGENCE.RAW.DIM_LOCATION
      PRIMARY KEY (location_id)
      WITH SYNONYMS ('store', 'nursery', 'dispatch store')
      COMMENT = 'Retail nursery location dimension',

    dates AS MVN_INTELLIGENCE.RAW.DIM_DATE
      PRIMARY KEY (calendar_date)
      WITH SYNONYMS ('sold date', 'calendar', 'season')
      COMMENT = 'Calendar date dimension linked to job sold_date'
  )

  RELATIONSHIPS (
    job_to_crew AS
      planted_jobs (crew_id) REFERENCES crews,
    job_to_location AS
      planted_jobs (location_id) REFERENCES locations,
    job_to_date AS
      planted_jobs (sold_date) REFERENCES dates (calendar_date)
  )

  FACTS (
    planted_jobs.rescheduled_job_int AS CASE WHEN reschedule_count > 0 OR status = 'Rescheduled' THEN 1 ELSE 0 END
      COMMENT = '1 if planting job was rescheduled at least once, else 0',
    planted_jobs.completed_job_int AS CASE WHEN status = 'Completed' THEN 1 ELSE 0 END
      COMMENT = '1 if planting job status is Completed, else 0',
    planted_jobs.warranty_job_int AS CASE WHEN warranty_flag THEN 1 ELSE 0 END
      COMMENT = '1 if customer purchased extended warranty on job, else 0'
  )

  DIMENSIONS (
    planted_jobs.job_id AS job_id
      COMMENT = 'Unique planting job ID',
    planted_jobs.job_status AS status
      WITH SYNONYMS = ('planting status', 'installation status')
      COMMENT = 'Job status (Scheduled, Completed, Rescheduled, Cancelled)'
      SAMPLE_VALUES ('Scheduled', 'Completed', 'Rescheduled', 'Cancelled')
      IS_ENUM,
    planted_jobs.reschedule_reason AS reschedule_reason
      WITH SYNONYMS = ('delay reason', 'reschedule cause')
      COMMENT = 'Primary reason planting job was rescheduled'
      SAMPLE_VALUES ('Caliche/Hard Dig Required Rock Breaker', 'Blue Stake Utility Marking Delay', 'Crane Access / HOA Gate Clearance', 'Extreme Heat Advisory Reschedule', 'Customer Site Readiness Request', 'Prior Job Crew Overtime Spillover'),
    planted_jobs.sold_date AS sold_date
      COMMENT = 'Date planting job was sold',
    planted_jobs.scheduled_date AS scheduled_date
      COMMENT = 'Scheduled installation date',
    planted_jobs.completed_date AS completed_date
      COMMENT = 'Actual completed installation date',
    planted_jobs.warranty_flag AS warranty_flag
      WITH SYNONYMS = ('has warranty', 'warranty attached')
      COMMENT = 'TRUE if extended tree warranty was purchased',

    crews.crew_id AS crew_id
      COMMENT = 'Planting crew ID',
    crews.crew_name AS crew_name
      WITH SYNONYMS = ('crew', 'team name')
      COMMENT = 'Planting crew name',
    crews.crew_size AS crew_size
      COMMENT = 'Number of technicians on planting crew',
    crews.crane_certified AS crane_certified
      COMMENT = 'TRUE if crew is certified for heavy crane box installations',

    locations.location_id AS location_id
      COMMENT = 'Store location ID',
    locations.location_name AS location_name
      WITH SYNONYMS = ('store', 'nursery', 'store name')
      COMMENT = 'Retail nursery store name',
    locations.state AS state
      WITH SYNONYMS = ('store state')
      COMMENT = 'Store state (AZ, CA, NV, TX, FL)'
      SAMPLE_VALUES ('AZ', 'CA', 'NV', 'TX', 'FL')
      IS_ENUM,
    locations.region AS region
      COMMENT = 'Operating region',

    dates.sold_year AS year
      COMMENT = 'Year planting job was sold',
    dates.sold_quarter AS quarter_name
      COMMENT = 'Quarter planting job was sold',
    dates.sold_month AS month_name
      COMMENT = 'Month planting job was sold',
    dates.sold_season AS season
      WITH SYNONYMS = ('season')
      COMMENT = 'Season planting job was sold (Spring, Summer, Fall, Winter)'
      SAMPLE_VALUES ('Spring', 'Summer', 'Fall', 'Winter')
      IS_ENUM,
    dates.is_peak_season AS is_peak_season
      COMMENT = 'TRUE during Spring and Fall peak planting seasons'
  )

  METRICS (
    planted_jobs.total_jobs AS COUNT(job_id)
      WITH SYNONYMS = ('job count', 'planting jobs', 'total installations')
      COMMENT = 'Total number of planting jobs',
    planted_jobs.completed_jobs AS SUM(planted_jobs.completed_job_int)
      COMMENT = 'Total completed planting jobs',
    planted_jobs.rescheduled_jobs AS SUM(planted_jobs.rescheduled_job_int)
      COMMENT = 'Number of jobs that were rescheduled',
    planted_jobs.reschedule_rate_pct AS ROUND(DIV0(SUM(planted_jobs.rescheduled_job_int), COUNT(job_id)) * 100, 2)
      WITH SYNONYMS = ('reschedule rate', 'crew reschedule rate', 'delay rate %')
      COMMENT = 'Percentage of planting jobs rescheduled',
    planted_jobs.avg_days_sold_to_planted AS ROUND(AVG(days_sold_to_completed), 2)
      WITH SYNONYMS = ('days sold-to-planted', 'planting lead time', 'average time from sale to completed planting')
      COMMENT = 'Average calendar days from sale date to completed planting date',
    planted_jobs.avg_days_to_schedule AS ROUND(AVG(days_to_schedule), 2)
      COMMENT = 'Average days from sale date to scheduled date',
    planted_jobs.total_trees_planted AS SUM(tree_count)
      WITH SYNONYMS = ('trees planted', 'installed trees')
      COMMENT = 'Total trees installed across planting jobs',
    planted_jobs.warranty_attach_rate_pct AS ROUND(DIV0(SUM(planted_jobs.warranty_job_int), COUNT(job_id)) * 100, 2)
      WITH SYNONYMS = ('warranty rate', 'warranty attach %')
      COMMENT = 'Percentage of planting jobs with extended tree warranty'
  )

  COMMENT = 'Moon Valley governed planting operations semantic view covering field crews, sale-to-planting lead times, reschedule rates, and warranty attach.'

  AI_SQL_GENERATION 'Round lead-time days and reschedule percentages to 2 decimal places. When asked about average time from sale to completed planting, use planted_jobs.avg_days_sold_to_planted.'

  AI_VERIFIED_QUERIES (
    lead_time_by_region_season AS (
      QUESTION 'What is the average time from sale to completed planting by region and season?'
      VERIFIED_AT 1761753600
      ONBOARDING_QUESTION TRUE
      SQL 'SELECT
             l.region,
             d.season,
             COUNT(j.job_id) AS completed_jobs,
             ROUND(AVG(j.days_sold_to_completed), 2) AS avg_days_sold_to_planted
           FROM MVN_INTELLIGENCE.RAW.FACT_PLANTED_JOBS j
           JOIN MVN_INTELLIGENCE.RAW.DIM_LOCATION l ON j.location_id = l.location_id
           JOIN MVN_INTELLIGENCE.RAW.DIM_DATE d ON j.sold_date = d.calendar_date
           WHERE j.status = ''Completed''
           GROUP BY l.region, d.season
           ORDER BY l.region, avg_days_sold_to_planted DESC'
    ),
    top_reschedule_crews AS (
      QUESTION 'Which crews have the highest reschedule rate?'
      VERIFIED_AT 1761753600
      ONBOARDING_QUESTION TRUE
      SQL 'SELECT
             c.crew_id,
             c.crew_name,
             l.location_name,
             l.state,
             COUNT(j.job_id) AS total_jobs,
             SUM(CASE WHEN j.reschedule_count > 0 THEN 1 ELSE 0 END) AS rescheduled_jobs,
             ROUND(DIV0(SUM(CASE WHEN j.reschedule_count > 0 THEN 1 ELSE 0 END), COUNT(j.job_id)) * 100, 2) AS reschedule_rate_pct
           FROM MVN_INTELLIGENCE.RAW.FACT_PLANTED_JOBS j
           JOIN MVN_INTELLIGENCE.RAW.DIM_CREW c ON j.crew_id = c.crew_id
           JOIN MVN_INTELLIGENCE.RAW.DIM_LOCATION l ON j.location_id = l.location_id
           GROUP BY c.crew_id, c.crew_name, l.location_name, l.state
           HAVING COUNT(j.job_id) >= 10
           ORDER BY reschedule_rate_pct DESC
           LIMIT 15'
    )
  );


-- =============================================================================
-- 3. SV_MOON_VALLEY_INVENTORY_SUPPLY
--    Inventory, Palm Stockouts, Farm Transfers & USDA Taxonomy/Suitability
-- =============================================================================

CREATE OR REPLACE SEMANTIC VIEW ANALYTICS.SV_MOON_VALLEY_INVENTORY_SUPPLY

  TABLES (
    inventory AS MVN_INTELLIGENCE.RAW.FACT_INVENTORY_DAILY
      PRIMARY KEY (date_key, location_id, product_id)
      WITH SYNONYMS ('daily inventory', 'stock levels', 'on hand inventory', 'stockouts')
      COMMENT = 'Daily store x product inventory position, days of supply, stockout flags, and estimated lost sales',

    farm_transfers AS MVN_INTELLIGENCE.RAW.FACT_FARM_TRANSFERS
      PRIMARY KEY (transfer_id)
      WITH SYNONYMS ('transfers', 'farm shipments', 'replenishment', 'farm supply')
      COMMENT = 'Farm-to-nursery tree and plant transfer shipments',

    farms AS MVN_INTELLIGENCE.RAW.DIM_FARM
      PRIMARY KEY (farm_id)
      WITH SYNONYMS ('growing farm', 'tree farm', 'source farm')
      COMMENT = 'Vertically integrated Moon Valley growing farms across AZ, CA, TX, and FL',

    locations AS MVN_INTELLIGENCE.RAW.DIM_LOCATION
      PRIMARY KEY (location_id)
      WITH SYNONYMS ('store', 'nursery', 'yard')
      COMMENT = 'Retail nursery locations with USDA hardiness zone',

    products AS MVN_INTELLIGENCE.RAW.DIM_PRODUCT
      PRIMARY KEY (product_id)
      WITH SYNONYMS ('sku', 'tree', 'palm', 'plant')
      COMMENT = 'Product catalog with category, container size, and water use',

    dates AS MVN_INTELLIGENCE.RAW.DIM_DATE
      PRIMARY KEY (date_key)
      WITH SYNONYMS ('snapshot date', 'calendar')
      COMMENT = 'Calendar date dimension',

    taxonomy_map AS MVN_INTELLIGENCE.REFERENCE.PRODUCT_TAXONOMY_MAP
      PRIMARY KEY (product_id)
      WITH SYNONYMS ('suitability map', 'hardiness crosswalk')
      COMMENT = 'Crosswalk linking products to USDA plant symbols, hardiness zones, and desert sun suitability',

    botanical_taxonomy AS MVN_INTELLIGENCE.REFERENCE.PLANT_TAXONOMY_DIM
      PRIMARY KEY (plant_symbol)
      WITH SYNONYMS ('scientific names', 'usda plants', 'species')
      COMMENT = 'USDA PLANTS Database scientific names, common names, and botanical families'
  )

  RELATIONSHIPS (
    inv_to_date AS
      inventory (date_key) REFERENCES dates,
    inv_to_location AS
      inventory (location_id) REFERENCES locations,
    inv_to_product AS
      inventory (product_id) REFERENCES products,
    transfer_to_farm AS
      farm_transfers (farm_id) REFERENCES farms,
    transfer_to_location AS
      farm_transfers (location_id) REFERENCES locations,
    transfer_to_product AS
      farm_transfers (product_id) REFERENCES products,
    product_to_tax_map AS
      products (product_id) REFERENCES taxonomy_map (product_id),
    tax_map_to_botanical AS
      taxonomy_map (plant_symbol) REFERENCES botanical_taxonomy (plant_symbol)
  )

  FACTS (
    inventory.stockout_day_int AS CASE WHEN stockout_flag THEN 1 ELSE 0 END
      COMMENT = '1 when store x SKU snapshot is out of stock (on_hand_units = 0), else 0',
    farm_transfers.transit_days AS DATEDIFF('day', ship_date, arrival_date)
      COMMENT = 'Days in transit from growing farm to retail nursery'
  )

  DIMENSIONS (
    dates.snapshot_date AS calendar_date
      COMMENT = 'Inventory snapshot date',
    dates.year AS year
      COMMENT = 'Snapshot year',
    dates.season AS season
      COMMENT = 'Nursery season (Spring, Summer, Fall, Winter)'
      SAMPLE_VALUES ('Spring', 'Summer', 'Fall', 'Winter')
      IS_ENUM,
    dates.is_peak_season AS is_peak_season
      COMMENT = 'TRUE during Spring and Fall peak seasons',

    locations.location_id AS location_id
      COMMENT = 'Store location ID',
    locations.location_name AS location_name
      WITH SYNONYMS = ('store', 'nursery', 'store name')
      COMMENT = 'Retail nursery store name',
    locations.city AS city
      COMMENT = 'Store city',
    locations.state AS state
      COMMENT = 'Store state (AZ, CA, NV, TX, FL)'
      SAMPLE_VALUES ('AZ', 'CA', 'NV', 'TX', 'FL')
      IS_ENUM,
    locations.region AS region
      COMMENT = 'Operating region',
    locations.store_hardiness_zone AS hardiness_zone
      WITH SYNONYMS = ('store zone', 'nursery hardiness zone')
      COMMENT = 'USDA Plant Hardiness Zone of the nursery store',

    products.product_id AS product_id
      COMMENT = 'Product ID',
    products.sku AS sku
      COMMENT = 'Product SKU code',
    products.product_name AS product_name
      COMMENT = 'Retail product name',
    products.category AS category
      WITH SYNONYMS = ('product category', 'plant category')
      COMMENT = 'Product category'
      SAMPLE_VALUES ('Shade Trees', 'Palms', 'Fruit Trees', 'Flowering Trees', 'Shrubs', 'Groundcover', 'Fertilizer & Soil')
      IS_ENUM,
    products.container_size AS container_size
      COMMENT = 'Container or box size',
    products.water_use AS water_use
      WITH SYNONYMS = ('water use class', 'drought rating')
      COMMENT = 'Water use classification (Very Low, Low, Moderate, High)',

    taxonomy_map.hardiness_min_zone AS hardiness_min_zone
      COMMENT = 'Minimum survivable USDA hardiness zone for the SKU',
    taxonomy_map.hardiness_max_zone AS hardiness_max_zone
      COMMENT = 'Maximum recommended USDA hardiness zone for the SKU',
    taxonomy_map.full_sun_desert_ok AS full_sun_desert_ok
      WITH SYNONYMS = ('desert suited', 'phoenix full sun ok')
      COMMENT = 'TRUE if rated for 115F+ full desert sun in Phoenix/Las Vegas',
    taxonomy_map.suitability_notes AS suitability_notes
      COMMENT = 'Agronomic suitability notes',

    botanical_taxonomy.plant_symbol AS plant_symbol
      COMMENT = 'USDA PLANTS Database symbol',
    botanical_taxonomy.scientific_name AS scientific_name
      WITH SYNONYMS = ('latin name', 'botanical name')
      COMMENT = 'Botanical Latin scientific name',
    botanical_taxonomy.species_common_name AS common_name
      COMMENT = 'Standard species common name',
    botanical_taxonomy.botanical_family AS family
      COMMENT = 'Botanical family',

    farms.farm_id AS farm_id
      COMMENT = 'Growing farm ID',
    farms.farm_name AS farm_name
      WITH SYNONYMS = ('farm', 'growing farm', 'source farm')
      COMMENT = 'Moon Valley growing farm name',
    farms.farm_state AS state
      COMMENT = 'State where growing farm is located',
    farms.farm_specialty AS primary_specialty
      COMMENT = 'Primary crop specialty of the farm',

    inventory.stockout_flag AS stockout_flag
      WITH SYNONYMS = ('out of stock', 'stocked out')
      COMMENT = 'TRUE when on_hand_units = 0'
  )

  METRICS (
    inventory.total_on_hand_units AS SUM(on_hand_units)
      WITH SYNONYMS = ('on hand units', 'current inventory')
      COMMENT = 'Total salable units on hand',
    inventory.total_on_order_units AS SUM(on_order_units)
      WITH SYNONYMS = ('on order units', 'in transit units')
      COMMENT = 'Total units on order from growing farms',
    inventory.stockout_days AS SUM(inventory.stockout_day_int)
      WITH SYNONYMS = ('stockout count', 'stockout events', 'out of stock days')
      COMMENT = 'Total store-SKU snapshot observations in stockout (on_hand_units = 0)',
    inventory.stockout_rate_pct AS ROUND(DIV0(SUM(inventory.stockout_day_int), COUNT(date_key)) * 100, 2)
      WITH SYNONYMS = ('stockout rate', 'out of stock %')
      COMMENT = 'Percentage of store-SKU observations with a stockout',
    inventory.lost_sales_estimate AS SUM(estimated_lost_sales)
      WITH SYNONYMS = ('lost sales', 'estimated lost sales', 'stockout cost in sales', 'missed revenue')
      COMMENT = 'Estimated lost sales in USD caused by stockouts',
    inventory.avg_days_of_supply AS ROUND(AVG(days_of_supply), 2)
      WITH SYNONYMS = ('days of supply', 'inventory cover days')
      COMMENT = 'Average days of inventory supply on hand',
    inventory.avg_daily_sell_rate AS ROUND(AVG(daily_sell_rate), 2)
      WITH SYNONYMS = ('sell-through velocity', 'daily sell rate')
      COMMENT = 'Average daily unit sales velocity',

    farm_transfers.total_transferred_units AS SUM(units)
      WITH SYNONYMS = ('farm transfer units', 'units shipped from farms')
      COMMENT = 'Total units transferred from Moon Valley farms to retail stores',
    farm_transfers.total_transfers AS COUNT(transfer_id)
      COMMENT = 'Total number of farm-to-store transfer shipments',
    farm_transfers.avg_transit_days AS ROUND(AVG(farm_transfers.transit_days), 2)
      COMMENT = 'Average transit days from farm to store'
  )

  COMMENT = 'Moon Valley governed inventory, palm stockouts, lost-sales impact, farm-to-store supply, and USDA hardiness/water-use suitability semantic view.'

  AI_SQL_GENERATION 'When asked about palm stockouts and lost sales, filter products.category = ''Palms'' and aggregate inventory.stockout_days and inventory.lost_sales_estimate by store. When asked about trees suited to Phoenix (Zone 9b) and low water use, filter products.is_tree = TRUE, products.water_use IN (''Very Low'', ''Low''), and taxonomy_map.full_sun_desert_ok = TRUE.'

  AI_VERIFIED_QUERIES (
    palm_stockouts_by_store AS (
      QUESTION 'Where are we running out of palms most often, and what did it cost us in sales?'
      VERIFIED_AT 1761753600
      ONBOARDING_QUESTION TRUE
      SQL 'SELECT
             l.location_id,
             l.location_name,
             l.state,
             SUM(CASE WHEN inv.stockout_flag THEN 1 ELSE 0 END) AS palm_stockout_snapshots,
             ROUND(DIV0(SUM(CASE WHEN inv.stockout_flag THEN 1 ELSE 0 END), COUNT(*)) * 100, 2) AS palm_stockout_rate_pct,
             ROUND(SUM(inv.estimated_lost_sales), 2) AS estimated_lost_sales_usd
           FROM MVN_INTELLIGENCE.RAW.FACT_INVENTORY_DAILY inv
           JOIN MVN_INTELLIGENCE.RAW.DIM_LOCATION l ON inv.location_id = l.location_id
           JOIN MVN_INTELLIGENCE.RAW.DIM_PRODUCT p ON inv.product_id = p.product_id
           WHERE p.category = ''Palms''
           GROUP BY l.location_id, l.location_name, l.state
           HAVING palm_stockout_snapshots > 0
           ORDER BY estimated_lost_sales_usd DESC
           LIMIT 15'
    ),
    phoenix_low_water_trees AS (
      QUESTION 'Which trees we sell are low-water-use and suited to Phoenix-area hardiness zones?'
      VERIFIED_AT 1761753600
      ONBOARDING_QUESTION TRUE
      SQL 'SELECT DISTINCT
             bt.plant_symbol,
             bt.common_name,
             bt.scientific_name,
             p.category,
             p.water_use,
             tm.hardiness_min_zone,
             tm.hardiness_max_zone,
             tm.full_sun_desert_ok,
             tm.suitability_notes
           FROM MVN_INTELLIGENCE.RAW.DIM_PRODUCT p
           JOIN MVN_INTELLIGENCE.REFERENCE.PRODUCT_TAXONOMY_MAP tm ON p.product_id = tm.product_id
           JOIN MVN_INTELLIGENCE.REFERENCE.PLANT_TAXONOMY_DIM bt ON tm.plant_symbol = bt.plant_symbol
           WHERE p.is_tree = TRUE
             AND p.water_use IN (''Very Low'', ''Low'')
             AND tm.full_sun_desert_ok = TRUE
           ORDER BY p.water_use, bt.common_name'
    )
  );

SHOW SEMANTIC VIEWS IN SCHEMA MVN_INTELLIGENCE.ANALYTICS;
