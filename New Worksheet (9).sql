show databases;

use database COE_PRACTISE_DB;

show grants on database COE_PRACTISE_DB;

show schemas;

create schema UTIL with managed access;




create or replace table tbl_validate (
col_number NUMBER, col_float float,col_varchar VARCHAR,col_binary BINARY,col_BOOLEAN BOOLEAN,co_date DATE,col_time TIME, col_TIMESTAMP_NTZ TIMESTAMP_NTZ,
    col_TIMESTAMP_LTZ TIMESTAMP_LTZ,col_TIMESTAMP_TZ TIMESTAMP_TZ, col_VARIANT VARIANT);
    
    desc table tbl_validate;
    
 insert into tbl_validate
 select 10,10.676767,'test',to_binary('ab'),true,'01-Jan-2021','10:00:00',current_timestamp(),current_timestamp(),current_timestamp(),
 ('{"key1": "value1", "key2": "value2"}'::variant);
 
 
 
 select * From tbl_validate;
 
 --call sp_insert_validate();
 
create or replace procedure sp_insert_validate_sql()
returns varchar
language sql
as
$$

begin
        insert into tbl_validate
        select 10,10.676767,'test',to_binary('ab'),true,'01-Jan-2021','10:00:00',current_timestamp(),current_timestamp(),current_timestamp(),
        ('{"key1": "value1", "key2": "value2"}'::variant);
    return 'Completed';
end;
$$
;


call sp_insert_validate_javascript();

create or replace procedure sp_insert_validate_javascript()
returns varchar
language javascript
as
$$

var insert_query = snowflake.createStatement( {sqlText: `insert into tbl_validate select 10,10.676767,'test',to_binary('ab'),true,'01-Jan-2021','10:00:00',current_timestamp(),current_timestamp(),current_timestamp(),('{"key1": "value1", "key2": "value2"}'::variant);`} );

try {
        snowflake.execute (
        {sqlText: "begin transaction"}
        );
        insert_query.execute();
      
        
      snowflake.execute (
        {sqlText: "commit"}
        );

         return 'Completed';
}
catch (err)  {
        snowflake.execute (
        {sqlText: "rollback"}
        ); 
       return err;
  }

$$
;


create or replace procedure sp_dup_removal(p_table_name string,p_session string)
  returns string
  language javascript
  as     
  $$  
    
var sql_key_column = snowflake.createStatement( {sqlText: "select TABLE_NAME,to_array(KEY_COL),SESSIONNAME from CDWDUPLICATE_CHECK where TABLE_NAME = ? and SESSIONNAME = ?;",
                                                 binds:[P_TABLE_NAME,P_SESSION]
                                               } );
                                                
var result1 = sql_key_column.execute();
if(result1.getRowCount() == 0 ) 
 {
  return 'Failed : Data missing in CDWDUPLICATE_CHECK'
  
  };
  
result1.next();



const sch_tbl = P_TABLE_NAME.split('.');
var p_schema =  sch_tbl[0];
var p_tbl_name = sch_tbl[1]

const key_columns  = String(result1.getColumnValue(2)).split(",");

var row_num = 0;
var column_name = '';
while (row_num < key_columns.length) {
    if(row_num == 0 )
        {
              column_name = "'" + key_columns[row_num].toUpperCase() + "'";
        }
    else 
        {
            column_name += ',';
            column_name += "'" + key_columns[row_num].toUpperCase() + "'";
        }

    row_num++;
}



var sql_column_meta = snowflake.createStatement( {sqlText: `select COLUMN_NAME,DATA_TYPE from information_schema.columns where table_name = '${p_tbl_name}' and  column_name in( ${column_name} ) and table_schema = '${p_schema}' ;`} );

 var result_set2 = sql_column_meta.execute();

 if(result_set2.getRowCount() == 0 ) 
 {
  return 'Failed : Columns missing  in information schema'
  
  };

  var condition_column = '';
