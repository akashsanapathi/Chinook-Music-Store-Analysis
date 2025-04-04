-- Objective questions
-- 1.	Does any table have missing values or duplicates? If yes, how would you handle it?
-- first search all over the database for the missing data
SELECT * FROM artist
WHERE name is null;
-- update the data to a value. to update the value we enable safe updates first.and
-- SET SQL_SAFE_UPDATES =1;
update artist
set composer = 'Unknown'
where composer is null;


-- 2.	Find the top-selling tracks and top artist in the USA and identify their most famous genres.
-- TOP SELLING TRACKS IN USA
SELECT t.name, SUM(il.quantity) AS quantity
FROM customer c INNER JOIN invoice i ON c.customer_id = i.customer_id INNER JOIN
invoice_line il ON i.invoice_id = il.invoice_id INNER JOIN track t ON il.track_id = t.track_id
WHERE c.country = 'USA'
GROUP BY t.name
ORDER BY quantity DESC;

-- TOP ARTIST IN USA
SELECT art.artist_id, SUM(il.quantity) AS quantity
FROM customer c INNER JOIN invoice i ON c.customer_id = i.customer_id INNER JOIN
invoice_line il ON i.invoice_id = il.invoice_id INNER JOIN track t ON il.track_id = t.track_id
INNER JOIN album a on t.album_id = a.album_id INNER JOIN artist art ON a.artist_id = art.artist_id
WHERE c.country = 'USA'
GROUP BY art.artist_id
ORDER BY quantity DESC;

-- Top genres of the top artist in USA
SELECT 
    	g.genre_id,
    	g.name AS genre_name,
   	SUM(il.quantity) AS total_sold
FROM
    	invoice_line il
    	INNER JOIN invoice i ON il.invoice_id = i.invoice_id
    	INNER JOIN customer c ON i.customer_id = c.customer_id
    	INNER JOIN track t ON il.track_id = t.track_id
    	INNER JOIN album al ON t.album_id = al.album_id
    	INNER JOIN artist a ON al.artist_id = a.artist_id
    	INNER JOIN genre g ON t.genre_id = g.genre_id
WHERE
    	c.country = 'USA' AND a.artist_id = 152
GROUP BY 
    	g.genre_id, g.name
ORDER BY 
    	total_sold DESC;



-- 3.	What is the customer demographic breakdown (age, gender, location) of Chinook's customer base?
-- Basis of country:
SELECT country, COUNT(*) AS NumberOfCustomers
FROM customer
GROUP BY country
ORDER BY NumberOfCustomers DESC;
-- Basis of State:
SELECT state as state, COUNT(customer_id) AS NumberOfCustomers
FROM customer
WHERE state != 'Unknown State'
GROUP BY state
ORDER BY NumberOfCustomers DESC;
-- Basis of City
SELECT city as city, COUNT(customer_id) AS NumberOfCustomers
FROM customer
GROUP BY city
ORDER BY NumberOfCustomers DESC;

-- 4.	Calculate the total revenue and number of invoices for each country, state, and city:
-- Revenue vs Country
SELECT c.country,
    SUM(il.unit_price * il.quantity) AS total_revenue,
    COUNT(il.invoice_id) AS n_invoices
FROM invoice I JOIN invoice_line il ON il.invoice_id = i.invoice_id JOIN customer c ON c.customer_id = i.customer_id
GROUP BY c.country
ORDER BY total_revenue DESC, n_invoices DESC;
-- Revenue vs State
SELECT COALESCE(c.state, 'N/A') AS state,
    SUM(il.unit_price * il.quantity) AS total_revenue,
    COUNT(il.invoice_id) AS n_invoices
FROM invoice i JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN customer c ON c.customer_id = i.customer_id
GROUP BY state
ORDER BY total_revenue DESC, n_invoices DESC;
-- Revnue vs City
SELECT 
    COALESCE(c.city, 'N/A') AS city,SUM(il.unit_price * il.quantity) AS total_revenue, COUNT(il.invoice_id) AS n_invoices
FROM  invoice I JOIN  invoice_line il ON il.invoice_id = i.invoice_id  JOIN customer c ON c.customer_id = i.customer_id        
GROUP BY city
ORDER BY total_revenue DESC, n_invoices DESC;
                  
--  5.	Find the top 5 customers by total revenue in each country

