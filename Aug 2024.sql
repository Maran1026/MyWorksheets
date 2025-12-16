with role_hier as (
    --Extract all Roles
    select
        grantee_name,
        name
    from
        SNOWFLAKE.ACCOUNT_USAGE.grants_to_roles
    where
        granted_on = 'ROLE'
        and privilege = 'USAGE'
        and deleted_on is null
    union all
        --Adding in dummy records for "root" roles
    select
        'root',
        r.name
    from
        SNOWFLAKE.ACCOUNT_USAGE.roles r
    where
        deleted_on is null
        and not exists (
            select
                1
            from
                SNOWFLAKE.ACCOUNT_USAGE.grants_to_roles gtr
            where
                gtr.granted_on = 'ROLE'
                and gtr.privilege = 'USAGE'
                and gtr.name = r.name
                and deleted_on is null
        )
) --CONNECT BY to create the polyarchy and SYS_CONNECT_BY_PATH to flatten it
,
role_path_pre as(
    select
        name,
        level,
        sys_connect_by_path(name, ' -> ') as path
    from
        role_hier connect by grantee_name = prior name start with grantee_name = 'root'
    order by
        path
) --Removing leading delimiter separately since there is some issue with how it interacted with sys_connect_by_path
,
role_path as (
    select
        name,
        level,
        substr(path, len(' -> ')) as path
    from
        role_path_pre
) --Joining in privileges from GRANT_TO_ROLES
,
role_path_privs as (
    select
        path,
        rp.name as role_name,
        privs.privilege,
        granted_on,
        privs.name as priv_name,
        'Role ' || path || ' has ' || privilege || ' on ' || granted_on || ' ' || privs.name as Description
    from
        role_path rp
        left join SNOWFLAKE.ACCOUNT_USAGE.grants_to_roles privs on rp.name = privs.grantee_name
        and privs.granted_on != 'ROLE'
        and deleted_on is null
    order by
        path
) --Aggregate total number of priv's per role, including hierarchy
,
role_path_privs_agg as (
    select
        trim(split(path, ' -> ') [0]) role,
        count(*) num_of_privs
    from
        role_path_privs
    group by
        trim(split(path, ' -> ') [0])
    order by
        count(*) desc
) --Most Dangerous Man - final query
select
    grantee_name as user,
    count(a.role) num_of_roles,
    sum(num_of_privs) num_of_privs
from
    SNOWFLAKE.ACCOUNT_USAGE.grants_to_users u
    join role_path_privs_agg a on a.role = u.role
where
    u.deleted_on is null
group by
    user
order by
    num_of_privs desc;


    show grants on role orgadmin;
select * from snowflake.account_usage.grants_to_users
where role = 'ORGADMIN'
--limit 10
;

show users like 'KOWSAL%';


SELECT
 l.user_name,
 first_authentication_factor,
 second_authentication_factor,
 count(*) as Num_of_events
FROM snowflake.account_usage.login_history as l
JOIN snowflake.account_usage.users u on l.user_name = u.name and l.user_name ilike '%svc' and has_rsa_public_key = 'true'
WHERE is_success = 'YES'
AND first_authentication_factor != 'RSA_KEYPAIR'
GROUP BY l.user_name, first_authentication_factor, second_authentication_factor
ORDER BY count(*) desc;


select
    user_name || ' granted the ' || role_name || ' role on ' || end_time as Description, query_text as Statement
from
    snowflake.account_usage.query_history
where
    execution_status = 'SUCCESS'
    and query_type = 'GRANT'
    and query_text ilike '%grant%accountadmin%to%'
order by
    end_time desc;

    select u.name, 
timediff(days, last_success_login, current_timestamp()) || ' days ago' last_login ,
timediff(days, password_last_set_time,current_timestamp(6)) || ' days ago' password_age
from snowflake.account_usage.users u
join snowflake.account_usage.grants_to_users g on grantee_name = name and role = 'ACCOUNTADMIN' and g.deleted_on is null
where ext_authn_duo = false and u.deleted_on is null and has_password = true
order by last_success_login desc;


select name, datediff('day', password_last_set_time, current_timestamp()) || ' days ago' as password_last_changed from snowflake.account_usage.users 
where deleted_on is null and 
password_last_set_time is not null
order by password_last_set_time;

select name, datediff("day", nvl(last_success_login, created_on), current_timestamp()) || ' days ago' Last_Login from snowflake.account_usage.users 
where deleted_on is null
order by datediff("day", nvl(last_success_login, created_on), current_timestamp()) desc;


