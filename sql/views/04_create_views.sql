/*=============================================================================
  Moon Valley Nursery Intelligence Agent
  04_create_views.sql
  
  Creates curated analytical views and ML feature engineering views in
  MVN_INTELLIGENCE.ANALYTICS:
    - V_SALES_DAILY_ENRICHED (Daily location sales + same-store comp flags)
    - V_SALES_LINE_ENRICHED (Line-level sales joined with conformed dimensions)
    - V_STORE_RAMP_COHORT (First-12-month store ramp for FL vs TX expansion)
    - V_PLANTING_OPERATIONS (Planted jobs + crew + store + lead time metrics)
    - V_INVENTORY_AND_STOCKOUTS (Daily inventory + USDA taxonomy + lost sales)
    - V_FARM_TO_STORE_SUPPLY (Farm transfers + store sell-through velocity)
    - V_CAMPAIGN_CONVERSION (Marketing lead conversion & attributed revenue)
    - V_WEEKLY_SALES_STORE_CATEGORY (ML Model 1: Store x Category Weekly Sales)
    - V_ML_STOCKOUT_FEATURES (ML Model 2: 14-Day Stockout Risk Classifier)
    - V_ML_PLANTING_ATTACH_FEATURES (ML Model 3: Planting Attach Propensity)
    - V_ML_PLANTING_DELAY_FEATURES (ML Model 4: Planting Job Delay Risk)
=============================================================================*/

USE DATABASE MVN_INTELLIGENCE;
USE SCHEMA ANALYTICS;
USE WAREHOUSE MOON_VALLEY_WH;

-- =============================================================================
-- 1. V_SALES_DAILY_ENRICHED
-- =============================================================================
CREATE OR REPLACE VIEW ANALYTICS.V_SALES_DAILY_ENRICHED AS
SELECT
    f.date_key,
    d.calendar_date,
    d.week,
    d.month,
    d.month_name,
    d.quarter,
    d.quarter_name,
    d.year,
    d.season,
    d.is_holiday,
    d.is_peak_season,
    f.location_id,
    l.location_name,
    l.city,
    l.state,
    l.region,
    l.market,
    l.open_date,
    l.sq_ft,
    l.hardiness_zone,
    l.is_new_market,
    DATEDIFF('month', l.open_date, d.calendar_date)                 AS months_open,
    (DATEDIFF('month', l.open_date, d.calendar_date) >= 12)         AS is_same_store_comp,
    f.gross_sales,
    f.net_sales,
    f.discounts,
    f.units,
    f.transactions,
    f.gross_margin,
    ROUND(DIV0(f.gross_margin, f.net_sales) * 100, 2)               AS gross_margin_pct,
    ROUND(DIV0(f.net_sales, f.transactions), 2)                     AS avg_ticket,
    f.planting_transactions,
    f.tree_transactions,
    ROUND(DIV0(f.planting_transactions, f.tree_transactions) * 100, 2) AS planting_attach_rate_pct
FROM RAW.FACT_SALES_DAILY_LOCATION f
JOIN RAW.DIM_DATE d     ON f.date_key = d.date_key
JOIN RAW.DIM_LOCATION l ON f.location_id = l.location_id;


-- =============================================================================
-- 2. V_SALES_LINE_ENRICHED
-- =============================================================================
CREATE OR REPLACE VIEW ANALYTICS.V_SALES_LINE_ENRICHED AS
SELECT
    sl.transaction_id,
    sl.line_no,
    sl.date_key,
    d.calendar_date,
    d.week,
    d.month,
    d.month_name,
    d.quarter,
    d.quarter_name,
    d.year,
    d.season,
    d.is_peak_season,
    sl.location_id,
    l.location_name,
    l.city,
    l.state,
    l.region,
    l.market,
    l.hardiness_zone,
    l.is_new_market,
    (DATEDIFF('month', l.open_date, d.calendar_date) >= 12) AS is_same_store_comp,
    t.customer_id,
    c.customer_name,
    c.customer_type,
    c.email AS customer_email,
    c.phone AS customer_phone,
    t.salesperson_id,
    sp.name AS salesperson_name,
    sp.role_title AS salesperson_role,
    t.campaign_id,
    cp.campaign_name,
    cp.channel AS campaign_channel,
    sl.product_id,
    p.sku,
    p.product_name,
    p.category,
    p.container_size,
    p.water_use,
    p.plant_symbol,
    p.is_tree,
    p.is_box_tree,
    sl.qty,
    sl.unit_price,
    ROUND(sl.qty * sl.unit_price, 2) AS line_gross_sales,
    sl.discount,
    sl.discount_promo_type,
    sl.extended_price AS line_net_sales,
    sl.unit_cost,
    sl.extended_cost AS line_cost,
    sl.line_margin,
    ROUND(DIV0(sl.line_margin, sl.extended_price) * 100, 2) AS line_margin_pct,
    t.includes_planting_flag
