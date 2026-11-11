# Bank Transaction System Database Design

## 1. Entities

The database keeps records of four entities:

* **Customer**: Individual retail users registered on the fintech platform.
* **Account**: Bank accounts created by customers to hold and transfer money.
* **Transaction**: Financial movement records including deposits, withdrawals, transfers, and bill payments.
* **Biller**: Registered utility or service companies that receive bill payments.

---

## 2. Attributes and Keys

### Customer
* **`customer_id`** (`INT`, Primary Key, Required): Unique number identifying each customer.
* **`full_name`** (`VARCHAR`, Required): Full legal name of the user.
* **`government_id`** (`VARCHAR`, Unique, Required): Official government identification document number.

### Account
* **`account_id`** (`INT`, Primary Key, Required): Unique account number.
* **`customer_id`** (`INT`, Foreign Key, Required): Links the account to its owner in `Customer`. A Foreign Key connects a row in one table to a row in another.
* **`account_type`** (`VARCHAR`, Required): Category restricted to `'Savings'`, `'Checking'`, or `'Money Market'`.
* **`balance`** (`NUMERIC`, Required): Current monetary balance. Stored directly to enable instant reading without recalculating millions of past transactions.
* **`is_frozen`** (`BOOLEAN`, Required): Status flag where `TRUE` means frozen and `FALSE` means active.

### Transaction
* **`transaction_id`** (`INT`, Primary Key, Required): Unique transaction record number.
* **`source_account_id`** (`INT`, Foreign Key, Optional): Sending account (empty for external cash deposits).
* **`destination_account_id`** (`INT`, Foreign Key, Optional): Receiving account (empty for cash withdrawals).
* **`amount`** (`NUMERIC`, Required): Transferred monetary sum.
* **`transaction_type`** (`VARCHAR`, Required): Operation restricted to `'Deposit'`, `'Withdrawal'`, `'Transfer'`, or `'Payment'`.
* **`created_at`** (`TIMESTAMP`, Required): Exact system execution time.

### Biller
* **`biller_id`** (`INT`, Primary Key, Required): Unique identifier for a utility service provider.
* **`biller_name`** (`VARCHAR`, Required): Official company name of the provider.

---

## 3. Relationships

* **Customer to Account**: One-to-many relationship. A customer can own zero, one, or multiple accounts. Each account belongs to exactly one customer. A newly registered customer can exist with zero accounts.
* **Account to Transaction (Source)**: One-to-many relationship. An account can initiate zero, one, or many transactions as a sender. A transaction has at most one source account.
* **Account to Transaction (Destination)**: One-to-many relationship. An account can receive zero, one, or many transactions as a receiver. A transaction has at most one destination account.
* **Biller to Transaction**: One-to-many relationship. A biller can receive zero, one, or many bill payment transactions. A payment transaction references at most one biller.

---

## 4. Business Rules and Constraints

* **Rule 1 (Customer Identity)**: Enforced by `PRIMARY KEY` on `customer_id` and `UNIQUE` with `NOT NULL` on `government_id`.
* **Rule 2 (Non-negative Balance)**: Enforced by `PRIMARY KEY` on `account_id` and a `CHECK (balance >= 0)` constraint.
* **Rule 3 (Account Types)**: Enforced by a `CHECK (account_type IN ('Savings', 'Checking', 'Money Market'))` constraint.
* **Rule 4 (Transaction Records)**: Enforced by `PRIMARY KEY` on `transaction_id` and `CHECK (transaction_type IN ('Deposit', 'Withdrawal', 'Transfer', 'Payment'))`.
* **Rule 5 (Positive Transfer & Available Balance)**: `CHECK (amount > 0)` enforces positive values. Verifying `amount <= balance` spans multiple rows and cannot be enforced by a key alone; it requires a database trigger or multi-statement transaction validation logic before processing.
* **Rule 6 (Distinct Accounts)**: Enforced by a `CHECK (source_account_id <> destination_account_id)` constraint.
* **Rule 7 (Frozen Account Block)**: Keys cannot inspect status flags across tables; enforced by conditional trigger logic checking `is_frozen = FALSE` prior to insertion.
* **Rule 8 (Immutable System Timestamps)**: Enforced by setting `created_at` default to current time and restricting `UPDATE` permissions.

---

## 5. Design Assumptions

1. **Joint Ownership Exclusion**: Joint ownership is excluded from scope; each account links to exactly one primary customer ID.
2. **Direct Balance Storage**: Direct balance storage is chosen for high read performance, with consistency guarded by transaction routines during updates.