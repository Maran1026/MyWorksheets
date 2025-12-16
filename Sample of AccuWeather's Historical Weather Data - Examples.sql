// Which locations received snow on January 15, 2022?
select country_code, city_name, latitude, longitude
from historical.top_city_daily_imperial
where snow_total > 0
and date = '1/15/2022'

;

