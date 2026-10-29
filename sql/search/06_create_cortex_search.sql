/*=============================================================================
  Moon Valley Nursery Intelligence Agent
  06_create_cortex_search.sql
  
  Creates three Cortex Search Services in MVN_INTELLIGENCE.ANALYTICS over
  synthetic unstructured operational, agronomic, and warranty documents:
    1. MVN_PLANTING_NOTES_SEARCH  — Crew field notes, caliche/rock breaker
       reschedules, 811 utility delays, crane/HOA access, and drip checks
    2. MVN_PLANT_CARE_SEARCH      — Species care guides, USDA hardiness zones,
       desert summer watering schedules, and Moon Juice fertilizer protocols
    3. MVN_WARRANTY_POLICY_SEARCH — Synthetic warranty & replacement policies
       for palms, 24in/36in/48in+ box trees, and commercial/builder accounts
=============================================================================*/

USE DATABASE MVN_INTELLIGENCE;
USE SCHEMA ANALYTICS;
USE WAREHOUSE MOON_VALLEY_WH;

-- =============================================================================
-- 1. MVN_PLANTING_NOTES_SEARCH
-- =============================================================================
CREATE OR REPLACE CORTEX SEARCH SERVICE ANALYTICS.MVN_PLANTING_NOTES_SEARCH
  ON content
  ATTRIBUTES note_category, location_id, state, crew_id
  WAREHOUSE = MOON_VALLEY_WH
  TARGET_LAG = '1 hour'
  COMMENT = 'Semantic search over field crew planting notes, caliche excavation logs, utility delays, crane access issues, and irrigation checks'
AS (
  SELECT
      note_id,
      job_id,
      location_id,
      state,
      crew_id,
      note_date,
      note_category,
      title,
      content
  FROM MVN_INTELLIGENCE.RAW.PLANTING_FIELD_NOTES
);


-- =============================================================================
-- 2. MVN_PLANT_CARE_SEARCH
-- =============================================================================
CREATE OR REPLACE CORTEX SEARCH SERVICE ANALYTICS.MVN_PLANT_CARE_SEARCH
  ON content
  ATTRIBUTES category, plant_symbol, hardiness_zone, water_use_class, region
  WAREHOUSE = MOON_VALLEY_WH
  TARGET_LAG = '1 hour'
  COMMENT = 'Semantic search over Moon Valley plant care guides, desert watering protocols, hardiness zone recommendations, and Moon Juice fertilization schedules'
AS (
  SELECT
      guide_id,
      category,
      plant_symbol,
      hardiness_zone,
      water_use_class,
      region,
      title,
      content
  FROM MVN_INTELLIGENCE.RAW.PLANT_CARE_GUIDES
);


-- =============================================================================
-- 3. MVN_WARRANTY_POLICY_SEARCH
-- =============================================================================
CREATE OR REPLACE CORTEX SEARCH SERVICE ANALYTICS.MVN_WARRANTY_POLICY_SEARCH
  ON content
  ATTRIBUTES policy_category, applicable_categories, customer_type
  WAREHOUSE = MOON_VALLEY_WH
  TARGET_LAG = '1 hour'
  COMMENT = 'Semantic search over synthetic Moon Valley warranty and replacement policies for palms, specimen box trees, and commercial/builder accounts'
AS (
  SELECT
      policy_id,
      policy_category,
      applicable_categories,
      customer_type,
      effective_date,
      title,
      content
  FROM MVN_INTELLIGENCE.RAW.WARRANTY_POLICIES
);

SHOW CORTEX SEARCH SERVICES IN SCHEMA MVN_INTELLIGENCE.ANALYTICS;