select
    user_name as by_whom,
    datediff('day', start_time, current_timestamp()) || ' days ago' as created_on,
    ADD_MONTHS(start_time, 6) as expires_on,
    datediff(
        'day',
        current_timestamp(),
        ADD_MONTHS(end_time, 6)
    ) as expires_in_days
from
    snowflake.account_usage.query_history
where
    execution_status = 'SUCCESS'
    and query_text ilike 'select%SYSTEM$GENERATE_SCIM_ACCESS_TOKEN%'
    and query_text not ilike 'select%where%SYSTEM$GENERATE_SCIM_ACCESS_TOKEN%'
order by expires_in_days;



with role_hier as (
    --Extract all Roles
    select
        grantee_name,
        name
    from
        grants_to_roles
    where
        granted_on = 'ROLE'
        and privilege = 'USAGE'
        and deleted_on is null
    union all
        --Adding in dummy records for "root" roles
    select
        'root',
        r.name
    from
        roles r
    where
        deleted_on is null
        and not exists (
            select
                1
            from
                grants_to_roles gtr
            where
                gtr.granted_on = 'ROLE'
                and gtr.privilege = 'USAGE'
                and gtr.name = r.name
                and deleted_on is null
        )
) --CONNECT BY to create the polyarchy and SYS_CONNECT_BY_PATH to flatten it
,
role_path_pre as(
    select
        name,
        level,
        sys_connect_by_path(name, ' -> ') as path
    from
        role_hier connect by grantee_name = prior name start with grantee_name = 'root'
    order by
        path
) --Removing leading delimiter separately since there is some issue with how it interacted with sys_connect_by_path
,
role_path as (
    select
        name,
        level,
        substr(path, len(' -> ')) as path
    from
        role_path_pre
) --Joining in privileges from GRANT_TO_ROLES
,
role_path_privs as (
    select
        path,
        rp.name as role_name,
        privs.privilege,
        granted_on,
        privs.name as priv_name,
        'Role ' || path || ' has ' || privilege || ' on ' || granted_on || ' ' || privs.name as Description
    from
        role_path rp
        left join grants_to_roles privs on rp.name = privs.grantee_name
        and privs.granted_on != 'ROLE'
        and deleted_on is null
    order by
        path
) --Aggregate total number of priv's per role, including hierarchy
,
role_path_privs_agg as (
    select
        trim(split(path, ' -> ') [0]) role,
        count(*) num_of_privs
    from
        role_path_privs
    group by
        trim(split(path, ' -> ') [0])
    order by
        count(*) desc
) --Most Dangerous Man - final query
select
    grantee_name as user,
    count(a.role) num_of_roles,
    sum(num_of_privs) num_of_privs
from
    grants_to_users u
    join role_path_privs_agg a on a.role = u.role
where
    u.deleted_on is null
group by
    user
order by
    num_of_privs desc;



    --Role Hierarchy
with role_hier as (
    --Extract all Roles
    select
        grantee_name,
        name
    from
        grants_to_roles
    where
        granted_on = 'ROLE'
        and privilege = 'USAGE'
        and deleted_on is null
    union all
        --Adding in dummy records for "root" roles
    select
        'root',
        r.name
    from
        roles r
    where
        deleted_on is null
        and not exists (
            select
                1
            from
                grants_to_roles gtr
            where
                gtr.granted_on = 'ROLE'
                and gtr.privilege = 'USAGE'
                and gtr.name = r.name
                and deleted_on is null
        )
) --CONNECT BY to create the polyarchy and SYS_CONNECT_BY_PATH to flatten it
,
role_path_pre as(
    select
        name,
        level,
        sys_connect_by_path(name, ' -> ') as path
    from
        role_hier connect by grantee_name = prior name start with grantee_name = 'root'
    order by
        path
) --Removing leading delimiter separately since there is some issue with how it interacted with sys_connect_by_path
,
role_path as (
    select
        name,
        level,
        substr(path, len(' -> ')) as path
    from
        role_path_pre
) --Joining in privileges from GRANT_TO_ROLES
,
role_path_privs as (
    select
        path,
        rp.name as role_name,
        privs.privilege,
        granted_on,
        privs.name as priv_name,
        'Role ' || path || ' has ' || privilege || ' on ' || granted_on || ' ' || privs.name as Description
    from
        role_path rp
        left join grants_to_roles privs on rp.name = privs.grantee_name
        and privs.granted_on != 'ROLE'
        and deleted_on is null
    order by
        path
) --Aggregate total number of priv's per role, including hierarchy
,
role_path_privs_agg as (
    select
        trim(split(path, ' -> ') [0]) role,
        count(*) num_of_privs
    from
        role_path_privs
    group by
        trim(split(path, ' -> ') [0])
    order by
        count(*) desc
) 
select * from role_path_privs_agg order by num_of_privs desc;


