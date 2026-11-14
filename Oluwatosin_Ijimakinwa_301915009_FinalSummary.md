# MIT 8103 Advanced Database Systems: Portfolio Summary

* **Case study:** PayPulse Digital Fintech Platform
* **Student name:** Oluwatosin Ijimakinwa
* **Student ID:** 301915009
* **Repository URL:** https://github.com/Bobby-Josh/Oluwatosin_301915009

## Case study

PayPulse is a digital fintech platform supporting retail deposit accounts (`Checking`, `Savings`, and `Money Market`), peer-to-peer transfers, and utility bill payments. Across five portfolios in an Ubuntu GitHub Codespace, PayPulse's data layer was designed, queried, benchmarked, tested under concurrent transactions, extended with a document event store, and evaluated for distributed cloud deployment.

## Portfolio 1: Database Design and Modelling

A third-normal-form (3NF) schema was built in PostgreSQL 16 (`paypulse_portfolio`, `public` schema) with four tables: `customer`, `biller`, `account`, and `transaction`. Each table defines an identity primary key alongside foreign keys, `NOT NULL` rules, a `UNIQUE` constraint on `customer.government_id`, and `CHECK` constraints enforcing valid account and transaction types, non-negative balances, positive amounts, non-future timestamps, and distinct source and destination accounts (PostgreSQL Global Development Group, 2026).

Executing the sample data script committed `3` customers, `2` billers, `4` accounts, and `4` transactions, while 16 negative `INSERT` tests all failed with expected constraint errors. This confirms PostgreSQL enforces single-row domain integrity automatically, whereas cross-row rules—such as checking available balances or blocking frozen accounts—require explicit transaction logic.

## Portfolio 2: Query Processing and Optimisation

Three queries ran against `paypulse_portfolio`, returning `3` outgoing transactions (`transaction_id` `2`, `3`, and `4`), `1` inactive frozen account (`account_id = 4`, Clara Adeyemi), and bill payment counts per biller (`Eko Electric Utility` with `1` and `Lagos Water Works` with `0`). An isolated 100,000-row table (`p2_benchmark.synthetic_transaction_history`) was then queried for `source_account_id = 1` over a 30-minute window (`2026-02-15 00:00:00` to `2026-02-15 00:30:00`, returning `7` rows) before and after adding composite B-tree index `idx_synth_tx_source_account_created_at` on `(source_account_id, created_at)` (PostgreSQL Global Development Group, 2026).

| Phase | Execution plan | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Median (ms) | Top-level shared buffer hits (Run 3) |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| Before index | `Seq Scan` (with `Sort`) | 8.996 | 7.740 | 6.284 | 7.740 | 814 |
| After index | `Bitmap Heap Scan` / `Bitmap Index Scan` (with `Sort`) | 0.046 | 0.046 | 0.047 | 0.046 | 5 |

The index eliminated full-table scans and cut shared buffer hits from `814` to `5`. Because sub-millisecond timings on warm in-memory buffers inside a container reflect cache residency and CPU scheduling rather than fixed production latency, these numbers show relative I/O reduction rather than guaranteed speedup, and the index adds storage and write overhead.

## Portfolio 3: Transactions and Concurrency

From the Portfolio 1 baseline (`account_id = 3` at `850.00`, `account_id = 1` at `1500.00`, `3` customers, and `4` transactions), a guarded transaction credited `100.00` to `account_id = 3` (`950.00`, `COMMIT`), while a repeat check using `WHERE balance = 850.00` affected `0` rows (`UPDATE 0`), preventing double-crediting. A second transaction debited `account_id = 1` (`UPDATE 1`) and attempted to insert a `-50.00` row, violating `transaction_amount_check` and forcing `ROLLBACK` (`account_id = 1` stayed `1500.00`, and `public.transaction` remained at `4` rows).

In a two-session test under `READ COMMITTED` isolation, `Session A` inserted `'David Nwosu'` (`government_id = 'GOV-1004'`) without committing. `Session B` saw only the `3` committed rows (preventing a dirty read) and blocked on the unique index when inserting `'Daniel Eze'` with `'GOV-1004'`. After `Session A` committed, `Session B` failed with `customer_government_id_key` and rolled back, leaving `4` customers with `'GOV-1004'` assigned only to `'David Nwosu'` (PostgreSQL Global Development Group, 2026).

## Portfolio 4: NoSQL and Advanced Data Models

