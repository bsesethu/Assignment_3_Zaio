--CREATE DATABASE Ride_booking;
USE Ride_booking;
--CREATE SCHEMA RIDE;

SELECT * FROM Ride.Bookings_raw;

--DROP TABLE Ride.booking_raw --If one needs to drop this table

	--This isn't actually ever used, a CTAS with the same schema and name: bookings_clean is created at a later stage
CREATE TABLE CLEAN.bookings(
	Date DATE,
	Time TIME,
	Booking_ID NVARCHAR(30) PRIMARY KEY,
	Booking_Status VARCHAR(30),
	Customer_ID NVARCHAR(30),
	Vehicle_Type VARCHAR(30),
	Pickup_Location VARCHAR(100),
	Drop_Location VARCHAR(100),
	Avg_VTAT DECIMAL(6, 2),
	Avg_CTAT DECIMAL(6, 2),
	Cancelled_by_Customer INT,
	Cancel_Reason_Customer VARCHAR(200),
	Cancelled_By_Driver INT,
	Cancel_Reason_Driver VARCHAR(200),
	Incomplete_Rides INT,
	Incomplete_Rides_Reason VARCHAR(200),
	Booking_Value DECIMAL(10, 2),
	Ride_Distance DECIMAL(8, 2),
	Driver_Ratings DECIMAL(3, 2),
	Customer_Rating DECIMAL(3, 2),
	Payment_Method VARCHAR(30)
	);

DROP TABLE CLEAN.bookings;

CREATE SCHEMA CLEAN;

EXEC sp_rename 'Ride.Bookings_raw', 'Ride.bookings_raw'; --Renaming the table

EXEC sp_rename '[RIDE].[Ride.bookings_raw]', 'bookings_raw'; --Getting rid of RIDE.RIDE...
-----------------------------------------------------------------------------------------------------------

--Missing value percentage per column in bookings_raw
	--First need to turn string null to NULL
UPDATE RIDE.bookings_raw
SET Payment_Method = NULL
WHERE Payment_Method = 'null'; --Did this for each of the other columns too

SELECT * FROM RIDE.bookings_raw;

SELECT COUNT(*) FROM RIDE.bookings_raw; --150 000 total rows - Before cleaning

	-- Table of Missing value percentage per column in RIDE.Bookings_raw
SELECT 
	COUNT(*) Row_Count,
	SUM(CASE WHEN Date IS NULL THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) * 100 Date_null_percent,
	SUM(CASE WHEN Time IS NULL THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) * 100 Time_null_percent,
	SUM(CASE WHEN Booking_ID IS NULL THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) * 100 Booking_ID_null_percent,
	SUM(CASE WHEN Booking_Status IS NULL THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) * 100 Booking_Status_null_percent,
	SUM(CASE WHEN Customer_ID IS NULL THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) * 100 Customer_ID_null_percent,
	SUM(CASE WHEN Vehicle_Type IS NULL THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) * 100 Vehicle_Type_null_percent,
	SUM(CASE WHEN Pickup_Location IS NULL THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) * 100 Pickup_Location_null_percent,
	SUM(CASE WHEN Drop_Location IS NULL THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) * 100 Drop_Location_null_percent,
	SUM(CASE WHEN Avg_VTAT IS NULL THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) * 100 Avg_VTAT_null_percent,
	SUM(CASE WHEN Avg_CTAT IS NULL THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) * 100 Avg_CTAT_null_percent,
	SUM(CASE WHEN Cancelled_Rides_by_Customer IS NULL THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) * 100 Cancelled_Rides_C_null_percent,
	SUM(CASE WHEN Reason_for_cancelling_by_Customer IS NULL THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) * 100 Reason_C_null_percent,
	SUM(CASE WHEN Cancelled_Rides_by_Driver IS NULL THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) * 100 Cancelled_Ride_D_null_percent,
	SUM(CASE WHEN Driver_Cancellation_Reason IS NULL THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) * 100 Reason_D_null_percent,
	SUM(CASE WHEN Incomplete_Rides IS NULL THEN 1 ELSE 0 END)/ CAST(COUNT(*) AS FLOAT) * 100 Incomplete_Rides_null_percent,
	SUM(CASE WHEN Incomplete_Rides_Reason IS NULL THEN 1 ELSE 0 END)  / CAST(COUNT(*) AS FLOAT) * 100 Incomplete_Rides_Reason_null_percent,
	SUM(CASE WHEN Booking_Value IS NULL THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) * 100 Booking_Value_null_percent,
	SUM(CASE WHEN Ride_Distance IS NULL THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) * 100 Ride_Distance_null_percent,
	SUM(CASE WHEN Driver_Ratings IS NULL THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) * 100 Driver_Ratings_null_percent,
	SUM(CASE WHEN Customer_Rating IS NULL THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) * 100 Customer_Rating_null_percent,
	SUM(CASE WHEN Payment_Method IS NULL THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) * 100 Payment_Method_null_percent