WITH cte1 as
(select customer_id,billing_country,sum(total) as customer_total,rank() over(partition by billing_country order by sum(total) desc) as rankk
from invoice
group by customer_id,billing_country)

select customer_id,billing_country,customer_total,rankk
from cte1
where rankk <=5
order by billing_country asc;

-- 6.	Identify the top-selling track for each customer
WITH ranked_tracks AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        t.track_id,
        t.name AS track_name,
        SUM(il.quantity) AS total_sales
    FROM 
        customer c
    JOIN 
        invoice i ON i.customer_id = c.customer_id
    JOIN 
        invoice_line il ON il.invoice_id = i.invoice_id
    JOIN 
        track t ON t.track_id = il.track_id
    GROUP BY 
        c.customer_id,
        c.first_name,
        c.last_name,
        t.track_id,
        t.name
)
SELECT 
    customer_id,
    first_name,
    last_name,
    track_id,
    track_name,
    total_sales
FROM 
    ranked_tracks
ORDER BY 
    total_sales DESC;



-- 6.	Identify the top-selling track for each customer
WITH ranked_tracks AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        t.track_id,
        t.name AS track_name,
        SUM(il.quantity) AS total_sales
    FROM 
        customer c
    JOIN 
        invoice i ON i.customer_id = c.customer_id
    JOIN 
        invoice_line il ON il.invoice_id = i.invoice_id
    JOIN 
        track t ON t.track_id = il.track_id
    GROUP BY 
        c.customer_id,
        c.first_name,
        c.last_name,
        t.track_id,
        t.name
)
SELECT 
    customer_id,
    first_name,
    last_name,
    track_id,
    track_name,
    total_sales
FROM 
    ranked_tracks
ORDER BY 
    total_sales DESC;


-- 07.	Are there any patterns or trends in customer purchasing behaviour (e.g., frequency of purchases, preferred payment methods, average order value)?
SELECT
		c.customer_id,
		CONCAT(c.first_name, ' ', c.last_name) as customers,
		YEAR(i.invoice_date) AS year,
		COUNT(i.invoice_id) AS purchase_count
FROM
		customer c
		INNER JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY 
		c.customer_id, customers, YEAR(i.invoice_date)
ORDER BY 
		c.customer_id, customers, YEAR(i.invoice_date);

-- 08.	What is the customer churn rate?
WITH MostRecentInvoice AS (
    SELECT 
        MAX(invoice_date) AS most_recent_invoice_date
    FROM 
        invoice
),
CutoffDate AS (
    SELECT 
        DATE_SUB((SELECT most_recent_invoice_date FROM MostRecentInvoice), INTERVAL 1 YEAR) AS cutoff_date
),
ChurnedCustomers AS (
    SELECT 
        c.customer_id,
        CONCAT(COALESCE(c.first_name, ''), ' ', COALESCE(c.last_name, '')) AS customer_name,
        MAX(i.invoice_date) AS last_purchase_date
    FROM 
        customer c
    LEFT JOIN 
        invoice i ON c.customer_id = i.customer_id
    GROUP BY 
        c.customer_id, customer_name
    HAVING 
        last_purchase_date IS NULL OR last_purchase_date < (SELECT cutoff_date FROM CutoffDate)
)

SELECT 
    (SELECT COUNT(*) FROM ChurnedCustomers) / COUNT(*) * 100 AS churn_rate
FROM 
    customer;

-- 9.	Calculate the percentage of total sales contributed by each genre in the USA and identify the best-selling genres and artists.

WITH genre_counts AS (
    SELECT 
        g.name AS genre_name,
        COUNT(g.genre_id) AS genre_count
    FROM 
        customer c
        INNER JOIN invoice i ON c.customer_id = i.customer_id
        INNER JOIN invoice_line il ON i.invoice_id = il.invoice_id
        INNER JOIN track t ON il.track_id = t.track_id
        INNER JOIN genre g ON t.genre_id = g.genre_id
    WHERE 
        c.country = 'USA'
    GROUP BY 
        g.name
),
total_count AS (
    SELECT 
        COUNT(g.genre_id) AS total_count
    FROM 
        customer c
        INNER JOIN invoice i ON c.customer_id = i.customer_id
        INNER JOIN invoice_line il ON i.invoice_id = il.invoice_id
        INNER JOIN track t ON il.track_id = t.track_id
        INNER JOIN genre g ON t.genre_id = g.genre_id
    WHERE 
        c.country = 'USA'
)

