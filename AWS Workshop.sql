--
-- Setup the environment to setup for the workshop
--
USE ROLE accountadmin;

-- Create the workshopadmin and workshopuser roles and adding this role to the login user;
CREATE ROLE workshopadmin;
CREATE ROLE workshopuser;
GRANT ROLE workshopadmin TO USER MANIMARARCHANDRASEKAR;  -- Change to your login
GRANT ROLE workshopuser TO USER MANIMARARCHANDRASEKAR;   -- Change to your login

-- Grant the roles to the sysadmin role this is best practice
GRANT ROLE workshopadmin TO ROLE sysadmin;
GRANT ROLE workshopuser TO ROLE sysadmin;

-- Grant the account level permissions needed for the lab to the workshopadmin role
GRANT CREATE DATABASE ON ACCOUNT TO ROLE workshopadmin;
GRANT CREATE WAREHOUSE ON ACCOUNT TO ROLE workshopadmin;
GRANT CREATE SHARE ON ACCOUNT TO ROLE workshopadmin;
GRANT APPLY MASKING POLICY ON ACCOUNT TO ROLE workshopadmin;
GRANT MANAGE GRANTS ON ACCOUNT TO ROLE workshopadmin;
GRANT CREATE INTEGRATION ON ACCOUNT TO ROLE workshopadmin;


USE ROLE workshopadmin;
CREATE OR REPLACE DATABASE MOVIELENS ;
GRANT USAGE ON DATABASE MOVIELENS TO workshopuser;



CREATE SCHEMA movielens.movies;
GRANT USAGE ON SCHEMA movielens.movies TO ROLE workshopuser;
GRANT SELECT,INSERT,delete, update ON FUTURE TABLES IN SCHEMA movielens.movies to role workshopuser;

USE SCHEMA movielens.movies;


CREATE OR REPLACE WAREHOUSE WORKSHOPWH WITH WAREHOUSE_SIZE = 'XSMALL' 
AUTO_SUSPEND = 60 AUTO_RESUME = TRUE;

GRANT USAGE ON WAREHOUSE workshopwh TO ROLE workshopuser;



CREATE OR REPLACE TABLE movies_raw  (
    movieid int,
    title varchar,
    genres varchar
);

CREATE OR REPLACE TABLE ratings_raw (
    userid int,
    movieid int,
    rating float,
    timestamp timestamp_ntz,
    firstname varchar,
    lastname varchar,
    street varchar,
    city varchar,
    state varchar,
    postcode varchar,
    country varchar,
    email varchar,
    phonenumber varchar
);



--
-- Handling PII data
--
-- Tags and Masking
--

use role accountadmin;
grant all on all schemas in database movielens to role workshopadmin;
USE ROLE workshopadmin;
CREATE TAG email;
CREATE TAG name;
CREATE TAG phone;
CREATE TAG address;




CREATE MASKING POLICY email AS (val STRING) RETURNS STRING ->
    CASE
      WHEN current_role() IN ('WORKSHOPADMIN') THEN val
      ELSE 'road_runner'  || substr(val,charindex('@', val))
    END
;

CREATE MASKING POLICY phone AS (val STRING) RETURNS STRING ->
    CASE
        WHEN current_role() IN ('WORKSHOPADMIN') THEN val
        ELSE '0500 123 456'
    END
;

CREATE MASKING POLICY address AS (val STRING) RETURNS STRING ->
    CASE
        WHEN current_role() IN ('WORKSHOPADMIN') THEN val
        ELSE '55 Main Street'
    END
;

CREATE MASKING POLICY name AS (val STRING) RETURNS STRING ->
    CASE
        WHEN current_role() IN ('WORKSHOPADMIN') THEN val
        ELSE '**********'
    END
;



ALTER TAG email SET MASKING POLICY email;
ALTER TAG phone SET MASKING POLICY phone;
ALTER TAG address SET MASKING POLICY address;
ALTER TAG name SET MASKING POLICY name;

ALTER TABLE ratings_raw MODIFY COLUMN email SET TAG email = 'True';
ALTER TABLE ratings_raw MODIFY COLUMN phonenumber SET TAG phone = 'True';
ALTER TABLE ratings_raw MODIFY COLUMN street SET TAG address = 'True';
ALTER TABLE ratings_raw MODIFY COLUMN firstname SET TAG name = 'True';
ALTER TABLE ratings_raw MODIFY COLUMN lastname SET TAG name = 'True';


CREATE TABLE movies_curated
(
  movieid number,
  title varchar,
  release integer
);

CREATE TABLE genres_curated
(
  genresid number autoincrement start 1 increment 1,
  genres varchar
);

CREATE TABLE movies_genres_curated
(
  genresid number,
  movieid number
);

