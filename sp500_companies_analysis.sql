SELECT TOP (1000) [Date]
      ,[Symbol]
      ,[Adj Close]
      ,[Close]
      ,[High]
      ,[Low]
      ,[Open]
      ,[Volume]
  FROM [s&p_project].[dbo].[sp500_stocks]
  WHERE [Date] = (SELECT MAX([Date]) FROM [s&p_project].[dbo].[sp500_stocks])

--ALTER TABLE [s&p_project].[dbo].[sp500_stocks]
--ALTER COLUMN [Date] date

--ALTER TABLE [s&p_project].[dbo].[sp500_stocks]
--ALTER COLUMN [Close] float

--ALTER TABLE [s&p_project].[dbo].[sp500_stocks]
--ALTER COLUMN [Volume] float

-- The First look at the data
SELECT YEAR([Date]) [Year], Symbol, MIN([Close]) Min_val, MAX([Close]) Max_val, AVG([Close]) Avg_val, STDEV([Close]) Stand_dev
FROM [s&p_project]..sp500_stocks
WHERE [Close] <> 0 AND Symbol = 'AAPL'
GROUP BY YEAR([Date]), Symbol
ORDER BY [Year]

SELECT YEAR([Date]) [Year], MONTH([Date]) [Month], Symbol, MIN([Close]) Min_val, MAX([Close]) Max_val,
	   AVG([Close]) Avg_val, STDEV([Close]) Stand_dev
FROM [s&p_project]..sp500_stocks
WHERE [Close] <> 0 AND Symbol = 'META'
GROUP BY YEAR([Date]), MONTH([Date]), Symbol
ORDER BY [Year], [Month]

-- How many nulls in each year
SELECT YEAR([Date]), COUNT([Close])
FROM [s&p_project]..sp500_stocks
WHERE [Close] = 0
GROUP BY YEAR([Date])

-- Which Companies have nulls in data (It means they were added to index after 2010)
SELECT DISTINCT Symbol
FROM [s&p_project]..sp500_stocks
WHERE [Close] = 0


-- Closing Date Scenario. This Temp Table will be used for creating 6 tables (TOP 100 and TOP 50 year to year change,
-- 5 year change and 10 year change)
DROP TABLE IF EXISTS #Closing_by_Years;
WITH Closing_Change AS(
SELECT [Date], Symbol, [Close], LAG([Close]) OVER(ORDER BY Symbol, [Date]) AS Prev_Year,
	   LAG([Close], 5) OVER(ORDER BY Symbol, [Date]) AS Prev_5Year,
	   LAG([Close], 10) OVER(ORDER BY Symbol, [Date]) AS Prev_10Year
FROM [s&p_project]..sp500_stocks
WHERE [Date] IN (
		SELECT MAX([Date])
		FROM [s&p_project]..sp500_stocks
		GROUP BY YEAR([Date])
		)
		AND [Close] <> 0
)
SELECT YEAR([Date]) AS [Year], Symbol, [Close], Prev_Year, Prev_5Year, Prev_10Year,
	   IIF(YEAR([Date]) = 2010, NULL, ROUND(([Close]/Prev_Year) - 1, 4)) AS Year_Change,
	   IIF(YEAR([Date]) < 2015, NULL, ROUND(([Close]/Prev_5Year) - 1, 4)) AS [5Year_Change],
	   IIF(YEAR([Date]) < 2020, NULL, ROUND(([Close]/Prev_10Year) - 1, 4)) AS [10Year_Change],
	   ROW_NUMBER() OVER(PARTITION BY YEAR([Date]) ORDER BY [Close]/Prev_Year DESC) AS Year_Rank,
	   ROW_NUMBER() OVER(PARTITION BY YEAR([Date]) ORDER BY [Close]/Prev_5Year DESC) AS [5Year_Rank],
	   ROW_NUMBER() OVER(PARTITION BY YEAR([Date]) ORDER BY [Close]/Prev_10Year DESC) AS [10Year_Rank]
INTO #Closing_by_Years
FROM Closing_Change
--WHERE Symbol = 'AAPL'
ORDER BY [Year], [5Year_Change] DESC;



DROP TABLE IF EXISTS #Year_Change_Top100;
WITH Annually_Change AS(
SELECT [Year], Symbol, [Close], Prev_Year, Year_Change, Year_Rank
FROM #Closing_by_Years
WHERE Year_Rank <= 100
)
SELECT [Year], AVG(Year_Change) AS Year_Change_100
INTO #Year_Change_Top100
FROM Annually_Change
GROUP BY [Year]
ORDER BY [Year];