SELECT 
    gc.genre_name,
    gc.genre_count,
    (gc.genre_count * 100 / tc.total_count) AS percentage
FROM 
    genre_counts gc
    CROSS JOIN total_count tc
ORDER BY 
    gc.genre_count DESC;
-- 10.	Find customers who have purchased tracks from at least 3 different genres
SELECT 
        c.first_name, count(distinct g.name) AS genre_count
        
    FROM 
        customer c
        INNER JOIN invoice i ON c.customer_id = i.customer_id
        INNER JOIN invoice_line il ON i.invoice_id = il.invoice_id
        INNER JOIN track t ON il.track_id = t.track_id
        INNER JOIN genre g ON t.genre_id = g.genre_id

	GROUP BY c.first_name
    HAVING count(distinct g.name) >=3
    ORDER BY genre_count DESC;
    -- 11.	Rank genres based on their sales performance in the USA
    select g.name,sum(i.total) as genre_sum, rank() over(order by sum(i.total) desc) as rankk
from customer c inner join invoice i on c.customer_id = i.customer_id inner join invoice_line il on i.invoice_id = il.invoice_id inner join track t on il.track_id = t.track_id
inner join genre g on t.genre_id = g.genre_id
where c.country = "USA"
group by g.name;

-- 12.	Identify customers who have not made a purchase in the last 3 months
WITH cte1 as
(SELECT customer_id,invoice_date,rank() over(partition by customer_id order by invoice_date desc) as rankk
FROM invoice
WHERE invoice_date<'2024-05-09')
SELECT customer_id,date(invoice_date)
FROM cte1
WHERE rankk=1;


-- Subjective Questions

-- 1.	Recommend the three albums from the new record label that should be prioritised for advertising and promotion in the USA based on genre sales analysis.

SELECT
	g.genre_id,
	g.name AS genre_name,
	al.album_id,
	al.title AS new_record_label,
	SUM(il.unit_price * il.quantity) AS total_genre_sales,
	DENSE_RANK() OVER (ORDER BY SUM(il.unit_price * il.quantity) DESC) AS Ranking
FROM 
	genre g
	INNER JOIN track t ON g.genre_id = t.genre_id
	INNER JOIN invoice_line il ON t.track_id = il.track_id 
	INNER JOIN invoice i ON il.invoice_id = i.invoice_id
	INNER JOIN customer c ON i.customer_id = c.customer_id
	INNER JOIN album al on t.album_id = al.album_id
WHERE
	c.country = 'USA'
GROUP BY 
	g.genre_id, g.name, al.album_id,
	al.title
ORDER BY 
	total_genre_sales DESC;

-- 2.	Determine the top-selling genres in countries other than the USA and identify any commonalities or differences.

SELECT 
    g.name,
    SUM(i.total) AS genre_sum,
    RANK() OVER (ORDER BY SUM(i.total) DESC) AS rankk
FROM 
    customer c 
INNER JOIN 
    invoice i ON c.customer_id = i.customer_id 
INNER JOIN 
    invoice_line il ON i.invoice_id = il.invoice_id 
INNER JOIN 
    track t ON il.track_id = t.track_id
INNER JOIN 
    genre g ON t.genre_id = g.genre_id
WHERE 
    c.country != 'USA'
GROUP BY 
    g.name;

-- 3.	Customer Purchasing Behaviour Analysis: How do the purchasing habits (frequency, basket size, spending amount) of long-term customers differ from those of new customers? What insights can these patterns provide about customer loyalty and retention strategies?
WITH Customerinsights AS (
    SELECT 
        	c.customer_id,
        	COUNT(i.invoice_id) AS purchase_frequency,
        	SUM(il.quantity) AS total_items_purchased,
        	SUM(i.total) AS total_spent,
        	AVG(i.total) AS avg_order_value,
        	DATEDIFF(MAX(i.invoice_date), MIN(i.invoice_date)) AS customer_tenure_days
    FROM 
        	customer c JOIN invoice i ON c.customer_id = i.customer_id
        	JOIN invoice_line il ON i.invoice_id = il.invoice_id
    GROUP BY 
        	c.customer_id
),

