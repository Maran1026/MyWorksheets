
SELECT *
FROM ATLAS_US_HEALTHCARE.SAMPLES.CLAIMS c
JOIN ATLAS_US_HEALTHCARE.SAMPLES.PATIENTS p 
    ON c.PATIENT_ID = p.PATIENT_ID
JOIN ATLAS_US_HEALTHCARE.SAMPLES.PROVIDERS pr 
    ON c.PROVIDER_ID = pr.PROVIDER_ID
JOIN ATLAS_US_HEALTHCARE.SAMPLES.PROCEDURES pc 
    ON c.PROCEDURE_CODE = pc.PROCEDURE_CODE;

    show tables;

SELECT *
FROM ATLAS_US_HEALTHCARE.SAMPLES.AFFILIATIONS_HCP_HCO_BY_DEFINITIVE_ID_ACTIVE a1
JOIN ATLAS_US_HEALTHCARE.SAMPLES.AFFILIATIONS_HCP_HCO_BY_NPI_ACTIVE a2 
    ON a1.DEFINITIVE_ID = a2.NPI
JOIN ATLAS_US_HEALTHCARE.SAMPLES.NRX_TRX_MONTHLY m 
    ON a2.NPI = m.NPI
JOIN ATLAS_US_HEALTHCARE.SAMPLES.NRX_TRX_YEARLY y 
    ON m.NPI = y.NPI
JOIN ATLAS_US_HEALTHCARE.SAMPLES.REF_HCO_BY_DEFINITIVE_ID h1 
    ON a1.DEFINITIVE_ID = h1.DEFINITIVE_ID
JOIN ATLAS_US_HEALTHCARE.SAMPLES.REF_HCO_BY_NPI h2 
    ON h2.NPI = a2.NPI
JOIN ATLAS_US_HEALTHCARE.SAMPLES.REF_HCO_FINANCIAL_AND_CLINICAL_METRICS f 
    ON h1.DEFINITIVE_ID = f.DEFINITIVE_ID
JOIN ATLAS_US_HEALTHCARE.SAMPLES.REF_HCO_LOCATIONS_BY_DEFINITIVE_ID l 
    ON l.DEFINITIVE_ID = h1.DEFINITIVE_ID
JOIN ATLAS_US_HEALTHCARE.SAMPLES.REF_HCO_TECHNOLOGY t 
    ON t.DEFINITIVE_ID = h1.DEFINITIVE_ID
JOIN ATLAS_US_HEALTHCARE.SAMPLES.REF_HCP_BY_NPI p 
    ON p.NPI = a2.NPI
JOIN ATLAS_US_HEALTHCARE.SAMPLES.RX_DECISIONS_YEARLY d 
    ON d.NPI = p.NPI
JOIN ATLAS_US_HEALTHCARE.SAMPLES.RX_PRODUCT_DECISIONS_YEARLY pd 
    ON pd.NPI = p.NPI
JOIN ATLAS_US_HEALTHCARE.SAMPLES.RX_SUBSTANCE_DECISIONS_YEARLY sd 
    ON sd.NPI = p.NPI;

create schema demo_cortex.US_HEALTHCARE with managed access;

create table demo_cortex.us_healthcare.AFFILIATIONS_HCP_HCO_BY_DEFINITIVE_ID_ACTIVE as select * from atlas_us_healthcare.samples.AFFILIATIONS_HCP_HCO_BY_DEFINITIVE_ID_ACTIVE;
create table demo_cortex.us_healthcare.AFFILIATIONS_HCP_HCO_BY_DEFINITIVE_ID_ACTIVE as select * from atlas_us_healthcare.samples.AFFILIATIONS_HCP_HCO_BY_DEFINITIVE_ID_ACTIVE;
create table demo_cortex.us_healthcare.AFFILIATIONS_HCP_HCO_BY_NPI_ACTIVE as select * from atlas_us_healthcare.samples.AFFILIATIONS_HCP_HCO_BY_NPI_ACTIVE;
create table demo_cortex.us_healthcare.NRX_TRX_MONTHLY as select * from atlas_us_healthcare.samples.NRX_TRX_MONTHLY;
create table demo_cortex.us_healthcare.NRX_TRX_YEARLY as select * from atlas_us_healthcare.samples.NRX_TRX_YEARLY;
create table demo_cortex.us_healthcare.REF_HCO_BY_DEFINITIVE_ID as select * from atlas_us_healthcare.samples.REF_HCO_BY_DEFINITIVE_ID;
create table demo_cortex.us_healthcare.REF_HCO_BY_NPI as select * from atlas_us_healthcare.samples.REF_HCO_BY_NPI;
create table demo_cortex.us_healthcare.REF_HCO_FINANCIAL_AND_CLINICAL_METRICS as select * from atlas_us_healthcare.samples.REF_HCO_FINANCIAL_AND_CLINICAL_METRICS;
create table demo_cortex.us_healthcare.REF_HCO_LOCATIONS_BY_DEFINITIVE_ID as select * from atlas_us_healthcare.samples.REF_HCO_LOCATIONS_BY_DEFINITIVE_ID;
create table demo_cortex.us_healthcare.REF_HCO_TECHNOLOGY as select * from atlas_us_healthcare.samples.REF_HCO_TECHNOLOGY;
create table demo_cortex.us_healthcare.REF_HCP_BY_NPI as select * from atlas_us_healthcare.samples.REF_HCP_BY_NPI;
create table demo_cortex.us_healthcare.RX_DECISIONS_YEARLY as select * from atlas_us_healthcare.samples.RX_DECISIONS_YEARLY;
create table demo_cortex.us_healthcare.RX_PRODUCT_DECISIONS_YEARLY as select * from atlas_us_healthcare.samples.RX_PRODUCT_DECISIONS_YEARLY;
create table demo_cortex.us_healthcare.RX_SUBSTANCE_DECISIONS_YEARLY as select * from atlas_us_healthcare.samples.RX_SUBSTANCE_DECISIONS_YEARLY;