FROM RAW.FACT_SALES_LINE sl
JOIN RAW.FACT_SALES_TRANSACTION t ON sl.transaction_id = t.transaction_id
JOIN RAW.DIM_DATE d               ON sl.date_key = d.date_key
JOIN RAW.DIM_LOCATION l           ON sl.location_id = l.location_id
JOIN RAW.DIM_PRODUCT p            ON sl.product_id = p.product_id
JOIN RAW.DIM_CUSTOMER c           ON t.customer_id = c.customer_id
JOIN RAW.DIM_SALESPERSON sp       ON t.salesperson_id = sp.salesperson_id
LEFT JOIN RAW.DIM_CAMPAIGN cp     ON t.campaign_id = cp.campaign_id;


-- =============================================================================
-- 3. V_STORE_RAMP_COHORT (New Florida vs Texas Stores in First 12 Months)
-- =============================================================================
CREATE OR REPLACE VIEW ANALYTICS.V_STORE_RAMP_COHORT AS
SELECT
    l.location_id,
    l.location_name,
    l.city,
    l.state,
    l.region,
    l.market,
    l.open_date,
    l.is_new_market,
    DATEDIFF('month', DATE_TRUNC('month', l.open_date), DATE_TRUNC('month', d.calendar_date)) + 1 AS ramp_month_number,
    DATE_TRUNC('month', d.calendar_date) AS sales_month,
    SUM(f.gross_sales)          AS gross_sales,
    SUM(f.net_sales)            AS net_sales,
    SUM(f.gross_margin)         AS gross_margin,
    SUM(f.units)                AS units,
    SUM(f.transactions)         AS transactions,
    SUM(f.planting_transactions) AS planting_transactions,
    ROUND(DIV0(SUM(f.net_sales), SUM(f.transactions)), 2) AS avg_ticket
FROM RAW.FACT_SALES_DAILY_LOCATION f
JOIN RAW.DIM_DATE d     ON f.date_key = d.date_key
JOIN RAW.DIM_LOCATION l ON f.location_id = l.location_id
WHERE DATEDIFF('month', DATE_TRUNC('month', l.open_date), DATE_TRUNC('month', d.calendar_date)) BETWEEN 0 AND 11
GROUP BY
    l.location_id,
    l.location_name,
    l.city,
    l.state,
    l.region,
    l.market,
    l.open_date,
    l.is_new_market,
    ramp_month_number,
    sales_month;


-- =============================================================================
-- 4. V_PLANTING_OPERATIONS
-- =============================================================================
CREATE OR REPLACE VIEW ANALYTICS.V_PLANTING_OPERATIONS AS
SELECT
    j.job_id,
    j.transaction_id,
    j.location_id,
    l.location_name,
    l.city,
    l.state,
    l.region,
    l.market,
    j.crew_id,
    cr.crew_name,
    cr.crew_size,
    cr.crane_certified,
    j.sold_date,
    d.year AS sold_year,
    d.quarter_name AS sold_quarter,
    d.month_name AS sold_month,
    d.season AS sold_season,
    d.is_peak_season,
    j.scheduled_date,
    j.completed_date,
    j.days_to_schedule,
    j.days_sold_to_completed,
    j.status,
    j.reschedule_count,
    (j.reschedule_count > 0) AS is_rescheduled,
    j.reschedule_reason,
    j.tree_count,
    j.max_container_code,
    CASE j.max_container_code
        WHEN 4 THEN '48in box+'
        WHEN 3 THEN '36in box'
        WHEN 2 THEN '24in box'
        ELSE        '15 gal'
    END AS max_container_size,
    j.warranty_flag,
    j.delayed_flag,
    j.notes_id
