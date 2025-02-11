  --- Použitie role
USE ROLE TRAINING_ROLE;
--- Vytvorenie a použitie skladiska 
CREATE WAREHOUSE IF NOT EXISTS CHEETAH_WH;
USE WAREHOUSE CHEETAH_WH;
--- Vytvorenie a použitie databázy
CREATE DATABASE IF NOT EXISTS CHINOOKV_D;
USE CHINOOKV_D;
--- Vytvorenie a použitie schémy
CREATE SCHEMA IF NOT EXISTS CHINOOKV_D.staging;
USE SCHEMA CHINOOKV_D.staging;
--- Vytvorenie stagu 
CREATE OR REPLACE STAGE CHINOOK_stage;


CREATE OR REPLACE TABLE Album
(
    AlbumId INT NOT NULL,
    Title VARCHAR(160) NOT NULL,
    ArtistId INT NOT NULL,
    CONSTRAINT PK_Album PRIMARY KEY  (AlbumId)
);

CREATE OR REPLACE TABLE Artist
(
    ArtistId INT NOT NULL,
    Name VARCHAR(120),
    CONSTRAINT PK_Artist PRIMARY KEY  (ArtistId)
);

CREATE OR REPLACE TABLE Customer
(
    CustomerId INT NOT NULL,
    FirstName VARCHAR(40) NOT NULL,
    LastName VARCHAR(20) NOT NULL,
    Company VARCHAR(80),
    Address VARCHAR(70),
    City VARCHAR(40),
    State VARCHAR(40),
    Country VARCHAR(40),
    PostalCode VARCHAR(10),
    Phone VARCHAR(24),
    Fax VARCHAR(24),
    Email VARCHAR(60) NOT NULL,
    SupportRepId INT,
    CONSTRAINT PK_Customer PRIMARY KEY  (CustomerId)
);

CREATE OR REPLACE TABLE Employee
(
    EmployeeId INT NOT NULL,
    LastName VARCHAR(20) NOT NULL,
    FirstName VARCHAR(20) NOT NULL,
    Title VARCHAR(30),
    ReportsTo INT,
    BirthDate DATE,
    HireDate DATE,
    Address VARCHAR(70),
    City VARCHAR(40),
    State VARCHAR(40),
    Country VARCHAR(40),
    PostalCode VARCHAR(10),
    Phone VARCHAR(24),
    Fax VARCHAR(24),
    Email VARCHAR(60),
    CONSTRAINT PK_Employee PRIMARY KEY  (EmployeeId)
);

CREATE OR REPLACE TABLE Genre
(
    GenreId INT NOT NULL,
    Name VARCHAR(120),
    CONSTRAINT PK_Genre PRIMARY KEY  (GenreId)
);

CREATE OR REPLACE TABLE Invoice
(
    InvoiceId INT NOT NULL,
    CustomerId INT NOT NULL,
    InvoiceDate DATE NOT NULL,
    BillingAddress VARCHAR(70),
    BillingCity VARCHAR(40),
    BillingState VARCHAR(40),
    BillingCountry VARCHAR(40),
    BillingPostalCode VARCHAR(10),
    Total NUMERIC(10,2) NOT NULL,
    CONSTRAINT PK_Invoice PRIMARY KEY  (InvoiceId)
);

CREATE OR REPLACE TABLE InvoiceLine
(
    InvoiceLineId INT NOT NULL,
    InvoiceId INT NOT NULL,
    TrackId INT NOT NULL,
    UnitPrice NUMERIC(10,2) NOT NULL,
    Quantity INT NOT NULL,
    CONSTRAINT PK_InvoiceLine PRIMARY KEY  (InvoiceLineId)
);

CREATE OR REPLACE TABLE MediaType
(
    MediaTypeId INT NOT NULL,
    Name VARCHAR(120),
    CONSTRAINT PK_MediaType PRIMARY KEY  (MediaTypeId)
);

CREATE OR REPLACE TABLE Playlist
(
    PlaylistId INT NOT NULL,
    Name VARCHAR(120),
    CONSTRAINT PK_Playlist PRIMARY KEY  (PlaylistId)
);

CREATE OR REPLACE TABLE PlaylistTrack
(
    PlaylistId INT NOT NULL,
    TrackId INT NOT NULL,
    CONSTRAINT PK_PlaylistTrack PRIMARY KEY  (PlaylistId, TrackId)
);

CREATE OR REPLACE TABLE Track
(
    TrackId INT NOT NULL,
    Name VARCHAR(200) NOT NULL,
    AlbumId INT,
    MediaTypeId INT NOT NULL,
    GenreId INT,
    Composer VARCHAR(220),
    Minute INT NOT NULL,
    Bytes INT,
    UnitPrice NUMERIC(10,2) NOT NULL,
    CONSTRAINT PK_Track PRIMARY KEY  (TrackId)
);


COPY INTO Album
FROM @CHINOOK_stage/Album.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO Artist
FROM @CHINOOK_stage/Artist.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1 NULL_IF = ('NULL', ''));

COPY INTO Customer
FROM @CHINOOK_stage/customer.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO Employee
FROM @CHINOOK_stage/employee.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO Genre
FROM @CHINOOK_stage/Genre.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO Invoice
FROM @CHINOOK_stage/invoiceline.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO InvoiceLine
FROM @CHINOOK_stage/invoicelineid.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);

COPY INTO MediaType
FROM @CHINOOK_stage/Media.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);
    
COPY INTO Playlist
FROM @CHINOOK_stage/playlist.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);    
    
COPY INTO PlaylistTrack
FROM @CHINOOK_stage/playlisttrack.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);  
    
COPY INTO Track
FROM @CHINOOK_stage/Track.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);   

--Vytvorenie dimenzií:
-- Vytvorenie dimenzií