MongoDB Community Server `8.0.38` was installed locally (`127.0.0.1:27017`, data in `/workspaces/mongodb-data`) alongside PostgreSQL. Four standalone fictional event documents (`EVT-2026-001` through `EVT-2026-004`) representing `Transfer` and `BillPayment` events were inserted into `paypulse_events.account_events` using shared metadata, embedded `customer` and `source_account` objects, and a polymorphic `details` subdocument (MongoDB, Inc., 2026a).

`countDocuments({})` confirmed `4` records; querying `customer.government_id: "GOV-1001"` sorted by `occurred_at` returned `3` chronological events for Alice Mensah; and filtering nested field `details.biller.biller_name: "Eko Electric Utility"` returned `1` document (`EVT-2026-002`). Storing heterogeneous events together avoids nullable foreign keys and supports single-read timelines, while PostgreSQL remains required for cross-account balance constraints.

## Portfolio 5: Distributed and Cloud Database Exercise

Portfolio 5 evaluated evolving PayPulse from its verified single-node Codespace setup—standalone PostgreSQL 16 and standalone MongoDB 8.0.38—toward a fault-tolerant cloud architecture. The proposed design replaces the standalone MongoDB process with a three-member voting replica set across three availability zones using `w: "majority"` write concern, while keeping authoritative ledger decisions in PostgreSQL because MongoDB replication does not replicate or synchronise PostgreSQL (MongoDB, Inc., 2026a). Sharding was judged unnecessary for four documents, and MongoDB Atlas was analysed for authentication, encryption, network restrictions, backups, and multi-node cost (MongoDB, Inc., 2026b). All replica set, election, sharding, and cloud designs are proposed architectures only; no multi-node cluster or failover test was implemented.

## Evidence

