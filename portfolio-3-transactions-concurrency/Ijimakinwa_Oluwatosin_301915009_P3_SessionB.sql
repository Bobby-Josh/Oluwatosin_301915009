-- Session B: Start an independent transaction and read public.customer
BEGIN ISOLATION LEVEL READ COMMITTED;

SELECT
    customer_id,
    full_name,
    government_id
FROM public.customer
ORDER BY customer_id ASC;

-- Attempt to register a different customer using the same GOV-1004
INSERT INTO public.customer (full_name, government_id)
VALUES ('Daniel Eze', 'GOV-1004');

-- Session B: Roll back the failed transaction and verify final table state
ROLLBACK;

SELECT
    customer_id,
    full_name,
    government_id
FROM public.customer
ORDER BY customer_id ASC;