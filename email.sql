use role accountadmin;
 
--Email Integration
Create notification integration Email_Notification_Integration
type=email
enabled=true
allowed_recipients=('manimaran.chandrasekar@ltimindtree.com')
COMMENT = 'Users part of Snowflake Email Notifications';
 
--Procedure for Sending mail alerts
 
use role sysadmin;
 
CREATE OR REPLACE PROCEDURE coe_practise_db.manimaranc.PRC_DAILY_TIME_ELASPSED_NOTIFY(P_EMAIL string)
RETURNS VARCHAR(16777216)
LANGUAGE JAVASCRIPT
EXECUTE AS OWNER
AS '
var result;
var mail_body;
 
/*-----------------------------------------------------------------------------------------------*
*                    PROCEDURE_FOR_ALERTS                                             *
*------------------------------------------------------------------------------------------------*
*  Author:          OPS DE Team                                                                   *
*  Date:            11-Jan-2023                                                                    *
*  Final Procedure Name: PRC_DAILY_TIME_ELASPSED_NOTIFY                                       *
**************************************************************************************************
*                                  Modification History                                          *
**************************************************************************************************
*  Version#     Date               EID          Description                                      *
*  01           11-Jan-2023        H529007      Initial version                                  *
*-----------------------------------------------------------------------------------------------*/
 