* **Portfolio 1:** [README](https://github.com/Bobby-Josh/Oluwatosin_301915009/blob/main/portfolio-1-database-design/Oluwatosin_Ijimakinwa_301915009_P1_README.md), [Schema.sql](https://github.com/Bobby-Josh/Oluwatosin_301915009/blob/main/portfolio-1-database-design/Oluwatosin_Ijimakinwa_301915009_P1_Schema.sql), [SampleData.sql](https://github.com/Bobby-Josh/Oluwatosin_301915009/blob/main/portfolio-1-database-design/Oluwatosin_Ijimakinwa_301915009_P1_SampleData.sql), [ConstraintTests.sql](https://github.com/Bobby-Josh/Oluwatosin_301915009/blob/main/portfolio-1-database-design/Oluwatosin_Ijimakinwa_301915009_P1_ConstraintTests.sql), and [RowCount Screenshot](https://github.com/Bobby-Josh/Oluwatosin_301915009/blob/main/portfolio-1-database-design/screenshots/Oluwatosin_Ijimakinwa_301915009_P1_ConstraintTestTransaction_RowCount.png).
* **Portfolio 2:** [README](https://github.com/Bobby-Josh/Oluwatosin_301915009/blob/main/portfolio-2-query-optimisation/Oluwatosin_Ijimakinwa_301915009_P2_README.md), [Queries.sql](https://github.com/Bobby-Josh/Oluwatosin_301915009/blob/main/portfolio-2-query-optimisation/Oluwatosin_Ijimakinwa_301915009_P2_Queries.sql), [Optimisation.sql](https://github.com/Bobby-Josh/Oluwatosin_301915009/blob/main/portfolio-2-query-optimisation/Oluwatosin_Ijimakinwa_301915009_P2_Optimisation.sql), [BeforeIndex Screenshot](https://github.com/Bobby-Josh/Oluwatosin_301915009/blob/main/portfolio-2-query-optimisation/Screenshot/Oluwatosin_Ijimakinwa_301915009_P2_BeforeIndex.png), and [AfterIndex Screenshot](https://github.com/Bobby-Josh/Oluwatosin_301915009/blob/main/portfolio-2-query-optimisation/Screenshot/Oluwatosin_Ijimakinwa_301915009_P2_AfterIndex.png).
* **Portfolio 3:** [README](https://github.com/Bobby-Josh/Oluwatosin_301915009/blob/main/portfolio-3-transactions-concurrency/Oluwatosin_Ijimakinwa_301915009_P3_README.md), [Transactions.sql](https://github.com/Bobby-Josh/Oluwatosin_301915009/blob/main/portfolio-3-transactions-concurrency/Oluwatosin_Ijimakinwa_301915009_P3_Transactions.sql), [SessionA.sql](https://github.com/Bobby-Josh/Oluwatosin_301915009/blob/main/portfolio-3-transactions-concurrency/Oluwatosin_Ijimakinwa_301915009_P3_SessionA.sql), [SessionB.sql](https://github.com/Bobby-Josh/Oluwatosin_301915009/blob/main/portfolio-3-transactions-concurrency/Oluwatosin_Ijimakinwa_301915009_P3_SessionB.sql), and [ConcurrencyOutcome Screenshot](https://github.com/Bobby-Josh/Oluwatosin_301915009/blob/main/portfolio-3-transactions-concurrency/Screenshots/Oluwatosin_Ijimakinwa_301915009_P3_ConcurrencyOutcome.png).
* **Portfolio 4:** [README](https://github.com/Bobby-Josh/Oluwatosin_301915009/blob/main/portfolio-4-nosql/Oluwatosin_Ijimakinwa_301915009_P4_README.md), [Setup.md](https://github.com/Bobby-Josh/Oluwatosin_301915009/blob/main/portfolio-4-nosql/Oluwatosin_Ijimakinwa_301915009_P4_Setup.md), [MongoDB.js](https://github.com/Bobby-Josh/Oluwatosin_301915009/blob/main/portfolio-4-nosql/Oluwatosin_Ijimakinwa_301915009_P4_MongoDB.js), and [MongoDBQueries Screenshot](https://github.com/Bobby-Josh/Oluwatosin_301915009/blob/main/portfolio-4-nosql/screenshots/Oluwatosin_Ijimakinwa_301915009_P4_MongoDBQueries.png).
* **Portfolio 5:** [README](https://github.com/Bobby-Josh/Oluwatosin_301915009/blob/main/portfolio-5-distributed-cloud/Oluwatosin_Ijimakinwa_301915009_P5_README.md) and [Discussion Screenshot](https://github.com/Bobby-Josh/Oluwatosin_301915009/blob/main/portfolio-5-distributed-cloud/screenshots/Oluwatosin_Ijimakinwa_301915009_P5_Discussion.png).

## Individual reflection

A key design choice was splitting PayPulse's relational and document workloads: keeping authoritative account balances and `CHECK` constraints in PostgreSQL (`paypulse_portfolio`), while storing `Transfer` and `BillPayment` activity logs in MongoDB (`paypulse_events`) so distinct event types do not leave unused `NULL` columns. The main difficulty was coordinating two-session concurrency testing (`Session A` and `Session B`) in exact step-by-step order during Portfolio 3 to observe `READ COMMITTED` visibility and unique-index lock waiting without running commands out of sequence. To address this, I pre-checked the baseline table state and isolation level before starting either transaction, executed the session steps in order, and rolled back `Session B` cleanly after the duplicate-key error. This reinforced that no single database fits every workload: relational databases are essential for strict constraints, ACID transactions, and ledger integrity, whereas document stores are better suited for flexible, event-driven records.

## References

* MongoDB, Inc. (2026a). *MongoDB Database Manual v8.0: Data Modeling Introduction, Query on Embedded/Nested Documents, Replication, Replica Set Elections, Write Concern, Sharding, and Install MongoDB Community Edition on Ubuntu*. https://www.mongodb.com/docs/v8.0/
* MongoDB, Inc. (2026b). *MongoDB Atlas Documentation: Back Up and Restore a Cluster*. https://www.mongodb.com/docs/atlas/backup-restore-cluster/
* PostgreSQL Global Development Group. (2026). *PostgreSQL 16 Documentation: Chapter 5 (Constraints), Chapter 11 (Indexes), Chapter 13 (Concurrency Control), Chapter 14 (Using EXPLAIN), and SQL Commands (BEGIN, COMMIT, ROLLBACK)*. https://www.postgresql.org/docs/16/

## AI-use declaration

Google Gemini was used during this coursework to help structure SQL and MongoDB scripts, troubleshoot terminal commands in GitHub Codespaces, refine Markdown documentation, and check formatting against assessment guidelines. I personally executed all SQL and `mongosh` commands in my Codespace terminal, verified every query output, execution plan, and constraint error against PayPulse's business rules, corrected Markdown formatting and file paths, and captured all verification screenshots in the repository.