-- Summary of objects created in this script:
--
-- Roles:
--   - snowflake_intelligence_admin
--
-- Warehouses:
--   - dash_wh_si
--
-- Databases:
--   - dash_db_si
--   - snowflake_intelligence
--
-- Schemas:
--   - dash_db_si.retail
--   - snowflake_intelligence.agents
--
-- File Format:
--   - swt_csvformat
--
-- Stages:
--   - swt_marketing_data_stage
--   - swt_products_data_stage
--   - swt_sales_data_stage
--   - swt_social_media_data_stage
--   - swt_support_data_stage
--   - semantic_models
--
-- Tables:
--   - marketing_campaign_metrics
--   - products
--   - sales
--   - social_media
--   - support_cases
--
-- Notification Integration:
--   - email_integration
--
-- Stored Procedure:
--   - send_email


use role accountadmin;

create or replace role snowflake_intelligence_admin;
grant create warehouse on account to role snowflake_intelligence_admin;
grant create database on account to role snowflake_intelligence_admin;
grant usage on warehouse coe_practise_wh to role snowflake_intelligence_admin;
grant create integration on account to role snowflake_intelligence_admin;

set current_user = (select current_user());   
grant role snowflake_intelligence_admin to user identifier($current_user);
alter user set default_role = snowflake_intelligence_admin;
alter user set default_warehouse = coe_practise_wh;

use role snowflake_intelligence_admin;
create or replace database dash_db_si;
create or replace schema retail;
create or replace warehouse dash_wh_si with warehouse_size='large';

create or replace database snowflake_intelligence;
create or replace schema snowflake_intelligence.agents;

use database dash_db_si;
use schema retail;
use warehouse dash_wh_si;

create or replace file format swt_csvformat  
  skip_header = 1  
  field_optionally_enclosed_by = '"'  
  type = 'csv';  
  
-- create table marketing_campaign_metrics and load data from s3 bucket
create or replace stage swt_marketing_data_stage  
  file_format = swt_csvformat  
  url = 's3://sfquickstarts/sfguide_getting_started_with_snowflake_intelligence/marketing/';  

  list @swt_marketing_data_stage;

  select $1,$2 from @swt_marketing_data_stage;
  
create or replace table marketing_campaign_metrics (
  date date,
  category varchar(16777216),
  campaign_name varchar(16777216),
  impressions number(38,0),
  clicks number(38,0)
);

copy into marketing_campaign_metrics  
  from @swt_marketing_data_stage;

select * from marketing_campaign_metrics;
  
-- create table products and load data from s3 bucket
create or replace stage swt_products_data_stage  
  file_format = swt_csvformat  
  url = 's3://sfquickstarts/sfguide_getting_started_with_snowflake_intelligence/product/';  
  
create or replace table products (
  product_id number(38,0),
  product_name varchar(16777216),
  category varchar(16777216)
);

copy into products  
  from @swt_products_data_stage;

  select * from products;

-- create table sales and load data from s3 bucket
create or replace stage swt_sales_data_stage  
  file_format = swt_csvformat  
  url = 's3://sfquickstarts/sfguide_getting_started_with_snowflake_intelligence/sales/';  
  
create or replace table sales (
  date date,
  region varchar(16777216),
  product_id number(38,0),
  units_sold number(38,0),
  sales_amount number(38,2)
);

copy into sales  
  from @swt_sales_data_stage;

  select * From sales;

-- create table social_media and load data from s3 bucket
create or replace stage swt_social_media_data_stage  
  file_format = swt_csvformat  
  url = 's3://sfquickstarts/sfguide_getting_started_with_snowflake_intelligence/social_media/';  
  
create or replace table social_media (
  date date,
  category varchar(16777216),
  platform varchar(16777216),
  influencer varchar(16777216),
  mentions number(38,0)
);

copy into social_media  
  from @swt_social_media_data_stage;

  select * from social_media;

-- create table support_cases and load data from s3 bucket
create or replace stage swt_support_data_stage  
  file_format = swt_csvformat  
  url = 's3://sfquickstarts/sfguide_getting_started_with_snowflake_intelligence/support/';  
  
create or replace table support_cases (
  id varchar(16777216),
  title varchar(16777216),
  product varchar(16777216),
  transcript varchar(16777216),
  date date
);

copy into support_cases  
  from @swt_support_data_stage;

  select * from support_cases;

create or replace stage semantic_models encryption = (type = 'snowflake_sse') directory = ( enable = true );

