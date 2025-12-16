/*
********************************************************************************************
* Get started with data quality monitoring. This Worksheet will walk you through how to:
*   - Set up roles and objects with the required access for data quality monitoring.
*   - Define a data metric function (DMF) schedule and setup associations and expectations.
*   - Create a custom DMF to measure data quality.
********************************************************************************************
* Access control setup
********************************************************************************************
*/

-- Ask your account admin to grant the following privileges to set up and review data metric functions (DMF).

grant execute data metric function on account to role ACCOUNTADMIN;
grant database role snowflake.data_metric_user to role ACCOUNTADMIN;

grant usage on database <data_metric_function_database> to role ACCOUNTADMIN;
grant usage on schema <data_metric_function_database>.<data_metric_function_schema> to role ACCOUNTADMIN;
grant create data metric function on schema <data_metric_function_database>.<data_metric_function_schema> to role ACCOUNTADMIN;

/*
******************************************************************************
* Define schedule and add DMF association and expectation to object
******************************************************************************
*/

-- Define schedule on a target object (i.e. table, dynamic table, view) to run DMFs.

use COE_PRACTISE_DB.MANIMARANC;

ALTER TABLE ACCESS_HISTORY SET DATA_METRIC_SCHEDULE = <'5 minutes'>;

-- Associate DMFs for row count, freshness, null count and add an expectation.
-- Feel free to adjust and use other DMFs as listed here: https://docs.snowflake.com/en/user-guide/data-quality-system-dmfs#system-dmfs

ALTER TABLE ACCESS_HISTORY
  ADD DATA METRIC FUNCTION
  < SNOWFLAKE.CORE.ROW_COUNT ON (),                   -- Row count (Volume)
    SNOWFLAKE.CORE.FRESHNESS ON (<timestamp_column>), -- Freshness
    SNOWFLAKE.CORE.NULL_COUNT ON (<column_name>) >    -- Null count
      EXPECTATION <expectation_name> ( <condition> );

/*
******************************************************************************
* Create a DMF
******************************************************************************
*/

-- The following is an example to validate referential integrity as defined by a primary key/foreign key relationship.
-- In this case, you can create a DMF to validate that all records in a source table have corresponding records in the referenced table.
-- This user-defined DMF returns the number of records where the value of a column in a table does not have a corresponding value in the column of another table:

CREATE OR REPLACE DATA METRIC FUNCTION
  governance.dmfs.referential_check(arg_t1 TABLE(arg_c1 INT), arg_t2 TABLE(arg_c2, INT))
  RETURNS NUMBER AS
  'SELECT COUNT(*) FROM arg_t1
    WHERE arg_c1 NOT IN (SELECT arg_c2 FROM arg_t2)';

ALTER TABLE ACCESS_HISTORY
  ADD DATA METRIC FUNCTION governance.dmfs.referential_check
    ON (c1, TABLE(my_db.sch1.table b(c1)));

/*
******************************************************************************
* Congrats! You have successfully set up your first DMFs.
* Navigate to the table data quality page to review DMF results.
******************************************************************************
*/
