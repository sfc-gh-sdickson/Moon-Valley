/*=============================================================================
  Moon Valley Nursery Intelligence Agent
  03b_seed_reference_data.sql
  
  Seeds the public standard reference tables in MVN_INTELLIGENCE.REFERENCE and
  the unstructured search document corpora in MVN_INTELLIGENCE.RAW:
    - REFERENCE.HARDINESS_ZONE_DIM (USDA Plant Hardiness Zones)
    - REFERENCE.PLANT_TAXONOMY_DIM (USDA PLANTS Database symbols & binomials)
    - REFERENCE.WATER_USE_DIM (Regional low-water-use plant classes)
    - REFERENCE.GS1_IDENTIFIERS (GTINs for SKUs, GLNs for locations & farms)
    - REFERENCE.PRODUCT_TAXONOMY_MAP (SKU-to-taxonomy/zone/water crosswalk)
    - RAW.PLANTING_FIELD_NOTES (240 field technician notes for Cortex Search)
    - RAW.PLANT_CARE_GUIDES (60 care & watering guides for Cortex Search)
    - RAW.WARRANTY_POLICIES (30 synthetic warranty & replacement policy docs)
=============================================================================*/

USE DATABASE MVN_INTELLIGENCE;
USE WAREHOUSE MOON_VALLEY_WH;

-- =============================================================================
-- 1. REFERENCE.HARDINESS_ZONE_DIM (USDA Plant Hardiness Zone Standard)
-- =============================================================================
TRUNCATE TABLE REFERENCE.HARDINESS_ZONE_DIM;

INSERT INTO REFERENCE.HARDINESS_ZONE_DIM VALUES
    ('8a',  10, 15, 'High-elevation mountain / northern desert transition; winter freezes common (10F to 15F).', 'Flagstaff AZ, Prescott Valley AZ, Northern DFW TX'),
    ('8b',  15, 20, 'Warm temperate / north-central Texas & high desert; brief winter dips to 15F-20F.', 'Dallas-Fort Worth TX, Georgetown/Austin Hills TX, Sedona AZ'),
    ('9a',  20, 25, 'Subtropical desert & Gulf transition; light winter frosts (20F to 25F).', 'Tucson Metro AZ, Las Vegas Valley NV, Greater Houston TX, San Antonio TX'),
    ('9b',  25, 30, 'Low-elevation Sonoran Desert & Central Florida; rare hard freezes (25F to 30F), extreme summer heat in AZ.', 'Phoenix Metro AZ, Scottsdale/Gilbert/Surprise/Chandler AZ, Tampa/Orlando FL'),
    ('10a', 30, 35, 'Frost-light Coachella Valley, Southern California inland/coastal, and Southwest Florida.', 'Palm Desert/Indio CA, San Diego/Orange County/Inland Empire CA, Fort Myers/Naples FL'),
    ('10b', 35, 40, 'Subtropical South Florida & frost-free microclimates (35F to 40F).', 'West Palm Beach FL, Boca Raton FL, Homestead FL'),
    ('11a', 40, 45, 'Tropical frost-free zone above 40F year-round.', 'Extreme South Florida Keys / Coastal Microclimates');


-- =============================================================================
-- 2. REFERENCE.PLANT_TAXONOMY_DIM (USDA PLANTS Database Standard Symbols)
-- =============================================================================
TRUNCATE TABLE REFERENCE.PLANT_TAXONOMY_DIM;

