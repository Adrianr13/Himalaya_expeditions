-----------------------------
--- HIMALAYAN EXPEDITIONS ---
-----------------------------

-- The Himalayan expeditions data contains historical information about expeditions that 
-- have taken place in the Himalayas. The data comes in three tables:
-- 1. Members table: contains information about the expedition members
-- 2. Peaks table: contains information about the peaks in the Himalayas
-- 3. Expeditions table: contains information about the expeditions themselves

-- In this exercise, I'll perform some exploratory data analysis, to see what sort of
-- information we can find. I'll present the main findings in Power BI.

use Himalayan_exp

-- 1. DATA PREPARATION

-- 1.1. SET PRIMARY KEYS 

-- We start off by preparing the data for the subsequent analysis.

-- 1.1.1. Expeditions table

-- Set expedition_id column to not null.

ALTER TABLE expeditions
ALTER COLUMN expedition_id nvarchar(50) NOT NULL;
GO;

-- Search for duplicates.

SELECT expedition_id, COUNT(expedition_id)
FROM expeditions
GROUP BY expedition_id
HAVING COUNT(expedition_id) > 1;
GO

-- Identify duplicates.

SELECT *
FROM expeditions
WHERE expedition_id = 'KANG10101'
GO

-- Delete duplicates.

DELETE 
FROM expeditions
WHERE expedition_id = 'KANG10101' AND year = '1910';
GO;

-- Set primary key to expedition_id column.

ALTER TABLE expeditions
ADD CONSTRAINT PK_expedition_id PRIMARY KEY (expedition_id);
GO;

-- 1.1.2. Members table

-- Set member_id column to not null.
ALTER TABLE members
ALTER COLUMN member_id nvarchar(50) NOT NULL;
GO;

-- Search for duplicates.

SELECT member_id, COUNT(member_id)
FROM members
GROUP BY member_id
HAVING COUNT(member_id) > 1;
GO;

--- Delete duplicates.

DELETE 
FROM members
WHERE expedition_id = 'KANG10101' AND year = '1910'
GO;

--- Set primary key to member_id column.

ALTER TABLE members
ADD CONSTRAINT member_id PRIMARY KEY (member_id);
GO;

-- 1.2. SET FOREIGN KEYS

ALTER TABLE members 
ADD CONSTRAINT FK_expedition_id FOREIGN KEY (expedition_id)
REFERENCES expeditions (expedition_id)
GO;

-- 1.3. SET NULL VALUES --

--- Expeditions table

ALTER TABLE expeditions
ALTER COLUMN termination_date nvarchar(50) NULL;
GO;

ALTER TABLE expeditions
ALTER COLUMN trekking_agency nvarchar(50) NULL;
GO;

UPDATE expeditions
SET termination_date = NULL 
WHERE termination_date = 'NA';
GO;

UPDATE expeditions
SET trekking_agency = NULL
WHERE trekking_agency = 'NA';
GO;

-- 2. ANALYSIS 

-- Now that our data is prepared, we can carry on the analysis. Let's start off by 
-- analyzing the peaks.

-- Summary statistics:

SELECT 
	AVG(height_metres) AS avg_height, 
	MIN(height_metres) AS min_height,
	MAX(height_metres) AS max_height
FROM peaks

-- Peaks range from 5407m to 8850m in height, with an average of 6656m.

-- Out of all peaks, what percentage have been climbed?

SELECT 
	climbing_status, 
	COUNT(*) * 100 / SUM(count(*)) over() 'Percentage'
FROM peaks
GROUP BY climbing_status

-- 72% of peaks registered in the database have been climbed. Out of all these peaks,
-- are there peaks that might be more difficult to climb? 

-- One way to assess this is to calculate how long it takes to climb 
-- each peak, on average. To do this, we need to create a new variable: days 
-- to reach highpoint. This can be computed by taking the difference between 
-- the start date of the expedition (basecamp_date) and the highpoint 
-- date (highpoint_date).

