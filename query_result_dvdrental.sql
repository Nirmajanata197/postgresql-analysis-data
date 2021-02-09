-- 1. Berapa total DVD yang disewa dan total pendapatan tiap genre? Genre apa yang paling banyak disewa dan memiliki total pendapatan paling tinggi?

WITH cte1 AS (
	 SELECT c.name genre, COUNT(r.*) total_sewa
	 FROM rental AS r
	 INNER JOIN inventory AS i
	 ON r.inventory_id = i.inventory_id
	 INNER JOIN film AS f
	 ON i.film_id = f.film_id
	 INNER JOIN film_category as fc
	 ON f.film_id = fc.film_id
	 INNER JOIN category as c
	 ON fc.category_id = c.category_id
	 GROUP BY 1
	 ORDER BY 2 DESC
 	),
 	cte2 AS (
	 SELECT c.name genre, SUM(p.amount) total_pendapatan
	 FROM rental AS r
	 INNER JOIN payment AS p
	 ON r.rental_id = p.rental_id
	 INNER JOIN inventory AS i
	 ON r.inventory_id = i.inventory_id
	 INNER JOIN film AS f
	 ON i.film_id = f.film_id
	 INNER JOIN film_category as fc
	 ON f.film_id = fc.film_id
	 INNER JOIN category as c
	 ON fc.category_id = c.category_id
	 GROUP BY 1
 	)
 SELECT cte1.genre, total_sewa, total_pendapatan
 FROM cte1
 INNER JOIN cte2
 ON cte1.genre = cte2.genre
 ORDER BY 2 DESC, 3 DESC;


-- 2.	Berapa total sewa dan total pendapatan yang diterima perusahaan tiap bulan? Pada bulan apa perusahaan mendapat order total sewa dan total pendapatan tertinggi?

SELECT DATE_PART('month', payment_date) AS bulan, COUNT(r.rental_id) AS total_sewa,
  	SUM(amount) AS total_pendapatan
 FROM payment AS p
 INNER JOIN rental AS r
 USING(rental_id)
 GROUP BY 1
 ORDER BY 2 DESC, 3 DESC;


-- 3.	Berapa total pendapatan pada masing-masing hari yang berbeda (day of week)?
-- Pada hari apa perusahaan menerima total pendapatan tertinggi dan terendah?


SELECT DATE_PART('dow', payment_date) AS day_of_week, 
	  COUNT(r.rental_id) AS total_sewa,
	  SUM(amount) AS total_pendapatan
 FROM payment AS p
 INNER JOIN rental AS r
 USING(rental_id)
 GROUP BY 1
 ORDER BY 2 DESC, 3 DESC;


-- 4.	Siapa staff yang menghasilkan total sewa dan total pendapatan paling tinggi?

WITH table1 AS (
	  SELECT s.staff_id, CONCAT(first_name, ' ', last_name) 
	   AS nama_staf, SUM(amount) AS total_pendapatan
	  FROM staff AS s
	  INNER JOIN payment AS p
	  ON s.staff_id = p.staff_id
	  GROUP BY 1
	),
	table2 AS(
	  SELECT s.staff_id, COUNT(r.staff_id) AS total_sewa
	  FROM staff AS s
	  INNER JOIN rental AS r
	  ON s.staff_id = r.staff_id
	  GROUP BY 1
  	)

SELECT table1.staff_id AS id_staf, nama_staf, total_sewa, total_pendapatan
FROM table1
INNER JOIN table2
ON table1.staff_id = table2.staff_id;


-- 5.	Berapa banyak pelanggan berbeda yang menyewa DVD setiap genre?


SELECT ca.name AS genre, COUNT(DISTINCT cu.customer_id) AS customer_unik
 FROM customer AS cu
 INNER JOIN rental AS r
 ON cu.customer_id = r.customer_id
 INNER JOIN inventory AS i
 ON r.inventory_id = i.inventory_id
 INNER JOIN film AS f
 ON i.film_id = f.film_id
 INNER JOIN film_category AS fc
 ON f.film_id = fc.film_id
 INNER JOIN category AS ca
 ON fc.category_id = ca.category_id
 GROUP BY 1
 ORDER BY 2 DESC;


