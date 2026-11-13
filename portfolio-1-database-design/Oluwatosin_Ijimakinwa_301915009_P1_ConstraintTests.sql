-- PayPulse Fintech Platform: ConstraintTests.sql
-- Negative constraint tests run outside a transaction block so each statement fails independently.
-- Each test violates exactly one rule while keeping all other column values valid.

-- ============================================================================
-- 1. PUBLIC.CUSTOMER CONSTRAINT TESTS
-- ============================================================================

-- Test 1: Required field (NOT NULL) on customer.full_name
-- Expected error: ERROR: null value in column "full_name" of relation "customer" violates not-null constraint
INSERT INTO public.customer (full_name, government_id)
VALUES (NULL, 'GOV-9001');

-- Test 2: Required field (NOT NULL) on customer.government_id
-- Expected error: ERROR: null value in column "government_id" of relation "customer" violates not-null constraint
INSERT INTO public.customer (full_name, government_id)
VALUES ('David Bello', NULL);

-- Test 3: Unique constraint on customer.government_id (Rule 1)
-- Expected error: ERROR: duplicate key value violates unique constraint "customer_government_id_key"
INSERT INTO public.customer (full_name, government_id)
VALUES ('Duplicate Identity User', 'GOV-1001');


-- ============================================================================
-- 2. PUBLIC.BILLER CONSTRAINT TESTS
-- ============================================================================

-- Test 4: Required field (NOT NULL) on biller.biller_name
-- Expected error: ERROR: null value in column "biller_name" of relation "biller" violates not-null constraint
INSERT INTO public.biller (biller_name)
VALUES (NULL);


-- ============================================================================
-- 3. PUBLIC.ACCOUNT CONSTRAINT TESTS
-- ============================================================================

-- Test 5: Required field (NOT NULL) on account.customer_id
-- Expected error: ERROR: null value in column "customer_id" of relation "account" violates not-null constraint
INSERT INTO public.account (customer_id, account_type, balance, is_frozen)
VALUES (NULL, 'Checking', 100.00, FALSE);

-- Test 6: Foreign key constraint on account.customer_id (Rule 1 - non-existent customer)
-- Expected error: ERROR: insert or update on table "account" violates foreign key constraint "account_customer_id_fkey"
INSERT INTO public.account (customer_id, account_type, balance, is_frozen)
VALUES (999999, 'Checking', 100.00, FALSE);

-- Test 7: CHECK constraint on account.account_type (Rule 3 - invalid account category)
-- Expected error: ERROR: new row for relation "account" violates check constraint "account_account_type_check"
INSERT INTO public.account (customer_id, account_type, balance, is_frozen)
VALUES (
    (SELECT customer_id FROM public.customer WHERE government_id = 'GOV-1001'),
    'Crypto Wallet',
    100.00,
    FALSE
);

-- Test 8: CHECK constraint on account.balance >= 0 (Rule 2 - negative balance rejected)
-- Expected error: ERROR: new row for relation "account" violates check constraint "account_balance_check"
INSERT INTO public.account (customer_id, account_type, balance, is_frozen)
VALUES (
    (SELECT customer_id FROM public.customer WHERE government_id = 'GOV-1001'),
    'Savings',
    -50.00,
    FALSE
);

-- Test 9: Required field (NOT NULL) on account.is_frozen
-- Expected error: ERROR: null value in column "is_frozen" of relation "account" violates not-null constraint
INSERT INTO public.account (customer_id, account_type, balance, is_frozen)
VALUES (
    (SELECT customer_id FROM public.customer WHERE government_id = 'GOV-1001'),
    'Savings',
    100.00,
    NULL
);


-- ============================================================================
-- 4. PUBLIC.TRANSACTION CONSTRAINT TESTS
-- ============================================================================

-- Test 10: Foreign key constraint on transaction.source_account_id (non-existent source account)
-- Expected error: ERROR: insert or update on table "transaction" violates foreign key constraint "transaction_source_account_id_fkey"
INSERT INTO public.transaction (source_account_id, destination_account_id, biller_id, amount, transaction_type, created_at)
VALUES (999999, NULL, NULL, 50.00, 'Withdrawal', CURRENT_TIMESTAMP);

-- Test 11: Foreign key constraint on transaction.destination_account_id (non-existent destination account)
-- Expected error: ERROR: insert or update on table "transaction" violates foreign key constraint "transaction_destination_account_id_fkey"
INSERT INTO public.transaction (source_account_id, destination_account_id, biller_id, amount, transaction_type, created_at)
VALUES (NULL, 999999, NULL, 50.00, 'Deposit', CURRENT_TIMESTAMP);

