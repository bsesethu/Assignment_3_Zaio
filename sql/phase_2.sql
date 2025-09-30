--Duplicate Analysis
--DROP TABLE CTAS_Duplicates;
SELECT 
	*,
	ROW_NUMBER() OVER(PARTITION BY Booking_ID ORDER BY (SELECT NULL)) RowNum
INTO CTAS_Duplicates
FROM CLEAN.bookings
DELETE FROM CTAS_Duplicates
WHERE RowNum > 1;
    --Keeping the earliest (Date, time) Later

SELECT COUNT(*) FROM CTAS_Duplicates; --Total rows 101452

SELECT COUNT(*) Count_TotalRows FROM CLEAN.bookings --Check duplicates in Booking_ID -- 102000 rows

	--Show counts removed
SELECT 
	COUNT(*) Num_Rows_After_DropDuplicates,
	(102000 - COUNT(*)) Num_Rows_Dropped
FROM CTAS_Duplicates;

    --Add Primary key, now that duplicates in Booking_ID have been removed
------------------------------------------------------------------------------------------------

--Feature Engineering
--DROP TABLE booking_holding;
	--Derive Day_of_week and Hour of day
SELECT 
	DATENAME(WEEKDAY, pickup_ts) Day_Of_Week,
	DATEPART(HOUR, pickup_ts) Hour_Of_Day,
	*
INTO booking_holding --Placeholder CTAS
FROM (
	SELECT 
	CAST(Date as DATETIME) + CAST(CAST(Time as TIME) as DATETIME) pickup_ts,
	*
	FROM CTAS_Duplicates
	)p;

SELECT * FROM booking_holding;

	--Create route as Pickup location to Drop location
    --And -Normalize payment method to upper case
    --Then create new table 'bookings_clean' as per the Task
--DROP TABLE CLEAN.bookings_clean
SELECT 
       [Booking_ID]
      ,[pickup_ts]
      ,[Day_Of_Week]
      ,[Hour_Of_Day]
      ,[Date]
      ,[Time]
      ,[Booking_Status]
      ,[Customer_ID]
      ,[Vehicle_Type]
      ,[Pickup_Location]
      ,[Drop_Location]
	  ,CONCAT(Pickup_Location, ' -> ', Drop_Location) Route
      ,[Avg_VTAT]
      ,[Avg_CTAT]
      ,[Cancelled_Rides_by_Customer]
      ,[Reason_for_cancelling_by_Customer]
      ,[Cancelled_Rides_by_Driver]
      ,[Driver_Cancellation_Reason]
      ,[Incomplete_Rides]
      ,[Incomplete_Rides_Reason]
      ,[Booking_Value]
      ,[Ride_Distance]
      ,[Driver_Ratings]
      ,[Customer_Rating]
      ,UPPER(REPLACE(Payment_Method, ' ', '')) Payment_Method_Norm --Normalize payment method to upper case
INTO CLEAN.bookings_clean
FROM booking_holding;

SELECT * FROM CLEAN.bookings_clean
------------------------------------------------------------------------------------------------

--Task: Done in the previous Query.
