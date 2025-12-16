show tables;

select * from DB_UNDER_UTL_WH limit 10;

use schema snowflake_sample_data.tpch_sf1;

use role accountadmin;
-- Create a database from the share.
CREATE DATABASE SNOWFLAKE_SAMPLE_DATA FROM SHARE SFC_SAMPLES.SAMPLE_DATA;

-- Grant the PUBLIC role access to the database.
-- Optionally change the role name to restrict access to a subset of users.
GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE_SAMPLE_DATA TO ROLE PUBLIC;

use database SFC_SAMPLES_SAMPLE_DATA;
show schemas;

use role sysadmin;

use schema tpcds_sf10Tcl;

with v1 as(
  select i_category, i_brand, cc_name, d_year, d_moy,
        sum(cs_sales_price) sum_sales,
        avg(sum(cs_sales_price)) over
          (partition by i_category, i_brand,
                     cc_name, d_year)
          avg_monthly_sales,
        rank() over
          (partition by i_category, i_brand,
                     cc_name
           order by d_year, d_moy) rn
  from item, catalog_sales, date_dim, call_center
  where cs_item_sk = i_item_sk and
       cs_sold_date_sk = d_date_sk and
       cc_call_center_sk= cs_call_center_sk and
       (
         d_year = 1999 or
         ( d_year = 1999-1 and d_moy =12) or
         ( d_year = 1999+1 and d_moy =1)
       )
  group by i_category, i_brand,
          cc_name , d_year, d_moy),
v2 as(
  select v1.i_category ,v1.d_year, v1.d_moy ,v1.avg_monthly_sales
        ,v1.sum_sales, v1_lag.sum_sales psum, v1_lead.sum_sales nsum
  from v1, v1 v1_lag, v1 v1_lead
  where v1.i_category = v1_lag.i_category and
       v1.i_category = v1_lead.i_category and
       v1.i_brand = v1_lag.i_brand and
       v1.i_brand = v1_lead.i_brand and
       v1.cc_name = v1_lag.cc_name and
       v1.cc_name = v1_lead.cc_name and
       v1.rn = v1_lag.rn + 1 and
       v1.rn = v1_lead.rn - 1)
select  *
from v2
where  d_year = 1999 and
        avg_monthly_sales > 0 and
        case when avg_monthly_sales > 0 then abs(sum_sales - avg_monthly_sales) / avg_monthly_sales else null end > 0.1
order by sum_sales - avg_monthly_sales, 3
limit 100;

elect current_user;

use snowflake.account_usage;
show views;
select try_parse_json(query_tag)['team']::string,* from query_history where try_parse_json(query_tag)['team']::string = 'consulting'
and date(start_time)>= current_date -7
and user_name = current_user;
--{"team": "consulting", "user": "Mani"}
desc view query_history;


select
    try_parse_json(query_tag)['model_name']::string as model_name,
    count(*) as num_executions,
    sum(query_cost) as total_cost,
    avg(total_elapsed_time_s) as avg_total_elapsed_time_s
from query_history_enriched
where
    try_parse_json(query_tag)['app_name']::string = 'pipeline'
    and start_time > current_date - 7
group by 1;



alter user MANIMARARCHANDRASEKAR set query_tag = '{"team": "consulting", "user": "Mani"}';



