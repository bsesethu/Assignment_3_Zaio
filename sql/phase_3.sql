--Distribution analysis
SELECT * FROM CLEAN.bookings_clean; 
SELECT COUNT(*) FROM CLEAN.bookings_clean;
-- 101452 total rows in the table

SELECT 
	Booking_Value_Distribution,
	COUNT(*) CountValues,
	ROUND(COUNT(*) / 101452.0 * 100, 2) Percentages
FROM (
	SELECT 
		Booking_ID,
		Booking_Value,
		CASE
			WHEN CAST(Booking_Value AS INT) < 100 THEN '<100'
			WHEN CAST(Booking_Value AS INT) BETWEEN 100 AND 199.99 THEN '100 - 199.99'
			WHEN CAST(Booking_Value AS INT) BETWEEN 200 AND 299.99 THEN '200 - 299.99'
			WHEN CAST(Booking_Value AS INT) >= 300 THEN '>=300'
		END Booking_Value_Distribution
	FROM CLEAN.bookings_clean
	)s
GROUP BY Booking_Value_Distribution
ORDER BY CountValues DESC;
	--•	66% of bookings are valued at 300 or more
------------------------------------------------------------------------------------------------------------------------------------

--Categorical analysis
	--Vehicle types and percentages
SELECT
	Vehicle_Type,
	Count_VehicleType,
	ROUND(Count_VehicleType / 101452.0 * 100, 2) Percent_VehicleType
FROM (
	SELECT
		Vehicle_Type,
		COUNT(*) Count_VehicleType
	FROM CLEAN.bookings_clean
	GROUP BY Vehicle_Type
	)r
ORDER BY Count_VehicleType DESC;
	--The Auto vehicle type is the most booked vehicle type

	--Booking status and percentages
	--Not using this query, see line 74
SELECT
	Booking_Status,
	Count_Booking_Status,
	ROUND(Count_Booking_Status / 101452.0 * 100, 2) Percent_VehicleType
FROM (
	SELECT
		Booking_Status,
		COUNT(*) Count_Booking_Status
	FROM CLEAN.bookings_clean
	GROUP BY Booking_Status
	)r
ORDER BY Count_Booking_Status DESC;

	--To gain insightfull information we will use the table RIDE.bookings_raw
	--This approach makes sense as CLEAN.bookings_clean accounts only for completed rides.
	--First drop duplicates in the RIDE_bookings_raw
--DROP TABLE CTAS_raw_Duplicates; --If one needs to drop this table
SELECT 
	*,
	ROW_NUMBER() OVER(PARTITION BY Booking_ID ORDER BY (SELECT NULL)) RowNum
INTO CTAS_raw_Duplicates 
FROM RIDE.bookings_raw
DELETE FROM CTAS_raw_Duplicates
WHERE RowNum > 1;

SELECT * FROM CTAS_raw_Duplicates;

SELECT COUNT(*) FROM CTAS_raw_Duplicates -- 148767 total rows

	--ACTUAL QUERY for Booking status and percentages
SELECT
	Booking_Status,
	Count_Booking_Status,
	ROUND(Count_Booking_Status / 148767.0 * 100, 2) Percent_VehicleType --150000 is the total number of rows in the selected table
FROM (
	SELECT
		Booking_Status,
		COUNT(*) Count_Booking_Status
	FROM CTAS_raw_Duplicates
	GROUP BY Booking_Status
	)r
ORDER BY Count_Booking_Status DESC;
	--most prevalent values in the Booking Status field are Completed at 62% followed by Cancelled by driver at 18%.
-------------------------------------------------------------------------------------------------------------------------------------------

--Relationship analysis
SELECT Ride_Distance, Booking_Value FROM CLEAN.bookings_clean;

	--COUNT
SELECT COUNT(*) FROM CLEAN.bookings_clean; --101452 total rows

	--Create CTAS of Pearson values
--DROP TABLE CTAS_Pearson_Values;
SELECT 
	--SUM(x)
	ROUND(SUM(CAST(Ride_Distance AS FLOAT)), 1) AS Sum_RideDistance, 
	--SUM(y)
	SUM(CAST(Booking_Value AS BIGINT)) AS Sum_BookingValue,
	--SUM(x*y)
	ROUND(SUM(CAST(Ride_Distance AS FLOAT) * CAST(Booking_Value AS INT)), 2) AS Sum_ProdRideXBooking,
	--SUM(x^2)
	ROUND(SUM(POWER(CAST(Ride_Distance AS FLOAT), 2)), 2) AS Sum_RideSquared,
	--SUM(y^2)
	ROUND(SUM(POWER(CAST(Booking_Value AS FLOAT), 2)), 2) AS Sum_BookingSquared
INTO CTAS_Pearson_Values
FROM CLEAN.bookings_clean;

SELECT * FROM CTAS_Pearson_Values;

	--Pearson correlation coeficient
SELECT ROUND(Numerator / (Denominator_1 * Denominator_2), 4) Pearson_correlation_RideDistance_vs_BookingValue
FROM (
	SELECT 
		Sum_ProdRideXBooking - (Sum_RideDistance * Sum_BookingValue) / 148767 Numerator,
		SQRT((Sum_RideSquared) - POWER(Sum_RideDistance, 2) / 148767) Denominator_1, --First Denominator 
		SQRT((Sum_BookingSquared) - POWER(Sum_BookingValue, 2) / 148767) Denominator_2 --Second Denominator
	FROM CTAS_Pearson_Values
	)q;
	--corr= 0.416 is neither high nor low. There is positive correlation, albeit not a strong one.
-----------------------------------------------------------------------------------------------------------------

--Comparitive analysis
SELECT Booking_ID, Payment_Method_Norm, Booking_Value FROM CLEAN.bookings_clean;

SELECT * --Subquery format used to condense the table, make it more readable
FROM (
	SELECT 
		Payment_Method_Norm,
		MIN(CAST(Booking_Value AS INT)) OVER(PARTITION BY Payment_Method_Norm) Min_BookingVal,
		PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY CAST(Booking_Value AS INT)) OVER(PARTITION BY Payment_Method_Norm) Q1_BookingVal,
		PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY CAST(Booking_Value AS INT)) OVER(PARTITION BY Payment_Method_Norm) Q2_BookingVal,
		PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY CAST(Booking_Value AS INT)) OVER(PARTITION BY Payment_Method_Norm) Q3_BookingVal,
		MAX(CAST(Booking_Value AS INT)) OVER(PARTITION BY Payment_Method_Norm) Max_BookingVal
	FROM CLEAN.bookings_clean
	)a
GROUP BY Payment_Method_Norm, Min_BookingVal, Q1_BookingVal, Q2_BookingVal, Q3_BookingVal, Max_BookingVal;
	--The type of payment method used has no bearing on booking value. Regardless of payment method, 
	--the corresponding number summaries are all essentially equal.
--------------------------------------------------------------------------------------------------------------------------------------
