use snowflake.account_usage;

show views like '%EVENTS%';
desc view WAREHOUSE_EVENTS_HISTORY;

select * from WAREHOUSE_EVENTS_HISTORY
where warehouse_name = 'COE_PRACTISE_WH'
and date(timestamp) >= current_date -7 
and EVENT_NAME = 'RESUME_WAREHOUSE';

select * from WAREHOUSE_EVENTS_HISTORY
where warehouse_name = 'COE_PRACTISE_WH'
and date(timestamp) >= current_date -7 
and EVENT_NAME = 'SUSPEND_WAREHOUSE';

with WH as (select * from WAREHOUSE_EVENTS_HISTORY
where warehouse_name = 'COE_PRACTISE_WH'
and  date(timestamp) >= current_date -7
and EVENT_NAME = 'RESUME_WAREHOUSE')
select * from WH A ASOF JOIN (select * from WAREHOUSE_EVENTS_HISTORY
where warehouse_name = 'COE_PRACTISE_WH'
and  date(timestamp) >= current_date -7
and EVENT_NAME = 'SUSPEND_WAREHOUSE') B 
MATCH_CONDITION (A.timestamp <= B.timestamp) 
--where A.EVENT_NAME = 'RESUME_WAREHOUSE' 
--and B.EVENT_NAME = 'SUSPEND_WAREHOUSE'
;

show views like 'QUERY_%';


select * from QUERY_ATTRIBUTION_HISTORY 
where parent_query_id is not null
and date(start_time) >= current_date -7
limit 100;

select start_time,end_time from query_history 
where query_id = '01b6a71e-0905-4b61-002b-e283039fa49a';


select --min(start_time),max(end_time) 
from query_attribution_history
where parent_query_id = '01b6a71e-0905-4b61-002b-e283039fa49a'
order by start_time asc;

select * --min(start_time),max(end_time) 
from query_attribution_history
where query_id = '01b6a71e-0905-4b61-002b-e283039fa49a'
order by start_time asc;

select user_name,sum(credits_attributed_compute) credit,monthname(start_time) monthname,year(start_time) year,date(start_time) date
from query_attribution_history
where parent_query_id is null 
and date(start_time) >= current_date -7
group by all
;

ALTER SESSION  SET TIMEZONE = 'UTC' ;

CREATE OR REPLACE DYNAMIC TABLE coe_practise_db.manimaranc.share_dynamic_test
  TARGET_LAG = '20 minutes'
  WAREHOUSE = coe_practise_wh
 
  AS
  select * from FANTASY_FOOTBALL_2020.NFL2022.PBP
  limit 10
;
use role accountadmin;
use schema FANTASY_FOOTBALL_2020.NFL2022;
show tables like 'PBP';
alter table PBP
set change_tracking = TRUE;
show grants on table PBP;
grant ownership on table PBP to role sysadmin;

show views;
use schema coe_practise_db.manimaranc;

show views;

METERING_DAILY_HISTORY_VW;

CREATE OR REPLACE DYNAMIC TABLE coe_practise_db.manimaranc.METERING_DAILY_HISTORY_VW_dynamic
  TARGET_LAG = '20 minutes'
  WAREHOUSE = coe_practise_wh
 AS
  select * from METERING_DAILY_HISTORY_VW
  ;

  select * from METERING_DAILY_HISTORY_VW_dynamic;

  drop dynamic table METERING_DAILY_HISTORY_VW_dynamic;


  show users like 'MANI%';
  alter user MANIMARARCHANDRASEKAR set type = NuLL;

  alter user MANIMARARCHANDRASEKAR set login_name = 'manimaran.chandrasekar@ltimindtree.com';

alter user MANIMARARCHANDRASEKAR set first_name = 'Manimaran',last_name = 'Chandrasekar';

  

  
  
  
https://github.com/mannyzm/Dev.git;

CREATE OR REPLACE SECRET mani_git_secret
  TYPE = password
  USERNAME = 'mannyzm'
  PASSWORD = 'Mandec#3112';

  CREATE OR REPLACE API INTEGRATION mani_git_api_integration
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/mannyzm')
  ALLOWED_AUTHENTICATION_SECRETS = (mani_git_secret)
  ENABLED = TRUE;


  CREATE OR REPLACE GIT REPOSITORY mani_snowflake_extensions
  API_INTEGRATION = mani_git_api_integration
  GIT_CREDENTIALS = mani_git_secret 
  ORIGIN = 'https://github.com/mannyzm/Dev.git';


  ALTER GIT REPOSITORY mani_snowflake_extensions FETCH;

  SHOW GIT BRANCHES IN mani_snowflake_extensions;

  LS @mani_snowflake_extensions/branches/master;

show streams;

select * from QUERY_HISTORY_STREAM;

show tables;

select * from lineitem 
where L_ORDERKEY = 2486750405 limit 10;


create stream   lineitem_stream on table lineitem;

update lineitem
set L_COMMENT = 'Test 1'
where L_ORDERKEY= 2486750405 ;

select * from lineitem_stream;

alter table lineitem
add column new_col1 string;

update lineitem
set new_col1 = 'Test 2'
where L_ORDERKEY= 2486750405 ;


SELECT TO_GEOMETRY('LINESTRING(100 102,100 102)', TRUE);
  
use snowflake.account_usage;

show views;
  desc view query_history;
  desc view QUERY_ATTRIBUTION_HISTORY;

  select user_name,query_id,sum(CREDITS_ATTRIBUTED_COMPUTE) ,sum(CREDITS_USED_QUERY_ACCELERATION), (CREDITS_USED_QUERY_ACCELERATION+CREDITS_ATTRIBUTED_COMPUTE),date(start_time),warehouse_name from QUERY_ATTRIBUTION_HISTORY
  where date(start_time) >= current_date - 7
  and parent_query_id is null
  
  group by all;


  select * from QUERY_ATTRIBUTION_HISTORY
  where date(start_time) >= current_date - 7
  and user_name = 'SRIKANTHBIDHANIYA'
  and query_id = '01b8ea35-0906-eb0a-002b-e28305b8f6d2';


    select min(start_time),max(end_time),sum(CREDITS_ATTRIBUTED_COMPUTE)from QUERY_ATTRIBUTION_HISTORY
  where date(start_time) >= current_date - 7
  and user_name = 'SRIKANTHBIDHANIYA'
  and Parent_query_id = '01b8ea35-0906-eb0a-002b-e28305b8f6d2';

  