INSERT INTO REFERENCE.PLANT_TAXONOMY_DIM VALUES
    ('PAFL6',  'Parkinsonia x ''Desert Museum''',   'Museum Palo Verde',            'Fabaceae',       'Tree',     30, 30),
    ('PRCH',   'Prosopis chilensis',                'Chilean Mesquite',             'Fabaceae',       'Tree',     35, 35),
    ('QUVI',   'Quercus virginiana',                'Southern Live Oak',            'Fagaceae',       'Tree',     50, 45),
    ('FRVE2',  'Fraxinus velutina ''Fan-Tex''',     'Arizona Fan-Tex Ash',          'Oleaceae',       'Tree',     35, 40),
    ('ULPA',   'Ulmus parvifolia ''True Green''',   'True Green Chinese Elm',       'Ulmaceae',       'Tree',     40, 40),
    ('OLTE',   'Olneya tesota',                     'Desert Ironwood',              'Fabaceae',       'Tree',     25, 25),
    ('OLEU',   'Olea europaea ''Swan Hill''',       'Swan Hill Fruitless Olive',    'Oleaceae',       'Tree',     30, 30),
    ('QUPO2',  'Quercus polymorpha',                'Monterey Mexican White Oak',   'Fagaceae',       'Tree',     35, 40),
    ('SYRO',   'Syagrus romanzoffiana',             'Piru Queen Palm',              'Arecaceae',      'Palm',     20, 40),
    ('CHHU2',  'Chamaerops humilis',                'Mediterranean Fan Palm',       'Arecaceae',      'Palm',     15, 15),
    ('PHDA4',  'Phoenix dactylifera ''Medjool''',   'Medjool Date Palm',            'Arecaceae',      'Palm',     25, 50),
    ('BUNA',   'x Butiagrus nabonnandii',           'Mule Palm',                    'Arecaceae',      'Palm',     20, 30),
    ('BINO',   'Bismarckia nobilis',                'Bismarck Silver Palm',         'Arecaceae',      'Palm',     20, 40),
    ('WARO',   'Washingtonia robusta',              'Mexican Fan Palm',             'Arecaceae',      'Palm',     15, 65),
    ('PHCA13', 'Phoenix canariensis',               'Canary Island Date Palm',      'Arecaceae',      'Palm',     30, 50),
    ('CILI5',  'Citrus x meyeri',                   'Meyer Improved Lemon',         'Rutaceae',       'Tree',     15, 15),
    ('CISI3',  'Citrus x sinensis',                 'Washington Navel Orange',      'Rutaceae',       'Tree',     18, 20),
    ('CIAU7',  'Citrus x latifolia',                'Bearss Seedless Lime',         'Rutaceae',       'Tree',     15, 18),
    ('PEAM3',  'Persea americana ''Hass''',         'Hass Avocado',                 'Lauraceae',      'Tree',     25, 30),
    ('PRPE3',  'Prunus persica ''Desert Gold''',    'Desert Gold Low-Chill Peach',  'Rosaceae',       'Tree',     18, 18),
    ('PUGR2',  'Punica granatum ''Wonderful''',     'Wonderful Pomegranate',        'Lythraceae',     'Tree',     15, 15),
    ('LAIN7',  'Lagerstroemia indica ''Tuscarora''','Tuscarora Crape Myrtle',       'Lythraceae',     'Tree',     20, 25),
    ('SOSE3',  'Sophora secundiflora',              'Texas Mountain Laurel',        'Fabaceae',       'Tree',     15, 20),
    ('DERE',   'Delonix regia',                     'Royal Poinciana',              'Fabaceae',       'Tree',     40, 35),
    ('CHLI2',  'Chilopsis linearis ''Bubba''',      'Bubba Desert Willow',          'Bignoniaceae',   'Tree',     20, 25),
    ('MAGR4',  'Magnolia grandiflora ''Little Gem''','Little Gem Southern Magnolia','Magnoliaceae',   'Tree',     15, 25),
    ('PRCE2',  'Prunus cerasifera ''Krauter Vesuvius''','Purple Leaf Plum',         'Rosaceae',       'Tree',     20, 25),
    ('LEFR3',  'Leucophyllum frutescens ''Green Cloud''','Green Cloud Texas Ranger','Scrophulariaceae','Shrub',    8,  8),
    ('CAPU13', 'Caesalpinia pulcherrima',           'Red Bird of Paradise',         'Fabaceae',       'Shrub',     8,  8),
    ('DOVI',   'Dodonaea viscosa',                  'Hopseed Privacy Bush',         'Sapindaceae',    'Shrub',    10, 12),
    ('BUMI',   'Buxus microphylla japonica',        'Japanese Boxwood',             'Buxaceae',       'Shrub',     5,  6),
    ('BOGL',   'Bougainvillea ''Torch Glow''',      'Torch Glow Bougainvillea',     'Nyctaginaceae',  'Shrub',     6,  6),
    ('LACA2',  'Lantana x ''New Gold''',            'New Gold Lantana',             'Verbenaceae',    'Subshrub',  6,  2),
    ('ROOF',   'Salvia rosmarinus ''Prostratus''',  'Trailing Rosemary',            'Lamiaceae',      'Subshrub',  6,  2),
    ('TRJA',   'Trachelospermum jasminoides',       'Star Jasmine',                 'Apocynaceae',    'Subshrub',  8,  3),
    ('TRPA8',  'Tradescantia pallida',              'Purple Heart Groundcover',     'Commelinaceae',  'Subshrub',  4,  2),
    ('FERT',   'N/A - Nutrient Amendment',          'Moon Valley Fertilizer/Soil',  'Agronomic Input','Input',     0,  0),
    ('SVC',    'N/A - Professional Service',        'Professional Planting/Design', 'Field Service',  'Service',   0,  0);