FROM RAW.FACT_PLANTED_JOBS j
JOIN RAW.DIM_LOCATION l ON j.location_id = l.location_id
JOIN RAW.DIM_CREW cr    ON j.crew_id = cr.crew_id
JOIN RAW.DIM_DATE d     ON j.sold_date = d.calendar_date;


-- =============================================================================
-- 5. V_INVENTORY_AND_STOCKOUTS (Inventory + USDA Suitability + GS1)
-- =============================================================================
CREATE OR REPLACE VIEW ANALYTICS.V_INVENTORY_AND_STOCKOUTS AS
SELECT
    inv.date_key,
    d.calendar_date,
    d.week,
    d.month,
    d.quarter_name,
    d.year,
    d.season,
    d.is_peak_season,
    inv.location_id,
    l.location_name,
    l.city,
    l.state,
    l.region,
    l.market,
    l.hardiness_zone AS store_hardiness_zone,
    inv.product_id,
    p.sku,
    p.product_name,
    p.category,
    p.container_size,
    p.unit_price,
    p.unit_cost,
    p.plant_symbol,
    pt.scientific_name,
    pt.common_name,
    pt.family AS botanical_family,
    ptm.hardiness_min_zone,
    ptm.hardiness_max_zone,
    ptm.water_use_class,
    wu.desert_hoa_approved_flag,
    wu.summer_drip_freq_days,
    ptm.full_sun_desert_ok,
    ptm.suitability_notes,
    inv.on_hand_units,
    inv.on_order_units,
    inv.daily_sell_rate,
    inv.days_of_supply,
    inv.lead_time_days,
    inv.stockout_flag,
    inv.stockout_next_14d_flag,
    inv.estimated_lost_sales
FROM RAW.FACT_INVENTORY_DAILY inv
JOIN RAW.DIM_DATE d                      ON inv.date_key = d.date_key
JOIN RAW.DIM_LOCATION l                  ON inv.location_id = l.location_id
JOIN RAW.DIM_PRODUCT p                   ON inv.product_id = p.product_id
LEFT JOIN REFERENCE.PRODUCT_TAXONOMY_MAP ptm ON p.product_id = ptm.product_id
LEFT JOIN REFERENCE.PLANT_TAXONOMY_DIM pt    ON p.plant_symbol = pt.plant_symbol
LEFT JOIN REFERENCE.WATER_USE_DIM wu         ON ptm.water_use_class = wu.water_use_class;


-- =============================================================================
-- 6. V_FARM_TO_STORE_SUPPLY
-- =============================================================================
CREATE OR REPLACE VIEW ANALYTICS.V_FARM_TO_STORE_SUPPLY AS
SELECT
    ft.transfer_id,
    ft.farm_id,
    f.farm_name,
    f.state AS farm_state,
    f.acres AS farm_acres,
    f.primary_specialty,
    ft.location_id,
    l.location_name,
    l.city AS store_city,
    l.state AS store_state,
    l.region AS store_region,
    ft.product_id,
    p.sku,
    p.product_name,
    p.category,
    p.container_size,
    ft.ship_date,
    ft.arrival_date,
    DATEDIFF('day', ft.ship_date, ft.arrival_date) AS transit_days,
    ft.units AS transferred_units,
    ft.freight_cost_usd
FROM RAW.FACT_FARM_TRANSFERS ft
JOIN RAW.DIM_FARM f     ON ft.farm_id = f.farm_id
JOIN RAW.DIM_LOCATION l ON ft.location_id = l.location_id
JOIN RAW.DIM_PRODUCT p  ON ft.product_id = p.product_id;


