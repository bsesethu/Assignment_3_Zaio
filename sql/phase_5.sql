--Operational performance
--Use CTAS_raw_Duplicates table where the cancelled and incomplete data fields are in their original state, less duplicates
SELECT * FROM CTAS_raw_Duplicates; --Entire table. We're using the RIDE.bookings_raw table, with the duplicate rows removed

	--Computing counts for each Vehicle_Type and it's respective Booking_Status
--DROP TABLE CTAS_Vehicle_nBooking_Grouped
SELECT 
	Vehicle_Type,
	Booking_Status,
	Count_Booking_Status
INTO CTAS_Vehicle_nBooking_Grouped --Save CTAS
FROM (
	SELECT
		Vehicle_Type,
		Booking_Status,
		Count(Booking_Status) OVER(PARTITION BY Booking_Status, Vehicle_Type) Count_Booking_Status
	FROM CTAS_raw_Duplicates
	)c
GROUP BY Vehicle_Type, Booking_Status, Count_Booking_Status
ORDER BY Vehicle_Type;

SELECT * FROM CTAS_Vehicle_nBooking_Grouped ORDER BY Vehicle_Type; --Querying the newly created table

	--Must create new columns for Booking_Status counts, from that - compute 'completion rate'
--DROP TABLE CTAS_Vehicle_nBooking_newColumns;
SELECT
	Vehicle_Type,
	Booking_Status,
	Count_Booking_Status,
	CASE WHEN Booking_Status = 'No Driver Found' THEN Count_Booking_Status ELSE NULL END No_Driver_Found,
	CASE WHEN Booking_Status = 'Completed' THEN Count_Booking_Status ELSE NULL END Completed,
	CASE WHEN Booking_Status = 'Incomplete' THEN Count_Booking_Status ELSE NULL END Incomplete,
	CASE WHEN Booking_Status = 'Cancelled by Driver' THEN Count_Booking_Status ELSE NULL END Cancelled_by_Driver,
	CASE WHEN Booking_Status = 'Cancelled by Customer' THEN Count_Booking_Status ELSE NULL END Cancelled_by_Customer
INTO CTAS_Vehicle_nBooking_newColumns
FROM CTAS_Vehicle_nBooking_Grouped
ORDER BY Vehicle_Type;

SELECT * FROM CTAS_Vehicle_nBooking_newColumns;

	--Finally compute Completion rate. Including 'No Driver Found' field/column
SELECT
	Vehicle_Type,
	ROUND(((completed * 1.0) / (completed + no_driver_found + incomplete + cancelled_by_driver + cancelled_by_customer)) * 100, 2) Completion_Rate
FROM (
	SELECT
		Vehicle_Type,
		AVG(No_Driver_Found) OVER(PARTITION BY Vehicle_Type) no_driver_found,
		AVG(Completed) OVER(PARTITION BY Vehicle_Type) completed,
		AVG(Incomplete) OVER(PARTITION BY Vehicle_Type) incomplete,
		AVG(Cancelled_by_Driver) OVER(PARTITION BY Vehicle_Type) cancelled_by_driver,
		AVG(Cancelled_by_Customer) OVER(PARTITION BY Vehicle_Type) cancelled_by_customer
		--There is the same quantity value repeated a couple times in each column corresponding to each vehicle type, so taking the avg just returns that number
	FROM CTAS_Vehicle_nBooking_newColumns
	)v
ORDER BY Completion_Rate DESC;
	--Completion rates are essentially the same across vehicle types
	--Completion rates range between 61% and 62.5%. With Uber XL, marginally having the highest value
-------------------------------------------------------------------------------------------------------------

--Route profitability
		--Not sure which table I should use. CTAS_raw_Duplicates or CLEAN.bookings_clean
		--The one that paints a more informed picture,
		--They both paint the same picture though
	--Top 10 routes by total booking value
SELECT TOP 10
	Route,
	SUM(CAST(Booking_Value AS INT)) Sum_Booking_Value,
	AVG(CAST(Booking_Value AS INT)) Avg_Booking_Value,
	COUNT(*) Ride_Count
FROM (
	SELECT 
		Booking_ID,
		CONCAT(Pickup_Location, ' -> ', Drop_Location) Route,
		Booking_Value
	FROM CLEAN.bookings_clean
	)s
GROUP BY Route
ORDER BY Sum_Booking_Value DESC;
	--Shows the top sum of booking value and top ride count 
	--most profitable route is the New Delhi Railway Station -> Rajouri Garden route
----------------------------------------------------------------------------------------------------------------
--Cancellation forensics

--Use CTAS_raw_Duplicates as we're dealing with cancelled and incomplete rides
	--Handling NULL/blank values for this specific problem
UPDATE CTAS_raw_Duplicates
--SET Reason_for_cancelling_by_Customer = 'Unspecified'
SET Driver_Cancellation_Reason = 'Unspecified'
--WHERE Reason_for_cancelling_by_Customer IS NULL
WHERE Driver_Cancellation_Reason IS NULL; --Comment out this line and do the same for Customer Reason

