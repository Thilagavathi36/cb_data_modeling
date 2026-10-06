
-- TASK 1

-- Grain: One row represents one passenger's booking along with the associated flight.

-- COLUMN CLASSIFICATION (bronze_bookings joined to bronze_flights)
-- booking_id              | bronze_bookings   | Dimension key 
-- passenger_id            | bronze_bookings   | Dimension key 
-- flight_id               | bronze_bookings   | Dimension key 
-- booking_date            | bronze_bookings   | Dimension key 
-- travel_date             | bronze_bookings   | Dimension key 
-- fare_class              | bronze_bookings   | Degenerate Dimension
-- booking_status          | bronze_bookings   | Degenerate Dimension
-- fare_amount             | bronze_bookings   | Measure
-- tax_amount              | bronze_bookings   | Measure
-- miles_earned            | bronze_bookings   | Measure
-- flight_number           | bronze_flights    | Dimension attribute 
-- origin_airport_code     | bronze_flights    | Dimension key 
-- dest_airport_code       | bronze_flights    | Dimension key 
-- aircraft_code           | bronze_flights    | Dimension key 
-- flight_date             | bronze_flights    | Dimension attribute 

-- ADDITIVITY NOTE:
-- Additive -fare_amount, tax_amount, and miles_earned  
-- Non-additive example: seats sold , seat capacity 

--TASK 2

--DIM_PASSENGER
CREATE TABLE DIM_PASSENGER (
    PASSENGER_KEY INT IDENTITY(1,1) PRIMARY KEY,
    PASSENGER_ID INT NOT NULL,
    PASSENGER_NAME VARCHAR(100),
    HOME_AIRPORT_CODE VARCHAR(10),
    FREQUENT_FLYER_TIER VARCHAR(50),
    SIGNUP_DATE DATE
);

INSERT INTO DIM_PASSENGER (
    PASSENGER_ID,
    PASSENGER_NAME,
    HOME_AIRPORT_CODE,
    FREQUENT_FLYER_TIER,
    SIGNUP_DATE
)
SELECT DISTINCT
    PASSENGER_ID,
    PASSENGER_NAME,
    HOME_AIRPORT_CODE,
    FREQUENT_FLYER_TIER,
    SIGNUP_DATE
FROM BRONZE_PASSENGERS;

-- DIM_AIRCRAFT
CREATE TABLE DIM_AIRCRAFT (
    AIRCRAFT_KEY INT IDENTITY(1,1) PRIMARY KEY,
    AIRCRAFT_CODE VARCHAR(20) NOT NULL,
    MODEL VARCHAR(100),
    MANUFACTURER VARCHAR(100),
    SEAT_CAPACITY INT
)
INSERT INTO DIM_AIRCRAFT (
    AIRCRAFT_CODE,
    MODEL,
    MANUFACTURER,
    SEAT_CAPACITY
)

SELECT DISTINCT
    AIRCRAFT_CODE,
    MODEL,
    MANUFACTURER,
    SEAT_CAPACITY
FROM BRONZE_AIRCRAFT;

-- DIM_AIRPORTS
CREATE TABLE DIM_AIRPORTS (
    AIRPORT_KEY INT IDENTITY(1,1) PRIMARY KEY,
    AIRPORT_CODE VARCHAR(10) NOT NULL,
    AIRPORT_NAME VARCHAR(100),
    CITY VARCHAR(100),
    COUNTRY VARCHAR(100),
    REGION VARCHAR(100)
);
INSERT INTO DIM_AIRPORTS (
    AIRPORT_CODE,
    AIRPORT_NAME,
    CITY,
    COUNTRY,
    REGION
)
SELECT DISTINCT
    AIRPORT_CODE,
    AIRPORT_NAME,
    CITY,
    COUNTRY,
    REGION
FROM BRONZE_AIRPORTS;

--DIM_FLIGHTS

