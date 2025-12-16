show tables;
select
    *
From
    TBL_VALIDATE;
    
    show parameters in account;
    
    show databases;
    
    show parameters in database COE_PRACTISE_DB;
    
    show warehouses;
    show parameters in warehouse  COE_PRACTISE_WH;
    
    
    show warehouses;
    
    
    show stages;
    
    

    use schema coe_practise_db.manimaranc;

    show procedures in schema manimaranc;

    select get_ddl('procedure','COE_PRACTISE_DB.MANIMARANC.PROC_GENERATE_MERGE_SCRIPT_METADATA_BACKUP()');

    show grants on procedures;


    select TABLE_NAME from snowflake.information_schema.views where table_schema = 'ACCOUNT_USAGE';

call PROC_GENERATE_MERGE_SCRIPT_METADATA_BACKUP();

    CREATE OR REPLACE PROCEDURE "PROC_GENERATE_MERGE_SCRIPT_METADATA_BACKUP"()
RETURNS VARCHAR(16777216)
LANGUAGE JAVASCRIPT
EXECUTE AS OWNER
AS ' 
  
  var v_views_stmt = snowflake.createStatement( {sqlText: "select TABLE_NAME from snowflake.information_schema.views where table_schema = ''ACCOUNT_USAGE'';"
                                                 
                                               } );
                                                
var v_view_list = v_views_stmt.execute();

var v_table_create_script ='''';
var v_merge_script='''';

while (v_view_list.next())
{

var v_table_sql = `select listagg(column_name,'','') within group (order by ordinal_position asc) from snowflake.information_schema.columns
where table_schema =  ''ACCOUNT_USAGE'' and table_name = ''`+v_view_list.getColumnValue(1)+`''
order by ordinal_position ;`


var v_table_stmt = snowflake.createStatement( {sqlText: v_table_sql} );
var v_result = v_table_stmt.execute();
v_result.next();


var v_join = '''';

var v_column_sql = `select column_name  from tbl_metadata_on
where view_name = ''`+v_view_list.getColumnValue(1)+`'';` ;

var v_column_stmt =  snowflake.createStatement( {sqlText: v_column_sql} );
var v_column_result = v_column_stmt.execute();
while (v_column_result.next())
{
  if (v_join == '''')
  {
    v_join = `HIST.`+v_column_result.getColumnValue(1)+` = DB_HIST.`+v_column_result.getColumnValue(1);
  }
  else 
  {
    v_join = v_join +` and HIST.`+v_column_result.getColumnValue(1)+` = DB_HIST.`+v_column_result.getColumnValue(1);
  }

}



if (v_merge_script == '''')
{
   
    v_merge_script = `if (:table_name = ''`+v_view_list.getColumnValue(1)+`'') THEN
    let query_to_run varchar := ''MERGE INTO '' || :table_name || '' DB_HIST USING ( Select ` + v_result.getColumnValue(1)
                      +` FROM SNOWFLAKE.ACCOUNT_USAGE.`+v_view_list.getColumnValue(1)+`) HIST ON ` + v_join + `
WHEN NOT MATCHED THEN
INSERT
(`+ v_result.getColumnValue(1)+ `) VALUES
(`+ v_result.getColumnValue(1)+ `);'';
execute immediate :query_to_run;
select "number of rows inserted" into :num_rec from table(result_scan(last_query_id()));
ret_status := ''Table, '' || :table_name || '' Backed up successfully with total of '' || :num_rec || '' records'';
return ret_status;
END IF;

`;
                      
                     
                      
}
else 
{
  v_merge_script = v_merge_script + `if (:table_name = ''`+v_view_list.getColumnValue(1)+`'') THEN
    let query_to_run varchar := ''MERGE INTO '' || :table_name || '' DB_HIST USING ( Select ` + v_result.getColumnValue(1)
                      +` FROM SNOWFLAKE.ACCOUNT_USAGE.`+v_view_list.getColumnValue(1)+`) HIST ON ` + v_join + `
WHEN NOT MATCHED THEN
INSERT
(`+ v_result.getColumnValue(1)+ `) VALUES
(`+ v_result.getColumnValue(1)+ `);'';
execute immediate :query_to_run;
select "number of rows inserted" into :num_rec from table(result_scan(last_query_id()));
ret_status := ''Table, '' || :table_name || '' Backed up successfully with total of '' || :num_rec || '' records'';
return ret_status;
END IF;

`;
}




}

return  v_merge_script;
  
  ';


    use role hon_platform_admin;

    use database coe_practise_db;
    show schemas;
    use schema MANIMARANC;
    use warehouse coe_practise_wh;
    
select * from snowflake.account_usage.query_history where user_name = 'KVISHAK' and start_time >= current_date()-1
--and execution_status = 'FAIL'
order by start_time desc;

grant all on  warehouse  COE_PRACTISE_WH to role HON_PLATFORM_ADMIN;

show warehouses;

use warehouse WH_TEST_SK;
    