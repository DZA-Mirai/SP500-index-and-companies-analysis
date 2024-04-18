SELECT *
FROM [s&p_project].[dbo].[s&p500_Historical_Data]

--ALTER TABLE [s&p_project].[dbo].[s&p500_Historical_Data]
--ADD DateConverted DATE

--UPDATE [s&p_project].[dbo].[s&p500_Historical_Data]
--SET DateConverted = CONVERT(Date, [Date])

-- The First Look at the data
SELECT YEAR(DateConverted) AS [Year], MIN(Price) AS Min_price, MAX(Price) AS Max_price, AVG(Price) AS Avg_price
FROM [s&p_project]..[s&p500_Historical_Data]
GROUP BY YEAR(DateConverted)
ORDER BY [Year] DESC


-- Average Price by Years Periods
WITH Avg_Change_by_Years AS(
SELECT YEAR(DateConverted) AS [Year], MIN(Price) AS Min_price, MAX(Price) AS Max_price, AVG(Price) AS Avg_price,
	   LAG(AVG(Price)) OVER(ORDER BY YEAR(DateConverted)) AS Prev_avg_price,
	   LAG(AVG(Price), 5) OVER(ORDER BY YEAR(DateConverted)) AS Prev_5Year,
	   LAG(AVG(Price), 10) OVER(ORDER BY YEAR(DateConverted)) AS Prev_10Year
FROM [s&p_project]..[s&p500_Historical_Data]
GROUP BY YEAR(DateConverted)
	)
SELECT [Year], Avg_Price,
	   IIF([Year] = 1980, NULL, ROUND((Avg_price / Prev_avg_price)-1, 4)) AS Year_Change,
	   IIF([Year] < 1985, NULL, ROUND(POWER((Avg_price / Prev_5Year), 1.0/5.0)-1, 4)) AS Annually_Growth_5Year,
	   IIF([Year] < 1990, NULL, ROUND(POWER((Avg_price / Prev_10Year), 1.0/10.0)-1, 4)) AS Annually_Growth_10Year
FROM Avg_Change_by_Years
ORDER BY [Year]


-- Closing Date Change by Years Periods
WITH Closing_Change AS(
SELECT DateConverted, Price, LAG(Price) OVER(ORDER BY DateConverted) AS Prev_year,
	   LAG(Price, 5) OVER(ORDER BY DateConverted) AS Prev_5year,
	   LAG(Price, 10) OVER(ORDER BY DateConverted) AS Prev_10year
FROM [s&p_project]..[s&p500_Historical_Data]
WHERE DateConverted IN (
		SELECT MAX(DateConverted)
		FROM [s&p_project]..[s&p500_Historical_Data]
		GROUP BY YEAR(DateConverted)
		)
)
SELECT YEAR(DateConverted) AS [Year], Price,
	   IIF(YEAR(DateConverted) = 1980, NULL, ROUND((Price / Prev_year) - 1, 4)) AS Year_change,
	   IIF(YEAR(DateConverted) < 1985, NULL, ROUND(POWER((Price / Prev_5year), 1.0/5.0) - 1, 4)) AS Annually_Growth_5Year,
	   IIF(YEAR(DateConverted) < 1990, NULL, ROUND(POWER((Price / Prev_10year), 1.0/10.0) - 1, 4)) AS Annually_Growth_10Year
FROM Closing_Change
ORDER BY [Year]