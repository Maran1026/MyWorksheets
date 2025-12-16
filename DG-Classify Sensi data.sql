CREATE TABLE customers (
  account_number NUMBER(38,0),
  first_name VARCHAR(16777216),
  last_name VARCHAR(16777216),
  email VARCHAR(16777216)
);





INSERT INTO customers (account_number, first_name, last_name, email)
  VALUES
    (1589420, 'john', 'doe', 'john.doe@example.com'),
    (2834123, 'jane', 'doe', 'jane.doe@example.com'),
    (4829381, 'jim', 'doe', 'jim.doe@example.com'),
    (9821802, 'susan', 'smith', 'susan.smith@example.com'),
    (8028387, 'bart', 'simpson', 'bart.barber@example.com');

    CREATE OR REPLACE SNOWFLAKE.DATA_PRIVACY.CLASSIFICATION_PROFILE
  my_classification_profile(
      {
        'minimum_object_age_for_classification_days': 0,
        'maximum_classification_validity_days': 30,
        'auto_tag': true
      });


      CREATE TAG tutorial_pii;

      SHOW SNOWFLAKE.DATA_PRIVACY.CLASSIFICATION_PROFILE;

   desc instance my_classification_profile;
   SELECT my_classification_profile!DESCRIBE();

CALL my_classification_profile!SET_TAG_MAP(
  {'column_tag_map':[
    {
      'tag_name':'COE_PRACTISE_DB.MANIMARANC.tutorial_pii',
      'tag_value':'sensitive_name',
      'semantic_categories':['NAME']
    }]});


    ALTER SCHEMA coe_practise_db.manimaranc
  SET CLASSIFICATION_PROFILE = 'COE_PRACTISE_DB.MANIMARANC.my_classification_profile';

  CALL SYSTEM$GET_CLASSIFICATION_RESULT('COE_PRACTISE_DB.MANIMARANC.customers');

  select * from COE_PRACTISE_DB.MANIMARANC.customers;

  select current_schema();
  COE_PRACTISE_DB.MANIMARANC

  