Customersegment AS (
    SELECT 
        	customer_id,
        	purchase_frequency,
        	total_items_purchased,
        	total_spent,
        	avg_order_value,
        	customer_tenure_days,
        	CASE 
            		WHEN customer_tenure_days >= 365 THEN 'Long-Term'
            		ELSE 'New'
        	END AS customer_segment
    FROM 
        	Customerinsights
)

SELECT 
    	customer_segment,
    	ROUND(AVG(purchase_frequency),2) AS avg_purchase_frequency,
    	ROUND(AVG(total_items_purchased),2) AS avg_basket_size,
    	ROUND(AVG(total_spent),2) AS avg_spending_amount,
    	ROUND(AVG(avg_order_value),2) AS avg_order_value
FROM 
    	Customersegment
GROUP BY 
    	customer_segment;

-- 4.	Product Affinity Analysis: Which music genres, artists, or albums are frequently purchased together by customers? How can this information guide product recommendations and cross-selling initiatives factors? 

-- -- 1. Genre Affinity Analysis --
WITH track_combinations AS (
    SELECT 
        il1.track_id AS track_id_1,
        il2.track_id AS track_id_2,
        COUNT(*) AS times_purchased_together
    FROM 
        invoice_line il1
    JOIN 
        invoice_line il2 ON il1.invoice_id = il2.invoice_id 
                          AND il1.track_id < il2.track_id
    GROUP BY 
        il1.track_id, il2.track_id
),
genre_combinations AS (
    SELECT 
        t1.genre_id AS genre_id_1,
        t2.genre_id AS genre_id_2,
        COUNT(*) AS times_purchased_together
    FROM 
        track_combinations tc
    JOIN 
        track t1 ON tc.track_id_1 = t1.track_id
    JOIN 
        track t2 ON tc.track_id_2 = t2.track_id
    WHERE 
        t1.genre_id <> t2.genre_id
    GROUP BY 
        t1.genre_id, t2.genre_id
)
SELECT 
    g1.name AS genre_1,
    g2.name AS genre_2,
    gc.times_purchased_together
FROM 
    genre_combinations gc
JOIN 
    genre g1 ON gc.genre_id_1 = g1.genre_id
JOIN 
    genre g2 ON gc.genre_id_2 = g2.genre_id
ORDER BY 
    gc.times_purchased_together DESC;
    
-- -- 2. Artist Affinity Analysis --
WITH track_combinations AS (
    SELECT 
        il1.track_id AS track_id_1,
        il2.track_id AS track_id_2,
        COUNT(*) AS times_purchased_together
    FROM 
        invoice_line il1
    JOIN 
        invoice_line il2 ON il1.invoice_id = il2.invoice_id 
                          AND il1.track_id < il2.track_id
    GROUP BY 
        il1.track_id, il2.track_id
),
artist_combinations AS (
    SELECT 
        a1.artist_id AS artist_id_1,
        a2.artist_id AS artist_id_2,
        COUNT(*) AS times_purchased_together
    FROM 
        track_combinations tc
    JOIN 
        track t1 ON tc.track_id_1 = t1.track_id
    JOIN 
        album al1 ON t1.album_id = al1.album_id
    JOIN 
        artist a1 ON al1.artist_id = a1.artist_id
    JOIN 
        track t2 ON tc.track_id_2 = t2.track_id
    JOIN 
        album al2 ON t2.album_id = al2.album_id
    JOIN 
        artist a2 ON al2.artist_id = a2.artist_id
    WHERE 
        a1.artist_id <> a2.artist_id
    GROUP BY 
        a1.artist_id, a2.artist_id
)
SELECT 
    a1.name AS artist_1,
    a2.name AS artist_2,
    ac.times_purchased_together
FROM 
    artist_combinations ac
JOIN 
    artist a1 ON ac.artist_id_1 = a1.artist_id
JOIN 
    artist a2 ON ac.artist_id_2 = a2.artist_id
ORDER BY 
    ac.times_purchased_together DESC;

