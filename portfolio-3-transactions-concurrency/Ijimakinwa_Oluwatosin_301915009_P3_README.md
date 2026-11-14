# Portfolio 3 Transactions and Concurrency

## Commit and rollback

In `paypulse_portfolio`, a guarded transaction credited `100.00` to active Checking `account_id = 3` (`850.00` to `950.00`) and committed (`UPDATE 1`, `COMMIT`), while a repeat check using `WHERE balance = 850.00` affected `0` rows (`UPDATE 0`) and prevented double-crediting. A second transaction debited `200.00` from `account_id = 1` (`UPDATE 1`) and then attempted to insert a `-50.00` row into `public.transaction`, which triggered `CHECK` constraint `transaction_amount_check` and required `ROLLBACK`; final checks confirmed `account_id = 3` retained `950.00`, `account_id = 1` reverted to `1500.00`, and `public.transaction` remained at 4 rows. While table-level `CHECK` constraints block invalid single-row values such as non-positive amounts, cross-row rules like verifying sufficient balance or blocking frozen accounts still depend on explicit `WHERE` guards or triggers inside each transaction.

## Isolation and concurrency control

Two independent `psql` connections (`Session A` and `Session B`) tested Business Rule 1 under PostgreSQL's `READ COMMITTED` isolation level (`SHOW transaction_isolation` returned `read committed`). After Session A began a transaction and inserted `'David Nwosu'` with `government_id = 'GOV-1004'` (`customer_id = 9`) without committing, Session B saw only the 3 committed rows (preventing a dirty read) and paused when trying to insert `'Daniel Eze'` with the same `'GOV-1004'` because Session A held an uncommitted unique-index lock. Once Session A executed `COMMIT`, Session B immediately unblocked with `duplicate key value violates unique constraint "customer_government_id_key"`, ran `ROLLBACK`, and confirmed 4 customer rows with `'GOV-1004'` assigned only to `'David Nwosu'`, showing that `READ COMMITTED` isolation prevents dirty reads while the `UNIQUE` constraint and index locking serialize and reject conflicting inserts.

## Conclusion

Combining explicit transaction blocks (`BEGIN`, `COMMIT`, `ROLLBACK`), guarded `UPDATE` conditions, `CHECK` and `UNIQUE` constraints, and `READ COMMITTED` isolation preserves atomicity and prevents duplicate or invalid records in `paypulse_portfolio`. However, neither default isolation nor single-row column checks automatically enforce multi-table lifecycle rules such as blocking frozen accounts across `public.account` and `public.transaction`, so production workflows must pair database constraints with disciplined multi-statement transaction logic or triggers.

## Files

| File | Description |
| :--- | :--- |
| [Ijimakinwa_Oluwatosin_301915009_P3_Transactions.sql](Ijimakinwa_Oluwatosin_301915009_P3_Transactions.sql) | Single-session commit, idempotency repeat check, constraint-error rollback, and verification queries. |
| [Ijimakinwa_Oluwatosin_301915009_P3_SessionA.sql](Ijimakinwa_Oluwatosin_301915009_P3_SessionA.sql) | Session A script checking `READ COMMITTED` isolation and inserting `GOV-1004` before committing. |
| [Ijimakinwa_Oluwatosin_301915009_P3_SessionB.sql](Ijimakinwa_Oluwatosin_301915009_P3_SessionB.sql) | Session B script testing pre-commit visibility, duplicate-key blocking, error handling, and rollback. |
| [Screenshots/Ijimakinwa_Oluwatosin_301915009_P3_Check Account.png](Screenshots/Ijimakinwa_Oluwatosin_301915009_P3_Check%20Account.png) | Terminal capture of the initial `public.account` and `public.transaction` baseline state. |
| [Screenshots/Ijimakinwa_Oluwatosin_301915009_P3_Commit.png](Screenshots/Ijimakinwa_Oluwatosin_301915009_P3_Commit.png) | Terminal capture of the guarded `UPDATE`, `COMMIT`, and `UPDATE 0` repeat check on `account_id = 3`. |
| [Screenshots/Ijimakinwa_Oluwatosin_301915009_P3_RollBack.png](Screenshots/Ijimakinwa_Oluwatosin_301915009_P3_RollBack.png) | Terminal capture of the `transaction_amount_check` violation and `ROLLBACK`. |
| [Screenshots/Ijimakinwa_Oluwatosin_301915009_P3_CommittedRollBack.png](Screenshots/Ijimakinwa_Oluwatosin_301915009_P3_CommittedRollBack.png) | Terminal capture verifying the final post-commit and post-rollback table state. |
| [Screenshots/Ijimakinwa_Oluwatosin_301915009_P3_ConcurrencyWait.png](Screenshots/Ijimakinwa_Oluwatosin_301915009_P3_ConcurrencyWait.png) | Two-session capture showing Session B waiting while Session A holds uncommitted `GOV-1004`. |
| [Screenshots/Ijimakinwa_Oluwatosin_301915009_P3_ConcurrencyOutcome.png](Screenshots/Ijimakinwa_Oluwatosin_301915009_P3_ConcurrencyOutcome.png) | Two-session capture showing Session A's commit, Session B's unique constraint error, rollback, and final 4-row check. |

## References

* PostgreSQL Global Development Group. (2026). *PostgreSQL 16 Documentation: Chapter 5 (Data Definition — Constraints), Chapter 13 (Concurrency Control), and SQL Commands (BEGIN, COMMIT, ROLLBACK)*. https://www.postgresql.org/docs/16/