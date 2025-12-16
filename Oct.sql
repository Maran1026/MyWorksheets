use database coe_practise_db;

use schema manimaranc;

show integrations;


desc integration HON_EMAIL_NOTIFICATION_INTEGRATION;

select CAPACITY_BALANCE from snowflake.organization_usage.remaining_balance_daily
where date = current_date()
;

with
  daily as (select TO_DATE(usage_date) usage_date,round(sum(usage_in_currency),2) actual_consumption from snowflake.organization_usage.usage_in_currency_daily
where usage_date >= date(current_date) -9
group by all)
select usage_date, actual_consumption, 7542.55 as ideal_consumption, round(7542.55 - actual_consumption,2) as difference 
  from daily
;

select usage_date,sum(usage_in_currency) from snowflake.organization_usage.usage_in_currency_daily
where usage_date >= date(current_date) -9
group by all
order by 1 desc;


select account_name,usage_date,sum(usage_in_currency) from snowflake.organization_usage.usage_in_currency_daily
where usage_date >= date(current_date) -9
and account_name = 'LTIDATACOE'
group by all
order by 2  desc;

select CAPACITY_BALANCE from snowflake.organization_usage.remaining_balance_daily
where date = current_date()
;;

show procedures;

select get_ddl('procedure','PUBLIC.PROC_EMAIL_DEMO()');


use role sysadmin;
 
CREATE OR REPLACE PROCEDURE coe_practise_db.manimaranc.PRC_MONITOR_CONSUMPTION_DAILY(P_EMAIL string)
RETURNS VARCHAR(16777216)
LANGUAGE JAVASCRIPT
EXECUTE AS OWNER
AS '
var result;
var mail_body;
 
/*-----------------------------------------------------------------------------------------------*
*                    PROCEDURE_FOR_ALERTS                                             *
*------------------------------------------------------------------------------------------------*
*  Author:          Manimaran                                                                   *
*  Date:            11-Jan-2023                                                                    *
*  Final Procedure Name: PRC_DAILY_TIME_ELASPSED_NOTIFY                                       *
**************************************************************************************************
*                                  Modification History                                          *
**************************************************************************************************
*  Version#     Date               EID          Description                                      *
*  01           11-Jan-2023        H529007      Initial version                                  *
*-----------------------------------------------------------------------------------------------*/
 

 
  var sql_query=`with
  daily as (select TO_DATE(usage_date) usage_date,round(sum(usage_in_currency),2) actual_consumption from snowflake.organization_usage.usage_in_currency_daily
where usage_date >= date(current_date) -9
group by all)
select usage_date, actual_consumption, 7542.55 as ideal_consumption, round(7542.55 - actual_consumption,2) as difference 
  from daily
order by 1 desc;`
 
 
  var sql_smt=snowflake.createStatement({sqlText: sql_query});
   var result_daily=sql_smt.execute();
   var table_html;
  table_html = `<html>
<head>
<style>
table, th, td {
  border: 1px solid black;
  border-collapse: collapse;
}
</style>
<title>Montior Daily Consumption</title>
</head>
<body>

<h1>Consumption Across Organization</h1>
<p>Remaining Balance :_remaining_balance</p>
<table style="width:100%">
  <tr>
    <th>Date</th>
    <th>Actual Consumption$</th>
    <th>Ideal Consumption$</th>
    <th>Difference$</th>
  </tr>`;

   if (result_daily.getRowCount()>0)
{
while(result_daily.next())
{
 table_html += "<tr><td>"+ result_daily.getColumnValue(1) +"</td>";
 table_html += "<td>"+ result_daily.getColumnValue(2) +"</td>";
 table_html += "<td>"+ result_daily.getColumnValue(3) +"</td>";
 table_html += "<td>"+ result_daily.getColumnValue(4) +"</td></tr>";
 
}
}
else 
{
return "No record";
}

table_html += "</table></body></html>";

  

var sql_query_bln=`select CAPACITY_BALANCE from snowflake.organization_usage.remaining_balance_daily
where date = current_date()
;`
 
 
  var sql_smt_bln=snowflake.createStatement({sqlText: sql_query_bln});
   var result_bln=sql_smt_bln.execute();
   result_bln.next();

  
  
  var remaining_balance = String(result_bln.getColumnValue(1));

  var mail_body = table_html.replace("_remaining_balance", remaining_balance);

  

 return mail_body;
  var mail_stmt_4= `call system$send_email(
  ''Email_Notification_Integration'',
   ''`+ P_EMAIL + `'',
  ''Snowflake Alert: Queries elapsed for 4 hours'',
  ''Results: \\n `+ mail_body + `'',
  ''text/html''
  );`


 
  var mail_query_10=snowflake.createStatement({sqlText: mail_stmt_4});
  mail_query_10.execute();
  return ''Done''
 

 

 
 
';

call manimaranc.PRC_MONITOR_CONSUMPTION_DAILY('manimaran.chandrasekar@ltimindtree.com');









--31 Oct



select hash(null);

SELECT sha2_binary(' ');


select current_date() -1;


select current_user;

show users like 'MANI%';