while (result_set2.next())
{

    if (condition_column == '')
        { 
           
           condition_column = "equal_null(og."+ result_set2.getColumnValue(1);
           condition_column += ",dup."+ result_set2.getColumnValue(1)+ ")" ;
           
          

        }
   else 
        {
        
        condition_column += " and equal_null(og."+ result_set2.getColumnValue(1);
        condition_column += ",dup."+ result_set2.getColumnValue(1)+ ")" ;
                    
                    
           
        }

     }


var  transient_query= ` create or replace transient table ${P_TABLE_NAME}_trans as select *  from  ${P_TABLE_NAME} qualify  
ROW_NUMBER() OVER (PARTITION BY ${key_columns} ORDER BY ${key_columns} DESC) > 1`;

var delete_query = ` delete from ${P_TABLE_NAME}  og  using (select ${key_columns} from  ${P_TABLE_NAME}_trans) as dup where ${condition_column};`;

var insert_query = `insert into ${P_TABLE_NAME} select * from ${P_TABLE_NAME}_trans qualify  
ROW_NUMBER() OVER (PARTITION BY ${key_columns} ORDER BY ${key_columns} DESC) = 1;`;


var sql_transient = snowflake.createStatement( {sqlText: transient_query} );
var sql_delete_dup = snowflake.createStatement( {sqlText: delete_query} );
var sql_insert = snowflake.createStatement( {sqlText: insert_query} );




  try {
        snowflake.execute (
        {sqlText: "begin transaction"}
        );
        sql_transient.execute();
        sql_delete_dup.execute();
        sql_insert.execute();
        
      snowflake.execute (
        {sqlText: "commit"}
        );

         return 'Completed';
}
catch (err)  {
        snowflake.execute (
        {sqlText: "rollback"}
        ); 
       return err;
  }


  $$;
  
  
  show roles;
  
  show parameters;
  
  show databases;
  
  
  
  
  
  with
params as (
select
    current_warehouse() as warehouse_name,
    '2021-11-01' as time_from,
    '2021-11-02' as time_to
),

jobs as (
select
    query_id,
    time_slice(start_time::timestamp_ntz, 15, 'minute','start') as interval_start,
    qh.warehouse_name,
    database_name,
    query_type,
    total_elapsed_time,
    compilation_time as compilation_and_scheduling_time,
    (queued_provisioning_time + queued_repair_time + queued_overload_time) as queued_time,
    transaction_blocked_time,
    execution_time
from snowflake.account_usage.query_history qh, params
where
    qh.warehouse_name = params.warehouse_name
and start_time >= params.time_from
and start_time <= params.time_to
and execution_status = 'SUCCESS'
and query_type in ('SELECT','UPDATE','INSERT','MERGE','DELETE')
),

interval_stats as (
select
    query_type,
    interval_start,
    count(distinct query_id) as numjobs,
    median(total_elapsed_time)/1000 as p50_total_duration,
    (percentile_cont(0.95) within group (order by total_elapsed_time))/1000 as p95_total_duration,
    sum(total_elapsed_time)/1000 as sum_total_duration,
    sum(compilation_and_scheduling_time)/1000 as sum_compilation_and_scheduling_time,
    sum(queued_time)/1000 as sum_queued_time,
    sum(transaction_blocked_time)/1000 as sum_transaction_blocked_time,
    sum(execution_time)/1000 as sum_execution_time,
    round(sum_compilation_and_scheduling_time/sum_total_duration,2) as compilation_and_scheduling_ratio,
    round(sum_queued_time/sum_total_duration,2) as queued_ratio,
    round(sum_transaction_blocked_time/sum_total_duration,2) as blocked_ratio,
    round(sum_execution_time/sum_total_duration,2) as execution_ratio,
    round(sum_total_duration/numjobs,2) as total_duration_perjob,
    round(sum_compilation_and_scheduling_time/numjobs,2) as compilation_and_scheduling_perjob,
    round(sum_queued_time/numjobs,2) as queued_perjob,
    round(sum_transaction_blocked_time/numjobs,2) as blocked_perjob,
    round(sum_execution_time/numjobs,2) as execution_perjob
from jobs
group by 1,2
order by 1,2
)
select * from interval_stats;
  