-- =============================================================================
-- 3. REFERENCE.WATER_USE_DIM (Regional WUCOLS / Desert Water Classification)
-- =============================================================================
TRUNCATE TABLE REFERENCE.WATER_USE_DIM;

INSERT INTO REFERENCE.WATER_USE_DIM VALUES
    ('Very Low', 'Native or desert-adapted xeric species thriving on minimal supplemental drip irrigation once established (10-14 day summer interval).', 10, TRUE),
    ('Low',      'Drought-tolerant Mediterranean/desert species requiring deep infrequent watering every 7-10 days in summer heat.', 7, TRUE),
    ('Moderate', 'Subtropical palms, citrus, and lawn/canopy trees requiring deep root soaking every 3-5 days during summer peak.', 4, FALSE),
    ('High',     'Moisture-loving tropicals requiring frequent irrigation every 2-3 days in summer.', 2, FALSE),
    ('N/A',      'Non-plant SKU (Fertilizer, soil amendment, or professional planting/design service).', 0, FALSE);


-- =============================================================================
-- 4. REFERENCE.GS1_IDENTIFIERS (GTINs for SKUs, GLNs for Stores & Farms)
-- =============================================================================
TRUNCATE TABLE REFERENCE.GS1_IDENTIFIERS;

INSERT INTO REFERENCE.GS1_IDENTIFIERS
SELECT
    'GS1-PRD-' || LPAD(ROW_NUMBER() OVER (ORDER BY product_id)::VARCHAR, 4, '0') AS gs1_id,
    'GTIN' AS identifier_type,
    '00850019' || LPAD(ROW_NUMBER() OVER (ORDER BY product_id)::VARCHAR, 6, '0') AS gtin,
    NULL AS gln,
    product_id,
    NULL AS location_id,
    sku || ' | ' || product_name AS registered_name
FROM RAW.DIM_PRODUCT

UNION ALL

SELECT
    'GS1-LOC-' || LPAD(ROW_NUMBER() OVER (ORDER BY location_id)::VARCHAR, 4, '0') AS gs1_id,
    'GLN' AS identifier_type,
    NULL AS gtin,
    '08500190' || LPAD(ROW_NUMBER() OVER (ORDER BY location_id)::VARCHAR, 5, '0') AS gln,
    NULL AS product_id,
    location_id,
    location_name || ' (' || city || ', ' || state || ')' AS registered_name
FROM RAW.DIM_LOCATION

UNION ALL

SELECT
    'GS1-FRM-' || LPAD(ROW_NUMBER() OVER (ORDER BY farm_id)::VARCHAR, 4, '0') AS gs1_id,
    'GLN' AS identifier_type,
    NULL AS gtin,
    '08500199' || LPAD(ROW_NUMBER() OVER (ORDER BY farm_id)::VARCHAR, 5, '0') AS gln,
    NULL AS product_id,
    farm_id AS location_id,
    farm_name || ' (' || state || ')' AS registered_name
FROM RAW.DIM_FARM;


