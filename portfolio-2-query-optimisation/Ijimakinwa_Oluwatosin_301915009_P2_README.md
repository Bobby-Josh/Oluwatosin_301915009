# Portfolio 2 Query Processing and Optimisation

## Queries and results

Three PostgreSQL queries were implemented in `Ijimakinwa_Oluwatosin_301915009_P2_Queries.sql` against the `public` schema of `paypulse_portfolio`:

* **Query 1 (Outgoing Transactions with Customer and Source Account Details):** Joins `public.transaction`, `public.account`, and `public.customer` for records from `2026-01-01` onward ordered by `transaction_id`, returning 3 rows (transactions `2`, `3`, and `4` for Alice Mensah and Bob Okafor) while excluding the external deposit where `source_account_id` is `NULL`.
* **Query 2 (Accounts with No Recorded Transaction Activity):** Uses `NOT EXISTS` across `public.account`, `public.customer`, and `public.transaction` to check Business Rule 7, returning 1 row (`account_id = 4`, Clara Adeyemi's frozen Money Market account with a `0.00` balance).
* **Query 3 (Bill Payment Count per Registered Biller):** Uses a `LEFT JOIN` from `public.biller` to `public.transaction` grouped by biller, returning 2 rows (`Eko Electric Utility` with `1` payment and `Lagos Water Works` with `0` payments).

## Index comparison

The indexing benchmark ran in an isolated `p2_benchmark.synthetic_transaction_history` table containing 100,000 deterministic rows, filtering `source_account_id = 1` over a 30-minute window (`2026-02-15 00:00:00` to `2026-02-15 00:30:00`, returning 7 rows). Each stage ran once for warm-up followed by three measured `EXPLAIN (ANALYZE, BUFFERS)` executions before and after creating the composite B-tree index `idx_synth_tx_source_account_created_at` on `(source_account_id, created_at)`:

| Phase | Scan type | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Median time (ms) | Top-level shared buffer hits (Run 3) |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| **Before index** | `Seq Scan` (with `Sort`) | 8.996 | 7.740 | 6.284 | 7.740 | 814 |
| **After index** | `Bitmap Heap Scan` / `Bitmap Index Scan` (with `Sort`) | 0.046 | 0.046 | 0.047 | 0.046 | 5 |

## Performance analysis

Without a supporting index, PostgreSQL executed a full `Seq Scan` across all 100,000 rows, reading 814 shared buffer pages and discarding 99,993 non-matching rows before sorting the 7 matches in memory; after creating the composite B-tree index on `(source_account_id, created_at)`, the planner switched to a `Bitmap Index Scan` paired with a `Bitmap Heap Scan`, accessing only 3 index pages and 2 heap pages (5 top-level shared buffer hits) and reducing median execution time from `7.740 ms` to `0.046 ms`. Because sub-millisecond timings measured on warm in-memory buffers inside a container environment reflect CPU scheduling and cache residency rather than fixed production latency, these numbers demonstrate relative buffer reduction rather than guaranteed speedup, and an index does not guarantee faster queries when predicates have low selectivity or tables are small. Moreover, maintaining `idx_synth_tx_source_account_created_at` requires additional disk and buffer memory and introduces write overhead during `INSERT`, `UPDATE`, and `DELETE` statements because PostgreSQL must update both the table heap and the B-tree index.

## Files

| File | Description |
| :--- | :--- |
| [Ijimakinwa_Oluwatosin_301915009_P2_Queries.sql](Ijimakinwa_Oluwatosin_301915009_P2_Queries.sql) | Three relational queries covering multi-table joins, `NOT EXISTS` inactivity checks, and `LEFT JOIN` grouped counts. |
| [Ijimakinwa_Oluwatosin_301915009_P2_Optimisation.sql](Ijimakinwa_Oluwatosin_301915009_P2_Optimisation.sql) | Isolated `p2_benchmark` schema setup, 100,000-row synthetic data generation, composite B-tree index creation, and `EXPLAIN (ANALYZE, BUFFERS)` runs. |
| [Screenshot/Ijimakinwa_Oluwatosin_301915009_P2_QueryResult.png](Screenshot/Ijimakinwa_Oluwatosin_301915009_P2_QueryResult.png) | Terminal output showing the result sets for Queries 1, 2, and 3. |
| [Screenshot/Ijimakinwa_Oluwatosin_301915009_P2_BeforeIndex.png](Screenshot/Ijimakinwa_Oluwatosin_301915009_P2_BeforeIndex.png) | Terminal capture of `EXPLAIN (ANALYZE, BUFFERS)` execution plans before creating the B-tree index. |
| [Screenshot/Ijimakinwa_Oluwatosin_301915009_P2_AfterIndex.png](Screenshot/Ijimakinwa_Oluwatosin_301915009_P2_AfterIndex.png) | Terminal capture of `EXPLAIN (ANALYZE, BUFFERS)` execution plans after creating the B-tree index. |

## Reference

* PostgreSQL Global Development Group. (2026). *PostgreSQL 16 Documentation: Chapter 11 (Indexes) and Chapter 14 (Performance Tips — Using EXPLAIN)*. https://www.postgresql.org/docs/16/