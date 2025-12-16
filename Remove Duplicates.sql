CREATE OR REPLACE PROCEDURE "SP_DUP_REMOVAL"("P_TABLE_NAME" VARCHAR(16777216), "P_SESSION" VARCHAR(16777216))
RETURNS VARCHAR(16777216)
LANGUAGE JAVASCRIPT
EXECUTE AS OWNER
AS '  
    
var sql_key_column = snowflake.createStatement( {sqlText: "select TABLE_NAME,to_array(KEY_COL),SESSIONNAME from CDWDUPLICATE_CHECK where TABLE_NAME = ? and SESSIONNAME = ?;",
                                                 binds:[P_TABLE_NAME,P_SESSION]
                                               } );
                                                
var result1 = sql_key_column.execute();
if(result1.getRowCount() == 0 ) 
 {
  return ''Failed : Data missing in CDWDUPLICATE_CHECK''
  
  };
  
result1.next();



const sch_tbl = P_TABLE_NAME.split(''.'');
var p_schema =  sch_tbl[0];
var p_tbl_name = sch_tbl[1]

const key_columns  = String(result1.getColumnValue(2)).split(",");

var row_num = 0;
var column_name = '''';
while (row_num < key_columns.length) {
    if(row_num == 0 )
        {
              column_name = "''" + key_columns[row_num].toUpperCase() + "''";
        }
    else 
        {
            column_name += '','';
            column_name += "''" + key_columns[row_num].toUpperCase() + "''";
        }

    row_num++;
}



var sql_column_meta = snowflake.createStatement( {sqlText: `select COLUMN_NAME,DATA_TYPE from information_schema.columns where table_name = ''${p_tbl_name}'' and  column_name in( ${column_name} ) and table_schema = ''${p_schema}'' ;`} );

 var result_set2 = sql_column_meta.execute();

 if(result_set2.getRowCount() == 0 ) 
 {
  return ''Failed : Columns missing  in information schema''
  
  };

  var condition_column = '''';
while (result_set2.next())
{

    if (condition_column == '''')
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

         return ''Completed'';
}
catch (err)  {
        snowflake.execute (
        {sqlText: "rollback"}
        ); 
       return err;
  }
    ';




select distinct usage_date, round(sum(usage_in_currency),2) actual_consumption, 7542.55 as ideal_consumption, round(7542.55 - usage_in_currency,2) as difference 
  from snowflake.organization_usage.usage_in_currency_daily
where usage_date >= date(current_date) -9
group by all
order by 1 desc;



select date(start_time),hour(start_time),dayname(start_time),warehouse_name,sum(avg_running),sum(avg_queued_load) from snowflake.account_usage.warehouse_load_history
where date(start_time) >= current_date()-1
AND warehouse_name = 'POLARSLED_WH'
group by all 
order by 2 ASC;

select date(start_time),hour(start_time),dayname(start_time),warehouse_name,count(query_id)
from snowflake.account_usage.query_history
where month(start_time) = month(current_date()-1)
--AND warehouse_name = 'POLARSLED_WH'
group by all;