create or replace notification integration email_integration
  type=email
  enabled=true
  default_subject = 'snowflake intelligence';

create or replace procedure send_email(
    recipient_email varchar,
    subject varchar,
    body varchar
)
returns varchar
language python
runtime_version = '3.12'
packages = ('snowflake-snowpark-python')
handler = 'send_email'
as
$$
def send_email(session, recipient_email, subject, body):
    try:
        # Escape single quotes in the body
        escaped_body = body.replace("'", "''")
        
        # Execute the system procedure call
        session.sql(f"""
            CALL SYSTEM$SEND_EMAIL(
                'email_integration',
                '{recipient_email}',
                '{subject}',
                '{escaped_body}'
            )
        """).collect()
        
        return "Email sent successfully"
    except Exception as e:
        return f"Error sending email: {str(e)}"
$$;

select 'Congratulations! Snowflake Intelligence setup has completed successfully!' as status;


-- Use AI_AGG to aggregate support cases summary and insert into a new table AGGREGATED_SUPPORT_CASES_SUMMARY

use database DASH_DB_SI;
use schema RETAIL;

create or replace table AGGREGATED_SUPPORT_CASES_SUMMARY as
 select 
    ai_agg(transcript,'Read and analyze all support cases to provide a long-form text summary in no less than 5000 words.') as summary
    from support_cases;

-- Create Cortex Search service on table AGGREGATED_SUPPORT_CASES_SUMMARY

select * From AGGREGATED_SUPPORT_CASES_SUMMARY;

create or replace cortex search service AGGREGATED_SUPPORT_CASES 
on summary 
attributes
  summary 
warehouse = coe_practise_wh 
embedding_model = 'snowflake-arctic-embed-m-v1.5' 
target_lag = '1 hour' 
initialize=on_schedule 
as (
  select
    summary
  from AGGREGATED_SUPPORT_CASES_SUMMARY
);


show grants on schema SNOWFLAKE_INTELLIGENCE.agents;

show users like '%MUTHU%';


SELECT DASH_DB_SI.RETAIL.DOC_AI_TEST!PREDICT(
  GET_PRESIGNED_URL(@<stage_name>, RELATIVE_PATH), 1)
FROM DIRECTORY(@<stage_name>);


show stages in schema retail;

SELECT DASH_DB_SI.RETAIL.DOC_AI_TEST!PREDICT(
  GET_PRESIGNED_URL(@semantic_models, 'semantic_models/Cycling_Jerseys_Sales_Report_2025.pdf'), 1);

SELECT DASH_DB_SI.RETAIL.DOC_AI_TEST!PREDICT(
  GET_PRESIGNED_URL(@semantic_models, RELATIVE_PATH), 1)
  FROM DIRECTORY(@semantic_models);


semantic_models/Cycling_Jerseys_Sales_Report_2025.pdf

create or replace stage sales_reports encryption = (type = 'snowflake_sse') directory = ( enable = true );

list @sales_reports;

list @SEMANTIC_MODELS;

--ai-observability
USE ROLE ACCOUNTADMIN;



GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE snowflake_intelligence_admin;

GRANT APPLICATION ROLE SNOWFLAKE.AI_OBSERVABILITY_EVENTS_LOOKUP TO ROLE snowflake_intelligence_admin;

GRANT CREATE EXTERNAL AGENT ON SCHEMA retail TO ROLE snowflake_intelligence_admin;

GRANT CREATE TASK ON SCHEMA retail TO ROLE snowflake_intelligence_admin;

GRANT EXECUTE TASK ON ACCOUNT TO ROLE snowflake_intelligence_admin;

GRANT ROLE snowflake_intelligence_admin TO USER MANIMARARCHANDRASEKAR;

select current_user();



CREATE OR REPLACE TABLE raw_text AS
SELECT
    RELATIVE_PATH,
    TO_VARCHAR (
        SNOWFLAKE.CORTEX.PARSE_DOCUMENT (
            '@sales_reports',
            RELATIVE_PATH,
            {'mode': 'LAYOUT'} ):content
        ) AS EXTRACTED_LAYOUT
FROM
    DIRECTORY('@sales_reports')
WHERE
    RELATIVE_PATH LIKE '%.pdf';


select * From raw_text;

    CREATE OR REPLACE TABLE doc_chunks AS