--Unspecified = 138358 for Reason_for_cancelling_by_Customer. Comment out the WHERE Clause to to find this value
--Unspecified = 121997 for Reason_for_cancelling_by_Customer
SELECT COUNT(*) FROM CTAS_raw_Duplicates;
--Total rows count = 148767
SELECT TOP 5
	Reason_for_cancelling_by_Customer,
	Count_Value,
	ROUND(((CAST(Count_Value AS FLOAT) * 1.0) / (148767 - 138358) * 100), 2) Percentage
FROM (
	SELECT 
		Reason_for_cancelling_by_Customer,
		COUNT(*) OVER(PARTITION BY Reason_for_cancelling_by_Customer) Count_Value
	FROM CTAS_raw_Duplicates
	WHERE Reason_for_cancelling_by_Customer != 'Unspecified' --We don't include unspecified, unspecified may not even mean cancelled rides
	)q
GROUP BY Reason_for_cancelling_by_Customer, Count_Value
ORDER BY Count_Value DESC;

SELECT TOP 5
	Driver_Cancellation_Reason,
	Count_Value,
	ROUND(((CAST(Count_Value AS FLOAT) * 1.0) / (148767 - 121981) * 100), 2) Percentage
FROM (
	SELECT 
		Driver_Cancellation_Reason,
		COUNT(*) OVER(PARTITION BY Driver_Cancellation_Reason) Count_Value
	FROM CTAS_raw_Duplicates
	WHERE Driver_Cancellation_Reason != 'Unspecified' --We don't include unspecified, unspecified may not even mean cancelled rides
	)w
GROUP BY Driver_Cancellation_Reason, Count_Value
ORDER BY Count_Value DESC;
	--In both Customer and Driver tables, there is no one reason that stands out among the rest
-------------------------------------------------------------------------------------------------------------------------------------

--Service levels (Time windows)
SELECT TOP 3
	Hour_Of_Day,
	ROUND(AVG(CAST(Avg_VTAT AS FLOAT)), 1) Avg_Avg_VTAT,
	ROUND(AVG(CAST(Avg_CTAT AS FLOAT)), 1) Avg_Avg_CTAT,
	COUNT(*) Ride_Count
FROM (
	SELECT 
		DATEPART(HOUR, CAST(Date as DATETIME) + CAST(CAST(Time as TIME) as DATETIME)) Hour_Of_Day, --From Part 2, simplified
		Avg_VTAT,
		Avg_CTAT	
	FROM CTAS_raw_Duplicates
	)t
GROUP BY Hour_Of_Day
ORDER BY Ride_Count DESC;
	--Hours 17, 18 and 19 make up the 3 highest ride counts, in comparison to all the other hours of the day.
---------------------------------------------------------------------------------------------------------------------------------------

--Customer cohorts and churn (SQL only)
WITH Customer_Cohort AS ( --CTE
	SELECT
		Customer_ID,
		FORMAT(MIN(pickup_ts), 'yyyy-MM') Cohort_Month,
		MIN(pickup_ts) First_Booking_Date
	FROM CLEAN.bookings_clean
	GROUP BY Customer_ID
	),
Monthly_Activity AS ( --CTE--Map every booking to it's corresponding Booking cohort and mMonth od Activity
	SELECT 
		cc.Customer_ID,
		cc.Cohort_Month,
		FORMAT(bc.pickup_ts, 'yyyy-MM') Activity_Month, --Month of current booking
			--Difference between current month and Cohort month
		DATEDIFF(MONTH, cc.First_Booking_Date, bc.pickup_ts) Month_Index
	FROM CLEAN.bookings_clean bc
	JOIN Customer_Cohort cc
	ON bc.Customer_ID = cc.Customer_ID
	GROUP BY cc.Customer_ID, cc.Cohort_Month, FORMAT(bc.pickup_ts, 'yyyy-MM'), DATEDIFF(MONTH, cc.First_Booking_Date, bc.pickup_ts)
	)
--Calculation of Cohort size and Retention rate
SELECT
	cc.Cohort_Month,
	COUNT(DISTINCT cc.Customer_ID) Cohort_Size,
		--Count customers who made a booking in the next month, where Month_Index = 1
	COUNT(DISTINCT CASE WHEN ma.Month_Index = 1 THEN ma.Customer_ID ELSE NULL END) Retained_Count
		--Maybe calculate retention rate later
FROM Customer_Cohort cc
JOIN Monthly_Activity ma
ON cc.Customer_ID = ma.Customer_ID
GROUP BY cc.Cohort_Month
ORDER BY cc.Cohort_Month
	--We see here that retention counts are very low compared to cohort size. 
	--This is the case with all the Cohort months; it’s certainly a cause for concern.
	
	--Churn risk
SELECT
	Customer_ID,
	Booking_year,
	CASE
		WHEN Booking_year = '2024' THEN 'Loyal' ELSE 'Risk' END Churn_risk
FROM (
	SELECT
		Customer_ID,
		FORMAT(pickup_ts, 'yyyy') Booking_year
	FROM CLEAN.bookings_clean
	WHERE FORMAT(pickup_ts, 'yyyy') = '2023'
	)ch
	--All the values in the dataset are for the year 2024
	------------------------------------------------------------------------------------------------------------------------------------------------------------------------