CREATE TABLE DIM_FLIGHTS (
    FLIGHT_KEY INT IDENTITY(1,1) PRIMARY KEY,
    FLIGHT_ID INT NOT NULL,
    FLIGHT_NUMBER VARCHAR(20),
    ORIGIN_AIRPORT_CODE VARCHAR(10),
    DESTINATION_AIRPORT_CODE VARCHAR(10),
    AIRCRAFT_CODE VARCHAR(20),
    FLIGHT_DATE DATE
);
INSERT INTO DIM_FLIGHTS (
    FLIGHT_ID,
    FLIGHT_NUMBER,
    ORIGIN_AIRPORT_CODE,
    DESTINATION_AIRPORT_CODE,
    AIRCRAFT_CODE,
    FLIGHT_DATE
)
SELECT DISTINCT
    FLIGHT_ID,
    FLIGHT_NUMBER,
    ORIGIN_AIRPORT_CODE,
    DESTINATION_AIRPORT_CODE,
    AIRCRAFT_CODE,
    FLIGHT_DATE
FROM BRONZE_FLIGHTS;

--DIM_DATE

CREATE TABLE DIM_DATE (
    date_key INT PRIMARY KEY,
    full_date DATE NOT NULL,
    day INT,
    month INT,
    month_name VARCHAR(20),
    quarter INT,
    year INT
);

INSERT INTO DIM_DATE(
    date_key,
    full_date,
    day,
    month,
    month_name,
    quarter,
    year
)
SELECT DISTINCT
    CONVERT(INT, CONVERT(VARCHAR(8), full_date, 112)),
    full_date,
    DAY(full_date),
    MONTH(full_date),
    DATENAME(MONTH, full_date),
    DATEPART(QUARTER, full_date),
    YEAR(full_date)
FROM (
    SELECT booking_date AS full_date
    FROM bronze_bookings

    UNION

    SELECT travel_date
    FROM bronze_bookings

    UNION

    SELECT signup_date
    FROM bronze_passengers
) d;

SELECT * FROM DIM_DATE

--FACTTICKETSALES

CREATE TABLE FactTicketSales (
    booking_id INT PRIMARY KEY,
    booking_date_key INT NOT NULL,
    travel_date_key INT NOT NULL,
    passenger_key INT NOT NULL,
    flight_key INT NOT NULL,
    aircraft_key INT NOT NULL,
    fare_amount DECIMAL(12,2),
    tax_amount DECIMAL(12,2),
    miles_earned INT,

    FOREIGN KEY (booking_date_key)
        REFERENCES DIM_DATE(date_key),

    FOREIGN KEY (travel_date_key)
        REFERENCES DIM_DATE(date_key),

    FOREIGN KEY (passenger_key)
        REFERENCES DIM_PASSENGER(passenger_key),

    FOREIGN KEY (flight_key)
        REFERENCES DIM_FLIGHTS(flight_key),

    FOREIGN KEY (aircraft_key)
        REFERENCES DIM_AIRCRAFT(aircraft_key)
);

INSERT INTO FactTicketSales (
    booking_id,
    booking_date_key,
    travel_date_key,
    passenger_key,
    flight_key,
    aircraft_key,
    fare_amount,
    tax_amount,
    miles_earned
)
SELECT
    b.booking_id,

    CONVERT(INT, CONVERT(VARCHAR(8), b.booking_date, 112)),
    CONVERT(INT, CONVERT(VARCHAR(8), b.travel_date, 112)),

    p.passenger_key,
    f.flight_key,
    ac.aircraft_key,
    b.fare_amount,
    b.tax_amount,
    b.miles_earned

FROM bronze_bookings b

JOIN DIM_PASSENGER p
    ON b.passenger_id = p.passenger_id

JOIN DIM_FLIGHTS f
    ON b.flight_id = f.flight_id


JOIN DIM_AIRCRAFT ac
    ON f.aircraft_code = ac.aircraft_code;

SELECT * FROM FactTicketSales

--TASK 4

CREATE TABLE DIM_COUNTRY(
COUNTRY_KEY INT IDENTITY(1,1) PRIMARY KEY,
COUNTRY_NAME NVARCHAR(50) NOT NULL,
REGION NVARCHAR(50) NOT NULL
)


CREATE TABLE DIM_CITY(
CITY_KEY INT IDENTITY(1,1) PRIMARY KEY,
CITY_NAME NVARCHAR(50) NOT NULL,
COUNTRY_KEY INT,
FOREIGN KEY(COUNTRY_KEY)
REFERENCES DIM_COUNTRY(COUNTRY_KEY)
)

ALTER TABLE DIM_AIRPORTS
ADD CITY_KEY INT;

ALTER TABLE DIM_AIRPORTS 
ADD FOREIGN KEY (CITY_KEY)
REFERENCES DIM_CITY(CITY_KEY)