-- =============================================================================
-- 5. REFERENCE.PRODUCT_TAXONOMY_MAP (SKU-to-Taxonomy, Hardiness & Water-Use)
-- =============================================================================
TRUNCATE TABLE REFERENCE.PRODUCT_TAXONOMY_MAP;

INSERT INTO REFERENCE.PRODUCT_TAXONOMY_MAP
SELECT
    p.product_id,
    p.plant_symbol,
    CASE
        WHEN p.plant_symbol IN ('PAFL6', 'PRCH', 'OLTE', 'CHLI2', 'LEFR3', 'CAPU13', 'DOVI') THEN '8b'
        WHEN p.plant_symbol IN ('QUVI', 'FRVE2', 'ULPA', 'OLEU', 'QUPO2', 'CHHU2', 'PHDA4', 'WARO', 'LAIN7', 'SOSE3', 'MAGR4', 'PRCE2', 'BUMI', 'ROOF', 'TRJA') THEN '8a'
        WHEN p.plant_symbol IN ('SYRO', 'BUNA', 'PHCA13', 'CILI5', 'CISI3', 'CIAU7', 'PRPE3', 'PUGR2', 'BOGL', 'LACA2', 'TRPA8') THEN '9a'
        WHEN p.plant_symbol IN ('BINO', 'PEAM3', 'DERE') THEN '9b'
        ELSE '8a'
    END AS hardiness_min_zone,
    CASE
        WHEN p.plant_symbol IN ('PAFL6', 'PRCH', 'OLTE', 'OLEU', 'CHLI2') THEN '10b'
        ELSE '11a'
    END AS hardiness_max_zone,
    p.water_use AS water_use_class,
    CASE
        WHEN p.plant_symbol IN ('PAFL6', 'PRCH', 'QUVI', 'FRVE2', 'ULPA', 'OLTE', 'OLEU', 'QUPO2', 'SYRO', 'CHHU2', 'PHDA4', 'BUNA', 'BINO', 'WARO', 'PHCA13', 'PUGR2', 'LAIN7', 'SOSE3', 'CHLI2', 'LEFR3', 'CAPU13', 'DOVI', 'BOGL', 'LACA2', 'ROOF')
        THEN TRUE
        ELSE FALSE
    END AS full_sun_desert_ok,
    CASE
        WHEN p.plant_symbol IN ('PAFL6', 'PRCH', 'OLTE', 'OLEU', 'CHLI2')
            THEN 'Prime Phoenix 9b & Las Vegas 9a desert-adapted shade/specimen tree; approved for low-water xeriscape rebates and 115F+ full western sun.'
        WHEN p.plant_symbol IN ('QUVI', 'ULPA', 'FRVE2', 'QUPO2')
            THEN 'High-canopy lawn and street shade tree suited to Zones 8a-10b across AZ, CA, NV, TX, and FL.'
        WHEN p.category = 'Palms'
            THEN 'Resort-grade palm suited to Zones 9a-11a; apply Super Palm Juice monthly March-October and maintain deep drip basin.'
        WHEN p.category = 'Fruit Trees'
            THEN 'Grafted orchard/patio fruit tree; protect young trunks with white tree wrap in desert summer sun.'
        ELSE 'Standard Moon Valley Nursery specimen installation guidelines apply.'
    END AS suitability_notes
FROM RAW.DIM_PRODUCT p;


-- =============================================================================
-- 6. RAW.PLANTING_FIELD_NOTES (240 Crew Notes for MVN_PLANTING_NOTES_SEARCH)
-- =============================================================================
TRUNCATE TABLE RAW.PLANTING_FIELD_NOTES;