SELECT
    relative_path,
    BUILD_SCOPED_FILE_URL(@sales_reports, relative_path) AS file_url,
    CONCAT(relative_path, ': ', c.value::TEXT) AS chunk,
    'English' AS language
FROM
    raw_text,
    LATERAL FLATTEN(SNOWFLAKE.CORTEX.SPLIT_TEXT_RECURSIVE_CHARACTER(
        EXTRACTED_LAYOUT,
        'markdown',
        2000, -- chunks of 2000 characters
        300 -- 300 character overlap
    )) c;


    select * from doc_chunks;

    
SELECT DASH_DB_SI.RETAIL.DOC_AI_TEST!PREDICT(
  GET_PRESIGNED_URL(@sales_reports, RELATIVE_PATH), 1)
  FROM DIRECTORY(@sales_reports);



  SELECT
  TO_VARCHAR (
    SNOWFLAKE.CORTEX.PARSE_DOCUMENT (
        '@sales_reports',
        'document_1.pdf',
        {'mode': 'LAYOUT'} ) ) AS LAYOUT;



        CREATE OR REPLACE TABLE doc_embeddings AS
SELECT relative_path,
       SNOWFLAKE.CORTEX.EMBED_TEXT_768('snowflake-arctic-embed-m-v1.5', extracted_layout) AS vector
FROM raw_text;


select * from doc_embeddings;

CREATE VECTOR INDEX idx_doc_embeddings ON doc_embeddings (vector) TYPE 'IVF_FLAT';



CREATE OR REPLACE STAGE audio_stage
    DIRECTORY = ( ENABLE = true )
    ENCRYPTION = ( TYPE = 'SNOWFLAKE_SSE' );

    list @audio_stage;

     insert into audio_transcribe
    SELECT TO_VARCHAR(AI_TRANSCRIBE(TO_FILE(
    '@audio_stage', 'strength_training_advantages.mp3')));

    create table audio_transcribe ( Value string);

    select * from audio_transcribe;

    use role orgadmin;
    show accounts; --LTIDATACOE2

    SELECT CURRENT_ORGANIZATION_NAME() || '.' || CURRENT_ACCOUNT_NAME();



    
show replication groups;
    ZQISEAM.LTIMOSAIC.SF_COE_REPL_GRP;
    use role accountadmin;

    show databases in replication group SF_REPL_LTIMOSAIC_GRP;
    SHOW DATABASES IN REPLICATION GROUP SF_REPL_LTIMOSAIC_GRP;
    SHOW shares IN REPLICATION GROUP SF_COE_REPL_GRP;

    grant monitor on all replication groups to role accountadmin;

CREATE REPLICATION GROUP SF_REPL_LTIMOSAIC_GRP
  AS REPLICA OF ZQISEAM.LTIMOSAIC.SF_COE_REPL_GRP;

  ALTER REPLICATION GROUP SF_REPL_LTIMOSAIC_GRP REFRESH;

  use database SUPPLY_CHAIN_DB;
  show schemas;
  use schema PROCUREMENT;
  show tables;
  use schema PRODUCTIVITY;
  show tables;

  show users like '%MUTHU%';
  show grants to user MUTHUSIVANVELLAPANDIAN;


  CREATE EVENT TABLE COE_PRACTISE_DB.manimaranc.event_table;
ALTER ACCOUNT SET EVENT_TABLE = COE_PRACTISE_DB.manimaranc.event_table;

alter ACCOUNT set log_level = DEBUG;
alter ACCOUNT set trace_level = ON_EVENT;
ALTER SESSION SET LOG_LEVEL = INFO;

select * from COE_PRACTISE_DB.manimaranc.event_table;

  
    select * From ai_observability_db.ai_observability_schema.insurance_support_data;

    insert into ai_observability_db.ai_observability_schema.insurance_support_data
    select latest_question,REQUEST_BODY from snowflake.local.CORTEX_ANALYST_REQUESTS_V
    where semantic_model_name = '@DEMO_INSURANCE.INSURANCE_SCH.SCHEMANTIC_STAGE/INSURANCE_INSIGHTS.yaml'
    and semantic_model_type = 'FILE_ON_STAGE';

    
show users;
show parameters for user;


SELECT SNOWFLAKE.CORTEX.ANALYST(
    'You are a insurance analyst. Summarize insights from this dataset.',
    TABLE(SELECT * FROM  DEMO_INSURANCE.INSURANCE_SCH.CLAIMS)
) AS analysis;
    
     
    

    