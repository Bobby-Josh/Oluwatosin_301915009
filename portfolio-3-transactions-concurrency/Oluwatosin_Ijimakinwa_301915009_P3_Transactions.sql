-- Check starting balances and frozen flags in public.account
SELECT
    account_id,
    customer_id,
    account_type,
    balance,
    is_frozen
FROM public.account
ORDER BY account_id ASC;

-- Check starting records in public.transaction
SELECT
    transaction_id,
    source_account_id,
    destination_account_id,
    biller_id,
    amount,
    transaction_type,
    created_at
FROM public.transaction
ORDER BY transaction_id ASC;

-- Credit 50.00 to active Checking account 3 only when balance equals 950.00
BEGIN;

UPDATE public.account
SET balance = balance + 50.00
WHERE account_id = 3
  AND balance = 950.00
  AND is_frozen = false;

COMMIT;

-- Repeat check: re-running the guarded update must affect 0 rows
UPDATE public.account
SET balance = balance + 50.00
WHERE account_id = 3
  AND balance = 950.00
  AND is_frozen = false;

  -- Apply a valid debit on account 1, then violate Business Rule 5 (amount > 0)
BEGIN;

UPDATE public.account
SET balance = balance - 300.00
WHERE account_id = 1
  AND balance >= 300.00
  AND is_frozen = false;

INSERT INTO public.transaction (
    source_account_id,
    destination_account_id,
    biller_id,
    amount,
    transaction_type,
    created_at
)
VALUES (
    1,
    3,
    NULL,
    -50.00,
    'Transfer',
    TIMESTAMP '2026-11-13 14:30:00'
);

ROLLBACK;

-- Verify account 3 keeps 1000.00 (committed) while account 1 stays 1500.00 (rolled back)
SELECT
    account_id,
    customer_id,
    account_type,
    balance,
    is_frozen
FROM public.account
ORDER BY account_id ASC;

-- Verify no failed transaction row was persisted
SELECT
    transaction_id,
    source_account_id,
    destination_account_id,
    biller_id,
    amount,
    transaction_type,
    created_at
FROM public.transaction
ORDER BY transaction_id ASC;