CREATE TABLE ratings_curated
(
    userid int,
    movieid int,
    rating float,
    timestamp timestamp_ntz
);

CREATE TABLE users_curated
(
    userid int,
    firstname varchar,
    lastname varchar,
    street varchar,
    city varchar,
    state varchar,
    postcode varchar,
    country varchar,
    email varchar,
    phonenumber varchar
);

ALTER TABLE users_curated MODIFY COLUMN email SET TAG email = 'True';
ALTER TABLE users_curated MODIFY COLUMN phonenumber SET TAG phone = 'True';
ALTER TABLE users_curated MODIFY COLUMN street SET TAG address = 'True';
ALTER TABLE users_curated MODIFY COLUMN firstname SET TAG name = 'True';
ALTER TABLE users_curated MODIFY COLUMN lastname SET TAG name = 'True';


-- Setup the snowflake context for the new worksheet
use role workshopadmin;
use database movielens;
use schema movies;
use warehouse workshopwh;


CREATE OR REPLACE FILE FORMAT movielens_ffmt
  TYPE = CSV
  FIELD_DELIMITER = ','
  SKIP_HEADER = 1
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  COMPRESSION = gzip;

  --
-- Scale up the warehouse to load the data
--
ALTER WAREHOUSE workshopwh SET WAREHOUSE_SIZE = LARGE;


-- movies data
COPY INTO movies_raw
  FROM s3://jhs-sf-aws-bucket/movies.csv.gz
  FILE_FORMAT = (FORMAT_NAME = 'movielens_ffmt');


  -- ratings data
COPY INTO ratings_raw
  FROM s3://jhs-sf-aws-bucket/ratings.csv.gz
  FILE_FORMAT = (FORMAT_NAME = 'movielens_ffmt');

-- Scale back down the
ALTER WAREHOUSE workshopwh SET WAREHOUSE_SIZE = SMALL;

SELECT * FROM movies_raw LIMIT 10;

SELECT * FROM ratings_raw LIMIT 10;


-- ratings_curated
INSERT INTO ratings_curated (userid, movieid, rating, timestamp)
SELECT userid, movieid, rating, timestamp
FROM ratings_raw;

-- users_curated
INSERT INTO users_curated(userid, firstname, lastname, street, city, state, postcode, country, email, phonenumber)
SELECT DISTINCT(userid), firstname, lastname, street, city, state, postcode, country, email, phonenumber
FROM ratings_raw
GROUP BY ALL;


-- Insert the unique generes, with genresid being an autoincrement column
INSERT INTO  genres_curated(genres)
SELECT distinct value
FROM movies_raw, LATERAL SPLIT_TO_TABLE(movies_raw.genres, '|');


SELECT * FROM genres_curated;

-- Insert the curated movied data
INSERT INTO  movies_curated
SELECT movieid,  substr(title,0,regexp_instr(title, '\([0-9]{4}\)')-2) as title,
    regexp_substr(title, '([0-9]{4})') as myear
FROM movies_raw
WHERE myear is not null;


SELECT * FROM movies_curated;

--
-- movie_genres_curated
--

-- Use a temprorary table to store the movieid and genres
CREATE OR REPLACE TEMPORARY TABLE movie_genres_tmp
AS
  SELECT movieid, value as genres
  FROM movies_raw, LATERAL SPLIT_TO_TABLE(movies_raw.genres, '|');

-- Now how do we get the genresid for the movie_genres_curated table
SELECT m.movieid, g.genresid
FROM movie_genres_tmp m, genres_curated g
WHERE m.genres = g.genres
LIMIT 10;

-- Insert the data into the movies_genres_curated table using
-- the above select
INSERT INTO movies_genres_curated
  SELECT m.movieid, g.genresid
  FROM movie_genres_tmp m, genres_curated g
  WHERE m.genres = g.genres;

  SELECT * FROM movies_genres_curated limit 5;


  -- ratings table
USE ROLE workshopadmin;
SELECT * FROM movies.ratings_raw LIMIT 5;

USE ROLE workshopuser;
SELECT * FROM movies.ratings_raw LIMIT 5;



use role workshopadmin;
use database movielens;
use schema movies;
use warehouse workshopwh;

CREATE OR REPLACE TABLE interactions
AS
SELECT
    userid as USER_ID,
    movieid as ITEM_ID,
    DATE_PART('EPOCH_SECOND', timestamp) AS TIMESTAMP,
    CASE
        WHEN rating > 3 THEN 'watch'
        WHEN rating > 1 THEN 'click'
    END AS EVENT_TYPE
FROM ratings_curated SAMPLE(10)
WHERE rating > 1;


select current_user();