FROM RIDE.bookings_raw;
	--Columns with the most Null values are Incomplete_Rides and Incomplete_Rides_Reason
	--Booking_Value is certainly a critical value
	--There has to be a more efficient way of doing this
----------------------------------------------------------------------------------------------

--Create and populate bookings with rows where critical fields are not NULL 
DROP TABLE CLEAN.bookings

--Populate the table 'bookings'
SELECT [Date]
      ,[Time]
      ,[Booking_ID]
      ,[Booking_Status]
      ,[Customer_ID]
      ,[Vehicle_Type]
      ,[Pickup_Location]
      ,[Drop_Location]
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
      ,[Payment_Method]
INTO CLEAN.bookings
FROM RIDE.bookings_raw
WHERE 
	[Booking_Value] IS NOT NULL 

SELECT COUNT(*) FROM CLEAN.bookings; --102 000 total rows - After cleaning

SELECT * FROM CLEAN.bookings
	
	--Check percentage of missing values after removing NULLs in the above query.
SELECT 
	COUNT(*) Row_Count,
	SUM(CASE WHEN Date IS NULL THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) * 100 Date_null_percent,
	SUM(CASE WHEN Time IS NULL THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) * 100 Time_null_percent,
	SUM(CASE WHEN Booking_ID IS NULL THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) * 100 Booking_ID_null_percent,
	SUM(CASE WHEN Booking_Status IS NULL THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) * 100 Booking_Status_null_percent,
	SUM(CASE WHEN Customer_ID IS NULL THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) * 100 Customer_ID_null_percent,
	SUM(CASE WHEN Vehicle_Type IS NULL THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) * 100 Vehicle_Type_null_percent,
	SUM(CASE WHEN Pickup_Location IS NULL THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) * 100 Pickup_Location_null_percent,
	SUM(CASE WHEN Drop_Location IS NULL THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) * 100 Drop_Location_null_percent,
	SUM(CASE WHEN Avg_VTAT IS NULL THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) * 100 Avg_VTAT_null_percent,
	SUM(CASE WHEN Avg_CTAT IS NULL THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) * 100 Avg_CTAT_null_percent,
	SUM(CASE WHEN Cancelled_Rides_by_Customer IS NULL THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) * 100 Cancelled_Rides_C_null_percent,
	SUM(CASE WHEN Reason_for_cancelling_by_Customer IS NULL THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) * 100 Reason_C_null_percent,
	SUM(CASE WHEN Cancelled_Rides_by_Driver IS NULL THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) * 100 Cancelled_Ride_D_null_percent,
	SUM(CASE WHEN Driver_Cancellation_Reason IS NULL THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) * 100 Reason_D_null_percent,
	SUM(CASE WHEN Incomplete_Rides IS NULL THEN 1 ELSE 0 END)/ CAST(COUNT(*) AS FLOAT) * 100 Incomplete_Rides_null_percent,
	SUM(CASE WHEN Incomplete_Rides_Reason IS NULL THEN 1 ELSE 0 END)  / CAST(COUNT(*) AS FLOAT) * 100 Incomplete_Rides_Reason_null_percent,
	SUM(CASE WHEN Booking_Value IS NULL THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) * 100 Booking_Value_null_percent,
	SUM(CASE WHEN Ride_Distance IS NULL THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) * 100 Ride_Distance_null_percent,
	SUM(CASE WHEN Driver_Ratings IS NULL THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) * 100 Driver_Ratings_null_percent,
	SUM(CASE WHEN Customer_Rating IS NULL THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) * 100 Customer_Rating_null_percent,
	SUM(CASE WHEN Payment_Method IS NULL THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) * 100 Payment_Method_null_percent
FROM CLEAN.bookings;

--Count rows before and after cleaning
SELECT COUNT(*) Row_Count_Before FROM RIDE.bookings_raw;
SELECT COUNT(*) Row_Count_After FROM CLEAN.bookings
-------------------------------------------------------------------------------------------------------------------------------------------------------
