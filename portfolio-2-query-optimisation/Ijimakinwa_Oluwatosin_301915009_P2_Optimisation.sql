-- Create an isolated benchmark schema and synthetic transaction history table
CREATE SCHEMA p2_benchmark;

CREATE TABLE p2_benchmark.synthetic_transaction_history (
    history_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    source_account_id INT REFERENCES public.account(account_id),
    destination_account_id INT REFERENCES public.account(account_id),
    biller_id INT REFERENCES public.biller(biller_id),
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    transaction_type VARCHAR NOT NULL CHECK (transaction_type IN ('Deposit', 'Withdrawal', 'Transfer', 'Payment')),
    created_at TIMESTAMP NOT NULL,
    CHECK (source_account_id <> destination_account_id)
);
-- Populate 100,000 deterministic rows using existing active account IDs (1..3) and biller IDs (1..2)
INSERT INTO p2_benchmark.synthetic_transaction_history (
    source_account_id,
    destination_account_id,
    biller_id,
    amount,
    transaction_type,
    created_at
)
SELECT
    CASE
        WHEN ((gs - 1) % 4) = 3 THEN NULL
        ELSE ((gs - 1) % 3) + 1
    END AS source_account_id,
    CASE
        WHEN ((gs - 1) % 4) = 0 THEN ((((gs - 1) % 3) + 1) % 3) + 1
        WHEN ((gs - 1) % 4) = 3 THEN ((gs - 1) % 3) + 1
        ELSE NULL
    END AS destination_account_id,
    CASE
        WHEN ((gs - 1) % 4) = 1 THEN ((gs - 1) % 2) + 1
        ELSE NULL
    END AS biller_id,
    ((1000 + ((gs * 703) % 49000)) / 100.00)::NUMERIC(12, 2) AS amount,
    CASE ((gs - 1) % 4)
        WHEN 0 THEN 'Transfer'
        WHEN 1 THEN 'Payment'
        WHEN 2 THEN 'Withdrawal'
        ELSE 'Deposit'
    END AS transaction_type,
    TIMESTAMP '2026-01-01 00:00:00' + ((gs - 1) * INTERVAL '1 minute') AS created_at
FROM generate_series(1, 100000) AS gs;

-- Update PostgreSQL planner statistics and verify the exact row count
ANALYZE p2_benchmark.synthetic_transaction_history;

SELECT COUNT(*) AS total_rows
FROM p2_benchmark.synthetic_transaction_history;

-- Selective query: retrieve outgoing transactions for account 1 within a 30-minute window
SELECT
    history_id,
    source_account_id,
    destination_account_id,
    biller_id,
    amount,
    transaction_type,
    created_at
FROM p2_benchmark.synthetic_transaction_history
WHERE source_account_id = 1
  AND created_at >= TIMESTAMP '2026-02-15 00:00:00'
  AND created_at < TIMESTAMP '2026-02-15 00:30:00'
ORDER BY created_at ASC;

-- Run once for warm-up, then three times for measurement before creating the B-tree index
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    history_id,
    source_account_id,
    destination_account_id,
    biller_id,
    amount,
    transaction_type,
    created_at
FROM p2_benchmark.synthetic_transaction_history
WHERE source_account_id = 1
  AND created_at >= TIMESTAMP '2026-02-15 00:00:00'
  AND created_at < TIMESTAMP '2026-02-15 00:30:00'
ORDER BY created_at ASC;

-- Create a composite B-tree index matching the equality filter, range filter, and sort order
CREATE INDEX idx_synth_tx_source_account_created_at
    ON p2_benchmark.synthetic_transaction_history
    USING btree (source_account_id, created_at);

ANALYZE p2_benchmark.synthetic_transaction_history;

-- Run the identical EXPLAIN query once for warm-up, then three times for measurement
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    history_id,
    source_account_id,
    destination_account_id,
    biller_id,
    amount,
    transaction_type,
    created_at
FROM p2_benchmark.synthetic_transaction_history
WHERE source_account_id = 1
  AND created_at >= TIMESTAMP '2026-02-15 00:00:00'
  AND created_at < TIMESTAMP '2026-02-15 00:30:00'
ORDER BY created_at ASC;