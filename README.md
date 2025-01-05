# Dokumentácia k implementácii ETL procesu v Snowflake pre Chinook databázu

## **1. Úvod a popis zdrojových dát**
Cieľom projektu je analyzovať hudobnú databázu **Chinook**, ktorá obsahuje informácie o interpretoch, albumoch, skladbách a transakciách. Tento ETL proces pripraví dáta na multidimenzionálnu analýzu a vizualizáciu kľúčových metrík.

Zdrojové dáta obsahujú tieto tabuľky:
- **Artist**: Informácie o interpretoch.
- **Album**: Zoznam albumov a prepojenie na interpreta.
- **Track**: Informácie o skladbách vrátane ceny a trvania.
- **Genre**: Hudobné žánre.
- **Customer**: Zákazníci a ich kontaktné údaje.
- **Invoice**: Faktúry vytvorené zákazníkmi.
- **InvoiceLine**: Položky z faktúr.
- **Employee**: Zamestnanci poskytujúci podporu zákazníkom.
- **Playlist**: Obsahuje zoznamy skladieb vytvorené zákazníkmi
- **PlaylistTrack**: Prepája skladby a playlisty
- **MediaType**: Typ médií pre skladby, napr. MP3, WAV
### **1.1 ERD diagram**
ERD diagram znázorňuje vzťahy medzi tabuľkami v zdrojovej databáze Chinook.


![Chinook_ERD](https://github.com/user-attachments/assets/70be31b1-e720-4365-81d3-d0241f934d7b)

---
## **2. Dimenzionálny model**
Pre tento projekt bol navrhnutý **hviezdicový model (star schema)**, ktorý zahŕňa jednu faktovú tabuľku a niekoľko dimenzií:

### **Faktová tabuľka: `fact_invoice_line`**
| Stĺpec         | Popis                       |
|------------------|----------------------------|
| InvoiceLineId    | Primárny kľúč.           |
| InvoiceId        | ID faktúry.               |
| TrackId          | ID skladby.                |
| UnitPrice        | Cena za jednotku.          |
| Quantity         | Zakúpené množstvo.       |
| TotalAmount      | Celková suma (vypočítana). |
| InvoiceDate      | Dátum faktúry.            |
| CustomerId       | ID zákazníka.            |

### **Dimenzie**
- **`dim_artist`**: Informácie o interpretoch.
  - Atribúty: `ArtistId`, `Name`
- **`dim_album`**: Informácie o albumoch.
  - Atribúty: `AlbumId`, `Title`, `ArtistId`
- **`dim_track`**: Detaily o skladbách.
  - Atribúty: `TrackId`, `Name`, `AlbumId`, `GenreId`, `UnitPrice`
- **`dim_genre`**: Informácie o žánroch.
  - Atribúty: `GenreId`, `Name`
- **`dim_customer`**: Zákazníci.
  - Atribúty: `CustomerId`, `FirstName`, `LastName`, `Country`
- **`dim_invoice`**: Informácie o faktúrach.
  - Atribúty: `InvoiceId`, `InvoiceDate`, `BillingCountry`
- **`dim_employee`**: Informácie o zamestnancoch.
  - Atribúty: `EmployeeId`, `FirstName`, `LastName`

### **2.1 Dimenzionálny model diagram**

![s](https://github.com/user-attachments/assets/d321d003-d528-43e3-8717-437172aa4d25)


---
## **3. ETL proces v Snowflake**

ETL proces je rozdelený do troch hlavných krokov: **Extract**, **Transform** a **Load**.

### **3.1 Extrahovanie dát (Extract)**
Dáta boli extrahované z SQL skriptu, ktorý obsahoval definície a dáta pre tabuľky databázy Chinook. Postup extrahovania bol nasledovný:

Načítanie SQL skriptu:
SQL skript, obsahujúci štruktúru databázy Chinook a vzorové dáta, bol otvorený v textovom editore alebo IDE.

Kopírovanie dát:
Dátové sekcie (príkazy INSERT INTO) obsahujúce záznamy boli manuálne extrahované (skopírované).

Import do Snowflake:
Dáta boli prilepené a spustené priamo v Snowflake konzole. Každá tabuľka bola nahratá samostatne, pričom sa postupovalo podľa nasledujúceho príkladu:

```sql
  CREATE OR REPLACE TABLE `artist` (
      `ArtistId` INT,
      `Name` VARCHAR
  );

  INSERT INTO `artist` (`ArtistId`, `Name`)
  VALUES 
    (1, 'AC/DC'),
    (2, 'Accept'),
    (3, 'Aerosmith'),
    ...
```
Tento proces bol zopakovaný pre všetky tabuľky databázy Chinook.


### **3.2 Transformácia dát (Transform)**
Transformácie zahŕňali vytvorenie dimenzií a faktovej tabuľky.

- **Vytvorenie dimenzií:**
   ```sql
   CREATE OR REPLACE TABLE dim_artist AS
   SELECT `ArtistId`, `Name`
   FROM `artist`;

   CREATE OR REPLACE TABLE dim_album AS
   SELECT `AlbumId`, `Title`, `ArtistId`
   FROM `album`;
   ```

- **Vytvorenie faktovej tabuľky:**
   ```sql
   CREATE OR REPLACE TABLE fact_invoice_line AS
   SELECT 
     il.`InvoiceLineId`, 
     il.`InvoiceId`, 
     il.`TrackId`, 
     il.`UnitPrice`, 
     il.`Quantity`, 
     il.`UnitPrice` * il.`Quantity` AS TotalAmount,
     i.`InvoiceDate`, 
     i.`CustomerId`
   FROM `invoiceline` il
   JOIN `invoice` i ON il.`InvoiceId` = i.`InvoiceId`;
   ```

### **3.3 Načítanie dát (Load)**
Transformované tabuľky boli načítané do Snowflake a staging tabuľky odstránené pre optimalizáciu:

```sql
DROP TABLE IF EXISTS `artist`;
DROP TABLE IF EXISTS `album`;
```

---
## **4. Vizualizácia dát**
Navrhnutých bolo 5 vizualizácií, ktoré poskytujú prehľad o dôležitých metrikách:
![Snímka obrazovky (342)](https://github.com/user-attachments/assets/126b6956-2aad-44a2-95f3-364b2685f9a4)  ![Snímka obrazovky (344)](https://github.com/user-attachments/assets/c1e87f59-d264-43d7-8129-d0ca9b6133c1)! ![Snímka obrazovky (349)](https://github.com/user-attachments/assets/42c5c6a0-d38e-4014-9055-5be8397b6539)![Snímka obrazovky (346)](https://github.com/user-attachments/assets/5c2f7b18-3b11-47de-b4be-0957bef4d7cc)![Snímka obrazovky (347)](https://github.com/user-attachments/assets/c4b9a7c5-0fdf-4249-a0b8-0de385aea22e)![Snímka obrazovky (348)](https://github.com/user-attachments/assets/07e557d5-b853-425e-9155-681025b032ea)







1. **Top 10 najpredávanejších skladieb**:
   ```sql
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
   ```

2. **Tržby podľa žánrov**:
   ```sql
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
   ```

3. **Tržby podľa krajín zákazníkov**:
   ```sql
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
   ```

4. **Počet skladieb na albumoch**:
   ```sql
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
   ```

5. **Tržby podľa zamestnancov**:
   ```sql
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
   ```
6. **Celková aktivita počas týždňa**:
   ```sql
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
  ```

  

Autor: Sebastián Vodička


