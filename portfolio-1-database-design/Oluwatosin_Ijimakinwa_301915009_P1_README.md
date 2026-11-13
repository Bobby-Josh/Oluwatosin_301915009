# Portfolio 1 Database Design and Modelling

## Case study
PayPulse is a digital fintech platform offering peer-to-peer transfers, bill payments, and deposit accounts for retail customers. The system processes real-time financial transactions while maintaining secure ledger balances and detailed audit trails.

## Users
Retail customers open accounts, execute transfers, and view transaction histories. System administrators oversee user onboarding, account status updates, and identity verification. Compliance officers access read-only audit logs to review flagged transactions.

## Main operations
Key operations include registering customer profiles, opening accounts, depositing funds, executing peer-to-peer transfers, processing bill payments, generating date-filtered account statements, and toggling account freeze statuses.

## Business rules
1. Each customer has a unique Customer ID and must provide a valid government ID. A customer may own multiple accounts, but each account belongs to one customer.   
2. Accounts are identified by a unique Account Number and must maintain a minimum balance of zero. Negative balances are strictly rejected.   
3. Account types are restricted to 'Savings', 'Checking', or 'Money Market'. Invalid type entries are rejected by system constraints.   
4. Each transaction receives a unique Transaction ID, execution timestamp, source account, and destination account. Transaction types are restricted to 'Deposit', 'Withdrawal', 'Transfer', or 'Payment'.   
5. Transfer amounts must be strictly positive and cannot exceed the source account's available balance. Transactions violating this condition are immediately blocked.   
6. Source and destination account IDs must be distinct. The database blocks transactions where source and target accounts are identical.   
7. Frozen accounts cannot initiate or receive funds. Any transaction referencing a frozen account must fail.   
8. Transaction timestamps must reflect the current system time and cannot be set to a future date. Committed transaction records are immutable.

## Scope
Included

Core customer profile management and identification verification.

Account ledger tracking for Savings, Checking, and Money Market accounts.

Real-time peer-to-peer transfers, deposits, and bill payment logs.

Constraint-enforced data integrity and audit-ready logging using fictional dataset entries.

Excluded

Credit scoring algorithms and loan processing modules.

Physical card issuing and PIN management systems.

Foreign exchange (FX) currency conversions.

External payment gateway integrations and API webhooks.

## Design and implementation files

| File | Contents |
| :--- | :--- |
| [Oluwatosin_Ijimakinwa_301915009_P1_Design.md](Oluwatosin_Ijimakinwa_301915009_P1_Design.md) | Entities, PostgreSQL data types, primary and foreign keys, relationship cardinalities, rule mappings, and design assumptions for PayPulse. |
| [Oluwatosin_Ijimakinwa_301915009_P1_ERDiagram.md](Oluwatosin_Ijimakinwa_301915009_P1_ERDiagram.md) | Mermaid entity-relationship diagram showing tables, keys, optional fields, and relationship symbols. |
| [Oluwatosin_Ijimakinwa_301915009_P1_Normalisation.md](Oluwatosin_Ijimakinwa_301915009_P1_Normalisation.md) | Step-by-step normalisation walkthrough from unnormalised records through 1NF, 2NF, and 3NF using sample PayPulse records. |
| [Oluwatosin_Ijimakinwa_301915009_P1_Schema.sql](Oluwatosin_Ijimakinwa_301915009_P1_Schema.sql) | PostgreSQL 16 DDL script creating the `customer`, `biller`, `account`, and `transaction` tables in `public` with keys and `CHECK` constraints. |
| [Oluwatosin_Ijimakinwa_301915009_P1_SampleData.sql](Oluwatosin_Ijimakinwa_301915009_P1_SampleData.sql) | Transactional script inserting valid fictional customers, billers, accounts, and transactions in parent-before-child order. |
| [Oluwatosin_Ijimakinwa_301915009_P1_ConstraintTests.sql](Oluwatosin_Ijimakinwa_301915009_P1_ConstraintTests.sql) | Independent negative `INSERT` statements testing required fields, unique values, foreign keys, and `CHECK` rules, ending with a table row-count query. |
| [screenshots/](screenshots/) | Terminal screenshots capturing database connection, schema creation, valid sample inserts, constraint rejection errors, and final row counts. |

## Implementation

The `paypulse_portfolio` database runs on PostgreSQL 16 inside the GitHub Codespaces workspace. Executing `Oluwatosin_Ijimakinwa_301915009_P1_Schema.sql` creates four tables in the `public` schema in parent-before-child order: `customer`, `biller`, `account`, and `transaction`. Each table uses an `INT GENERATED ALWAYS AS IDENTITY` primary key, alongside `NOT NULL` constraints on required fields, a `UNIQUE` constraint on `customer.government_id`, foreign keys linking `account` to `customer` and `transaction` to `account` and `biller`, and `CHECK` constraints enforcing valid account types (`'Savings'`, `'Checking'`, `'Money Market'`), non-negative balances (`balance >= 0`), positive transaction amounts (`amount > 0`), valid transaction types (`'Deposit'`, `'Withdrawal'`, `'Transfer'`, `'Payment'`), non-future timestamps (`created_at <= CURRENT_TIMESTAMP`), and distinct source and destination accounts (`source_account_id <> destination_account_id`).

In `psql` connected to `paypulse_portfolio`, the schema script was executed first, followed by `Oluwatosin_Ijimakinwa_301915009_P1_SampleData.sql` inside a `BEGIN` and `COMMIT` transaction block using subqueries on unique fields to resolve generated IDs. Next, `Oluwatosin_Ijimakinwa_301915009_P1_ConstraintTests.sql` was run outside a transaction block so each invalid `INSERT` failed independently without halting subsequent checks, and terminal outputs were saved in `screenshots/`.

## Test results

`Oluwatosin_Ijimakinwa_301915009_P1_SampleData.sql` committed cleanly, loading valid fictional customers, billers, accounts across all three account types and active/frozen states, and transactions across all four transaction types. After running the negative test script, the final verification query confirmed that no invalid rows were written, returning exact expected counts of 3 rows in `customer`, 2 rows in `biller`, 4 rows in `account`, and 4 rows in `transaction`.

PostgreSQL rejected the deliberately invalid statements in `Oluwatosin_Ijimakinwa_301915009_P1_ConstraintTests.sql` with the expected constraint errors. Observed errors confirmed `not-null` enforcement on `customer.full_name`, `customer.government_id`, `biller.biller_name`, `account.customer_id`, and `account.is_frozen`; `unique` enforcement on duplicate `government_id` (`GOV-1001`); `foreign key` enforcement against missing ID `999999` for `customer_id`, `source_account_id`, `destination_account_id`, and `biller_id`; and `check` constraint enforcement against invalid account type (`'Crypto Wallet'`), negative balance (`-50.00`), zero transaction amount (`0.00`), invalid transaction type (`'CryptoSwap'`), a future `created_at` timestamp, and identical source and destination accounts (`1` and `1`).

Three business rules span multiple rows or record lifecycles and remain untested by table-level constraints alone: verifying that a transfer or withdrawal amount does not exceed the source account's available balance (Rule 5), blocking transactions referencing accounts where `is_frozen = TRUE` (Rule 7), and preventing updates or deletions on committed transaction records (Rule 8). These rules require multi-statement transaction logic, triggers, or database access privileges in later portfolio activities.