INSERT INTO RAW.PLANTING_FIELD_NOTES
WITH seq AS (
    SELECT SEQ4() + 1 AS n_idx
    FROM TABLE(GENERATOR(ROWCOUNT => 240))
),
jobs_sample AS (
    SELECT
        job_id,
        location_id,
        state,
        crew_id,
        sold_date,
        scheduled_date,
        status,
        reschedule_reason,
        ROW_NUMBER() OVER (ORDER BY CASE WHEN state = 'AZ' AND reschedule_count > 0 THEN 0 ELSE 1 END, job_id) AS rn
    FROM RAW.FACT_PLANTED_JOBS
    QUALIFY rn <= 240
)
SELECT
    'NOTE-' || LPAD(s.n_idx::VARCHAR, 4, '0') AS note_id,
    j.job_id,
    j.location_id,
    j.state,
    j.crew_id,
    j.scheduled_date AS note_date,
    CASE MOD(s.n_idx, 5)
        WHEN 0 THEN 'Reschedule Reason - Caliche & Hard Dig'
        WHEN 1 THEN 'Reschedule Reason - Blue Stake Utility Delay'
        WHEN 2 THEN 'Reschedule Reason - Crane & HOA Gate Access'
        WHEN 3 THEN 'Soil, Drainage & Irrigation Observation'
        ELSE        'Post-Planting Inspection & Moon Juice Protocol'
    END AS note_category,
    CASE MOD(s.n_idx, 5)
        WHEN 0 THEN 'Fall Planting Reschedule: Heavy Caliche Layer Required Hydraulic Rock Breaker (' || j.location_id || ')'
        WHEN 1 THEN 'Fall Planting Reschedule: Arizona 811 Blue Stake Utility Marking Delay (' || j.location_id || ')'
        WHEN 2 THEN 'Fall Planting Reschedule: 36in/48in Box Crane Clearance & HOA Gate Access (' || j.location_id || ')'
        WHEN 3 THEN 'Field Crew Soil & Drip Emitter Flow Verification (' || j.location_id || ')'
        ELSE        'Specimen Box Tree Staking, Mulch Basin & Moon Juice Root Drench Completed (' || j.location_id || ')'
    END AS title,
    CASE MOD(s.n_idx, 5)
        WHEN 0 THEN
            'Field Crew Log [' || j.crew_id || ' | Store ' || j.location_id || ' | State ' || j.state || ' | Job ' || j.job_id || ']: '
            || 'Arrived on site for fall tree installation (24in and 36in box Museum Palo Verde and Piru Queen Palms). '
            || 'Excavation encountered a dense 18-inch cemented caliche hardpan layer at 14 inches depth. Standard hand augers could not penetrate. '
            || 'Job was rescheduled by 4 days to dispatch heavy mini-excavator with hydraulic rock-breaker attachment and drill drainage chimneys through the caliche shelf so root balls do not sit in perched water.'
        WHEN 1 THEN
            'Field Crew Log [' || j.crew_id || ' | Store ' || j.location_id || ' | State ' || j.state || ' | Job ' || j.job_id || ']: '
            || 'Scheduled fall planting job had to be rescheduled because underground fiber-optic and gas lines in the front yard setback had not yet been marked by 811 Blue Stake utility locators during peak fall backlog. '
            || 'Re-booked installation 5 days out once utility clearance flags were verified; crew pre-marked tree locations with customer.'
        WHEN 2 THEN
            'Field Crew Log [' || j.crew_id || ' | Store ' || j.location_id || ' | State ' || j.state || ' | Job ' || j.job_id || ']: '
            || 'Customer ordered two 48in box Southern Live Oaks and three 36in box Medjool Date Palms requiring knuckle-boom crane placement over backyard perimeter wall. '
            || 'Job was rescheduled in Arizona fall peak because HOA architectural gate clearance and street crane outrigger permit required 72-hour advance sign-off and overhead line spotter.'
        WHEN 3 THEN
            'Field Crew Log [' || j.crew_id || ' | Store ' || j.location_id || ' | State ' || j.state || ' | Job ' || j.job_id || ']: '
            || 'Completed excavation in decomposed granite / clay loam soil. Amended backfill 30% with Moon Valley Mulch & Compost blend. '
            || 'Inspected customer existing drip irrigation manifold: found two clogged 2-GPH emitters on the palm zone and upgraded to dedicated multi-port bubblers delivering 15 gallons per deep cycle.'
        ELSE
            'Field Crew Log [' || j.crew_id || ' | Store ' || j.location_id || ' | State ' || j.state || ' | Job ' || j.job_id || ']: '
            || 'Completed professional planting of specimen box trees. Built 4-inch earthen watering berm around outer edge of root ball, applied initial drench of Moon Juice root bio-stimulant and Super Charged Moon Green, double-staked trunks with lodgepole stakes and rubber cinch ties, and walked homeowner through seasonal watering calendar.'
    END AS content
