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