CALL AI_GENERATE_TABLE_DESC(
  'RX_SUBSTANCE_DECISIONS_YEARLY',
  {
    'describe_columns': true,
    'use_table_data': true
  });

  


  CREATE OR REPLACE PROCEDURE DESCRIBE_TABLES_SET_COMMENT (database_name STRING, schema_name STRING,
  set_table_comment BOOLEAN,
  set_column_comment BOOLEAN)
  RETURNS STRING
  LANGUAGE PYTHON
  RUNTIME_VERSION = '3.10'
  PACKAGES=('snowflake-snowpark-python','joblib')
  HANDLER = 'main'
AS
$$
import json
from joblib import Parallel, delayed
import multiprocessing

def generate_descr(session, database_name, schema_name, table, set_table_comment, set_column_comment):
  table_name =  table['TABLE_NAME']
  async_job = session.sql(f"CALL AI_GENERATE_TABLE_DESC( '{database_name}.{schema_name}.{table_name}',{{'describe_columns': true, 'use_table_data': true}})").collect_nowait()
  result = async_job.result()
  output = json.loads(result[0][0])
  columns_ret = output["COLUMNS"]
  table_ret = output["TABLE"][0]

  table_description = table_ret["description"]
  table_name = table_ret["name"]
  database_name = table_ret["database_name"]
  schema_name = table_ret["schema_name"]

  if (set_table_comment):
      table_description = table_description.replace("'", "\\'")
      session.sql(f"""ALTER TABLE {database_name}.{schema_name}.{table_name} SET COMMENT = '{table_description}'""").collect()

  for column in columns_ret:
      column_description = column["description"];
      column_name = column["name"];
      if not column_name.isupper():
        column_name = '"' + column_name + '"'

      if (set_column_comment):
          column_description = column_description.replace("'", "\\'")
          session.sql(f"""ALTER TABLE  {database_name}.{schema_name}.{table_name} MODIFY COLUMN {column_name}  COMMENT '{column_description}'""").collect()

  return 'Success';

def main(session, database_name, schema_name, set_table_comment, set_column_comment):

    schema_name = schema_name.upper()
    database_name = database_name.upper()
    tablenames = session.sql(f"""SELECT table_name
                      FROM {database_name}.information_schema.tables
                      WHERE table_schema = '{schema_name}'
                      AND table_type = 'BASE TABLE'""").collect()
    try:
        Parallel(n_jobs=multiprocessing.cpu_count(), backend="threading")(
                delayed(generate_descr)(
                    session,
                    database_name,
                    schema_name,
                    table,
                    set_table_comment,
                    set_column_comment,
                ) for table in tablenames
            )
        return 'Success'
    except Exception as e:
        # Catch and return the error message
        return f"An error occurred: {str(e)}"
$$;


CALL describe_tables_set_comment('demo_cortex', 'us_healthcare', true, true);


show tables;

desc table RX_SUBSTANCE_DECISIONS_YEARLY;
select get_ddl('table','AFFILIATIONS_HCP_HCO_BY_DEFINITIVE_ID_ACTIVE');
AFFILIATIONS_HCP_HCO_BY_NPI_ACTIVE
NRX_TRX_MONTHLY
NRX_TRX_YEARLY
REF_HCO_BY_DEFINITIVE_ID
REF_HCO_BY_NPI
REF_HCO_FINANCIAL_AND_CLINICAL_METRICS
REF_HCO_LOCATIONS_BY_DEFINITIVE_ID
REF_HCO_TECHNOLOGY
REF_HCP_BY_NPI
RX_DECISIONS_YEARLY
RX_PRODUCT_DECISIONS_YEARLY
RX_SUBSTANCE_DECISIONS_YEARLY