create database airpure_innovation;

use airpure_innovation;

-- Primary Analysis (Based on Available data): 
/* 1. List the top 5 and bottom 5 areas with highest average AQI. (Consider areas 
	which contains data from last 6 months: December 2024 to May 2025) */
SELECT * FROM aqi;

-- Top 5 areas with avg AQI
SELECT 
    area, AVG(aqi_value) AS avg_aqi
FROM
    aqi
WHERE
    date BETWEEN '01-12-2024' AND '31-05-2025'
GROUP BY area
HAVING COUNT(*) > 0
ORDER BY avg_aqi DESC
LIMIT 5;


-- Bottom 5 areas with avg AQI
SELECT 
    area, AVG(aqi_value) AS avg_aqi
FROM
    aqi
WHERE
    date BETWEEN '01-12-2024' AND '31-05-2025'
GROUP BY area
HAVING COUNT(*) > 0
ORDER BY avg_aqi ASC
LIMIT 5;

/* 2. List out top 2 and bottom 2 prominent pollutants for each state of southern India. 
	(Consider data post covid: 2022 onwards) */

WITH filtered_data AS (
  SELECT
    state,
    prominent_pollutants,
    AVG(aqi_value) AS avg_value
  FROM
    aqi
  WHERE
    state IN ('Andhra Pradesh', 'Tamil Nadu', 'Karnataka', 'Kerala', 'Telangana')
    AND date >= '01-01-2022'
  GROUP BY
    state, prominent_pollutants
),
ranked_data AS (
  SELECT *,
         RANK() OVER (PARTITION BY state ORDER BY avg_value DESC) AS rank_high,
         RANK() OVER (PARTITION BY state ORDER BY avg_value ASC) AS rank_low
  FROM filtered_data
)
SELECT state, prominent_pollutants, avg_value, 'Top 2' AS category
FROM ranked_data
WHERE rank_high <= 2

UNION ALL

SELECT state, prominent_pollutants, avg_value, 'Bottom 2' AS category
FROM ranked_data
WHERE rank_low <= 2;

/* 3. Does AQI improve on weekends vs weekdays in Indian metro cities (Delhi, 
	Mumbai, Chennai, Kolkata, Bengaluru, Hyderabad, Ahmedabad, Pune)? (Consider data from last 1 year) */
    
select distinct air_quality_status from aqi;
SELECT 
    area,
    AVG(CASE
        WHEN DAYOFWEEK(str_to_date(date, '%Y-%m-%d')) IN (1 , 7) THEN aqi_value
    END) AS avg_aqi_weekend,
    AVG(CASE
        WHEN DAYOFWEEK(str_to_date(date, '%Y-%m-%d')) NOT IN (1 , 7) THEN aqi_value
    END) AS avg_aqi_weekdays
FROM
    aqi
WHERE
    area IN ('Delhi' , 'Mumbai',
        'Chennai',
        'Kolkata',
        'Bengaluru',
        'Hyderabad',
        'Ahmedabad',
        'Pune') and
	YEAR(STR_TO_DATE(date, '%d-%m-%Y')) >= 2024
GROUP BY area
ORDER BY area;

/* 4. Which months consistently show the worst air quality across Indian states — 
	(Consider top 10 states with high distinct areas) */ 
select state, count(distinct area) as area_count
from aqi
group by state
order by area_count desc
limit 10; 

SELECT 
	state,
    MONTHNAME(STR_TO_DATE(date, '%Y-%m-%d')) AS Month,
    AVG(aqi_value) AS avg_aqi,
    air_quality_status
FROM
    aqi
WHERE
    state IN (SELECT 
            state
        FROM
            (SELECT 
                state, COUNT(DISTINCT area) AS area_count
            FROM
                aqi
            GROUP BY state
            ORDER BY area_count DESC
            LIMIT 10) AS top_states)
        AND aqi_value IS NOT NULL and air_quality_status in ('Severe')
GROUP BY state, Month, air_quality_status
ORDER BY avg_aqi DESC;

SELECT 
	state,
    MONTHNAME(STR_TO_DATE(date, '%Y-%m-%d')) AS Month,
    AVG(aqi_value) AS avg_aqi,
    air_quality_status