INSERT INTO DIM_COUNTRY(
COUNTRY_NAME,
REGION)
SELECT DISTINCT COUNTRY , REGION FROM DIM_AIRPORTS

INSERT INTO DIM_CITY (
    CITY_NAME,
    COUNTRY_KEY
)
SELECT DISTINCT
    a.CITY,
    c.COUNTRY_KEY
FROM DIM_AIRPORTS a
JOIN DIM_COUNTRY c
    ON a.COUNTRY = c.COUNTRY_NAME
    AND a.REGION = c.REGION;


UPDATE a
SET a.CITY_KEY = c.CITY_KEY
FROM DIM_AIRPORTS a
JOIN DIM_CITY c
    ON a.CITY = c.CITY_NAME;


SELECT
    a.airport_code,
    a.airport_name,
    c.city_name,
    co.country_name,
    co.region
FROM dim_airports a
JOIN dim_city c 
    ON a.city_key = c.city_key
JOIN dim_country co 
    ON c.country_key = co.country_key;

---TASK 5

--ADD HOME AIRPORT KEY AS THE FK FROM DIM AIRPORT

ALTER TABLE DIM_PASSENGER
ADD HOME_AIRPORT_KEY INT, 
CONSTRAINT FK_HOME_AIRPORT_KEY
FOREIGN KEY (HOME_AIRPORT_KEY)
REFERENCES DIM_AIRPORTS(AIRPORT_KEY)

UPDATE P
SET P.HOME_AIRPORT_KEY = A.AIRPORT_KEY
FROM DIM_PASSENGER P
JOIN DIM_AIRPORTS A
    ON P.HOME_AIRPORT_CODE = A.AIRPORT_CODE; --1500 ROWS


--1. MODIFY THE DIM_PASSENGER TABLE BY ADDING THE COLUMNS FOR SCD 2
--ADD EFFECTIVE_FROM, EFFECTIVE_TO , IS_CURRENT

ALTER TABLE DIM_PASSENGER
ADD EFFECTIVE_FROM DATE  NULL,
     EFFECTIVE_TO DATE  NULL,
     IS_CURRENT BIT  NULL

--2. ADD DATA INTO ABOVE COLUMNS

UPDATE DIM_PASSENGER
SET EFFECTIVE_FROM = SIGNUP_DATE,
    EFFECTIVE_TO = NULL,
    IS_CURRENT = 1;

-- 3. COPY DATA FROM STG PASSENGER UPD TO TEMP TABLE

SELECT 
S.PASSENGER_ID, 
S.PASSENGER_NAME, 
TRIM(S.FREQUENT_FLYER_TIER) AS FREQUENT_FLYER_TIER, 
S.HOME_AIRPORT_CODE , 
A.AIRPORT_KEY AS HOME_AIRPORT_KEY 
INTO STG_PASSENGERS_UPD
FROM stg_passenger_updates S INNER JOIN DIM_AIRPORTS A ON S.home_airport_code = A.AIRPORT_CODE -- 250 ROWS AFFECTED

SELECT * INTO DIM_PASSENGER_SCD_TYPE2_UP FROM DIM_PASSENGER --1500 ROWS AFFECTED

ALTER TABLE DIM_PASSENGER_SCD_TYPE2_UP
DROP COLUMN HOME_AIRPORT_CODE;

ALTER TABLE DIM_PASSENGER_SCD_TYPE2_UP
ALTER COLUMN SIGNUP_DATE DATE NULL;

SELECT * FROM DIM_PASSENGER_SCD_TYPE2_UP

--MERGE QUERY -- EXPIRES THE ROW WHERE THE ATTRIBUTES HAS CHNAGED

MERGE INTO DIM_PASSENGER_SCD_TYPE2_UP AS TGT 
USING STG_PASSENGERS_UPD AS SRC
ON TGT.PASSENGER_ID = SRC.PASSENGER_ID AND TGT.IS_CURRENT =1
WHEN MATCHED AND 
( TGT.HOME_AIRPORT_KEY <> SRC.HOME_AIRPORT_KEY
    OR TGT.FREQUENT_FLYER_TIER <> SRC.FREQUENT_FLYER_TIER) 