DROP TABLE IF EXISTS #Year_Change_Top50;
WITH Annually_Change AS(
SELECT [Year], Symbol, [Close], Year_Change, Year_Rank
FROM #Closing_by_Years
WHERE Year_Rank <= 50
)
SELECT [Year], AVG(Year_Change) AS Year_Change_50
INTO #Year_Change_Top50
FROM Annually_Change
GROUP BY [Year]
ORDER BY [Year];


DROP TABLE IF EXISTS #5Year_Change_Top100;
WITH Annually_Change AS(
SELECT [Year], Symbol, [Close], [5Year_Change], [5Year_Rank],
	   IIF([5Year_Change] IS NULL, NULL, POWER([5Year_Change] + 1, 1.0 / 5.0) - 1) AS Annually_5Year
FROM #Closing_by_Years
WHERE [5Year_Rank] <= 100
)
SELECT [Year], AVG([5Year_Change]) AS [5Year_Change_100], AVG(Annually_5Year) AS Annually_5Year_100
INTO #5Year_Change_Top100
FROM Annually_Change
GROUP BY [Year]
ORDER BY [Year];


DROP TABLE IF EXISTS #5Year_Change_Top50;
WITH Annually_Change AS(
SELECT [Year], Symbol, [Close], [5Year_Change], [5Year_Rank],
	   IIF([5Year_Change] IS NULL, NULL, POWER([5Year_Change] + 1, 1.0 / 5.0) - 1) AS Annually_5Year
FROM #Closing_by_Years
WHERE [5Year_Rank] <= 50
)
SELECT [Year], AVG([5Year_Change]) AS [5Year_Change_50], AVG(Annually_5Year) AS Annually_5Year_50
INTO #5Year_Change_Top50
FROM Annually_Change
GROUP BY [Year]
ORDER BY [Year];


DROP TABLE IF EXISTS #10Year_Change_Top100;
WITH Annually_Change AS(
SELECT [Year], Symbol, [Close], [10Year_Change], [10Year_Rank],
	   IIF([10Year_Change] IS NULL, NULL, POWER([10Year_Change] + 1, 1.0 / 10.0) - 1) AS Annually_10Year
FROM #Closing_by_Years
WHERE [10Year_Rank] <= 100
)
SELECT [Year], AVG([10Year_Change]) AS [10Year_Change_100], AVG(Annually_10Year) AS Annually_10Year_100
INTO #10Year_Change_Top100
FROM Annually_Change
GROUP BY [Year]
ORDER BY [Year];


DROP TABLE IF EXISTS #10Year_Change_Top50;
WITH Annually_Change AS(
SELECT [Year], Symbol, [Close], [10Year_Change], [10Year_Rank],
	   IIF([10Year_Change] IS NULL, NULL, POWER([10Year_Change] + 1, 1.0 / 10.0) - 1) AS Annually_10Year
FROM #Closing_by_Years
WHERE [10Year_Rank] <= 50
)
SELECT [Year], AVG([10Year_Change]) AS [10Year_Change_50], AVG(Annually_10Year) AS Annually_10Year_50
INTO #10Year_Change_Top50
FROM Annually_Change
GROUP BY [Year]
ORDER BY [Year];


-- Final Table for Visualization 
SELECT yc100.[Year], Year_Change_100, Year_Change_50, Annually_5Year_100, Annually_5Year_50, Annually_10Year_100, Annually_10Year_50
FROM #Year_Change_Top100 yc100
JOIN #Year_Change_Top50 yc50
	ON yc100.Year = yc50.Year
JOIN #5Year_Change_Top100 [5yc100]
	ON [5yc100].Year = yc50.Year
JOIN #5Year_Change_Top50 [5yc50]
	ON [5yc50].Year = yc50.Year
JOIN #10Year_Change_Top100 [10yc100]
	ON [10yc100].Year = yc50.Year
JOIN #10Year_Change_Top50 [10yc50]
	ON [10yc50].Year = yc50.Year
ORDER BY yc100.[Year]




-- Volume Traded. Find the most liquid assets in stocks.
WITH Volume_Traded AS(
SELECT YEAR([Date]) AS [Year], Symbol, AVG(Volume) AS Avg_stocks_traded,
	   LAG(AVG(Volume)) OVER(ORDER BY Symbol, YEAR([Date])) AS Prev_Year,
	   ROW_NUMBER() OVER(PARTITION BY YEAR([Date]) ORDER BY AVG(Volume) DESC) AS [Rank]
FROM [s&p_project]..sp500_stocks
WHERE Volume <> 0
GROUP BY YEAR([Date]), Symbol
--ORDER BY [Year], Avg_stocks_traded DESC
)
SELECT [Year], Symbol, Avg_stocks_traded, IIF([Year] = 2010, NULL, ROUND((Avg_stocks_traded / Prev_Year) - 1, 4)) AS Year_Change
FROM Volume_Traded
WHERE [Rank] <= 100
ORDER BY [Year], Avg_stocks_traded DESC