-- Check active isolation level and existing customer records
SHOW transaction_isolation;

SELECT
    customer_id,
    full_name,
    government_id
FROM public.customer
ORDER BY customer_id ASC;

-- Session A: Start transaction and insert a new customer with GOV-1004
BEGIN ISOLATION LEVEL READ COMMITTED;

INSERT INTO public.customer (full_name, government_id)
VALUES ('David Nwosu', 'GOV-1004');

SELECT
    customer_id,
    full_name,
    government_id
FROM public.customer
ORDER BY customer_id ASC;

-- Session A: Commit David Nwosu (GOV-1004)
COMMIT;