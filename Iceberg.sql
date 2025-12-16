use role accountadmin;

CREATE EXTERNAL VOLUME iceberg_extvol
  STORAGE_LOCATIONS =
    (
      (
        NAME = 'azure_adlsgen2_storage'
        STORAGE_PROVIDER = 'AZURE'
        STORAGE_BASE_URL = 'azure://stagingareafromsaptosf.blob.core.windows.net/snowflakeicebergcontainer'
        AZURE_TENANT_ID = 'ff355289-721e-4dd7-a663-afec62ab9d54'
      )
    );

   desc external volume iceberg_extvol;

   show versions;

   show accounts;



   CREATE or replace EXTERNAL VOLUME azure_iceberg_extvol
  STORAGE_LOCATIONS =
    (
      (
        NAME = 'azure_adlsgen2_storage_iceberg'
        STORAGE_PROVIDER = 'AZURE'
        STORAGE_BASE_URL = 'azure://icebergsnowflakewest.blob.core.windows.net/enterprisedata'
        AZURE_TENANT_ID = 'f2fb322a-9ff8-44da-bde3-04f571fc68db'
      )
    );

    desc external volume azure_iceberg_extvol;


    {
   "NAME":"azure_adlsgen2_storage",
   "STORAGE_PROVIDER":"AZURE",
   "STORAGE_BASE_URL":"azure://sficebergfabricint.blob.core.windows.net/enterprisedata",
   "STORAGE_ALLOWED_LOCATIONS":[
      "azure://sficebergfabricint.blob.core.windows.net/enterprisedata/*"
   ],
   "AZURE_TENANT_ID":"ff355289-721e-4dd7-a663-afec62ab9d54",
   "AZURE_MULTI_TENANT_APP_NAME":"SnowflakePACInt0799_1618491843412",
   "AZURE_CONSENT_URL":"https://login.microsoftonline.com/ff355289-721e-4dd7-a663-afec62ab9d54/oauth2/authorize?client_id=5109fc87-e840-4c44-91cc-53e70c9b1a09&response_type=code",
   "ENCRYPTION_TYPE":"NONE",
   "ENCRYPTION_KMS_KEY_ID":""
}



{
   "NAME":"azure_adlsgen2_storage_iceberg",
   "STORAGE_PROVIDER":"AZURE",
   "STORAGE_BASE_URL":"azure://icebergsnowflakewest.blob.core.windows.net/enterprisedata",
   "STORAGE_ALLOWED_LOCATIONS":[
      "azure://icebergsnowflakewest.blob.core.windows.net/enterprisedata/*"
   ],
   "AZURE_TENANT_ID":"f2fb322a-9ff8-44da-bde3-04f571fc68db",
   "AZURE_MULTI_TENANT_APP_NAME":"SnowflakePACInt0799_1618491843412",
   "AZURE_CONSENT_URL":"https://login.microsoftonline.com/f2fb322a-9ff8-44da-bde3-04f571fc68db/oauth2/authorize?client_id=5109fc87-e840-4c44-91cc-53e70c9b1a09&response_type=code",
   "ENCRYPTION_TYPE":"NONE",
   "ENCRYPTION_KMS_KEY_ID":""
};



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
    EXTERNAL_VOLUME = 'azure_iceberg_extvol'
    BASE_LOCATION = 'customer_iceberg'
    ;

    SELECT SYSTEM$VERIFY_EXTERNAL_VOLUME('azure_iceberg_extvol');


    FAILED with exception message This request is not authorized to perform this operation using this permission. (Status Code: 403; Error Code: AuthorizationPermissionMismatch)",
   "readResult":"S