WITH
filtered_queries AS (
    SELECT
        query_id,
        query_text AS original_query_text,

        -- First, we remove comments enclosed by /* <comment text> */
        REGEXP_REPLACE(query_text, '(/\*.*\*/)') AS _cleaned_query_text,
        -- Next, removes single line comments starting with --
        -- and either ending with a new line or end of string
        REGEXP_REPLACE(_cleaned_query_text, '(--.*$)|(--.*\n)') AS cleaned_query_text,
        warehouse_id,
        try_parse_json(query_tag)['team']::string QUERY_TAG,
        TIMEADD(
            'millisecond',
            queued_overload_time + compilation_time +
            queued_provisioning_time + queued_repair_time +
            list_external_files_time,
            start_time
        ) AS execution_start_time,
        end_time
    FROM snowflake.account_usage.query_history 
     AS q
    WHERE TRUE
        AND warehouse_size IS NOT NULL
        AND try_parse_json(query_tag)['team']::string = 'consulting'
        --AND start_time >= DATEADD('day', -30, DATEADD('day', -1, CURRENT_DATE))
),
-- 1 row per hour from 30 days ago until the end of today
hours_list AS (
    SELECT
        DATEADD(
            'hour',
            '-' || row_number() over (order by null),
            DATEADD('day', '+1', CURRENT_DATE)
        ) as hour_start,
        DATEADD('hour', '+1', hour_start) AS hour_end
    FROM TABLE(generator(rowcount => (24*31))) t
),
-- 1 row per hour a query ran
query_hours AS (
    SELECT
        hl.hour_start,
        hl.hour_end,
        queries.*
    FROM hours_list AS hl
    INNER JOIN filtered_queries AS queries
        ON hl.hour_start >= DATE_TRUNC('hour', queries.execution_start_time)
        AND hl.hour_start < queries.end_time
),
query_seconds_per_hour AS (
    SELECT
        *,
        DATEDIFF('millisecond', GREATEST(execution_start_time, hour_start), LEAST(end_time, hour_end)) AS num_milliseconds_query_ran,
        SUM(num_milliseconds_query_ran) OVER (PARTITION BY warehouse_id, hour_start) AS total_query_milliseconds_in_hour,
        num_milliseconds_query_ran/total_query_milliseconds_in_hour AS fraction_of_total_query_time_in_hour,
        hour_start AS hour
    FROM query_hours
),
credits_billed_per_hour AS (
    SELECT
        start_time AS hour,
        warehouse_id,
        credits_used_compute
    FROM snowflake.account_usage.warehouse_metering_history
),
query_cost AS (
    SELECT
        query.*,
        credits.credits_used_compute*2.28 AS actual_warehouse_cost,
        credits.credits_used_compute*fraction_of_total_query_time_in_hour*2.28 AS query_allocated_cost_in_hour
    FROM query_seconds_per_hour AS query
    INNER JOIN credits_billed_per_hour AS credits
        ON query.warehouse_id=credits.warehouse_id
        AND query.hour=credits.hour
),
cost_per_query AS (
    SELECT
        query_id,
        ANY_VALUE(MD5(cleaned_query_text)) AS query_signature,
        SUM(query_allocated_cost_in_hour) AS query_cost,
        ANY_VALUE(original_query_text) AS original_query_text,
        ANY_VALUE(warehouse_id) AS warehouse_id,
        SUM(num_milliseconds_query_ran) / 1000 AS execution_time_s,
        QUERY_TAG
    FROM query_cost
    GROUP BY ALL
)
SELECT
    query_signature,
    COUNT(*) AS num_executions,
    AVG(query_cost) AS avg_cost_per_execution,
    SUM(query_cost) AS total_cost_last_30d,
    ANY_VALUE(original_query_text) AS sample_query_text,
    QUERY_TAG
FROM cost_per_query
GROUP BY ALL;





show views;
show users;

use role accountadmin;

alter user KOWSALYANATARAJAN set password ="Welcome123";

desc view WAREHOUSE_EVENTS_HISTORY;

select date(timestamp),hour(timestamp), minute(timestamp),warehouse_name,cluster_number,event_name,event_state,event_reason,size,cluster_count,count(1) from WAREHOUSE_EVENTS_HISTORY where warehouse_name = 'COE_PRACTISE_WH'
and year(timestamp) = year(current_date)
and month(timestamp) = month(current_date) - 3
group by all
order by 1,2,3 asc;
;

select * From WAREHOUSE_EVENTS_HISTORY
where date(timestamp) = '2024-03-01'
and warehouse_name = 'COE_PRACTISE_WH'
order by timestamp asc;


show views like '%DAILY%';

select  SERVICE_TYPE ,year(usage_date), monthname(usage_date),sum(credits_billed) from  METERING_DAILY_HISTORY  
where year(usage_date) = year(usage_date)
group by all;

show views;