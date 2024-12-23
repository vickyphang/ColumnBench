SELECT count(*) FROM uk_price_paid;
SELECT city, AVG(price) AS average_price FROM uk_price_paid GROUP BY city ORDER BY average_price DESC LIMIT 10;
SELECT postcode, AVG(price) AS average_price FROM uk_price_paid GROUP BY postcode ORDER BY average_price DESC LIMIT 10;
SELECT property_type, COUNT(*) AS property_count, ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage FROM uk_price_paid GROUP BY property_type ORDER BY property_count DESC;
SELECT COUNT(*) AS missing_postcodes FROM uk_price_paid WHERE postcode IS NULL OR postcode = '';
SELECT EXTRACT(YEAR FROM transfer_date) AS year, ROUND(AVG(price)) AS price, REPEAT('#', CAST(ROUND((AVG(price) - 0) / 1000000 * 80) AS INT)) AS bar FROM uk_price_paid GROUP BY year ORDER BY year;
SELECT EXTRACT(YEAR FROM transfer_date) AS year, ROUND(AVG(price)) AS price, REPEAT('#', CAST(ROUND((AVG(price) - 0) / 2000000 * 100) AS INT)) AS bar FROM uk_price_paid WHERE city = 'LONDON' GROUP BY year ORDER BY year;