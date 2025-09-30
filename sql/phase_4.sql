--Descriptive statistics
SELECT * FROM CLEAN.bookings_clean;

	--Must use two different queries. One for Median, other for Avg and Std Dev
	--Booking_Value
SELECT *
FROM (
	SELECT 
		PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY CAST(Booking_Value AS INT)) OVER() Median_Booking_Value
	FROM CLEAN.bookings_clean
	)a
GROUP BY Median_Booking_Value --Condensing the table to one row

SELECT 
	AVG(CAST(Booking_Value AS INT)) Mean_Booking_Value,
	ROUND(STDEV(CAST(Booking_Value AS INT)), 1) StdDev_Booking_Value
FROM CLEAN.bookings_clean;

	--Ride_Distance
SELECT *
FROM (
	SELECT 
		PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY CAST(Ride_Distance AS FLOAT)) OVER() Median_Ride_Distance_Value
	FROM CLEAN.bookings_clean
	)b
GROUP BY Median_Ride_Distance_Value

SELECT 
	ROUND(AVG(CAST(Ride_Distance AS FLOAT)), 2) Mean_Ride_Distance,
	ROUND(STDEV(CAST(Ride_Distance AS FLOAT)), 2) StdDev_Ride_Distance
FROM CLEAN.bookings_clean;
	--Result is median, mean and std dev
-----------------------------------------------------------------------------------------------------------------------------

--Correlation analysis
	--From Phase 3 Pearson correlation coeficient
SELECT Numerator / (Denominator_1 * Denominator_2) r
FROM (
	SELECT 
		Sum_ProdRideXBooking - (Sum_RideDistance * Sum_BookingValue) / 148767 Numerator,
		SQRT((Sum_RideSquared) - POWER(Sum_RideDistance, 2) / 148767) Denominator_1, --First Denominator 
		SQRT((Sum_BookingSquared) - POWER(Sum_BookingValue, 2) / 148767) Denominator_2 --Second Denominator
	FROM CTAS_Pearson_Values
	)q;
	--A Pearson correlation of 0.4161, for Ride Distance vs Booking Value. Indicates a modest positive correlation between the two.

	--Using StD and Mean equation to find correlation coefficient
	--It's not working out, rather use the previous method
		--Creating a CTE
WITH Stats AS (
	SELECT
		AVG(CAST(Booking_Value AS FLOAT)) Mean_Booking_Value,
		STDEV(CAST(Booking_Value AS FLOAT)) StdDev_Booking_Value,

		AVG(CAST(Ride_Distance AS FLOAT)) Mean_Ride_Distance,
		STDEV(CAST(Ride_Distance AS FLOAT)) StdDev_Ride_Distance,

		COUNT(*) Count_TotalRows
	FROM CLEAN.bookings_clean
	)
SELECT
	SUM((d.Booking_Value - s.Mean_Booking_Value) * (d.Ride_Distance - s.Mean_Ride_Distance)) / ((1.0/(s.Count_TotalRows)) * s.StdDev_Booking_Value * s.StdDev_Ride_Distance) p
FROM CLEAN.bookings_clean d, Stats s --NOTE We can FROM two diffenrent tables here
GROUP BY Mean_Booking_Value, StdDev_Booking_Value, Mean_Ride_Distance, StdDev_Ride_Distance, Count_TotalRows;
--Correlation coefficient isn't showing up how it should here. Use the previous method
---------------------------------------------------------------------------------------------------------------------

--Outlier detection (IQR)
SELECT TOP 20
	Booking_ID,
	Route,
	Booking_Value
	--Q3_Booking_Value - Q1_Booking_Value IQR_Booking_Value
FROM (
	SELECT 
		Booking_ID,
		CONCAT(Pickup_Location, ' -> ', Drop_Location) Route,
		Booking_Value,
		PERCENTILE_CONT(0.25) WITHIN GROUP(ORDER BY CAST(Booking_Value AS FLOAT)) OVER() Q1_Booking_Value,
		PERCENTILE_CONT(0.75) WITHIN GROUP(ORDER BY CAST(Booking_Value AS FLOAT)) OVER() Q3_Booking_Value
	FROM CLEAN.bookings_clean
	)q
WHERE Booking_Value > Q3_Booking_Value + 1.5 * (Q3_Booking_Value - Q1_Booking_Value)
ORDER BY Booking_Value DESC;
	--3418 total outliers, when 'TOP 20' removed
	--Outliers occure where Booking_Value > Q3 + 1.5*IQR
-----------------------------------------------------------------------------------------------------------------
