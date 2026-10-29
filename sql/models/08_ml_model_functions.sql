/*=============================================================================
  Moon Valley Nursery Intelligence Agent
  08_ml_model_functions.sql
  
  Creates four SQL UDFs in MVN_INTELLIGENCE.ANALYTICS that call the registered
  models in the Snowflake Model Registry via MODEL()!PREDICT():
    1. AGENT_FORECAST_WEEKLY_SALES      -> WEEKLY_SALES_FORECAST_MODEL (V1)
    2. AGENT_STOCKOUT_RISK              -> STOCKOUT_RISK_MODEL (V1)
    3. AGENT_PLANTING_ATTACH_PROPENSITY -> PLANTING_ATTACH_MODEL (V1)
    4. AGENT_PLANTING_DELAY_RISK        -> PLANTING_DELAY_RISK_MODEL (V1)
  
  CRITICAL RULES:
    - Uses RETURNS ARRAY (never RETURNS VARIANT) for ARRAY_AGG
    - Omits LANGUAGE SQL clause per verified UDF syntax
    - Calls registered models via MODEL()!PREDICT() — no hardcoded thresholds
=============================================================================*/

USE DATABASE MVN_INTELLIGENCE;
USE SCHEMA ANALYTICS;
USE WAREHOUSE MOON_VALLEY_WH;

-- =============================================================================
-- 1. AGENT_FORECAST_WEEKLY_SALES
--    Forecasts weekly store x category tree sales for peak season planning
-- =============================================================================
CREATE OR REPLACE FUNCTION ANALYTICS.AGENT_FORECAST_WEEKLY_SALES()
RETURNS ARRAY
AS
$$
SELECT ARRAY_AGG(OBJECT_CONSTRUCT(
    'location_id', location_id,
    'location_name', location_name,
    'state', state,
    'category', category,
    'trailing_4wk_avg_sales_usd', ROUND(prior_4wk_avg_sales, 2),
    'forecast_weekly_peak_sales_usd', ROUND(predicted_weekly_sales, 2),
    'forecast_12wk_spring_sales_usd', ROUND(predicted_weekly_sales * 12, 2),
    'projected_uplift_pct', ROUND(DIV0(predicted_weekly_sales - prior_4wk_avg_sales, prior_4wk_avg_sales) * 100, 1)
)) FROM (
    SELECT
        w.location_id,
        w.location_name,
        w.state,
        w.category,
        w.prior_4wk_avg_sales,
        MODEL(MVN_INTELLIGENCE.ANALYTICS.WEEKLY_SALES_FORECAST_MODEL, V1)!PREDICT(
            w.state_code,
            w.category_code,
            1, -- Spring season_code = 1
            1, -- is_peak_season_num = 1
            w.sq_ft,
            w.store_age_months + 4,
            w.prior_4wk_avg_sales
        ):output_feature_0::FLOAT AS predicted_weekly_sales
    FROM MVN_INTELLIGENCE.ANALYTICS.V_WEEKLY_SALES_STORE_CATEGORY w
    WHERE w.category IN ('Shade Trees', 'Palms', 'Fruit Trees', 'Flowering Trees')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY w.location_id, w.category ORDER BY w.year DESC, w.week DESC) = 1
    ORDER BY predicted_weekly_sales DESC
    LIMIT 50
)
$$;


-- =============================================================================
-- 2. AGENT_STOCKOUT_RISK
--    Predicts 14-day stockout risk by store and product SKU
-- =============================================================================
CREATE OR REPLACE FUNCTION ANALYTICS.AGENT_STOCKOUT_RISK()
RETURNS ARRAY
AS
$$
SELECT ARRAY_AGG(OBJECT_CONSTRUCT(
    'location_id', location_id,
    'location_name', location_name,
    'state', state,
    'product_id', product_id,
    'sku', sku,
    'product_name', product_name,
    'category', category,
    'container_size', container_size,
    'on_hand_units', on_hand_units,
    'on_order_units', on_order_units,
    'daily_sell_rate', daily_sell_rate,
    'days_of_supply', days_of_supply,
    'lead_time_days', lead_time_days,
    'predicted_stockout_14d_flag', prediction,
    'risk_status', CASE WHEN prediction = 1 THEN 'HIGH STOCKOUT RISK (NEXT 14 DAYS)' ELSE 'ADEQUATE SUPPLY' END,
    'estimated_14d_revenue_at_risk_usd', CASE WHEN prediction = 1 THEN ROUND(daily_sell_rate * unit_price * 7, 2) ELSE 0 END
)) FROM (
    SELECT
        s.location_id,
        s.location_name,
        s.state,
        s.product_id,
        s.sku,
        s.product_name,
        s.category,
        s.container_size,
        s.unit_price,
        s.on_hand_units,
        s.on_order_units,
        s.daily_sell_rate,
        s.days_of_supply,
        s.lead_time_days,
        MODEL(MVN_INTELLIGENCE.ANALYTICS.STOCKOUT_RISK_MODEL, V1)!PREDICT(
            s.on_hand_units,
            s.on_order_units,
            s.daily_sell_rate,
            s.days_of_supply,
            s.lead_time_days,
            s.is_peak_season_num,
            s.is_palm_num
        ):output_feature_0::INT AS prediction
    FROM MVN_INTELLIGENCE.ANALYTICS.V_ML_STOCKOUT_FEATURES s
    QUALIFY ROW_NUMBER() OVER (PARTITION BY s.location_id, s.product_id ORDER BY s.date_key DESC) = 1
    ORDER BY prediction DESC, s.days_of_supply ASC, (s.daily_sell_rate * s.unit_price) DESC
    LIMIT 50
)
$$;


