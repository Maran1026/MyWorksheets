
CREATE OR REPLACE TABLE raw_json_input (
  raw_content STRING
);

CREATE OR REPLACE TABLE cleaned_json_output (
  base_object VARIANT,
  extracted_object VARIANT
);

CREATE OR REPLACE STAGE my_json_stage;
 $my_json_stage;

 large_nested_json;


CREATE OR REPLACE PROCEDURE process_json_file()
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = '3.10'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'process_json'
AS
$$
from snowflake.snowpark import Session
from snowflake.snowpark.functions import col, lit
import json
import re

def clean_json_whitespace(json_string):
    # Remove unnecessary whitespace using regex
    return re.sub(r'\s+', ' ', json_string).strip()

def process_json(session: Session):
    stage_path = "@my_json_stage/large_nested_json.json"
    
    # Read raw file
    df = session.read.option("compression", "gzip").text(stage_path)

    results = []
    for row in df.collect():
        raw_json = row[0]
        cleaned_json = clean_json_whitespace(raw_json)

        try:
            json_obj = json.loads(cleaned_json)

            # Mode 1: If it's a JSON array, strip outer array
            if isinstance(json_obj, list):
                for obj in json_obj:
                    results.append((None, json.dumps(obj)))
            else:
                results.append((json.dumps(json_obj), None))

        except Exception as e:
            print(f"Skipping malformed line: {e}")

    # Save cleaned results into target table
    result_df = session.create_dataframe(results, schema=["base_object", "extracted_object"])
    result_df = result_df.with_column("base_object", col("base_object").cast("VARIANT")) \
                         .with_column("extracted_object", col("extracted_object").cast("VARIANT"))

    result_df.write.mode("append").save_as_table("cleaned_json_output")
$$;

call process_json_file();


use role accountadmin;


SELECT SYSTEM$ENABLE_BEHAVIOR_CHANGE_BUNDLE('2025_03');  

create table test_varchar_128(id varchar(16777217 ));





CREATE STORAGE INTEGRATION s3_int
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::866135604456:role/snw_catalog_role'
  ENABLED = TRUE
  STORAGE_ALLOWED_LOCATIONS = ('s3://snwbucket1/');

  desc storage integration s3_int;


  CREATE STAGE my_s3_stage
  STORAGE_INTEGRATION = s3_int
  URL = 's3://snwbucket1/';

  list @my_s3_stage;


  create table table1(col variant);
 
 
create or replace file format my_json_format
  type = json
  strip_outer_array=true;
 

copy into table1
from @my_s3_stage/archive_feed_20250501_0.json
file_format=my_json_format;

  select * from table1;


  use role accountadmin;
  --grant application_role 

  USE ROLE GLOBALORGADMIN;
  GRANT APPLICATION ROLE ORGANIZATION_OBJECT_VIEWER TO ROLE hon_platform_admin;

  grant role GLOBALORGADMIN to role hon_platform_admin;
  use role orgadmin;

  revoke role orgadmin from role hon_platform_admin;


  use role accountadmin;

  show tables;

  select get_ddl('table','work_table');

  use role securityadmin;
  show users like '%mani%';

  alter user MANIMARARCHANDRASEKAR set type = PERSON;
  

  
 