-- Test 12: Foreign key constraint on transaction.biller_id (non-existent biller)
-- Expected error: ERROR: insert or update on table "transaction" violates foreign key constraint "transaction_biller_id_fkey"
INSERT INTO public.transaction (source_account_id, destination_account_id, biller_id, amount, transaction_type, created_at)
VALUES (
    (SELECT a.account_id
       FROM public.account a
       JOIN public.customer c ON a.customer_id = c.customer_id
      WHERE c.government_id = 'GOV-1001' AND a.account_type = 'Checking'),
    NULL,
    999999,
    50.00,
    'Payment',
    CURRENT_TIMESTAMP
);

-- Test 13: CHECK constraint on transaction.amount > 0 (Rule 5 - zero or negative amount rejected)
-- Expected error: ERROR: new row for relation "transaction" violates check constraint "transaction_amount_check"
INSERT INTO public.transaction (source_account_id, destination_account_id, biller_id, amount, transaction_type, created_at)
VALUES (
    NULL,
    (SELECT a.account_id
       FROM public.account a
       JOIN public.customer c ON a.customer_id = c.customer_id
      WHERE c.government_id = 'GOV-1001' AND a.account_type = 'Checking'),
    NULL,
    0.00,
    'Deposit',
    CURRENT_TIMESTAMP
);

-- Test 14: CHECK constraint on transaction.transaction_type (Rule 4 - invalid transaction type)
-- Expected error: ERROR: new row for relation "transaction" violates check constraint "transaction_transaction_type_check"
INSERT INTO public.transaction (source_account_id, destination_account_id, biller_id, amount, transaction_type, created_at)
VALUES (
    NULL,
    (SELECT a.account_id
       FROM public.account a
       JOIN public.customer c ON a.customer_id = c.customer_id
      WHERE c.government_id = 'GOV-1001' AND a.account_type = 'Checking'),
    NULL,
    50.00,
    'CryptoSwap',
    CURRENT_TIMESTAMP
);

-- Test 15: CHECK constraint on transaction.created_at <= CURRENT_TIMESTAMP (Rule 8 - future timestamp rejected)
-- Expected error: ERROR: new row for relation "transaction" violates check constraint "transaction_created_at_check"
INSERT INTO public.transaction (source_account_id, destination_account_id, biller_id, amount, transaction_type, created_at)
VALUES (
    NULL,
    (SELECT a.account_id
       FROM public.account a
       JOIN public.customer c ON a.customer_id = c.customer_id
      WHERE c.government_id = 'GOV-1001' AND a.account_type = 'Checking'),
    NULL,
    50.00,
    'Deposit',
    CURRENT_TIMESTAMP + INTERVAL '1 day'
);

-- Test 16: CHECK constraint on source_account_id <> destination_account_id (Rule 6 - self-transfer rejected)
-- Expected error: ERROR: new row for relation "transaction" violates check constraint "transaction_check"
INSERT INTO public.transaction (source_account_id, destination_account_id, biller_id, amount, transaction_type, created_at)
VALUES (
    (SELECT a.account_id
       FROM public.account a
       JOIN public.customer c ON a.customer_id = c.customer_id
      WHERE c.government_id = 'GOV-1001' AND a.account_type = 'Checking'),
    (SELECT a.account_id
       FROM public.account a
       JOIN public.customer c ON a.customer_id = c.customer_id
      WHERE c.government_id = 'GOV-1001' AND a.account_type = 'Checking'),
    NULL,
    50.00,
    'Transfer',
    CURRENT_TIMESTAMP
);


-- ============================================================================
-- 5. ROW COUNT VERIFICATION QUERY
-- ============================================================================

-- Expected counts after SampleData.sql succeeds and all 16 invalid inserts fail:
--   account     : 4
--   biller      : 2
--   customer    : 3
--   transaction : 4
SELECT 'account' AS table_name, COUNT(*) AS row_count FROM public.account
UNION ALL
SELECT 'biller' AS table_name, COUNT(*) AS row_count FROM public.biller
UNION ALL
SELECT 'customer' AS table_name, COUNT(*) AS row_count FROM public.customer
UNION ALL
SELECT 'transaction' AS table_name, COUNT(*) AS row_count FROM public.transaction
ORDER BY table_name;
