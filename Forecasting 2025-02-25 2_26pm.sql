-- This is your Cortex Project.
-----------------------------------------------------------
-- SETUP
-----------------------------------------------------------
use role ACCOUNTADMIN;
use warehouse COE_PRACTISE_WH;
use database SNOWFLAKE;
use schema ACCOUNT_USAGE;

-- Inspect the first 10 rows of your training data. This is the data we'll use to create your model.
select * from METERING_DAILY_HISTORY limit 10;

-- Prepare your training data. Timestamp_ntz is a required format. Also, only include select columns.
CREATE  or replace VIEW coe_practise_db.manimaranc.METERING_DAILY_HISTORY_v1 AS SELECT
    to_timestamp_ntz(USAGE_DATE) as USAGE_DATE_v1,
    CREDITS_BILLED,
    SERVICE_TYPE
FROM METERING_DAILY_HISTORY;



-----------------------------------------------------------
-- CREATE PREDICTIONS
-----------------------------------------------------------
-- Create your model.
CREATE  or replace SNOWFLAKE.ML.FORECAST Account_Usage_Metrics_Model(
    INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'METERING_DAILY_HISTORY_v1'),
    SERIES_COLNAME => 'SERVICE_TYPE',
    TIMESTAMP_COLNAME => 'USAGE_DATE_v1',
    TARGET_COLNAME => 'CREDITS_BILLED',
    CONFIG_OBJECT => { 'ON_ERROR': 'SKIP' }
);

show models in schema coe_practise_db.manimaranc;
show instances in database coe_practise_db;

-- Generate predictions and store the results to a table.
BEGIN
    -- This is the step that creates your predictions.
    CALL Account_Usage_Metrics_Model!FORECAST(
        FORECASTING_PERIODS => 30,
        -- Here we set your prediction interval.
        CONFIG_OBJECT => {'prediction_interval': 0.95}
    );
    -- These steps store your predictions to a table.
    LET x := SQLID;
    CREATE TABLE Account_usage_metrics_2025_02_25 AS SELECT * FROM TABLE(RESULT_SCAN(:x));
END;

-- View your predictions.
SELECT * FROM Account_usage_metrics_2025_02_25;

-- Union your predictions with your historical data, then view the results in a chart.
SELECT SERVICE_TYPE, USAGE_DATE, CREDITS_BILLED AS actual, NULL AS forecast, NULL AS lower_bound, NULL AS upper_bound
    FROM METERING_DAILY_HISTORY
UNION ALL
SELECT replace(series, '"', '') as SERVICE_TYPE, ts as USAGE_DATE, NULL AS actual, forecast, lower_bound, upper_bound
    FROM Account_usage_metrics_2025_02_25;

-----------------------------------------------------------
-- INSPECT RESULTS
-----------------------------------------------------------

-- Inspect the accuracy metrics of your model. 
CALL Account_Usage_Metrics_Model!SHOW_EVALUATION_METRICS();

-- Inspect the relative importance of your features, including auto-generated features. 
CALL Account_Usage_Metrics_Model!EXPLAIN_FEATURE_IMPORTANCE();