-- Create new variable: Days to reach highpoint.

BEGIN TRANSACTION
ALTER TABLE expeditions 
ADD days_to_highpoint nvarchar(50) NULL;
GO;

UPDATE expeditions 
SET days_to_highpoint = 
	(DATEDIFF(day, basecamp_date, highpoint_date));
COMMIT TRANSACTION;
GO;

ALTER TABLE expeditions
ALTER COLUMN days_to_highpoint int NULL;
GO;

-- We can also calculate how long it takes for each expedition to complete
-- (termination_date - basecamp_date).

-- Create new variable: Days to complete expedition.

BEGIN TRANSACTION;
ALTER TABLE expeditions 
ADD expedition_days nvarchar(50) NULL;
GO
UPDATE expeditions 
SET expedition_days = 
	(DATEDIFF(day, basecamp_date, termination_date));
COMMIT TRANSACTION;

ALTER TABLE expeditions
ALTER COLUMN expedition_days int NULL;
GO;

-- Now that we have created these two variables (days_to_highpoint and expedition_days),
-- we can check which peaks took the most days to reach the highpoint and which
-- took the longest to complete, on average. Let's only consider peaks that have been
-- successfully climbed at least 10 times.

SELECT 
	e.peak_name, 
	p.height_metres,
	count(expedition_id) AS num_of_exp,
	AVG(expedition_days) AS avg_completion_days,
	AVG(days_to_highpoint) AS avg_days_to_highpoint
FROM expeditions AS e
INNER JOIN peaks as p ON e.peak_id = p.peak_id
WHERE termination_reason = 'Success (main peak)' 
GROUP BY e.peak_name, p.height_metres
HAVING count(expedition_id) > 10
ORDER BY avg_completion_days desc;
GO

-- Unsurprisingly, expeditions to Mount Everest, the tallest mountain on Earth, take
-- longest to complete, with an average of 42 days. Expeditions there take on average
-- 37 days to reach the summit.

-- Another way to assess the climbing difficulty for each peak is to count the number
-- of deaths. The more deaths there are, the more difficult an expedition probably is.

-- Top ten deadliest peaks (absolute):

SELECT top(10) peak_name, count(died) AS total_deaths
FROM members
WHERE died = 1
GROUP BY peak_name, died
ORDER BY total_deaths desc;
GO

-- Again, Mt. Everest is the deadliest peak, with 306 recorded deaths in the database.
-- We have to keep in mind though, that many expeditions have taken place there, so it
-- is not surprising that many have died there as well.

-- What were the most common causes of these deaths?

SELECT 
	distinct(death_cause) AS death_cause_type,
	COUNT(*) OVER(PARTITION BY death_cause) AS num_deaths
FROM members
ORDER BY num_deaths desc;

-- Most deaths were a result from avalanches (369 deaths) followed by falls (331 deaths).

-- We can also check the nationalities of the expedition members who lost their lives.

SELECT citizenship, COUNT(*) AS num_deaths
FROM members
WHERE died = 1
GROUP BY citizenship
ORDER BY num_deaths DESC;

-- Most of these expedition members were of Nepalese nationality (315), followed by 
-- Japanese nationals (123), South Koreans (58), French (57) and Americans (46).

-- The ranking of the amount of dead expedition members by nationality probably reflects
-- the total amount of expedition members; that is, we can expect there to be many Nepalese,
-- Japanese, South Koreans and French expeditioners. Let's check this.

-- Count nationalities:

SELECT citizenship, COUNT(*) AS count_nationality
FROM members
GROUP BY citizenship
ORDER BY count_nationality desc;
GO

-- The most common nationalities are Nepalese (16135), Americans (6448), Japanese (6432),
-- British (5218) and French (4611). 

-- How many members are men and women?

SELECT sex, COUNT(*) AS 'count_sex'
FROM members
GROUP BY sex

-- There are almost 10 times as many men (69472) as there are women (7044)

-- We can also check the number of expeditions per year.