FROM
    aqi
WHERE
    state IN (SELECT 
            state
        FROM
            (SELECT 
                state, COUNT(DISTINCT area) AS area_count
            FROM
                aqi
            GROUP BY state
            ORDER BY area_count DESC
            LIMIT 10) AS top_states)
        AND aqi_value IS NOT NULL and air_quality_status in ('Severe')
GROUP BY state, Month, air_quality_status
ORDER BY avg_aqi DESC;

/* 5. For the city of Bengaluru, how many days fell under each air quality category 
	(e.g., Good, Moderate, Poor, etc.) between March and May 2025? */
  
SELECT 
    area, air_quality_status, COUNT(DISTINCT date) AS days
FROM
    aqi
WHERE
    area = 'Bengaluru'
        AND date BETWEEN '01-03-2025' AND '01-05-2025'
        AND aqi_value IS NOT NULL
GROUP BY air_quality_status
ORDER BY air_quality_status;

/* 6. List the top two most reported disease illnesses in each state over the past three 
	years, along with the corresponding average Air Quality Index (AQI) for that period. */

with total_disease as (
	SELECT 
    state, disease_illness_name, SUM(cases) AS total_cases
FROM
    health_related_consequences
WHERE
    year BETWEEN 2022 AND 2024
GROUP BY state , disease_illness_name
ORDER BY total_cases DESC
),
avg_aqi_state as (
	SELECT 
    state, AVG(aqi_value) AS avg_aqi
FROM
    aqi
WHERE
    YEAR(STR_TO_DATE(date, '%d-%m-%Y')) BETWEEN 2022 AND 2024
GROUP BY state
    
)
SELECT 
    d.state, d.disease_illness_name, d.total_cases, a.avg_aqi
FROM
    total_disease d
        JOIN
    avg_aqi_state a ON a.state = d.state
ORDER BY d.state , d.total_cases DESC
;


/* 7. List the top 5 states with high EV adoption and analyse if their average AQI is 
	significantly better compared to states with lower EV adoption fuel = 'ELECTRIC(BOV)' */


WITH ev_count AS (
  SELECT 
    state, 
    count(*) AS ev_count
  FROM vehicle_data
  WHERE fuel = 'ELECTRIC(BOV)'
  GROUP BY state
),

top_5_states AS (
  SELECT e.state, e.ev_count, avg(a.aqi_value) as avg_aqi
  FROM ev_count e
  join aqi a
  on a.state = e.state
  group by e.state
  ORDER BY e.ev_count DESC
  LIMIT 5
),

bottom_5_states AS (
  SELECT e.state, e.ev_count, avg(a.aqi_value) as avg_aqi
  FROM ev_count e
  join aqi a 
  on a.state = e.state
  group by e.state
  ORDER BY e.ev_count ASC
  LIMIT 5
)

SELECT 'Top 5 EV State' AS category, state, ev_count, avg_aqi
FROM top_5_states 
UNION ALL

SELECT 'Bottom 5 EV State' AS category, state, ev_count, avg_aqi
FROM bottom_5_states 
ORDER BY ev_count desc
;



-- Secondary Analysis (This will require additional data and research) 
/* 1. Which age group is most affected by air pollution-related health outcomes — and how 
does this vary by city? 

- According to WHO (World Health Organization) Children, elderly and pregnant women are more affected by 
  air pollution-related diseses. 
- Urban and Rural areas are also affected by air pollution especially those with high traffic density
  and industrial activity have hgher levels of air pollution  
- Different cities have varying levels of air pollution due to industrial activity, transportation and weather. 
  For example, Delhi is major metropolitan area face severe air quallity challenges, while some smaller cities may have relatively better air quality.*/


/* 2. Who are the major competitors in the Indian air purifier market, and what are their key 
differentiators (e.g., price, filtration stages, smart features)? 

- There are various competitors in the Indian air purifier market, but major competitors are 
Dyson, Phillips, Mi (Xiaomi), Honeywell, Sharp, Kent, LG, Samsung, Blue Star, and Realme.
- If in terms of price Mi and Realme give affordable price with HEPA filters and app control.
- Phillips and Honeywell offer multi-stage filters with middle range price.
- In terms of advanced and smart filteration Dyson offer premium quality.
- LG an Samsung provide stylish and high tech purifier.
*/