SELECT
    query_text,
    user_name,
    role_name,
    end_time
  FROM snowflake.account_usage.query_history
    WHERE execution_status = 'SUCCESS'
      AND query_type NOT in ('SELECT')
      AND (query_text ILIKE '%create role%'
          OR query_text ILIKE '%manage grants%'
          OR query_text ILIKE '%create integration%'
          OR query_text ILIKE '%create share%'
          OR query_text ILIKE '%create account%'
          OR query_text ILIKE '%monitor usage%'
          OR query_text ILIKE '%ownership%'
          OR query_text ILIKE '%drop table%'
          OR query_text ILIKE '%drop database%'
          OR query_text ILIKE '%create stage%'
          OR query_text ILIKE '%drop stage%'
          OR query_text ILIKE '%alter stage%'
          )
  ORDER BY end_time desc;


  select user_name || ' made the following Network Policy change on ' || end_time || ' [' ||  query_text || ']' as Events
   from query_history where execution_status = 'SUCCESS'
   and query_type in ('CREATE_NETWORK_POLICY', 'ALTER_NETWORK_POLICY', 'DROP_NETWORK_POLICY')
   or (query_text ilike '% set network_policy%' or
       query_text ilike '% unset network_policy%')
       and query_type != 'SELECT' and query_type != 'UNKNOWN'
   order by end_time desc;



   select table_id,any_value(table_name),sum(partitions_scanned) total_partitions, sum(partitions_pruned)/greatest(sum(partitions_scanned)+ sum(partitions_pruned),1) as purning_percentage from snowflake.account_usage.table_pruning_history
   where start_time >= current_date - 7
   group by table_id
   order by total_partitions desc 
   --limit 5
   ;


   SELECT
    table_id,
    ANY_VALUE(table_name) AS table_name,
    SUM(partitions_pruned_default) / GREATEST(SUM(partitions_scanned) + SUM(partitions_pruned_default) + SUM(partitions_pruned_additional), 1) AS pruning_percentage_default,
    SUM(partitions_pruned_additional) / GREATEST(SUM(partitions_scanned) + SUM(partitions_pruned_default) + SUM(partitions_pruned_additional), 1) AS pruning_percentage_with_search,
    (SUM(partitions_pruned_default) + SUM(partitions_pruned_additional)) / GREATEST(SUM(partitions_scanned), 1) AS pruning_percentage,
    (SUM(partitions_pruned_default) + SUM(partitions_pruned_additional)) / GREATEST(SUM(partitions_scanned), 1) AS search_optimization_percentage
FROM SNOWFLAKE.ACCOUNT_USAGE.SEARCH_OPTIMIZATION_BENEFITS
WHERE start_time >= DATEADD(day,-7,CURRENT_TIMESTAMP())
GROUP BY table_id
ORDER BY total_partitions_pruned_from_search_optimization DESC
LIMIT 5;

select * from SNOWFLAKE.ACCOUNT_USAGE.SEARCH_OPTIMIZATION_BENEFITS limit 10;

SELECT
    t1.table_id AS table_id,
    ANY_VALUE(t1.table_name) AS table_name,
    SUM(t1.rows_added) AS total_rows_added,
    SUM(t1.rows_removed) AS total_rows_removed,
    SUM(t1.rows_updated) AS total_rows_updated,
    SUM(t2.credits_used) AS total_automatic_clustering_credits
FROM SNOWFLAKE.ACCOUNT_USAGE.TABLE_DML_HISTORY t1
JOIN SNOWFLAKE.ACCOUNT_USAGE.AUTOMATIC_CLUSTERING_HISTORY t2 ON (t1.table_id = t2.table_id AND
    t1.schema_id = t2.schema_id AND t1.database_id = t2.database_id AND t1.start_time = t2.start_time)
WHERE t1.start_time >= DATEADD(day, -7, CURRENT_TIMESTAMP())
GROUP BY t1.table_id
ORDER BY total_automatic_clustering_credits DESC
LIMIT 5;



    