-- Dimenzia Artist
CREATE OR REPLACE TABLE dim_artist AS
SELECT 
    a.ArtistId AS artist_id,
    a.Name AS artist_name
FROM artist a;

-- Dimenzia Album
CREATE OR REPLACE TABLE dim_album AS
SELECT 
    al.AlbumId AS album_id,
    al.Title AS album_title,
    al.ArtistId AS artist_id
FROM album al;

-- Dimenzia Date
CREATE OR REPLACE TABLE dim_date AS
SELECT DISTINCT 
    i.InvoiceDate AS date_id,
    DAY(i.InvoiceDate) AS day,
    MONTH(i.InvoiceDate) AS month,
    QUARTER(i.InvoiceDate) AS quarter,
    YEAR(i.InvoiceDate) AS year
FROM invoice i;

-- Dimenzia Customers
CREATE OR REPLACE TABLE dim_customers AS
SELECT 
    c.CustomerId AS customer_id,
    c.FirstName AS first_name,
    c.LastName AS last_name,
    c.Country,
    c.City,
    c.Email
FROM customer c;

-- Dimenzia Employees
CREATE OR REPLACE TABLE dim_employees AS
SELECT 
    e.EmployeeId AS employee_id,
    e.FirstName AS first_name,
    e.LastName AS last_name,
    e.Title
FROM employee e;

-- Dimenzia Tracks
CREATE OR REPLACE TABLE dim_tracks AS
SELECT 
    t.TrackId AS track_id,
    t.Name AS track_name,
    t.Composer
FROM track t;

-- Dimenzia Genre
CREATE OR REPLACE TABLE dim_genre AS
SELECT 
    g.GenreId AS genre_id,
    g.Name AS genre_name
FROM genre g;

-- Vytvorenie fact tabuľky
CREATE OR REPLACE TABLE fact_sales AS
SELECT 
    i.InvoiceId AS invoice_id,
    i.InvoiceDate AS date_id,
    il.InvoiceLineId AS invoice_line_id,
    il.TrackId AS track_id,
    i.CustomerId AS customer_id,
    e.EmployeeId AS employee_id,
    il.Quantity AS quantity,
    il.UnitPrice AS unit_price,
    (il.Quantity * il.UnitPrice) AS total,
    t.AlbumId AS album_id,
    t.GenreId AS genre_id,
    a.ArtistId AS artist_id
FROM invoice i
JOIN invoice_line il ON i.InvoiceId = il.InvoiceId
JOIN track t ON il.TrackId = t.TrackId
JOIN album a ON t.AlbumId = a.AlbumId
JOIN customer c ON i.CustomerId = c.CustomerId
LEFT JOIN employee e ON c.SupportRepId = e.EmployeeId;


-- 1. Top 10 najpredávanejších skladieb:
SELECT 
    t.Name AS TrackName,
    COUNT(il.Quantity) AS TotalSales
FROM 
    InvoiceLine il
JOIN 
    Track t ON il.TrackId = t.TrackId
GROUP BY 
    t.Name
ORDER BY 
    TotalSales DESC
LIMIT 10;

-- 2. Tržby podľa žánrov:
SELECT 
    g.Name AS Genre,
    SUM(il.UnitPrice * il.Quantity) AS Revenue
FROM 
    InvoiceLine il
JOIN 
    Track t ON il.TrackId = t.TrackId
JOIN 
    Genre g ON t.GenreId = g.GenreId
GROUP BY 
    g.Name
ORDER BY 
    Revenue DESC;

-- 3. Tržby podľa krajín zákazníkov:
SELECT 
    c.Country,
    SUM(i.Total) AS Revenue
FROM 
    Invoice i
JOIN 
    Customer c ON i.CustomerId = c.CustomerId
GROUP BY 
    c.Country
ORDER BY 
    Revenue DESC; 

-- 4. Počet skladieb na albumoch:
SELECT 
    a.Title AS AlbumTitle,
    COUNT(t.TrackId) AS NumberOfTracks
FROM 
    Album a
JOIN 
    Track t ON a.AlbumId = t.AlbumId
GROUP BY 
    a.Title
ORDER BY 
    NumberOfTracks DESC; 

-- 5. Tržby podľa zamestnancov:
SELECT 
    e.FirstName || ' ' || e.LastName AS EmployeeName,
    SUM(i.Total) AS Revenue
FROM 
    Invoice i
JOIN 
    Customer c ON i.CustomerId = c.CustomerId
JOIN 
    Employee e ON c.SupportRepId = e.EmployeeId
GROUP BY 
    EmployeeName
ORDER BY 
    Revenue DESC;
    
-- 6. Celková aktivita počas týždňa:
SELECT 
    CASE 
        WHEN EXTRACT(DOW FROM i.InvoiceDate) = 0 THEN 'Sunday'
        WHEN EXTRACT(DOW FROM i.InvoiceDate) = 1 THEN 'Monday'
        WHEN EXTRACT(DOW FROM i.InvoiceDate) = 2 THEN 'Tuesday'
        WHEN EXTRACT(DOW FROM i.InvoiceDate) = 3 THEN 'Wednesday'
        WHEN EXTRACT(DOW FROM i.InvoiceDate) = 4 THEN 'Thursday'
        WHEN EXTRACT(DOW FROM i.InvoiceDate) = 5 THEN 'Friday'
        WHEN EXTRACT(DOW FROM i.InvoiceDate) = 6 THEN 'Saturday'
    END AS DayOfWeek,
    COUNT(i.InvoiceId) AS TotalInvoices,
    SUM(i.Total) AS TotalRevenue
FROM 
    Invoice i
GROUP BY 
    EXTRACT(DOW FROM i.InvoiceDate)
ORDER BY 
    EXTRACT(DOW FROM i.InvoiceDate);


