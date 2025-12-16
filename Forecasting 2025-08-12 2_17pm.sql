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

-- Prepare your training data. Timestamp_ntz is a required format.
CREATE or replace VIEW METERING_DAILY_HISTORY_v1 AS SELECT
    * EXCLUDE USAGE_DATE,
    to_timestamp_ntz(USAGE_DATE) as USAGE_DATE_v1
FROM METERING_DAILY_HISTORY;

-- Prepare your prediction data. Timestamp_ntz is a required format.
CREATE or replace VIEW METERING_DAILY_HISTORY_v1 AS SELECT
    * EXCLUDE USAGE_DATE,
    to_timestamp_ntz(USAGE_DATE) as USAGE_DATE_v1
FROM METERING_DAILY_HISTORY;

-----------------------------------------------------------
-- CREATE PREDICTIONS
-----------------------------------------------------------
-- Create your model.
CREATE SNOWFLAKE.ML.FORECAST snowflake_cost_estimation(
    INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'METERING_DAILY_HISTORY_v1'),
    SERIES_COLNAME => 'SERVICE_TYPE',
    TIMESTAMP_COLNAME => 'USAGE_DATE_v1',
    TARGET_COLNAME => 'CREDITS_BILLED',
    CONFIG_OBJECT => { 'ON_ERROR': 'SKIP' }
);

-- Generate predictions and store the results to a table.
BEGIN
    -- This is the step that creates your predictions.
    CALL snowflake_cost_estimation!FORECAST(
        INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'METERING_DAILY_HISTORY_v1'),
        SERIES_COLNAME => 'SERVICE_TYPE',
        TIMESTAMP_COLNAME => 'USAGE_DATE_v1',
        -- Here we set your prediction interval.
        CONFIG_OBJECT => {'prediction_interval': 0.95}
    );
    -- These steps store your predictions to a table.
    LET x := SQLID;
    CREATE TABLE Snowflake_cost_forecasts_2025_08_12 AS SELECT * FROM TABLE(RESULT_SCAN(:x));
END;

-- View your predictions.
SELECT * FROM Snowflake_cost_forecasts_2025_08_12;

-- Union your predictions with your historical data, then view the results in a chart.
SELECT SERVICE_TYPE, USAGE_DATE, CREDITS_BILLED AS actual, NULL AS forecast, NULL AS lower_bound, NULL AS upper_bound
    FROM METERING_DAILY_HISTORY
UNION ALL
SELECT replace(series, '"', '') as SERVICE_TYPE, ts as USAGE_DATE, NULL AS actual, forecast, lower_bound, upper_bound
    FROM Snowflake_cost_forecasts_2025_08_12;

-----------------------------------------------------------
-- INSPECT RESULTS
-----------------------------------------------------------

-- Inspect the accuracy metrics of your model. 
CALL snowflake_cost_estimation!SHOW_EVALUATION_METRICS();

-- Inspect the relative importance of your features, including auto-generated features. 
CALL snowflake_cost_estimation!EXPLAIN_FEATURE_IMPORTANCE();
