-- 1. Top 10 najpredávanejších skladieb:
SELECT 
    t.`Name` AS TrackName,
    COUNT(il.`Quantity`) AS TotalSales
FROM 
    `InvoiceLine` il
JOIN 
    `Track` t ON il.`TrackId` = t.`TrackId`
GROUP BY 
    t.`Name`
ORDER BY 
    TotalSales DESC
LIMIT 10;

-- 2. Tržby podľa žánrov:
SELECT 
    g.`Name` AS Genre,
    SUM(il.`UnitPrice` * il.`Quantity`) AS Revenue
FROM 
    `InvoiceLine` il
JOIN 
    `Track` t ON il.`TrackId` = t.`TrackId`
JOIN 
    `Genre` g ON t.`GenreId` = g.`GenreId`
GROUP BY 
    g.`Name`
ORDER BY 
    Revenue DESC;

-- 3. Tržby podľa krajín zákazníkov:
SELECT 
    c.`Country`,
    SUM(i.`Total`) AS Revenue
FROM 
    `Invoice` i
JOIN 
    `Customer` c ON i.`CustomerId` = c.`CustomerId`
GROUP BY 
    c.`Country`
ORDER BY 
    Revenue DESC; 

-- 4. Počet skladieb na albumoch:
SELECT 
    a.`Title` AS AlbumTitle,
    COUNT(t.`TrackId`) AS NumberOfTracks
FROM 
    `Album` a
JOIN 
    `Track` t ON a.`AlbumId` = t.`AlbumId`
GROUP BY 
    a.`Title`
ORDER BY 
    NumberOfTracks DESC; 

-- 5. Tržby podľa zamestnancov:
SELECT 
    e.`FirstName` || ' ' || e.`LastName` AS EmployeeName,
    SUM(i.`Total`) AS Revenue
FROM 
    `Invoice` i
JOIN 
    `Customer` c ON i.`CustomerId` = c.`CustomerId`
JOIN 
    `Employee` e ON c.`SupportRepId` = e.`EmployeeId`
GROUP BY 
    EmployeeName
ORDER BY 
    Revenue DESC;
    
-- 6. Celková aktivita počas týždňa:
SELECT 
    CASE 
        WHEN EXTRACT(DOW FROM i.`InvoiceDate`) = 0 THEN 'Sunday'
        WHEN EXTRACT(DOW FROM i.`InvoiceDate`) = 1 THEN 'Monday'
        WHEN EXTRACT(DOW FROM i.`InvoiceDate`) = 2 THEN 'Tuesday'
        WHEN EXTRACT(DOW FROM i.`InvoiceDate`) = 3 THEN 'Wednesday'
        WHEN EXTRACT(DOW FROM i.`InvoiceDate`) = 4 THEN 'Thursday'
        WHEN EXTRACT(DOW FROM i.`InvoiceDate`) = 5 THEN 'Friday'
        WHEN EXTRACT(DOW FROM i.`InvoiceDate`) = 6 THEN 'Saturday'
    END AS DayOfWeek,
    COUNT(i.`InvoiceId`) AS TotalInvoices,
    SUM(i.`Total`) AS TotalRevenue
FROM 
    `Invoice` i
GROUP BY 
    EXTRACT(DOW FROM i.`InvoiceDate`)
ORDER BY 
    EXTRACT(DOW FROM i.`InvoiceDate`);
