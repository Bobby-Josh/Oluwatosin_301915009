BEGIN;

-- PayPulse Fintech Platform PostgreSQL 16 Schema

-- 1. Customer table (Rule 1: unique customer ID and government ID)
CREATE TABLE public.customer (
    customer_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name VARCHAR NOT NULL,
    government_id VARCHAR NOT NULL UNIQUE
);

-- 2. Biller table (registered utility and service providers)
CREATE TABLE public.biller (
    biller_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    biller_name VARCHAR NOT NULL
);

-- 3. Account table (Rules 1, 2, 3: owner link, non-negative balance, valid types)
CREATE TABLE public.account (
    account_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES public.customer(customer_id),
    account_type VARCHAR NOT NULL CHECK (account_type IN ('Savings', 'Checking', 'Money Market')),
    balance NUMERIC NOT NULL CHECK (balance >= 0),
    is_frozen BOOLEAN NOT NULL DEFAULT FALSE
);

-- 4. Transaction table (Rules 4, 5, 6, 8: valid types, positive amount, distinct accounts, no future dates)
CREATE TABLE public.transaction (
    transaction_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_account_id INT REFERENCES public.account(account_id),
    destination_account_id INT REFERENCES public.account(account_id),
    biller_id INT REFERENCES public.biller(biller_id),
    amount NUMERIC NOT NULL CHECK (amount > 0),
    transaction_type VARCHAR NOT NULL CHECK (transaction_type IN ('Deposit', 'Withdrawal', 'Transfer', 'Payment')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP CHECK (created_at <= CURRENT_TIMESTAMP),
    CHECK (source_account_id <> destination_account_id)
);

-- Note on cross-row and lifecycle rules not enforced by table definitions alone:
-- Rule 5 (checking amount <= source account balance), Rule 7 (blocking frozen accounts),
-- and Rule 8 (preventing updates/deletes on committed transactions) require later
-- transaction logic, triggers, or database access privileges.

COMMIT;