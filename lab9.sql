CREATE OR REPLACE FUNCTION calculate_discount(
    original_price NUMERIC,
    discount_percent NUMERIC
)
RETURNS NUMERIC AS $$
BEGIN
    RETURN original_price - (original_price * discount_percent / 100);
END;
$$ LANGUAGE plpgsql;

SELECT calculate_discount(100, 15);
SELECT calculate_discount(250.50, 20);

CREATE OR REPLACE FUNCTION film_stats(
    p_rating VARCHAR,
    OUT total_films INTEGER,
    OUT avg_rental_rate NUMERIC
)
AS $$
BEGIN
    SELECT 
        COUNT(*),
        AVG(rental_rate)
    INTO total_films, avg_rental_rate
    FROM film
    WHERE rating = p_rating;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM film_stats('PG');
SELECT * FROM film_stats('R');

CREATE OR REPLACE FUNCTION get_customer_rentals(p_customer_id INTEGER)
RETURNS TABLE(
    rental_date DATE,
    film_title VARCHAR,
    return_date DATE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.rental_date::DATE,
        f.title,
        r.return_date::DATE
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film f ON i.film_id = f.film_id
    WHERE r.customer_id = p_customer_id
    ORDER BY r.rental_date;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM get_customer_rentals(1);
SELECT * FROM get_customer_rentals(5) LIMIT 5;

CREATE OR REPLACE FUNCTION search_films(
    p_title_pattern VARCHAR
)
RETURNS TABLE(
    title VARCHAR,
    release_year INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        title,
        release_year
    FROM film
    WHERE title LIKE p_title_pattern;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION search_films(
    p_title_pattern VARCHAR,
    p_rating VARCHAR
)
RETURNS TABLE(
    title VARCHAR,
    release_year INTEGER,
    rating VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        title,
        release_year,
        rating
    FROM film
    WHERE title LIKE p_title_pattern
      AND rating = p_rating;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM search_films('A%');
SELECT * FROM search_films('A%', 'PG');