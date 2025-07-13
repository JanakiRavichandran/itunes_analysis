-- Creating and Using Schema
CREATE SCHEMA itunes;
USE itunes;
-- Importing Tables from Csv to Sql using Import Wizard
CREATE TABLE employee  (last_name varchar(30),first_name varchar(30),title varchar(50),reports_to	int NULL,levels varchar(10),birthdate datetime,hire_date datetime,address varchar(50),city varchar(30),state varchar(30),country varchar(30),postal_code varchar(30),phone varchar(30),fax varchar(30),email varchar(50));
select * from employee;

CREATE TABLE albums (album_id int, title varchar(30),artist_id int);
select * from albums;

CREATE TABLE artist (artist_id int,name varchar(30));
select * from artist;

CREATE TABLE customer(customer_id int,first_name varchar(50),last_name varchar(50),company varchar(50)NULL,address varchar(50),city varchar(30),state varchar(30) NULL,country varchar(30),postal_code varchar(30)NULL,phone varchar(30) NULL,fax varchar(30)NULL,email varchar(50),support_rep_id int);
select * from customer;

CREATE TABLE genre(genre_id int,name varchar(30));
select * from genre;

CREATE TABLE invoice(invoice_id int,customer_id int,invoice_date datetime,billing_address varchar(50),billing_city varchar(30),billing_state varchar(30),billing_country varchar(30),billing_postal_code varchar(30),total float);
select * from invoice;

CREATE TABLE invoice_line(invoice_line_id int,invoice_id int,track_id int,unit_price float,quantity int);
select * from invoice_line;

CREATE TABLE media_type(media_type_id int,name varchar(30));
select * from media_type;

CREATE TABLE playlist(playlist_id int,name varchar(30));
select * from playlist;

CREATE TABLE playlist_track(playlist_id int,track_id int);
select * from playlist_track;
-- Visualizing all the imported tables
SHOW TABLES;

-- Creating Tables for Analysis and Visualization

-- Objective 1 - Analyze Customer Behavior

-- Q1. Which countries have the highest number of customers?
CREATE TABLE customer_country_summary AS
SELECT country, 
       COUNT(customer_id) AS customer_count,
       ROUND(COUNT(customer_id) * 100.0 / (SELECT COUNT(*) FROM customer), 2) AS total_percentage
FROM customer
GROUP BY country
ORDER BY customer_count DESC;

SELECT * FROM customer_country_summary;

-- Q2. What is the average purchase amount per customer by country?
CREATE TABLE avg_customer_purchase_country AS
SELECT customer.country,
       ROUND(SUM(invoice.total)/COUNT(DISTINCT invoice.customer_id), 2) AS average_customer_purchase
FROM invoice
INNER JOIN customer ON customer.customer_id = invoice.customer_id
GROUP BY customer.country
ORDER BY average_customer_purchase DESC;

SELECT * FROM avg_customer_purchase_country;

-- Q3. Who are the top 10% of customers based on total spending?
CREATE TABLE top_10_percent_customers AS
SELECT customer_id, first_name, last_name, total_spent
FROM (
    SELECT customer.customer_id, customer.first_name, customer.last_name,
           SUM(invoice.total) AS total_spent,
           NTILE(10) OVER (ORDER BY SUM(invoice.total) DESC) AS decile
    FROM customer
    JOIN invoice ON customer.customer_id = invoice.customer_id
    GROUP BY customer.customer_id
) AS ranked
WHERE decile = 1
ORDER BY total_spent DESC;

SELECT * FROM top_10_percent_customers;

-- Objective 2 - Identify Popular and Unpopular Content

-- Q4. Which music genres are most and least popular based on number of purchases?
CREATE TABLE most_famous_genre AS
SELECT genre.name AS genre_name,
       COUNT(invoice_line.invoice_line_id) AS total_purchases,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM invoice_line), 2) AS purchase_percentage
FROM invoice_line
JOIN track ON track.track_id = invoice_line.track_id
JOIN genre ON genre.genre_id = track.genre_id
GROUP BY genre.genre_id, genre.name
ORDER BY total_purchases DESC;

SELECT * FROM most_famous_genre;

-- Q5. Which playlists have the most purchased tracks?
CREATE TABLE most_purchased_track AS
SELECT playlisttrack.playlist_id, playlist.name,
       COUNT(invoice_line.invoice_line_id) AS invoice_count
FROM invoice_line
JOIN playlist_track AS playlisttrack ON invoice_line.track_id = playlisttrack.track_id
JOIN playlist ON playlisttrack.playlist_id = playlist.playlist_id
GROUP BY playlisttrack.playlist_id, playlist.name
ORDER BY invoice_count DESC;

SELECT * FROM most_purchased_track;

