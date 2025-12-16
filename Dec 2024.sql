show grants on database coe_practise_db;

--Create,Read,Update,Delete

--RO,RW,ALL

--COE_PRACTISE_DB

use role sysadmin;

create database role COE_PRACTISE_DB_RO;
create database role COE_PRACTISE_DB_RW;
create database role COE_PRACTISE_DB_ALL;

show roles like 'COE_PRACTISE_DB%';

show roles in database COE_PRACTISE_DB;


grant all on database COE_PRACTISE_DB to role COE_PRACTISE_DB_ALL;
grant usage on database COE_PRACTISE_DB to role COE_PRACTISE_DB_RO;
grant usage on all schemas in database COE_PRACTISE_DB to role COE_PRACTISE_DB_RO;
grant usage on future schemas in database COE_PRACTISE_DB to role COE_PRACTISE_DB_RO;
grant monitor on all alert in database COE_PRACTISE_DB to role COE_PRACTISE_DB_RO;