-- Number of expeditions per year:
SELECT 
	DISTINCT year,
	COUNT(*) OVER(PARTITION BY year) AS 'expeditions count'
FROM expeditions
ORDER BY 'expeditions count' desc;
GO

-- The years with the most expeditions are more recent years: in 2009, 2011 and 2012,
-- there were 420, 418 and 413 expeditions. We'll later check the number of expeditions
-- per country.

-- We can also check the first time each peak was successfully climbed:

SELECT 
	DISTINCT(peak_name), 
	min(year) OVER(PARTITION BY peak_name) AS first_year_ascent
FROM expeditions
WHERE termination_reason = 'Success (main peak)'
ORDER BY first_year_ascent
GO

-- We can see that in every decade since the 1930s, there has been a new peak that
-- has been climbed successfully for the first time. We can also see that Mt. Everest 
-- was climbed for the first time in 1953. So, which expedition party climbed this peak
-- for the first time?

SELECT 
	p.peak_name, 
	first_ascent_country, 
	first_ascent_expedition_id, 
	first_ascent_year,
	m.sex,
	m.age,
	m.citizenship,
	m.member_id,
	m.expedition_role
FROM peaks as p
INNER JOIN members as m on p.first_ascent_expedition_id = m.expedition_id
WHERE p.peak_name = 'Everest'

-- The resulting table shows the expedition members: all of them were men and of different
-- nationalities (British, New Zealanders, Nepalese and one Indian national). This 
-- expedition was the Ninth British expedition to Everest, with Tenzing Norgay and Edmund
-- Hillary reached the summit on 29 May 1953.


-- 3. VIEWS FOR POWER BI

-- The following views present key findings and are used to create visuals 
-- in Power BI.

-- Nationality table
CREATE VIEW nationality_table AS
SELECT citizenship, COUNT(*) AS count_nationality
FROM members
GROUP BY citizenship;

CREATE VIEW nationality_table2 AS 
SELECT citizenship, count_nationality,
	CASE WHEN (count_nationality < 2500) THEN 'Other'
	ELSE 'top'
END AS category
FROM nationality_table  

-- Top ten deadliest peaks table
CREATE VIEW deadliest_peaks AS
SELECT peak_name, count(died) AS total_deaths
FROM members
WHERE died = 1
GROUP BY peak_name, died;

-- Longest expeditions table
CREATE VIEW longest_expeditions AS
SELECT peak_name, count(expedition_id) AS num_of_exp,
	avg(expedition_days) as avg_completion_days
FROM expeditions
WHERE termination_reason = 'Success (main peak)' 
GROUP BY peak_name
HAVING count(expedition_id) > 10;

-- Number of expeditions per year table
CREATE VIEW expeditions_per_year AS
SELECT 
	DISTINCT year,
	COUNT(*) OVER(PARTITION BY year) AS 'expeditions count'
FROM expeditions;

-- Most common cause of death table
CREATE VIEW death_causes_table AS
SELECT 
	distinct(death_cause) AS death_cause_type,
	COUNT(*) OVER(PARTITION BY death_cause) AS num_deaths
FROM members;

-- Expeditions by country per year
CREATE VIEW exp_countries_per_year AS
SELECT 
	e.year,
	m.expedition_id,
	ROW_NUMBER() OVER(
		PARTITION BY e.expedition_id 
		ORDER BY e.year DESC) AS count,
	m.citizenship AS country
FROM expeditions AS e
INNER JOIN members AS m ON m.expedition_id = e.expedition_id
WHERE 
	expedition_role = 'Leader' OR 
	expedition_role = 'Co-Leader';


------

--SELECT 
--	expedition_id, 
--	member_id, 
--	expedition_role,
--	citizenship,
--	COUNT(*) OVER(PARTITION BY citizenship) AS count
--FROM members
--WHERE 
--	expedition_role = 'Leader' OR 
--	expedition_role = 'Co-Leader'
--ORDER BY count desc