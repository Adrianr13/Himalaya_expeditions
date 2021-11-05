# Exploratory Data Analysis in SQL and Power BI - The Himalayan Database

## Presentation

The Himalayan Database is a compilation of records for all expeditions that have climbed in the Nepal Himalaya. It includes information on the expedition members, information about the peaks in the Himalayas and information about the expeditions themselves. More information can be found [here](https://www.himalayandatabase.com/index.html).

For this analysis, I'll use three databases:

  1. **Members table**: contains information about the expedition members.
  2. **Peaks table**: contains information about the peaks in the Himalayas.
  3. **Expeditions table**: contains information about the expeditions.

In this exercise, I'll perform some exploratory data analysis, to see what sort of information we can find. The main findings are visualized in Power BI.

## 1. Data preparation

### 1.1. Set primary keys

### 1.1.1. Expeditions table

### 1.1.2. Members table

### 1.1.3. Peaks table

### 1.2. Set foreign keys

### 1.3. Set null values

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




### Markdown

Markdown is a lightweight and easy-to-use syntax for styling your writing. It includes conventions for

```markdown
Syntax highlighted code block

# Header 1
## Header 2
### Header 3

- Bulleted
- List

1. Numbered
2. List

**Bold** and _Italic_ and `Code` text

[Link](url) and ![Image](src)
```

For more details see [GitHub Flavored Markdown](https://guides.github.com/features/mastering-markdown/).

### Jekyll Themes

Your Pages site will use the layout and styles from the Jekyll theme you have selected in your [repository settings](https://github.com/Adrianr13/Himalaya_expeditions/settings/pages). The name of this theme is saved in the Jekyll `_config.yml` configuration file.



<iframe width="1140" height="541.25" src="https://app.powerbi.com/reportEmbed?reportId=48ab6dec-1ec9-4f05-be21-384bfcf86ab9&autoAuth=true&ctid=6b0b7df3-2a59-4305-9076-be80608111d9&config=eyJjbHVzdGVyVXJsIjoiaHR0cHM6Ly93YWJpLXBhYXMtMS1zY3VzLXJlZGlyZWN0LmFuYWx5c2lzLndpbmRvd3MubmV0LyJ9" frameborder="0" allowFullScreen="true"></iframe>
