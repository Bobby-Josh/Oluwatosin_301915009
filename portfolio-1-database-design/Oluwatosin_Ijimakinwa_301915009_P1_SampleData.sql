BEGIN;

-- PayPulse Fintech Platform: SampleData.sql
-- Inserts a small valid dataset in parent-before-child order.
-- Note: The agreed public.customer schema stores full_name and government_id (no email column).

-- 1. Insert parent records into public.customer (Rule 1: unique government_id)
INSERT INTO public.customer (full_name, government_id) VALUES
    ('Alice Mensah', 'GOV-1001'),
    ('Bob Okafor', 'GOV-1002'),
    ('Clara Adeyemi', 'GOV-1003');

-- 2. Insert parent records into public.biller
INSERT INTO public.biller (biller_name) VALUES
    ('Eko Electric Utility'),
    ('Lagos Water Works');

-- 3. Insert child records into public.account (looking up customer_id via unique government_id)
-- Covers all account types ('Checking', 'Savings', 'Money Market'), zero/positive balances, and active/frozen states
INSERT INTO public.account (customer_id, account_type, balance, is_frozen) VALUES
    ((SELECT customer_id FROM public.customer WHERE government_id = 'GOV-1001'), 'Checking', 1500.00, FALSE),
    ((SELECT customer_id FROM public.customer WHERE government_id = 'GOV-1001'), 'Savings', 5000.00, FALSE),
    ((SELECT customer_id FROM public.customer WHERE government_id = 'GOV-1002'), 'Checking', 850.00, FALSE),
    ((SELECT customer_id FROM public.customer WHERE government_id = 'GOV-1003'), 'Money Market', 0.00, TRUE);

-- 4. Insert child records into public.transaction (looking up account_id and biller_id dynamically)
-- Covers all four transaction types: Deposit, Transfer, Payment, and Withdrawal

-- 4a. Deposit into Alice's Checking account
INSERT INTO public.transaction (
    source_account_id,
    destination_account_id,
    biller_id,
    amount,
    transaction_type,
    created_at
) VALUES (
    NULL,
    (SELECT a.account_id
       FROM public.account a
       JOIN public.customer c ON a.customer_id = c.customer_id
      WHERE c.government_id = 'GOV-1001' AND a.account_type = 'Checking'),
    NULL,
    1500.00,
    'Deposit',
    CURRENT_TIMESTAMP - INTERVAL '2 days'
);

-- 4b. Peer-to-peer Transfer from Alice's Checking account to Bob's Checking account
INSERT INTO public.transaction (
    source_account_id,
    destination_account_id,
    biller_id,
    amount,
    transaction_type,
    created_at
) VALUES (
    (SELECT a.account_id
       FROM public.account a
       JOIN public.customer c ON a.customer_id = c.customer_id
      WHERE c.government_id = 'GOV-1001' AND a.account_type = 'Checking'),
    (SELECT a.account_id
       FROM public.account a
       JOIN public.customer c ON a.customer_id = c.customer_id
      WHERE c.government_id = 'GOV-1002' AND a.account_type = 'Checking'),
    NULL,
    250.00,
    'Transfer',
    CURRENT_TIMESTAMP - INTERVAL '1 day'
);

-- 4c. Bill Payment from Bob's Checking account to Eko Electric Utility
INSERT INTO public.transaction (
    source_account_id,
    destination_account_id,
    biller_id,
    amount,
    transaction_type,
    created_at
) VALUES (
    (SELECT a.account_id
       FROM public.account a
       JOIN public.customer c ON a.customer_id = c.customer_id
      WHERE c.government_id = 'GOV-1002' AND a.account_type = 'Checking'),
    NULL,
    (SELECT biller_id FROM public.biller WHERE biller_name = 'Eko Electric Utility'),
    75.50,
    'Payment',
    CURRENT_TIMESTAMP - INTERVAL '12 hours'
);

-- 4d. Withdrawal from Alice's Savings account
INSERT INTO public.transaction (
    source_account_id,
    destination_account_id,
    biller_id,
    amount,
    transaction_type,
    created_at
) VALUES (
    (SELECT a.account_id
       FROM public.account a
       JOIN public.customer c ON a.customer_id = c.customer_id
      WHERE c.government_id = 'GOV-1001' AND a.account_type = 'Savings'),
    NULL,
    NULL,
    200.00,
    'Withdrawal',
    CURRENT_TIMESTAMP - INTERVAL '1 hour'
);

COMMIT;