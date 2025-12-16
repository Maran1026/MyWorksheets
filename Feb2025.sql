SELECT SNOWFLAKE.CORTEX.COMPLETE('claude-3-5-sonnet', 'What are the Data Governance features available in Snowflake');

show parameters in account ;

select  snowflake.alert.last_successful_scheduled_time();


select * from snowflake.account_usage.query_history limit 10;


select current_user;

show users like '%MANIMARARCHANDRASEKAR%';

alter user MANIMARARCHANDRASEKAR set TYPE = 'LEGACY_SERVICE';


desc catalog integration demo_open_catalog_int;

CREATE OR REPLACE CATALOG INTEGRATION demo_open_catalog_int 
  CATALOG_SOURCE = POLARIS 
  TABLE_FORMAT = ICEBERG 
  CATALOG_NAMESPACE = 'spark_demo'
  REST_CONFIG = (
    CATALOG_URI = 'https://nwb67072.snowflakecomputing.com/polaris/api/catalog' 
    CATALOG_NAME = 'snwcatalog1'
  )
    REST_AUTHENTICATION = (
    TYPE = OAUTH 
    OAUTH_CLIENT_ID = 'dJ813AaH05x65vZdmYUf1DGynZ4=' 
    OAUTH_CLIENT_SECRET = 'kMGcCn84DnfHDeA0e9zsEHMohMBggtQDnfnP5VnwyGE=' 
    OAUTH_ALLOWED_SCOPES = ('PRINCIPAL_ROLE:ALL') 
  ) 
  ENABLED = TRUE;

use role accountadmin;

  CREATE OR REPLACE EXTERNAL VOLUME exvol
  STORAGE_LOCATIONS =
      (
        (
            NAME = 'my-s3-us-west-2'
            STORAGE_PROVIDER = 'S3'
            STORAGE_BASE_URL = 's3://snwbucket1/'
            STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::866135604456:role/snw_catalog_role'
            
        )
      )
  ALLOW_WRITES = FALSE;


  CREATE OR REPLACE EXTERNAL VOLUME exvol
   STORAGE_LOCATIONS =
      (
         (
            NAME = 'my-s3-us-west-2'
            STORAGE_PROVIDER = 'S3'
            STORAGE_BASE_URL = 's3://snwbucket1/'
            STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::866135604456:role/snw_catalog_role'
            STORAGE_AWS_EXTERNAL_ID = 'snw_open_catalog_external_id'
         )
      )ALLOW_WRITES = FALSE;


  use role sysadmin;
  
  CREATE OR REPLACE ICEBERG TABLE test_table
  CATALOG = 'demo_open_catalog_int'
  EXTERNAL_VOLUME = 'exvol'
  CATALOG_TABLE_NAME = 'test_table'
  AUTO_REFRESH = true;


  use database coe_practise_db;
  use schema manimaranc;
SELECT * FROM test_table;

ALTER ICEBERG TABLE test_table SET AUTO_REFRESH = true;


use role accountadmin;
CREATE OR REPLACE EXTERNAL VOLUME snw_iceberg_external_volume
   STORAGE_LOCATIONS =
      (
         (
            NAME = 'my-s3-us-west-2'
            STORAGE_PROVIDER = 'S3'
            STORAGE_BASE_URL = 's3://icebergbucket2/'
            STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::866135604456:role/snowflake_iceberg_role'
            STORAGE_AWS_EXTERNAL_ID = 'snowflake_iceberg_table_external_id'
         )
      );


      DESC EXTERNAL VOLUME snw_iceberg_external_volume;

      use role sysadmin;

      CREATE OR REPLACE ICEBERG TABLE customer_iceberg (
    c_custkey INTEGER,
    c_name STRING,
    c_address STRING,
    c_nationkey INTEGER,
    c_phone STRING,
    c_acctbal INTEGER,
    c_mktsegment STRING,
    c_comment STRING
)
    CATALOG = 'SNOWFLAKE'
    EXTERNAL_VOLUME = 'snw_iceberg_external_volume'
    BASE_LOCATION = 'customer_iceberg';

    ALTER DATABASE coe_practise_db SET CATALOG = 'SNOWFLAKE';
ALTER DATABASE coe_practise_db SET EXTERNAL_VOLUME = 'snw_iceberg_external_volume';

SHOW PARAMETERS IN DATABASE ;


CREATE OR REPLACE ICEBERG TABLE lineitem_iceberg (
  L_ORDERKEY string,
  L_LINESTATUS STRING
)
  BASE_LOCATION = 'lineitem_iceberg'
  AS SELECT
    L_ORDERKEY,
    L_LINESTATUS
  FROM LINEITEM
  limit 100;

  show tables;

  desc table LINEITEM;
select * from lineitem_iceberg;