try
{
 
 
 
  var temp_table_query = `create or replace temporary table manimaranc.TEMP_MAIL_NOTIFY_TIME_ELAPSED
  as
  select a.QUERY_ID,substr(Query_text,1,200) as Query_text,Query_type,User_name,WAREHOUSE_NAME,START_TIME,END_TIME,
  TO_NUMBER(total_elapsed_time/1000/60/60,10,1) as Total_elaspsed_time_Hrs
  from "SNOWFLAKE"."ACCOUNT_USAGE"."QUERY_HISTORY" a
  where (a.TOTAL_ELAPSED_TIME/1000/60/60) >= 4  and start_time >= current_date() -7;`
 
  var temp_table_stmt=snowflake.createStatement({sqlText: temp_table_query});
  temp_table_stmt.execute();
 
  var query_4_hr =`select query_id,query_text,query_type,user_name,WAREHOUSE_NAME,START_TIME,END_TIME,TOTAL_ELASPSED_TIME_HRS
  from  manimaranc.TEMP_MAIL_NOTIFY_TIME_ELAPSED where TOTAL_ELASPSED_TIME_HRS between 4 and 6;`
 
  
 
 
  var stmt_4_hr=snowflake.createStatement({sqlText: query_4_hr});
  var rs_4_hr=stmt_4_hr.execute();
 
  var query_6_hr=`select query_id,query_text,query_type,user_name,WAREHOUSE_NAME,START_TIME,END_TIME,TOTAL_ELASPSED_TIME_HRS
  from  manimaranc.TEMP_MAIL_NOTIFY_TIME_ELAPSED
  where TOTAL_ELASPSED_TIME_HRS between 6 and 8;`
 
 
  var stmt_6_hr=snowflake.createStatement({sqlText: query_6_hr});
  var rs_6_hr=stmt_6_hr.execute();
 
  var query_8_hr=`select query_id,query_text,query_type,user_name,WAREHOUSE_NAME,START_TIME,END_TIME,TOTAL_ELASPSED_TIME_HRS
  from  manimaranc.TEMP_MAIL_NOTIFY_TIME_ELAPSED
  where TOTAL_ELASPSED_TIME_HRS between 8 and 10;`
 
 
  var stmt_8_hr=snowflake.createStatement({sqlText: query_8_hr});
  var rs_8_hr=stmt_8_hr.execute();
 
  var query_10_hr=`select query_id,query_text,query_type,user_name,WAREHOUSE_NAME,START_TIME,END_TIME,TOTAL_ELASPSED_TIME_HRS
  from  manimaranc.TEMP_MAIL_NOTIFY_TIME_ELAPSED
  where TOTAL_ELASPSED_TIME_HRS > 10;`
 
 
  var stmt_10_hr=snowflake.createStatement({sqlText: query_10_hr});
  var rs_10_hr=stmt_10_hr.execute();
result = '''';
mail_body = '''';
var rs_4_hr_count=rs_4_hr.getRowCount();
if (rs_4_hr_count>0)
{
while(rs_4_hr.next())
{
     result += "Query Id : "+ rs_4_hr.getColumnValue(1) + \\n;
     result += "Query Text : "+ rs_4_hr.getColumnValue(2) + \\n;
     result += "Query Type : "+ rs_4_hr.getColumnValue(3) + \\n;
     result += "User : "+ rs_4_hr.getColumnValue(4) + \\n;
     result += "WAREHOUSE NAME : "+ rs_4_hr.getColumnValue(5) + \\n;
     result += "START TIME : "+ rs_4_hr.getColumnValue(6) + \\n;
     result += "END TIME : "+ rs_4_hr.getColumnValue(7) + \\n;
     result += "Elapsed Hrs : "+ rs_4_hr.getColumnValue(8) + \\n;
     result += "----------------------------------------------------------"+ \\n;
    
 
     mail_body = result.replaceAll("''","");
  
}
//return mail_body;
  var mail_stmt_4= `call system$send_email(
  ''HON_EMAIL_NOTIFICATION_INTEGRATION'',
   ''`+ P_EMAIL + `'',
  ''Snowflake Alert: Queries elapsed for 4 hours'',
  ''Results: \\n `+ mail_body + `''
  );`
 
 
  var mail_query_4=snowflake.createStatement({sqlText: mail_stmt_4});
  mail_query_4.execute();
}
 
  result = '''';
  mail_body = '''';
  var rs_6_hr_count=rs_6_hr.getRowCount();
if (rs_6_hr_count>0)
{
while(rs_6_hr.next())
{
     result += "Query Id : "+ rs_6_hr.getColumnValue(1) + \\n;
     result += "Query Text : "+ rs_6_hr.getColumnValue(2) + \\n;
     result += "Query Type : "+ rs_6_hr.getColumnValue(3) + \\n;
     result += "User : "+ rs_6_hr.getColumnValue(4) + \\n;
     result += "WAREHOUSE NAME : "+ rs_6_hr.getColumnValue(5) + \\n;
     result += "START TIME : "+ rs_6_hr.getColumnValue(6) + \\n;
     result += "END TIME : "+ rs_6_hr.getColumnValue(7) + \\n;
     result += "Elapsed Hrs : "+ rs_6_hr.getColumnValue(8) + \\n;
     result += "----------------------------------------------------------"+ \\n;
    
 
     var mail_body = result.replaceAll("''","");
 
 
 
  
  
  }
  //return mail_body;
    var mail_stmt_6= `call system$send_email(
    ''HON_EMAIL_NOTIFICATION_INTEGRATION'',
      ''`+ P_EMAIL + `'',
    ''Snowflake Alert: Queries elapsed for 6 hours'',
    ''Results: \\n `+ mail_body + `''
);`
 
 
  var mail_query_6=snowflake.createStatement({sqlText: mail_stmt_6});
  mail_query_6.execute();
}
  result = '''';
  mail_body = '''';
  var rs_8_hr_count=rs_8_hr.getRowCount();
if (rs_8_hr_count>0)
{
while(rs_8_hr.next())
{
     result += "Query Id : "+ rs_8_hr.getColumnValue(1) + \\n;
     result += "Query Text : "+ rs_8_hr.getColumnValue(2) + \\n;
     result += "Query Type : "+ rs_8_hr.getColumnValue(3) + \\n;
     result += "User : "+ rs_8_hr.getColumnValue(4) + \\n;
     result += "WAREHOUSE NAME : "+ rs_8_hr.getColumnValue(5) + \\n;
     result += "START TIME : "+ rs_8_hr.getColumnValue(6) + \\n;
     result += "END TIME : "+ rs_8_hr.getColumnValue(7) + \\n;
     result += "Elapsed Hrs : "+ rs_8_hr.getColumnValue(8) + \\n;
     result += "----------------------------------------------------------"+ \\n;
    
 
     var mail_body = result.replaceAll("''","");
 
 
 
}
//return mail_body;
     var mail_stmt_8= `call system$send_email(
    ''HON_EMAIL_NOTIFICATION_INTEGRATION'',
     ''`+ P_EMAIL + `'',
    ''Snowflake Alert: Queries elapsed for 8 hours'',
    ''Results: \\n `+ mail_body + `''
);`
 
 
  var mail_query_8=snowflake.createStatement({sqlText: mail_stmt_8});
  mail_query_8.execute();
}
result = '''';
mail_body = '''';
var rs_10_hr_count=rs_10_hr.getRowCount();
if (rs_10_hr_count>0)
{
while(rs_10_hr.next())
{
     result += "Query Id : "+ rs_10_hr.getColumnValue(1) + \\n;
     result += "Query Text : "+ rs_10_hr.getColumnValue(2) + \\n;
     result += "Query Type : "+ rs_10_hr.getColumnValue(3) + \\n;
     result += "User : "+ rs_10_hr.getColumnValue(4) + \\n;
     result += "WAREHOUSE NAME : "+ rs_10_hr.getColumnValue(5) + \\n;
     result += "START TIME : "+ rs_10_hr.getColumnValue(6) + \\n;
     result += "END TIME : "+ rs_10_hr.getColumnValue(7) + \\n;
     result += "Elapsed Hrs : "+ rs_10_hr.getColumnValue(8) + \\n;
     result += "----------------------------------------------------------"+ \\n;
    
 
     var mail_body = result.replaceAll("''","");
 
 
}
//return mail_body;
var mail_stmt_10= `call system$send_email(
    ''HON_EMAIL_NOTIFICATION_INTEGRATION'',
    ''`+ P_EMAIL + `'',
    ''Snowflake Alert: Queries elapsed more than 10 hours'',
    ''Results: \\n `+ mail_body + `''
);`
 
 
  var mail_query_10=snowflake.createStatement({sqlText: mail_stmt_10});
  mail_query_10.execute();
  return ''Done'';
}
 
}
 
 
 
catch(err)
{
result= "Failed code: "+err.code+\\n state: +err.state;
result += \\n Message:  +err.message;
result +=\\n Stack Trase : \\n  + err.stackTraceTxt;
}
 
return result;
 
 
';
 
---Task scheduled every day 8 am EST
 
create or replace task TASK_DAILY_TIME_ELAPSED_NOTIFY
warehouse=COE_PRACTISE_WH
schedule='USING CRON 0 8 * * * America/New_York'
COMMENT = 'Mail notification for long running queries.Scheduled at 8.00 am EST'
as call manimaranc.PRC_DAILY_TIME_ELASPSED_NOTIFY('manimaran.chandrasekar@ltimindtree.com');



show procedures;


select get_ddl('procedure','SP_DUP_REMOVAL(VARCHAR, VARCHAR)');