show tables ;
desc table TBL_VALIDATE;
--src:dealership
--:total_partition_coun
--select partition_value :total_partition_count from (
select partition_value['total_partition_count'] from (
select to_variant(text) partition_value from (
select  "SYSTEM$CLUSTERING_INFORMATION('TBL_VALIDATE', '(COL_NUMBER)')" as TEXT
from (select  system$clustering_information('TBL_VALIDATE', '(COL_NUMBER)')))
);


select partition_value :total_partition_count from (
select text partition_value from (
select  "SYSTEM$CLUSTERING_INFORMATION('TBL_VALIDATE', '(COL_NUMBER)')" as TEXT
from (select  system$clustering_information('TBL_VALIDATE', '(COL_NUMBER)')))
);


select * from (select SYSTEM$CLUSTERING_INFORMATION ('TBL_VALIDATE','TBL_VALIDATE'));

SELECT parse_json(SYSTEM$CLUSTERING_INFORMATION('TBL_VALIDATE', '(COL_NUMBER)')):total_partition_count;


CREATE TABLE num_partitions (
  table_catalog STRING,
  table_schema STRING,
  table_name STRING,
  num_partitions INTEGER,
  num_rows INTEGER,
  num_bytes INTEGER
);
 
CREATE OR REPLACE PROCEDURE get_num_partitions(param_num_partitions_table STRING)
  RETURNS STRING
  LANGUAGE JAVASCRIPT
  AS     
  $$  
    var sql_command = "SELECT c.table_catalog, c.table_schema, c.table_name, MIN(c.column_name) AS column_name, MAX(t.row_count) AS num_rows, MAX(t.bytes) AS num_bytes FROM information_schema.columns c JOIN information_schema.tables t ON (c.table_catalog = t.table_catalog AND c.table_schema = t.table_schema AND c.table_name = t.table_name) WHERE t.table_type = \'BASE TABLE\' AND c.data_type NOT IN (\'VARIANT\', \'ARRAY\') GROUP BY c.table_catalog, c.table_schema, c.table_name ORDER BY table_catalog, table_schema, table_name";    
    var statement = snowflake.createStatement( {sqlText: sql_command} );
    var result_set = statement.execute();
    
    while (result_set.next())  {
       var col1 = result_set.getColumnValue(1);
       var col2 = result_set.getColumnValue(2);
       var col3 = result_set.getColumnValue(3);
       var col4 = result_set.getColumnValue(4);
       var col5 = result_set.getColumnValue(5);
       var col6 = result_set.getColumnValue(6);
       
       var table_parameter = col1 + "." + col2 + "." + col3;
       var num_partitions_sql = "SELECT parse_json(SYSTEM$CLUSTERING_INFORMATION('" + table_parameter + "', '(" + col4 + ")')):total_partition_count";
       var num_partitions_stmt = snowflake.createStatement( {sqlText: num_partitions_sql} );
       var num_partitions_res = num_partitions_stmt.execute();
       var result_value = "";
       
       while (num_partitions_res.next())  {
           result_value = num_partitions_res.getColumnValue(1);
       }
       
       var insert_sql = "INSERT INTO " + PARAM_NUM_PARTITIONS_TABLE + " VALUES ('" + col1 + "', '" + col2 + "', '" + col3 + "', " + result_value + ", " + col5 + ", " + col6 + ")";
       var insert_stmt = snowflake.createStatement( {sqlText: insert_sql} );
       var insert_res = insert_stmt.execute();
    }
  return ""; 
  $$
;
 
CALL get_num_partitions('num_partitions');
 
SELECT 
    * 
FROM 
    num_partitions
;


show grants on role practise_role;

use role accountadmin;