-- =============================================================================
-- 7. V_CAMPAIGN_CONVERSION
-- =============================================================================
CREATE OR REPLACE VIEW ANALYTICS.V_CAMPAIGN_CONVERSION AS
SELECT
    ml.lead_id,
    ml.campaign_id,
    cp.campaign_name,
    cp.channel,
    cp.start_date AS campaign_start_date,
    cp.end_date AS campaign_end_date,
    cp.budget_usd AS campaign_budget_usd,
    ml.location_id,
    l.location_name,
    l.state,
    l.region,
    ml.lead_date,
    YEAR(ml.lead_date) AS lead_year,
    QUARTER(ml.lead_date) AS lead_quarter,
    ml.customer_type,
    ml.converted_flag,
    ml.converted_transaction_id,
    COALESCE(t.net_sales, 0)    AS converted_net_sales,
    COALESCE(t.gross_margin, 0) AS converted_gross_margin
FROM RAW.FACT_MARKETING_LEADS ml
JOIN RAW.DIM_CAMPAIGN cp              ON ml.campaign_id = cp.campaign_id
JOIN RAW.DIM_LOCATION l               ON ml.location_id = l.location_id
LEFT JOIN RAW.FACT_SALES_TRANSACTION t ON ml.converted_transaction_id = t.transaction_id;


-- =============================================================================
-- 8. ML FEATURE VIEW 1: V_WEEKLY_SALES_STORE_CATEGORY
--    Seasonality-aware store x category weekly sales forecast dataset
-- =============================================================================
CREATE OR REPLACE VIEW ANALYTICS.V_WEEKLY_SALES_STORE_CATEGORY AS
WITH weekly_agg AS (
    SELECT
        d.year,
        d.week,
        MIN(d.calendar_date) AS week_start_date,
        MAX(CASE WHEN d.is_peak_season THEN 1 ELSE 0 END) AS is_peak_season_num,
        MAX(CASE d.season
            WHEN 'Spring' THEN 1
            WHEN 'Summer' THEN 2
            WHEN 'Fall'   THEN 3
            ELSE               4
        END) AS season_code,
        sl.location_id,
        l.location_name,
        l.state,
        CASE l.state
            WHEN 'AZ' THEN 1
            WHEN 'CA' THEN 2
            WHEN 'NV' THEN 3
            WHEN 'TX' THEN 4
            ELSE           5
        END AS state_code,
        l.sq_ft,
        GREATEST(1, DATEDIFF('month', l.open_date, MIN(d.calendar_date))) AS store_age_months,
        p.category,
        CASE p.category
            WHEN 'Shade Trees'     THEN 1
            WHEN 'Palms'           THEN 2
            WHEN 'Fruit Trees'     THEN 3
            WHEN 'Flowering Trees' THEN 4
            WHEN 'Shrubs'          THEN 5
            WHEN 'Groundcover'     THEN 6
            WHEN 'Fertilizer & Soil' THEN 7
            ELSE                        8
        END AS category_code,
        SUM(sl.qty)            AS weekly_units,
        SUM(sl.extended_price) AS weekly_net_sales,
        SUM(sl.line_margin)    AS weekly_gross_margin
    FROM RAW.FACT_SALES_LINE sl
    JOIN RAW.DIM_DATE d     ON sl.date_key = d.date_key
    JOIN RAW.DIM_LOCATION l ON sl.location_id = l.location_id
    JOIN RAW.DIM_PRODUCT p  ON sl.product_id = p.product_id
    WHERE d.year >= 2023
    GROUP BY
        d.year,
        d.week,
        sl.location_id,
        l.location_name,
        l.state,
        l.sq_ft,
        l.open_date,
        p.category
)
SELECT
    year,
    week,
    week_start_date,
    location_id,
    location_name,
    state,
    state_code,
    category,
    category_code,
    season_code,
    is_peak_season_num,
    sq_ft,
    store_age_months,
    ROUND(AVG(weekly_net_sales) OVER (
        PARTITION BY location_id, category
        ORDER BY year, week
        ROWS BETWEEN 4 PRECEDING AND 1 PRECEDING
    ), 2) AS prior_4wk_avg_sales,
    weekly_units,
    weekly_net_sales,
    weekly_gross_margin
