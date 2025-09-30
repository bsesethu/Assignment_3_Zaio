# 🚗E-hailing Rides Analysis

## NCR Ride Bookings — SQL Analysis Project

> A comprehensive SQL-driven analysis of ride bookings from an e-hailing service, NCR Ride.  

---

## 📊 Project Overview

This project explores and analyses real-world-style e-hailing data using only SQL. Using the **NCR_Ride_bookings** dataset, I perform:

- **Data cleaning and preprocessing**
- **Feature engineering**
- **Exploratory Data Analysis (EDA)**
- **Statistical analysis**
- **Operational insights**
- **Cohort and churn analysis**

The analysis is executed entirely within a relational database environment (SQL Server in my case), showcasing SQL proficiency and an end-to-end data analytics workflow.

---

## 📁 Dataset Summary

| Column Name                     | Description                                 |
|--------------------------------|---------------------------------------------|
| `Date`, `Time`                 | Timestamp of the ride booking               |
| `Booking ID`                   | Unique identifier for each booking          |
| `Booking Status`              | Status (Completed, Cancelled, Incomplete)   |
| `Customer ID`                 | Unique identifier for the customer          |
| `Vehicle Type`                | Type of ride requested                      |
| `Pickup Location`, `Drop Location` | Origin and destination points          |
| `Avg VTAT`, `Avg CTAT`        | Vehicle/Customer turnaround time (avg)      |
| `Cancelled Rides` & Reasons   | Cancellations by customer/driver with reasons |
| `Booking Value`               | Monetary value of the booking               |
| `Ride Distance`               | Distance covered during the ride            |
| `Ratings`, `Payment Method`   | Quality feedback and mode of payment        |

---

## 🛠️ Tech Stack

- **SQL Engine**: SQL Server Database Engine (supports window functions, CTEs, CORR, etc.)
- **Database Tool**: Transact-SQL (T-SQL)
- **Tools Used**: SQL only (no Python/R visualization)

---

## 🚦 Project Phases

### 1. 📥 Data Collection
- Imported the CSV as `bookings_raw`
- Created a cleaned version `bookings` with appropriate data types
- Computed % of missing values per column
- Logged row count before and after filtering critical NULLs

### 2. 🧹 Data Preparation
- Removed duplicate `Booking ID`s based on earliest timestamp
- Feature engineering:
  - `pickup_ts` (timestamp from Date + Time)
  - `Day_Of_Week`, `Hour_Of_Day`
  - `Route`: `Pickup_Location → Drop_Location`
  - Normalized `Payment_Method` to `Payment_Method_Norm`

### 3. 📈 Exploratory Data Analysis (EDA)
- Fare distribution buckets (`<100`, `100–199.99`, `200–299.99`, `>=300`)
- Top 10 combinations of `Vehicle Type × Booking Status`
- Correlation proxies between `Booking Value` and `Ride Distance`
- Booking Value quartile summaries by `Payment_Method_Norm`

### 4. 📐 Statistical Analysis
- Descriptive stats: mean, median, standard deviation
- Correlation coefficient between distance and value
- IQR outlier detection on `Booking Value` with flagged outliers

### 5. 🔍 Advanced Analysis
- 🚗 Completion rates by `Vehicle Type`
- 💰 Top 10 profitable routes (Total & Avg Booking Value)
- ❌ Top 5 cancellation reasons by customer and driver
- 🕐 Service time trends (by `Hour_Of_Day`)
- 👥 Customer cohort analysis & churn detection

### 6. 🧾 Conclusion & Insights
---


## 📚 How to Run

1. Set up your SQL database (e.g., SQL Server).
2. Import `NCR_Ride_bookings.csv` as `bookings_raw`.
3. Execute each `.sql` file in sequence from the `/sql/` folder.
4. Verify outputs by running summary queries or exporting views.
5. Open the final report (`output/report.pdf`) for full commentary and findings.

---

## 🙋🏽‍♂️ Author

**Sesethu M. Bango**  
*Aspiring Data Analyst & Engineering Enthusiast*  
📫 [Connect on LinkedIn]([https://linkedin.com](https://www.linkedin.com/in/sesethu-bango-197856380/)

---