FROM seq s
JOIN jobs_sample j ON s.n_idx = j.rn;


-- =============================================================================
-- 7. RAW.PLANT_CARE_GUIDES (60 Agronomic Care Guides for MVN_PLANT_CARE_SEARCH)
-- =============================================================================
TRUNCATE TABLE RAW.PLANT_CARE_GUIDES;

INSERT INTO RAW.PLANT_CARE_GUIDES
WITH seq AS (
    SELECT SEQ4() + 1 AS g_idx
    FROM TABLE(GENERATOR(ROWCOUNT => 60))
),
tax AS (
    SELECT
        plant_symbol,
        scientific_name,
        common_name,
        growth_habit,
        ROW_NUMBER() OVER (ORDER BY plant_symbol) AS t_rn
    FROM REFERENCE.PLANT_TAXONOMY_DIM
    WHERE plant_symbol NOT IN ('FERT', 'SVC')
)
SELECT
    'CARE-' || LPAD(s.g_idx::VARCHAR, 3, '0') AS guide_id,
    CASE t.growth_habit
        WHEN 'Palm'  THEN 'Palms'
        WHEN 'Shrub' THEN 'Shrubs'
        WHEN 'Subshrub' THEN 'Groundcover'
        ELSE 'Shade & Flowering Trees'
    END AS category,
    t.plant_symbol,
    CASE
        WHEN t.plant_symbol IN ('PAFL6', 'PRCH', 'OLTE', 'OLEU', 'CHLI2') THEN '8b-10b'
        WHEN t.plant_symbol IN ('SYRO', 'PHDA4', 'CHHU2', 'BUNA', 'BINO', 'WARO', 'PHCA13') THEN '9a-11a'
        ELSE '8a-10b'
    END AS hardiness_zone,
    CASE
        WHEN t.plant_symbol IN ('PAFL6', 'PRCH', 'OLTE', 'CHLI2', 'LEFR3', 'CAPU13', 'DOVI') THEN 'Very Low'
        WHEN t.plant_symbol IN ('QUVI', 'FRVE2', 'ULPA', 'OLEU', 'QUPO2', 'CHHU2', 'PHDA4', 'WARO') THEN 'Low'
        ELSE 'Moderate'
    END AS water_use_class,
    CASE MOD(s.g_idx, 4)
        WHEN 0 THEN 'Desert Southwest (AZ / NV)'
        WHEN 1 THEN 'Southern California'
        WHEN 2 THEN 'Texas'
        ELSE        'Florida'
    END AS region,
    'Moon Valley Care & Watering Guide: ' || t.common_name || ' (' || t.scientific_name || ') - Guide #' || s.g_idx AS title,
    'SYNTHETIC AGRONOMIC CARE GUIDE [' || t.common_name || ' | Symbol: ' || t.plant_symbol || ' | Scientific: ' || t.scientific_name || ']: '
    || '1. HARDINESS & SUN EXPOSURE: Thrives in USDA Zones '
    || (CASE WHEN t.plant_symbol IN ('PAFL6', 'PRCH', 'OLTE', 'OLEU', 'CHLI2') THEN '8b to 10b (Phoenix Metro 9b and Las Vegas 9a certified).' ELSE '9a to 11a.' END)
    || ' Handles full desert sun and reflected heat when deep-watered properly. '
    || '2. NEW TRANSPLANT WATERING PROTOCOL (FIRST 90 DAYS): Water deeply using a 3-to-4 inch soil basin or high-flow bubblers so moisture reaches the bottom of the 24in/36in/48in box root ball (24-36 inches deep). '
    || 'In Spring/Fall (70F-90F), deep soak every 3 to 4 days. In Desert Summer Peak (100F-118F in AZ/NV), deep soak Newly Planted box trees every 2 to 3 days; once established (Year 2+), Very Low and Low water-use trees (Museum Palo Verde, Chilean Mesquite, Desert Ironwood, Swan Hill Olive, Desert Willow) transition to deep soaking every 7 to 14 days. '
    || '3. FERTILIZATION & SOIL CARE: Apply Moon Juice Root Bio-Stimulant monthly for the first 6 months after transplanting to accelerate root hair recovery. Feed with Super Charged Moon Green (for shade/evergreen trees) or Super Palm Juice (for Piru Queen Palm, Medjool Date Palm, Mule Palm, Mediterranean Fan Palm) in March, May, August, and October to prevent iron/manganese chlorosis in alkaline caliche soils.'
    AS content