-- Q6. Which playlists contain the most unique tracks that were purchased?
CREATE TABLE most_unique_tracks AS
SELECT playlisttrack.playlist_id, playlist.name,
       COUNT(DISTINCT invoice_line.track_id) AS unique_purchases
FROM playlist_track AS playlisttrack
JOIN invoice_line ON playlisttrack.track_id = invoice_line.track_id
JOIN playlist ON playlisttrack.playlist_id = playlist.playlist_id
GROUP BY playlisttrack.playlist_id, playlist.name
ORDER BY unique_purchases DESC;

SELECT * FROM most_unique_tracks;

-- Objective 3 - Evaluate Sales Performance

-- Q7. Which support representatives (employees) generated the highest total sales?
CREATE TABLE employee_highest_total AS
SELECT support_rep_id,
       ROUND(SUM(invoice.total), 2) AS total_sales
FROM customer
JOIN invoice ON customer.customer_id = invoice.customer_id
GROUP BY support_rep_id
ORDER BY total_sales DESC;

SELECT * FROM employee_highest_total;

-- Q8. Which countries/regions have the highest total sales revenue?
CREATE TABLE highest_revenue_country AS
SELECT billing_country,
       ROUND(SUM(total), 2) AS total_revenue
FROM invoice
GROUP BY billing_country
ORDER BY total_revenue DESC;

SELECT * FROM highest_revenue_country;

-- Q9. Which employee manages customers from the highest number of different countries?
CREATE TABLE employee_highest_different_country AS
SELECT support_rep_id,
       COUNT(DISTINCT country) AS country_count
FROM customer
GROUP BY support_rep_id
ORDER BY country_count DESC;

SELECT * FROM employee_highest_different_country;

-- Objective 4 - Analyze Revenue Trends

-- Q10. What is the total revenue generated each year?
CREATE TABLE total_revenue_year AS
SELECT billing_year,
       ROUND(SUM(total), 2) AS total_revenue
FROM (
    SELECT STR_TO_DATE(SUBSTRING_INDEX(invoice_date, ' ', 1), '%c/%e/%Y') AS full_date,
           YEAR(STR_TO_DATE(SUBSTRING_INDEX(invoice_date, ' ', 1), '%c/%e/%Y')) AS billing_year,
           total
    FROM invoice
) AS sub
WHERE full_date IS NOT NULL
GROUP BY billing_year
ORDER BY total_revenue DESC;

SELECT * FROM total_revenue_year;

-- Q11. What is the total revenue by month and year?
CREATE TABLE total_revenue_month AS
SELECT billing_month_year,
       ROUND(SUM(total), 2) AS total_revenue
FROM (
    SELECT STR_TO_DATE(SUBSTRING_INDEX(invoice_date, ' ', 1), '%c/%e/%Y') AS full_date,
           DATE_FORMAT(STR_TO_DATE(SUBSTRING_INDEX(invoice_date, ' ', 1), '%c/%e/%Y'), '%Y-%m') AS billing_month_year,
           total
    FROM invoice
) AS sub
WHERE full_date IS NOT NULL
GROUP BY billing_month_year
ORDER BY billing_month_year;

SELECT * FROM total_revenue_month;

-- Q12. What is the total revenue by media type?
CREATE TABLE total_revenue_media AS
SELECT media.media_type_id, media.name,
       ROUND(SUM(invoice.total), 2) AS total_revenue
FROM invoice
JOIN invoice_line ON invoice.invoice_id = invoice_line.invoice_id
JOIN track ON invoice_line.track_id = track.track_id
JOIN media_type AS media ON track.media_type_id = media.media_type_id
GROUP BY media.media_type_id, media.name;

SELECT * FROM total_revenue_media;

-- Objective 5 - Find Growth Opportunities

-- Q13. Which tracks have never been purchased?
CREATE TABLE tracks_never_purchased AS
SELECT track.track_id, track.name
FROM track
LEFT JOIN invoice_line ON track.track_id = invoice_line.track_id
WHERE invoice_line.track_id IS NULL;

SELECT * FROM tracks_never_purchased;

-- Q14. Who are the customers who have never made a purchase?
CREATE TABLE inactive_customer AS
SELECT customer.customer_id, customer.first_name, customer.last_name
FROM customer
LEFT JOIN invoice ON customer.customer_id = invoice.customer_id
WHERE invoice.invoice_id IS NULL;

SELECT * FROM inactive_customer;

-- Q15. Which artists have the fewest purchases?
CREATE TABLE least_purchased_artists AS
SELECT artist.artist_id, artist.name,
       COUNT(invoice_line.invoice_line_id) AS purchase_count
FROM artist
JOIN albums ON artist.artist_id = albums.artist_id
JOIN track ON albums.album_id = track.album_id
LEFT JOIN invoice_line ON track.track_id = invoice_line.track_id
GROUP BY artist.artist_id, artist.name
ORDER BY purchase_count ASC;

SELECT * FROM least_purchased_artists;