FROM weekly_agg
QUALIFY prior_4wk_avg_sales IS NOT NULL;


-- =============================================================================
-- 9. ML FEATURE VIEW 2: V_ML_STOCKOUT_FEATURES
--    Location x Product 14-day stockout risk dataset
-- =============================================================================
CREATE OR REPLACE VIEW ANALYTICS.V_ML_STOCKOUT_FEATURES AS
SELECT
    inv.date_key,
    d.calendar_date,
    inv.location_id,
    l.location_name,
    l.state,
    inv.product_id,
    p.sku,
    p.product_name,
    p.category,
    p.container_size,
    p.unit_price,
    inv.on_hand_units,
    inv.on_order_units,
    inv.daily_sell_rate,
    inv.days_of_supply,
    inv.lead_time_days,
    CASE WHEN d.is_peak_season THEN 1 ELSE 0 END AS is_peak_season_num,
    CASE WHEN p.category = 'Palms' THEN 1 ELSE 0 END AS is_palm_num,
    inv.stockout_next_14d_flag
FROM RAW.FACT_INVENTORY_DAILY inv
JOIN RAW.DIM_DATE d     ON inv.date_key = d.date_key
JOIN RAW.DIM_LOCATION l ON inv.location_id = l.location_id
JOIN RAW.DIM_PRODUCT p  ON inv.product_id = p.product_id;


-- =============================================================================
-- 10. ML FEATURE VIEW 3: V_ML_PLANTING_ATTACH_FEATURES
--     Transaction-level professional planting attach propensity dataset
-- =============================================================================
CREATE OR REPLACE VIEW ANALYTICS.V_ML_PLANTING_ATTACH_FEATURES AS
SELECT
    t.transaction_id,
    t.date_key,
    d.calendar_date,
    t.location_id,
    l.location_name,
    l.state,
    t.customer_id,
    c.customer_name,
    c.customer_type,
    CASE c.customer_type
        WHEN 'Homeowner'          THEN 1
        WHEN 'Landscaper'         THEN 2
        ELSE                           3
    END AS customer_type_code,
    t.tree_units,
    t.box_tree_units,
    t.units AS total_units,
    t.gross_sales,
    t.net_sales,
    CASE WHEN d.is_peak_season THEN 1 ELSE 0 END AS is_peak_season_num,
    CASE WHEN t.includes_planting_flag THEN 1 ELSE 0 END AS includes_planting_num
FROM RAW.FACT_SALES_TRANSACTION t
JOIN RAW.DIM_DATE d     ON t.date_key = d.date_key
JOIN RAW.DIM_LOCATION l ON t.location_id = l.location_id
JOIN RAW.DIM_CUSTOMER c ON t.customer_id = c.customer_id
WHERE d.year >= 2024
  AND t.tree_units > 0;


-- =============================================================================
-- 11. ML FEATURE VIEW 4: V_ML_PLANTING_DELAY_FEATURES
--     Planting job delay / reschedule risk dataset
-- =============================================================================
CREATE OR REPLACE VIEW ANALYTICS.V_ML_PLANTING_DELAY_FEATURES AS
SELECT
    j.job_id,
    j.transaction_id,
    j.location_id,
    l.location_name,
    l.state,
    j.crew_id,
    cr.crew_name,
    j.sold_date,
    j.scheduled_date,
    j.status,
    j.days_to_schedule,
    j.tree_count,
    j.max_container_code,
    cr.crew_size,
    CASE WHEN d.is_peak_season THEN 1 ELSE 0 END AS is_peak_season_num,
    CASE WHEN cr.crane_certified THEN 1 ELSE 0 END AS crane_certified_num,
    j.delayed_flag
FROM RAW.FACT_PLANTED_JOBS j
JOIN RAW.DIM_LOCATION l ON j.location_id = l.location_id
JOIN RAW.DIM_CREW cr    ON j.crew_id = cr.crew_id
JOIN RAW.DIM_DATE d     ON j.sold_date = d.calendar_date;

SHOW VIEWS IN SCHEMA MVN_INTELLIGENCE.ANALYTICS;