THEN
UPDATE SET TGT.IS_CURRENT = 0, TGT.EFFECTIVE_TO = CAST(GETDATE() AS DATE)
WHEN NOT MATCHED BY TARGET THEN
INSERT ( PASSENGER_ID, PASSENGER_NAME, HOME_AIRPORT_KEY, FREQUENT_FLYER_TIER, EFFECTIVE_FROM, EFFECTIVE_TO, IS_CURRENT)
VALUES( SRC.PASSENGER_ID, SRC.PASSENGER_NAME, SRC.HOME_AIRPORT_KEY, SRC.FREQUENT_FLYER_TIER, CAST(GETDATE() AS DATE), NULL, 1); --250 ROWS AFFECTED

--INSERT QUERY -- INSERTING THE NEW VERSIONS WHICH EXPIRES ABOVE

INSERT INTO DIM_PASSENGER_SCD_TYPE2_UP 
(PASSENGER_ID, PASSENGER_NAME, HOME_AIRPORT_KEY, FREQUENT_FLYER_TIER,SIGNUP_DATE, EFFECTIVE_FROM, EFFECTIVE_TO, IS_CURRENT)
SELECT
SRC.PASSENGER_ID,
SRC.PASSENGER_NAME, 
SRC.HOME_AIRPORT_KEY,
SRC.FREQUENT_FLYER_TIER,
EXPR.SIGNUP_DATE, 
CAST(GETDATE() AS DATE), 
NULL, 
1
FROM STG_PASSENGERS_UPD AS SRC
JOIN DIM_PASSENGER_SCD_TYPE2_UP AS EXPR
ON EXPR.PASSENGER_ID = SRC.PASSENGER_ID 
AND EXPR.IS_CURRENT = 0 
AND EXPR.EFFECTIVE_TO = CAST(GETDATE() AS DATE)
WHERE NOT EXISTS(
SELECT 1 FROM DIM_PASSENGER_SCD_TYPE2_UP CUR
WHERE CUR.PASSENGER_ID = SRC.PASSENGER_ID AND CUR.IS_CURRENT =1
) --200 ROWS AFFECTED

SELECT * FROM DIM_PASSENGER_SCD_TYPE2_UP WHERE PASSENGER_ID = '701490'

SELECT COUNT(PASSENGER_ID), PASSENGER_ID FROM DIM_PASSENGER_SCD_TYPE2_UP 
GROUP BY PASSENGER_ID

--TASK 6

SP_HELP 'FACTTICKETSALES'

SELECT * FROM FactTicketSales

SELECT
    MIN(travel_date) AS MIN_TRAVEL_DATE,
    MAX(travel_date) AS MAX_TRAVEL_DATE
FROM bronze_bookings;

CREATE PARTITION FUNCTION PF_TravelDate (INT)
AS RANGE LEFT FOR VALUES (
    
    20250131, 20250228, 20250331, 20250430, 20250531, 20250630,
    20250731, 20250831, 20250930, 20251031, 20251130, 20251231,
    20260131, 20260228, 20260331
);

CREATE PARTITION SCHEME PS_TRAVELDATE
AS PARTITION PF_TRAVELDATE
ALL TO ([PRIMARY])

ALTER TABLE FACTTICKETSALES
DROP CONSTRAINT PK__FactTick__5DE3A5B1DC60B618;

ALTER TABLE FactTicketSales
ADD CONSTRAINT PK_FactTicketSales
PRIMARY KEY NONCLUSTERED (booking_id);

CREATE CLUSTERED INDEX CX_FactTicketSales_TravelDate
ON FactTicketSales (TRAVEL_DATE_KEY)
ON PS_TravelDate(TRAVEL_DATE_KEY);

SELECT
    i.name AS index_name,
    i.type_desc,
    ds.name AS data_space_name
FROM sys.indexes i
JOIN sys.data_spaces ds
    ON i.data_space_id = ds.data_space_id
WHERE i.object_id = OBJECT_ID('FactTicketSales');

--QUERY A
SELECT SUM(FARE_AMOUNT)
FROM FactTicketSales
WHERE travel_date_key BETWEEN 20260301 AND 20260331;

--QUERY B
SELECT SUM(FARE_AMOUNT)
FROM FactTicketSales
WHERE passenger_key = 1;

-- For Query A, check the Clustered Index Scan/Seek operator and its
-- partition information. SQL Server should access only the partition(s)
-- containing the requested TRAVEL_DATE_KEY range.
--
-- Query B does not filter on TRAVEL_DATE_KEY, so partition elimination
-- is not possible based on the partition key and more partitions may be accessed.


