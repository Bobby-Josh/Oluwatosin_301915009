-- Query 1: List outgoing transactions joined with source account and customer details
SELECT
    t.transaction_id,
    c.full_name,
    c.government_id,
    a.account_id AS source_account_id,
    a.account_type,
    t.transaction_type,
    t.amount
FROM public.transaction AS t
INNER JOIN public.account AS a
    ON t.source_account_id = a.account_id
INNER JOIN public.customer AS c
    ON a.customer_id = c.customer_id
WHERE t.created_at >= TIMESTAMP '2026-01-01 00:00:00'
ORDER BY t.transaction_id ASC;

-- Query 2: Identify accounts that have neither initiated nor received any transaction (Rule 7 check)
SELECT
    a.account_id,
    c.full_name,
    a.account_type,
    a.balance,
    a.is_frozen
FROM public.account AS a
INNER JOIN public.customer AS c
    ON a.customer_id = c.customer_id
WHERE NOT EXISTS (
    SELECT 1
    FROM public.transaction AS t
    WHERE t.source_account_id = a.account_id
       OR t.destination_account_id = a.account_id
)
ORDER BY a.account_id ASC;

-- Query 3: Count payment transactions per biller while retaining billers with zero payments
SELECT
    b.biller_id,
    b.biller_name,
    COUNT(t.transaction_id) AS payment_count
FROM public.biller AS b
LEFT JOIN public.transaction AS t
    ON b.biller_id = t.biller_id
GROUP BY b.biller_id, b.biller_name
ORDER BY b.biller_id ASC;