---------------- Polaris Catalog


use role accountadmin;
CREATE OR REPLACE CATALOG INTEGRATION snw_demo_open_catalog_int 
  CATALOG_SOURCE = POLARIS 
  TABLE_FORMAT = ICEBERG 
  CATALOG_NAMESPACE = 'spark_demo'
  REST_CONFIG = (
    CATALOG_URI = 'https://nwb67072.snowflakecomputing.com/polaris/api/catalog' 
    CATALOG_NAME = 'demo_catalog'
  )
    REST_AUTHENTICATION = (
    TYPE = OAUTH 
    OAUTH_CLIENT_ID = 'zUZkYN8aY2siNPAsKqMLxLdJX34=' 
    OAUTH_CLIENT_SECRET = '2acWpA+W2lmRDcKUl+hZCNmE89dSj9dqZxmobSd1zUE=' 
    OAUTH_ALLOWED_SCOPES = ('PRINCIPAL_ROLE:ALL') 
  ) 
  ENABLED = TRUE;


  use role accountadmin;
CREATE OR REPLACE EXTERNAL VOLUME snw_iceberg_external_volume1
   STORAGE_LOCATIONS =
      (
         (
            NAME = 'my-s3-us-west-2'
            STORAGE_PROVIDER = 'S3'
            STORAGE_BASE_URL = 's3://icebergbucket3/'
            STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::866135604456:role/snw_iceberg_role'
            STORAGE_AWS_EXTERNAL_ID = 'snw_iceberg_catalog_external_id'
         )
      )
     ;


    desc EXTERNAL VOLUME snw_iceberg_external_volume1;

    SELECT SYSTEM$VERIFY_EXTERNAL_VOLUME('snw_iceberg_external_volume1');


      use role sysadmin;
      CREATE OR REPLACE ICEBERG TABLE test_table
  CATALOG = 'snw_demo_open_catalog_int'
  EXTERNAL_VOLUME = 'snw_iceberg_external_volume1'
  CATALOG_TABLE_NAME = 'test_table'
  AUTO_REFRESH = FALSE;


  
   use database coe_practise_db;
  use schema manimaranc;

SELECT * FROM test_table;

alter table test_table AUTO_REFRESH = FALSE;


desc table test_table;

insert into  test_table VALUES (6);
--------Snowflake Managed---------

use role accountadmin;
CREATE OR REPLACE CATALOG INTEGRATION demo_open_catalog_ext 
  CATALOG_SOURCE=POLARIS 
  TABLE_FORMAT=ICEBERG 
  REST_CONFIG = (
    CATALOG_URI = 'https://nwb67072.snowflakecomputing.com/polaris/api/catalog' 
    CATALOG_NAME = 'demo_catalog_ext'
  )
  REST_AUTHENTICATION = (
    TYPE = OAUTH 
    OAUTH_CLIENT_ID = '8pdEY5+/5zvZHmE//sr8NBSZBq4=' 
    OAUTH_CLIENT_SECRET = 'XKTpi3fCEPsWoZ8CvdYlB5eJP/vmmfPQtA/1LXdQaGQ=' 
    OAUTH_ALLOWED_SCOPES = ('PRINCIPAL_ROLE:ALL') 
  ) 
  ENABLED=TRUE;


use role sysadmin;
create database open_catalog_demo;
create schema test with managed access;

ALTER DATABASE open_catalog_demo SET CATALOG_SYNC = 'demo_open_catalog_ext';

use role accountadmin;
CREATE OR REPLACE EXTERNAL VOLUME snowflake_demo_ext
  STORAGE_LOCATIONS =
      (
        (
            NAME = 'us-west-2'
            STORAGE_PROVIDER = 'S3'
            STORAGE_BASE_URL = 's3://icebergbucket4/'
            STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::866135604456:role/snowflake_iceberg_role1'
            STORAGE_AWS_EXTERNAL_ID = 'snw_open_catalog_external_id1'
        )
      );


      desc external volume snowflake_demo_ext;
use role sysadmin;
      CREATE OR REPLACE ICEBERG TABLE test_table_managed (col1 int)
  CATALOG = 'SNOWFLAKE'
  EXTERNAL_VOLUME = 'snowflake_demo_ext'
  BASE_LOCATION = 'test_table_managed';

  CREATE OR REPLACE ICEBERG TABLE my_iceberg_table (co1 int)
  EXTERNAL_VOLUME = 'snowflake_demo_ext'
  CATALOG = 'demo_open_catalog_ext'
  CATALOG_TABLE_NAME = 'my_remote_table';


  use database open_catalog_demo;
  use schema test;
  select * from test_table_managed;

  insert into test_table_managed values (10);

  --SYSTEM$SEND_NOTIFICATIONS_TO_CATALOG
  