-- -- 3. Album Affinity Analysis --
WITH track_combinations AS (
    SELECT 
        il1.track_id AS track_id_1,
        il2.track_id AS track_id_2,
        COUNT(*) AS times_purchased_together
    FROM 
        invoice_line il1
    JOIN 
        invoice_line il2 ON il1.invoice_id = il2.invoice_id 
                          AND il1.track_id < il2.track_id
    GROUP BY 
        il1.track_id, il2.track_id
),
album_combinations AS (
    SELECT 
        al1.album_id AS album_id_1,
        al2.album_id AS album_id_2,
        COUNT(*) AS times_purchased_together
    FROM 
        track_combinations tc
    JOIN 
        track t1 ON tc.track_id_1 = t1.track_id
    JOIN 
        album al1 ON t1.album_id = al1.album_id
    JOIN 
        track t2 ON tc.track_id_2 = t2.track_id
    JOIN 
        album al2 ON t2.album_id = al2.album_id
    WHERE 
        al1.album_id <> al2.album_id
    GROUP BY 
        al1.album_id, al2.album_id
)
SELECT 
    al1.title AS album_1,
    al2.title AS album_2,
    ac.times_purchased_together
FROM 
    album_combinations ac
JOIN 
    album al1 ON ac.album_id_1 = al1.album_id
JOIN 
    album al2 ON ac.album_id_2 = al2.album_id
ORDER BY 
    ac.times_purchased_together DESC;

-- 5.	Regional Market Analysis: Do customer purchasing behaviours and churn rates vary across different geographic regions or store locations? How might these correlate with local demographic or economic factors?

SELECT 
    c.country,
    COUNT(c.customer_id) AS Valued_countries
FROM 
    customer c
INNER JOIN (
    SELECT 
        customer_id,
        COUNT(quantity) AS purchased_quantity
    FROM 
        invoice i
    INNER JOIN 
        invoice_line il ON i.invoice_id = il.invoice_id
    GROUP BY 
        customer_id
    HAVING 
        COUNT(quantity) > 100
    ORDER BY 
        purchased_quantity DESC
) AS t ON t.customer_id = c.customer_id
GROUP BY 
    c.country
ORDER BY 
    Valued_countries DESC;

-- 6.	Customer Risk Profiling: Based on customer profiles (age, gender, location, purchase history), which customer segments are more likely to churn or pose a higher risk of reduced spending? What factors contribute to this risk?
SELECT country, COUNT(*) AS NumberOfCustomers
FROM customer
GROUP BY country
ORDER BY NumberOfCustomers DESC;

SELECT 
    c.country,
    COUNT(c.customer_id) AS low_Valued_countries
FROM 
    customer c
INNER JOIN (
    SELECT 
        customer_id,
        COUNT(quantity) AS purchased_quantity
    FROM 
        invoice i
    INNER JOIN 
        invoice_line il ON i.invoice_id = il.invoice_id
    GROUP BY 
        customer_id
    HAVING 
        COUNT(quantity) > 100
    ORDER BY 
        purchased_quantity DESC
) AS t ON t.customer_id = c.customer_id
GROUP BY 
    c.country
ORDER BY 
    low_Valued_countries DESC;

-- 10.	How can you alter the "Albums" table to add a new column named "ReleaseYear" of type INTEGER to store the release year of each album?
ALTER TABLE Album
ADD COLUMN ReleaseYear INTEGER;
select * from album;

-- 11.	Chinook is interested in understanding the purchasing behavior of customers based on their geographical location. They want to know the average total amount spent by customers from each country, along with the number of customers and the average number of tracks purchased per customer. Write an SQL query to provide this information.
-- average tracks per customer

WITH customer_tracks AS (
    SELECT 
        i.customer_id,
        SUM(il.quantity) AS total_tracks
    FROM 
        invoice i
    JOIN 
        invoice_line il ON i.invoice_id = il.invoice_id
    GROUP BY 
        i.customer_id
),
total_customer_spending AS (
    SELECT 
        c.country,
        c.customer_id,
        SUM(i.total) AS total_spent,
        ct.total_tracks
    FROM 
        customer c
    JOIN 
        invoice i ON c.customer_id = i.customer_id
    JOIN 
        customer_tracks ct ON c.customer_id = ct.customer_id
    GROUP BY 
        c.country, c.customer_id, ct.total_tracks
)
SELECT 
    cs.country,
    COUNT(DISTINCT cs.customer_id) AS number_of_customers,
    ROUND(AVG(cs.total_spent),2) AS average_amount_spent_per_customer,
    ROUND(AVG(cs.total_tracks),2) AS average_tracks_purchased_per_customer
FROM 
    total_customer_spending cs
GROUP BY 
    cs.country
ORDER BY 
    average_amount_spent_per_customer DESC;