-- =============================================================================
-- 3. AGENT_PLANTING_ATTACH_PROPENSITY
--    Scores recent unattached tree transactions for planting attach follow-up
-- =============================================================================
CREATE OR REPLACE FUNCTION ANALYTICS.AGENT_PLANTING_ATTACH_PROPENSITY()
RETURNS ARRAY
AS
$$
SELECT ARRAY_AGG(OBJECT_CONSTRUCT(
    'transaction_id', transaction_id,
    'calendar_date', calendar_date::VARCHAR,
    'location_id', location_id,
    'location_name', location_name,
    'state', state,
    'customer_type', customer_type,
    'tree_units', tree_units,
    'box_tree_units', box_tree_units,
    'gross_sales_usd', gross_sales,
    'predicted_attach_flag', prediction,
    'recommendation', CASE WHEN prediction = 1 THEN 'HIGH PROPENSITY — OFFER PROFESSIONAL PLANTING & EXTENDED WARRANTY' ELSE 'STANDARD FOLLOW-UP' END
)) FROM (
    SELECT
        a.transaction_id,
        a.calendar_date,
        a.location_id,
        a.location_name,
        a.state,
        a.customer_type,
        a.tree_units,
        a.box_tree_units,
        a.gross_sales,
        MODEL(MVN_INTELLIGENCE.ANALYTICS.PLANTING_ATTACH_MODEL, V1)!PREDICT(
            a.customer_type_code,
            a.tree_units,
            a.box_tree_units,
            a.total_units,
            a.gross_sales,
            a.is_peak_season_num
        ):output_feature_0::INT AS prediction
    FROM MVN_INTELLIGENCE.ANALYTICS.V_ML_PLANTING_ATTACH_FEATURES a
    WHERE a.includes_planting_num = 0
      AND a.calendar_date >= '2026-09-01'::DATE
    ORDER BY prediction DESC, a.box_tree_units DESC, a.gross_sales DESC
    LIMIT 50
)
$$;


-- =============================================================================
-- 4. AGENT_PLANTING_DELAY_RISK
--    Predicts which scheduled planting jobs are at risk of missing scheduled date
-- =============================================================================
CREATE OR REPLACE FUNCTION ANALYTICS.AGENT_PLANTING_DELAY_RISK()
RETURNS ARRAY
AS
$$
SELECT ARRAY_AGG(OBJECT_CONSTRUCT(
    'job_id', job_id,
    'transaction_id', transaction_id,
    'location_id', location_id,
    'location_name', location_name,
    'state', state,
    'crew_id', crew_id,
    'crew_name', crew_name,
    'sold_date', sold_date::VARCHAR,
    'scheduled_date', scheduled_date::VARCHAR,
    'status', status,
    'days_to_schedule', days_to_schedule,
    'tree_count', tree_count,
    'max_container_code', max_container_code,
    'crew_size', crew_size,
    'predicted_delay_flag', prediction,
    'delay_risk_label', CASE WHEN prediction = 1 THEN 'AT RISK OF DELAY / RESCHEDULE' ELSE 'ON TRACK' END
)) FROM (
    SELECT
        d.job_id,
        d.transaction_id,
        d.location_id,
        d.location_name,
        d.state,
        d.crew_id,
        d.crew_name,
        d.sold_date,
        d.scheduled_date,
        d.status,
        d.days_to_schedule,
        d.tree_count,
        d.max_container_code,
        d.crew_size,
        MODEL(MVN_INTELLIGENCE.ANALYTICS.PLANTING_DELAY_RISK_MODEL, V1)!PREDICT(
            d.days_to_schedule,
            d.tree_count,
            d.max_container_code,
            d.crew_size,
            d.is_peak_season_num,
            d.crane_certified_num
        ):output_feature_0::INT AS prediction
    FROM MVN_INTELLIGENCE.ANALYTICS.V_ML_PLANTING_DELAY_FEATURES d
    WHERE d.status IN ('Scheduled', 'Rescheduled')
    ORDER BY prediction DESC, d.max_container_code DESC, d.days_to_schedule DESC
    LIMIT 50
)
$$;

SHOW USER FUNCTIONS IN SCHEMA MVN_INTELLIGENCE.ANALYTICS;