-- 6.	Berapa tarif sewa rata-rata untuk setiap genre? (dari yang tertinggi ke terendah)


SELECT ca.name AS genre, ROUND(AVG(f.rental_rate), 2) AS rerata_tarif_sewa
 FROM film AS f
 INNER JOIN film_category AS fc
 USING(film_id)
 INNER JOIN category AS ca
 USING(category_id)
 GROUP BY 1
 ORDER BY 2 DESC;


-- 7.	Berapa total DVD film yang dikembalikan terlambat, lebih awal, dan tepat waktu? sebutkan persentase masing-masing status pengembalian

	
WITH table1 AS(
	SELECT (return_date - rental_date) AS diff_date, EXTRACT(DAY FROM return_date - rental_date) AS lama_sewa, inventory_id
	FROM rental
	),
  table2 AS(
   	SELECT rental_duration, lama_sewa,
      CASE WHEN rental_duration > lama_sewa THEN 'Lebih Awal'
           WHEN rental_duration = lama_sewa THEN 'Tepat Waktu'
           ELSE 'Terlambat'
      END AS status_pengembalian
   	FROM film AS f
   	INNER JOIN inventory AS i
   	USING(film_id)
   	INNER JOIN table1
   	USING(inventory_id)
  	),
  table3 AS(
   	SELECT table2.status_pengembalian AS status_pengembalian,
      count(table2.status_pengembalian) AS total_status_pengembalian
   	FROM table2
   	GROUP BY 1
  ),
  table4 AS(
    SELECT SUM(total_status_pengembalian) AS total_sp
    FROM table3
  ), 
  table5 AS(
    SELECT table3.status_pengembalian, ROUND(table3.total_status_pengembalian / table4.total_sp * 100, 2) AS "persentase_status_pengembalian (%)"
    from table3
    CROSS JOIN table4
  )
  
 SELECT *
 FROM table3
 INNER JOIN table5
 USING(status_pengembalian);



-- 8.	Sebutkan negara mana saja yang menjadi basis lokasi perusahaan DVD rental ‘XYZ’? Berapa basis pelanggan dari perusahaan DVD rental ‘XYZ’ di setiap negara? Berapa total pendapatan yang diterima dari setiap negara? (dari tertinggi hingga terendah)

SELECT co.country_id AS id_negara, co.country AS negara, COUNT(DISTINCT cu.customer_id) AS total_pelanggan, SUM(p.amount) AS total_pendapatan
 FROM country AS co
 INNER JOIN city AS ci
 USING(country_id)
 INNER JOIN address AS a
 USING(city_id)
 INNER JOIN customer AS cu
 USING(address_id)
 INNER JOIN payment AS p
 USING(customer_id)
 GROUP BY 1, 2
 ORDER BY 4 DESC;



-- 9.	Siapakah 10 pelanggan yang loyal terhadap perusahaan DVD rental ‘XYZ’ ditinjau dari total pembayaran tertinggi. Berikan alamat detail dari 10 pelanggan tersebut sehingga perusahaan dapat memberikan reward atau hadiah kepada mereka

WITH table1 AS(
     SELECT customer_id AS id_pelanggan, CONCAT(first_name, ' ', last_name) AS nama_pelanggan, email, SUM(amount) AS total_pembayaran,
     	address AS alamat, district AS distrik, postal_code AS kode_pos, phone AS no_telp, city AS kota, country AS negara
     FROM payment AS p
     INNER JOIN customer AS cu
     USING(customer_id)
     INNER JOIN address AS a
     USING(address_id)
     INNER JOIN city AS ci
     USING(city_id)
     INNER JOIN country AS co
     USING(country_id)
     GROUP BY 1, 2, 3, 5, 6, 7, 8, 9, 10
     ORDER BY 4 DESC
     LIMIT 10)
SELECT *
FROM table1;