/* 3. What is the relationship between a city’s population size and its average AQI — do larger 
cities always suffer from worse air quality? (Consider 2024 population and AQI data for this) 

- Generally large city with large population have worst average AQI due to transpotation, open 
  burning and industrial activity such as Delhi, Mumbai and Kolkata, but this is not always case like 
  some larger cities Bangalore or Hyderabad had compartively better AQI because of better urban planning,
  favorable weather.
- There are many small cities like Kanpur or Ghaziabad had very poor air quality with smaller population
  due to cities pleased near by industrial zone.  
- As per the 2024 report, Delhi had approximately 33.8 million population with worst annual AQI around 209
*/ 

/* 4. How aware are Indian citizens of what AQI (Air Quality Index) means — and do they 
  understand its health implications? 
- Recent years, the awareness of the Air Quality Index has improved, especially in metro cities such as 
  Delhi, Mumbai and Bangalore. They know of air pollution, but limited aware of detailed understanding of the Air Quality Index 
  and its health implications.   
- Some people in cities like Delhi and Mumbai often check AQI through mobile app or news, but some do not fully understand how different
  AQI levels affect health. 
- The people who come from middle and upper income groups can correctly understand AQI categories like Poor and 
  Hazardous and even fewer take specific precautions like wearing masks. 
- on the other hand, rural communities ans low-income urban area awareness of AQI is very low, they only recognize
  pollution only through visible dust and breathing difficulty. 
*/

/* 5. Which pollution control policies introduced by the Indian government in the past 5 years 
have had the most measurable impact on improving air quality — and how have these impacts varied across regions or cities? 

- The Indian Government introduced various policies in the past 5 years, but there are some key policies that impact 
  more. 
- National Clean Air Programme (NCAP) launched in 2019. The aim of this policy was to reduce PM2.5 and PM10
  by 20-30% by 2024, and by 2026 expected 40%. Recent report of 2024-2025, as compared to 2017-18 PM10 saw reduction
  , mumbai led metros with a 44% drop. Some cities achived dramatic declines like Dhanbad (~81%) and
  Varansi (~68%). 
- Bharat Stage VI Emission Standards (BS-VI)/ Vehicle Policies introdused in April 2020 marked a significant 
  step in curbing vehiular pollition.BS-VI fuel has lower sulpher content and mandates clener engine technology. 
- Another important innovation was the lunch of an Emission Trading Scheme (ETS) in Surat (Gujarat) in patnership 
  with the Gujarat Pollution Control Board (GPCB) and J-PAL South Asia. This market-based approach allowed industries
  to trade emissions permits and proved to be highly cost-effective — reducing particulate pollution by around 20–30% 
  while improving compliance rates. The ETS has since been expanded to Ahmedabad and is being studied for replication 
  in other industrial cities.
*/


-- Extra Details: 
-- 1. Answer Critical Questions: 
-- • Priority Cities: Which Tier 1/2 cities show irreversible AQI degradation? 
-- • Health Burden: How do AQI spikes correlate with pediatric asthma admissions? 
-- • Behavior Shifts: Do pollution emergencies increase purifier searches/purchases? 
-- • Feature Gap: What do existing products lack (e.g., smart AQI syncing, compact designs)? 

-- 2. Deliverables: 
--  Market Prioritization Dashboard with: 
-- ▪ City risk scores (AQI severity × population density × income) 
-- ▪ Health cost impact projections 
-- ▪ Competitor feature gap matrix 
--  Product Requirements Document specifying: 
-- ▪ Must-have features (e.g., PM2.5/VOC sensors) 
-- ▪ Tiered pricing models for target segments 

-- 3. Innovate: 
--  Integrate external data (e.g., Google Trends, crop-burning satellite imagery) 
--  Video must demonstrate dashboard functionality + city-specific entry simulations
