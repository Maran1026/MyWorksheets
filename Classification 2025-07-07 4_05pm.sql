-- This is your Cortex Project.
-----------------------------------------------------------
-- SETUP
-----------------------------------------------------------
use role ACCOUNTADMIN;
use warehouse LTPOC_WH;
use database LT_POC;
use schema ML_FUNCTIONS;

-- Inspect the first 10 rows of your training data. This is the data we'll
-- use to create your model.
select * from TRAINING_VIEW limit 10;

-- Inspect the first 10 rows of your prediction data. This is the data the model
-- will use to generate predictions.
select * from INFERENCE_VIEW limit 10;

-----------------------------------------------------------
-- CREATE PREDICTIONS
-----------------------------------------------------------
-- Create your model.
CREATE OR REPLACE SNOWFLAKE.ML.CLASSIFICATION LT_CLASSIFIER_POC(
    INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'TRAINING_VIEW'),
    TARGET_COLNAME => 'CLIENT_SUBSCRIBED',
    CONFIG_OBJECT => { 'ON_ERROR': 'SKIP' }
);

-- Inspect your logs to ensure training completed successfully. 
CALL LT_CLASSIFIER_POC!SHOW_TRAINING_LOGS();

-- Generate predictions as new columns in to your prediction table.
CREATE TABLE LT_POC_classification_2025_07_07 AS SELECT
    *, 
    LT_CLASSIFIER_POC!PREDICT(
        OBJECT_CONSTRUCT(*),
        -- This option alows the prediction process to complete even if individual rows must be skipped.
        {'ON_ERROR': 'SKIP'}
    ) as predictions
from INFERENCE_VIEW;

-- View your predictions.
SELECT * FROM LT_POC_classification_2025_07_07;

-- Parse the prediction results into separate columns. 
-- Note: This is a just an example. Be sure to update this to reflect 
-- the classes in your dataset.
SELECT * EXCLUDE predictions,
        predictions:class AS class,
        round(predictions['probability'][class], 3) as probability
FROM LT_POC_classification_2025_07_07;

-----------------------------------------------------------
-- INSPECT RESULTS
-----------------------------------------------------------

-- Inspect your model's evaluation metrics.
CALL LT_CLASSIFIER_POC!SHOW_EVALUATION_METRICS();
CALL LT_CLASSIFIER_POC!SHOW_GLOBAL_EVALUATION_METRICS();
CALL LT_CLASSIFIER_POC!SHOW_CONFUSION_MATRIX();

-- Inspect the relative importance of your features, including auto-generated features.  
CALL LT_CLASSIFIER_POC!SHOW_FEATURE_IMPORTANCE();
