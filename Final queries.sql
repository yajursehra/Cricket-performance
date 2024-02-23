-- DATA MANAGEMENT SQL QUERIES
-- YAJUR SEHRA

#QUES 1
# Find the top 3 players with the most runs scored in ODIs in the year 2019 before world cup, 
# including the number of matches they played and their average score per match
SELECT 
    Batsman,
    COUNT(Match_ID) AS Matches_Played,
    SUM(Runs) AS Total_Runs,
    ROUND(AVG(Runs),2) AS Average_Score
FROM 
    Batsman_Data
JOIN 
    WC_Players ON Batsman_Data.Player_ID = WC_Players.ID
where Start_Date LIKE '%-19%'
GROUP BY 
    Batsman
ORDER BY 
    Total_Runs DESC
LIMIT 3;

#QUES 2
# Calculate the bowling economy rate of each player across all matches played, 
# and ranking them for each country, minimum 200 overs bowled.
SELECT 
    DISTINCT Bowler_Data.Bowler,
    WC_Players.Country,
    ROUND(Avg(Bowler_Data.Econ),2) AS Economy,
    DENSE_RANK() OVER (PARTITION BY Country ORDER BY Avg(Bowler_Data.Econ)) AS Rank_In_Country
FROM 
    Bowler_Data
JOIN 
    WC_Players ON Bowler_Data.Player_ID = WC_Players.ID
GROUP BY 
    Bowler_Data.Bowler, WC_Players.Country
HAVING 
    Avg(Bowler_Data.Econ) > 0 and SUM(Bowler_Data.Overs) > 200;

#QUES 3
# Which 5 players have the highest average number of runs in 
# matches where their team lost, using data from the last 5 years?
SELECT 
    Batsman,
    wp.Country,
    Round(AVG(Runs),2) AS Average_Runs
FROM 
    Batsman_Data AS bd
INNER JOIN 
    WC_Players AS wp ON bd.Player_ID = wp.ID
INNER JOIN 
    ODI_Match_Results AS mr ON bd.Match_ID = mr.Match_ID and bd.Opposition = mr.Opposition
WHERE 
    mr.Result = 'lost' 
    AND ( bd.Start_Date LIKE '%-19%' 
		or bd.Start_Date LIKE '%-18%' 
        or bd.Start_Date LIKE '%-17%' 
        or bd.Start_Date LIKE '%-16%' 
        or bd.Start_Date LIKE '%-15%')
GROUP BY 
    Batsman, wp.Country
ORDER BY 
    Average_Runs DESC
LIMIT 5;

#QUES 4
#What is the win percentage for each country in ODIs when a specific player scored a century (100 or more runs)?
WITH Century_Matches AS (
    SELECT 
        Match_ID, 
        Batsman, Opposition 
    FROM 
        Batsman_Data
    WHERE 
        Runs >= 100 )
SELECT 
    mr.Country,
    COUNT(mr.Match_ID) AS Matches_Won,
    (COUNT(mr.Match_ID) * 100.0) / (SELECT COUNT(*) FROM Century_Matches) AS Win_Percentage
FROM 
    ODI_Match_Results AS mr
JOIN 
    Century_Matches AS cm ON mr.Match_ID = cm.Match_ID and cm.Opposition = mr.Opposition
WHERE 
    mr.Result = 'won'
GROUP BY 
    mr.Country;

#QUES 5
#Determine the player with the most consistent batting performance, 
#defined by the smallest standard deviation in runs scored over the past 3 years along with boundaries.
SELECT 
    Batsman, sum(4s) Fours, sum(6s) Sixes,
    ROUND(STDDEV(Runs),2) AS Std_Deviation
FROM 
    Batsman_Data bd
WHERE 
	bd.Start_Date LIKE '%-19%' 
		or bd.Start_Date LIKE '%-18%' 
        or bd.Start_Date LIKE '%-17%' 
GROUP BY 
     Batsman
HAVING 
 SUM(Runs) > 1200
ORDER BY 
    Std_Deviation ASC;

#QUES 6
#Which players have improved their batting average the most over their last 5 innings compared to their first 5 innings?

WITH FirstFiveInnings AS (
    SELECT 
        Player_ID,
        AVG(Runs) AS Average_First_Five
    FROM (
        SELECT 
            Player_ID,
            Runs,
            ROW_NUMBER() OVER (PARTITION BY Player_ID ORDER BY Start_Date) AS RowNum
        FROM 
            Batsman_Data
    ) AS EarlyMatches
    WHERE 
        RowNum <= 5
    GROUP BY 
        Player_ID
), LastFiveInnings AS (
    SELECT 
        Player_ID,
        AVG(Runs) AS Average_Last_Five
    FROM (
        SELECT 
            Player_ID,
            Runs,
            ROW_NUMBER() OVER (PARTITION BY Player_ID ORDER BY Start_Date DESC) AS RowNum
        FROM 
            Batsman_Data
    ) AS RecentMatches
    WHERE 
        RowNum <= 5
    GROUP BY 
        Player_ID
)

SELECT 
    wp.Player,
    round((lf.Average_Last_Five - ff.Average_First_Five),2) AS Improvement
FROM 
    FirstFiveInnings ff
JOIN 
    LastFiveInnings lf ON ff.Player_ID = lf.Player_ID
JOIN 
    WC_Players wp ON ff.Player_ID = wp.ID
WHERE 
    lf.Average_Last_Five > ff.Average_First_Five
ORDER BY 
    Improvement DESC;
    
#QUES 7
#Who is the most economical bowler (minimum 10 overs bowled) in matches where the total score was above 300?
SELECT
    WC_Players.Player,
    SUM(Bowler_Data.Runs) / SUM(Bowler_Data.Overs) AS Economy_Rate,
    ROUND(SUM(Bowler_Data.Overs),2) AS Total_Overs
FROM
    Bowler_Data
JOIN
    WC_Players ON Bowler_Data.Player_ID = WC_Players.ID
JOIN
    ODI_Match_Totals ON Bowler_Data.Match_ID = ODI_Match_Totals.Match_ID
WHERE
    ODI_Match_Totals.Score > 300
GROUP BY
    WC_Players.Player
HAVING
    SUM(Bowler_Data.Overs) >= 10
ORDER BY
    Economy_Rate ASC
LIMIT 3;

#QUES 8
#Which batsman has the highest average in winning matches for their country?
SELECT 
    WC_Players.Player,
    WC_Players.Country,
    Round(AVG(Batsman_Data.Runs),2) AS Batting_Average
FROM 
    Batsman_Data
JOIN 
    WC_Players ON Batsman_Data.Player_ID = WC_Players.ID
JOIN 
    ODI_Match_Results ON Batsman_Data.Match_ID = ODI_Match_Results.Match_ID
WHERE 
    ODI_Match_Results.Result = 'won'
GROUP BY 
    1,2
ORDER BY 
    Batting_Average DESC
LIMIT 5;

