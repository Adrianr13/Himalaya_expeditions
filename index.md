# Exploratory Data Analysis in SQL and Power BI - The Himalayan Database

## Presentation

The Himalayan Database is a compilation of records for all expeditions that have climbed in the Nepal Himalaya. It includes information on the expedition members, information about the peaks in the Himalayas and information about the expeditions themselves. More information can be found [here](https://www.himalayandatabase.com/index.html).

For this analysis, I'll use three databases:

  1. **Members table**: contains information about the expedition members.
  2. **Peaks table**: contains information about the peaks in the Himalayas.
  3. **Expeditions table**: contains information about the expeditions.

In this exercise, I'll perform some exploratory data analysis, to see what sort of information we can find. The main findings are visualized in Power BI [below](#4-data-visualization-in-power-bi) (you must be signed in to view the report). Click [here](https://github.com/Adrianr13/Himalaya_expeditions/blob/db2bf6cdc5e74dd9bca46430a61285607b5b0e85/Himalaya%20expeditions.pdf) for a static version of the report.

## 1. Data preparation

Before actually analyzing the data, we have to make sure that the data we're working with is properly cleaned and prepared.

### 1.1. Set primary keys

We start off by setting the primary keys for all three tables. We have to make sure that the primary key uniquely identifies each observation; no duplicates are allowed in the primary key column.

### 1.1.1. Expeditions table

```
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
```

### 1.1.2. Members table

```
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
```

### 1.1.3. Peaks table

```
ALTER TABLE peaks
ADD CONSTRAINT peak_id PRIMARY KEY (peak_id);
```

### 1.2. Set foreign keys

```
ALTER TABLE members 
ADD CONSTRAINT FK_expedition_id FOREIGN KEY (expedition_id)
REFERENCES expeditions (expedition_id)
GO;
```

### 1.3. Set null values

Some columns contain null values that SQLSERVER does not recognize as such. In this case, those values (NA's) must be explicitly idientified as null values. Addiotionally, we must make some columns nullable.

```
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
```

## 2. Analysis

Now that our data is prepared, we can start analyzing the data. Let's start off by analyzing the peaks.

```markdown
-- Summary statistics

SELECT 
	AVG(height_metres) AS avg_height, 
	MIN(height_metres) AS min_height,
	MAX(height_metres) AS max_height
FROM peaks
```

![image](https://user-images.githubusercontent.com/67914619/140496244-5c834583-664e-4a61-ba72-22e20255cfa8.png)

Peaks range from 5407m to 8850m in height, with an average of 6656m. What percentage of these peaks have been climbed?

```markdown
SELECT 
	climbing_status, 
	COUNT(*) * 100 / SUM(count(*)) over() 'Percentage'
FROM peaks
GROUP BY climbing_status
```

![image](https://user-images.githubusercontent.com/67914619/140526874-df4ffb5a-3bc0-4fea-8196-9d013695ab89.png)

72% of peaks in the database have been climbed. It's likely that some of these peaks are more difficult to climb than others. One way to assess this is to calculate how long it takes to climb each peak, on average. To do this, we need to create a new variable: days to reach highpoint. This can be computed by taking the difference between the start date of the expedition (basecamp_date) and the date when the expedition reaches the summit (highpoint_date).

```markdown
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
```

We can also calculate how long it takes for each expedition to complete. This is simply the difference between the `termination_date` and the `basecamp_date` variables.

```markdown
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
```

Now that we have created these two variables (days_to_highpoint and expedition_days), we can check which peaks took the most days to reach the highpoint and which took the longest to complete, on average. Let's only consider peaks that have been successfully climbed at least 10 times.

```markdown
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
```

![image](https://user-images.githubusercontent.com/67914619/140531267-8bdbb693-7feb-47b9-ade8-c468a889accc.png)


Unsurprisingly, expeditions to Mount Everest, the tallest mountain on Earth, take longest to complete, with an average of 42 days. Expeditions there take on average 37 days to reach the summit.

Another way to assess the climbing difficulty for each peak is to count the number of deaths. The more deaths there are, the more difficult an expedition probably is.

```markdowns
SELECT top(10) peak_name, count(died) AS total_deaths
FROM members
WHERE died = 1
GROUP BY peak_name, died
ORDER BY total_deaths desc;
GO
```

![image](https://user-images.githubusercontent.com/67914619/140531463-67f504c0-a892-44cc-90e5-951104e443c0.png)

Again, Mt. Everest is the deadliest peak, with 306 recorded deaths in the database. We have to keep in mind though, that many expeditions have taken place there, so it is not surprising that many have died there as well.

What were the most common causes of these deaths?

```markdowns
SELECT 
	distinct(death_cause) AS death_cause_type,
	COUNT(*) OVER(PARTITION BY death_cause) AS num_deaths
FROM members
ORDER BY num_deaths desc;
```

![image](https://user-images.githubusercontent.com/67914619/140531606-0651b56f-4a44-4785-b812-aacf04b451e9.png)

Most deaths were a result from avalanches (369 deaths) followed by falls (331 deaths) (NAs are missing values). We can also check the nationalities of the expedition members who lost their lives.

```
SELECT citizenship, COUNT(*) AS num_deaths
FROM members
WHERE died = 1
GROUP BY citizenship
ORDER BY num_deaths DESC;
```

![image](https://user-images.githubusercontent.com/67914619/140533376-4a3ebe33-000f-4890-b3fd-a894c6ae1eda.png)

Most of these expedition members were of Nepalese nationality (315), followed by Japanese nationals (123), South Koreans (58), French (57) and Americans (46). The ranking of the amount of dead expedition members by nationality probably reflects the total amount of expedition members; that is, we can expect there to be many Nepalese, Japanese, South Korean and French expeditioners. Let's check this.

```
SELECT citizenship, COUNT(*) AS count_nationality
FROM members
GROUP BY citizenship
ORDER BY count_nationality desc;
GO
```

![image](https://user-images.githubusercontent.com/67914619/140534166-e34f0f40-37ca-44a1-84f9-4a76b004733d.png)

The most common nationalities are Nepalese (16135), Americans (6448), Japanese (6432), British (5218) and French (4611). What about the sex of expedition members?

```
SELECT sex, COUNT(*) AS 'count_sex'
FROM members
GROUP BY sex
```

![image](https://user-images.githubusercontent.com/67914619/140641358-7a5abab9-227d-4276-bf49-496edaef274d.png)


There are almost 10 times as many men (69472) as there are women (7044). We can also check the number of expeditions per year.

```
SELECT 
	DISTINCT year,
	COUNT(*) OVER(PARTITION BY year) AS 'expeditions count'
FROM expeditions
ORDER BY 'expeditions count' desc;
GO
```

![image](https://user-images.githubusercontent.com/67914619/140641348-4c7e30d5-fca1-42cc-bb30-63fc8b02b601.png)

The years with the most expeditions are more recent years: in 2009, 2011 and 2012, there were 420, 418 and 413 expeditions. We'll later check the number of expeditions per country.

Lastly, we can check the first time each peak was successfully climbed.

```
SELECT 
	DISTINCT(peak_name), 
	min(year) OVER(PARTITION BY peak_name) AS first_year_ascent
FROM expeditions
WHERE termination_reason = 'Success (main peak)'
ORDER BY first_year_ascent
GO
```

![image](https://user-images.githubusercontent.com/67914619/140641330-4b8b0117-071a-486d-a17c-41f593bc428e.png)

We can see that in every decade since the 1930s, there has been a new peak that has been climbed successfully for the first time. We can also see that Mt. Everest was climbed for the first time in 1953. Which expedition party climbed this peak for the first time?

```
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
```

![image](https://user-images.githubusercontent.com/67914619/140641313-a22f0213-1f00-4f62-b8df-67b7748327d9.png)

The resulting table shows the expedition members: all of them were men and of different nationalities (British, New Zealanders, Nepalese and one Indian national). This expedition was the Ninth British expedition to Everest, with Tenzing Norgay and Edmund Hillary reaching the summit on May 29th, 1953.

## 3. Views

This section provides the code used to create the views which are correspondingly used to visualize the data in Power BI. 

```
-- Nationality table

CREATE VIEW nationality_table AS
SELECT citizenship, COUNT(*) AS count_nationality
FROM members
GROUP BY citizenship;

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
```

## 4. Data visualization in Power BI

<iframe width="1140" height="541.25" src="https://app.powerbi.com/reportEmbed?reportId=48ab6dec-1ec9-4f05-be21-384bfcf86ab9&autoAuth=true&ctid=6b0b7df3-2a59-4305-9076-be80608111d9&config=eyJjbHVzdGVyVXJsIjoiaHR0cHM6Ly93YWJpLXBhYXMtMS1zY3VzLXJlZGlyZWN0LmFuYWx5c2lzLndpbmRvd3MubmV0LyJ9" frameborder="0" allowFullScreen="true"></iframe>