FROM seq s
JOIN tax t ON t.t_rn = MOD(s.g_idx - 1, 36) + 1;


-- =============================================================================
-- 8. RAW.WARRANTY_POLICIES (30 Synthetic Warranty & Replacement Policies)
-- =============================================================================
TRUNCATE TABLE RAW.WARRANTY_POLICIES;

INSERT INTO RAW.WARRANTY_POLICIES
WITH seq AS (
    SELECT SEQ4() + 1 AS p_idx
    FROM TABLE(GENERATOR(ROWCOUNT => 30))
)
SELECT
    'POL-' || LPAD(p_idx::VARCHAR, 3, '0') AS policy_id,
    CASE MOD(p_idx, 5)
        WHEN 0 THEN 'Palm Tree Replacement & Warranty Policy'
        WHEN 1 THEN 'Specimen Box Tree (24in / 36in / 48in+) 1-Year Guarantee'
        WHEN 2 THEN 'Professional Planting Required for Full Warranty Coverage'
        WHEN 3 THEN 'Extreme Heat, Freeze & Caliche Drainage Provisions'
        ELSE        'Commercial, Landscaper & Homebuilder Volume Warranty Terms'
    END AS policy_category,
    CASE MOD(p_idx, 5)
        WHEN 0 THEN 'Palms'
        WHEN 1 THEN 'Shade Trees, Flowering Trees, Fruit Trees'
        WHEN 2 THEN 'All Trees & Palms'
        WHEN 3 THEN 'Palms, Fruit Trees, Subtropicals'
        ELSE        'All Categories (Commercial/Builder)'
    END AS applicable_categories,
    CASE MOD(p_idx, 5)
        WHEN 4 THEN 'Builder/Commercial'
        ELSE        'All'
    END AS customer_type,
    DATEADD('month', -MOD(p_idx, 24), '2026-01-01'::DATE) AS effective_date,
    CASE MOD(p_idx, 5)
        WHEN 0 THEN 'Moon Valley Synthetic Policy #' || p_idx || ': Palm Tree Replacement & Extended Warranty Terms'
        WHEN 1 THEN 'Moon Valley Synthetic Policy #' || p_idx || ': Specimen Box Tree 12-Month Guarantee'
        WHEN 2 THEN 'Moon Valley Synthetic Policy #' || p_idx || ': Professional Planting & Care Eligibility Requirements'
        WHEN 3 THEN 'Moon Valley Synthetic Policy #' || p_idx || ': Desert Heat Stress, Winter Freeze & Caliche Provisions'
        ELSE        'Moon Valley Synthetic Policy #' || p_idx || ': Commercial & Builder Account Replacement SLA'
    END AS title,
    CASE MOD(p_idx, 5)
        WHEN 0 THEN
            'SYNTHETIC WARRANTY POLICY — PALM REPLACEMENT TERMS (Document POL-' || LPAD(p_idx::VARCHAR, 3, '0') || '): '
            || 'All Piru Queen Palms, Medjool Date Palms, Mediterranean Fan Palms, Mule Palms, Bismarck Palms, and Canary Island Date Palms planted by Moon Valley Nursery professional planting crews are covered under our 90-day standard transplant survival guarantee, expandable to a full 12-month one-time replacement warranty when the Extended Tree Warranty Plan is purchased at time of sale. '
            || 'PALM REPLACEMENT CRITERIA: Palm fronds naturally yellow or brown on outer lower rings after transplanting; replacement is triggered only if the central spear leaf (heart frond) fails to push new growth or pulls out due to bud rot within the coverage window. '
            || 'WHAT IS INCLUDED: One-time replacement with a palm of equal container size (15 gal, 24in box, 36in box, or 48in box+) and store credit up to original purchase price, including standard crew re-planting labor when Extended Warranty Flag = TRUE. Crane mobilization fees on 48in+ specimen palms are covered at 50% on warranty re-installs.'
        WHEN 1 THEN
            'SYNTHETIC WARRANTY POLICY — SPECIMEN BOX TREE GUARANTEE (Document POL-' || LPAD(p_idx::VARCHAR, 3, '0') || '): '
            || '24in box, 36in box, and 48in+ specimen Shade, Flowering, and Fruit Trees professionally planted by Moon Valley crews carry a 1-year one-time replacement guarantee when enrolled in the Extended Warranty Plan. '
            || 'Before issuing a replacement order, a Moon Valley Field Tree Tech performs an on-site scratch-and-soil moisture diagnostic and prescribes a 30-day Moon Juice recovery protocol if cambium tissue remains green.'
        WHEN 2 THEN
            'SYNTHETIC WARRANTY POLICY — PROFESSIONAL PLANTING REQUIREMENT (Document POL-' || LPAD(p_idx::VARCHAR, 3, '0') || '): '
            || 'Full replacement labor coverage applies exclusively to trees and palms installed by Moon Valley Nursery certified crews (includes_planting_flag = TRUE). Cash-and-carry trees planted by third parties carry a 30-day 50% store-credit-only nursery stock guarantee.'
        WHEN 3 THEN
            'SYNTHETIC WARRANTY POLICY — HEAT, FREEZE & CALICHE PROVISIONS (Document POL-' || LPAD(p_idx::VARCHAR, 3, '0') || '): '
            || 'To maintain warranty eligibility in Desert Southwest markets (AZ/NV Zones 9a-9b), customers must maintain functional drip or bubbler irrigation and allow crews to drill drainage chimneys if hardpan caliche is identified during excavation. Trees planted outside their rated USDA hardiness zone minimum are excluded from freeze replacement.'
        ELSE
            'SYNTHETIC WARRANTY POLICY — COMMERCIAL, LANDSCAPER & BUILDER ACCOUNTS (Document POL-' || LPAD(p_idx::VARCHAR, 3, '0') || '): '
            || 'Registered Landscaper and Builder/Commercial accounts receive a 90-day post-acceptance workmanship and stock mortality replacement SLA on model-home and community common-area installations when site irrigation is certified active at handoff.'
    END AS content
FROM seq;


-- Verify Reference & Unstructured Table Counts
SELECT 'HARDINESS_ZONE_DIM'   AS table_name, COUNT(*) AS row_count FROM REFERENCE.HARDINESS_ZONE_DIM
UNION ALL SELECT 'PLANT_TAXONOMY_DIM',   COUNT(*) FROM REFERENCE.PLANT_TAXONOMY_DIM
UNION ALL SELECT 'WATER_USE_DIM',        COUNT(*) FROM REFERENCE.WATER_USE_DIM
UNION ALL SELECT 'GS1_IDENTIFIERS',      COUNT(*) FROM REFERENCE.GS1_IDENTIFIERS
UNION ALL SELECT 'PRODUCT_TAXONOMY_MAP', COUNT(*) FROM REFERENCE.PRODUCT_TAXONOMY_MAP
UNION ALL SELECT 'PLANTING_FIELD_NOTES', COUNT(*) FROM RAW.PLANTING_FIELD_NOTES
UNION ALL SELECT 'PLANT_CARE_GUIDES',    COUNT(*) FROM RAW.PLANT_CARE_GUIDES
UNION ALL SELECT 'WARRANTY_POLICIES',    COUNT(*) FROM RAW.WARRANTY_POLICIES;
