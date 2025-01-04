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
- **Playlist**:
- **PlaylistTrack**:
- **MediaType**:
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
Dáta boli extrahované z relačnej databázy Chinook a uložené do Snowflake pomocou **stage**. Načítanie dát do Snowflake prebiehalo cez:

```sql
CREATE OR REPLACE STAGE chinook_stage;
COPY INTO chinook.artist
FROM @chinook_stage/artist.csv
FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);
```

### **3.2 Transformácia dát (Transform)**
Transformácie zahŕňali vytvorenie dimenzií a faktovej tabuľky.

- **Vytvorenie dimenzií:**
   ```sql
   CREATE OR REPLACE TABLE dim_artist AS
   SELECT ArtistId, Name
   FROM chinook.artist;
   
   CREATE OR REPLACE TABLE dim_album AS
   SELECT AlbumId, Title, ArtistId
   FROM chinook.album;
   ```

- **Vytvorenie faktovej tabuľky:**
   ```sql
   CREATE OR REPLACE TABLE fact_invoice_line AS
   SELECT 
       il.InvoiceLineId, 
       il.InvoiceId, 
       il.TrackId, 
       il.UnitPrice, 
       il.Quantity, 
       il.UnitPrice * il.Quantity AS TotalAmount,
       i.InvoiceDate, 
       i.CustomerId
   FROM chinook.invoiceline il
   JOIN chinook.invoice i ON il.InvoiceId = i.InvoiceId;
   ```

### **3.3 Načítanie dát (Load)**
Transformované tabuľky boli načítané do Snowflake a staging tabuľky odstránené pre optimalizáciu:

```sql
DROP TABLE IF EXISTS chinook_stage.artist;
DROP TABLE IF EXISTS chinook_stage.album;
```

---
## **4. Vizualizácia dát**
Navrhnutých bolo 5 vizualizácií, ktoré poskytujú prehľad o dôležitých metrikách:

1. **Top 10 najpredávanejších skladieb**:
   ```sql
   SELECT t.Name AS TrackName, SUM(f.Quantity) AS TotalSales
   FROM fact_invoice_line f
   JOIN dim_track t ON f.TrackId = t.TrackId
   GROUP BY t.Name
   ORDER BY TotalSales DESC
   LIMIT 10;
   ```

2. **Tržby podľa žánrov**:
   ```sql
   SELECT g.Name AS Genre, SUM(f.TotalAmount) AS Revenue
   FROM fact_invoice_line f
   JOIN dim_track t ON f.TrackId = t.TrackId
   JOIN dim_genre g ON t.GenreId = g.GenreId
   GROUP BY g.Name
   ORDER BY Revenue DESC;
   ```

3. **Tržby podľa krajín zákazníkov**:
   ```sql
   SELECT c.Country, SUM(f.TotalAmount) AS Revenue
   FROM fact_invoice_line f
   JOIN dim_customer c ON f.CustomerId = c.CustomerId
   GROUP BY c.Country
   ORDER BY Revenue DESC;
   ```

4. **Počet skladieb na albumoch**:
   ```sql
   SELECT a.Title AS AlbumTitle, COUNT(t.TrackId) AS TrackCount
   FROM dim_album a
   JOIN dim_track t ON a.AlbumId = t.AlbumId
   GROUP BY a.Title
   ORDER BY TrackCount DESC;
   ```

5. **Tržby podľa zamestnancov**:
   ```sql
   SELECT e.FirstName || ' ' || e.LastName AS EmployeeName, SUM(f.TotalAmount) AS Revenue
   FROM fact_invoice_line f
   JOIN dim_customer c ON f.CustomerId = c.CustomerId
   JOIN dim_employee e ON c.SupportRepId = e.EmployeeId
   GROUP BY EmployeeName
   ORDER BY Revenue DESC;
   ```

---
## **Formát odovzdania**
- **README.md** obsahuje kompletnú dokumentáciu k projektu.
- **SQL skripty**: ETL proces (Extract, Transform, Load).
- **GitHub repozitár** s pravidelnými a popisnými commitmi.

---

**Autor:** Sebastián Vodička


