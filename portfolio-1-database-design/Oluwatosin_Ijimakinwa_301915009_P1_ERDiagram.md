# PayPulse Fintech Platform ER Diagram

```mermaid
erDiagram
    direction LR

    CUSTOMER {
        int customer_id PK
        string full_name
        string government_id UK
    }

    ACCOUNT {
        int account_id PK
        int customer_id FK
        string account_type
        numeric balance
        boolean is_frozen
    }

    TRANSACTION {
        int transaction_id PK
        int source_account_id FK "optional"
        int destination_account_id FK "optional"
        numeric amount
        string transaction_type
        timestamp created_at
    }

    BILLER {
        int biller_id PK
        string biller_name
    }

    CUSTOMER ||--o{ ACCOUNT : "owns"
    ACCOUNT |o--o{ TRANSACTION : "initiates_as_source"
    ACCOUNT |o--o{ TRANSACTION : "receives_as_destination"
    BILLER |o--o{ TRANSACTION : "receives_payment"
```

## Key and Relationship Definitions

* **PK (Primary Key)**: A column containing a unique identifier for each row in a table. For example, `customer_id` uniquely identifies each registered retail user.
* **FK (Foreign Key)**: A column referencing a primary key in another table to establish a link between entity records. For example, `customer_id` in the `ACCOUNT` table links an account to its owner.
* **UK (Unique Key)**: A constraint enforcing that no two rows contain identical non-null values in that column. For example, `government_id` ensures every customer registers with a distinct identification document.
* **Relationship Symbols**:
  * `||--o{`: Exactly one entity on the left connects to zero, one, or many entities on the right.
  * `|o--o{`: Zero or one entity on the left connects to zero, one, or many entities on the right.

## System Example

Customer Sarah has `customer_id = 101`. She opens a Savings account (`account_id = 501`) and a Checking account (`account_id = 502`). Both rows in the `ACCOUNT` table contain `customer_id = 101` as a Foreign Key. When Sarah transfers \$50 from Savings to Checking, `TRANSACTION` creates a record (`transaction_id = 9001`) with `source_account_id = 501` and `destination_account_id = 502`.

## Optional Fields

* `source_account_id`: Optional (NULL for direct cash deposits into an account).
* `destination_account_id`: Optional (NULL for cash withdrawals from an account).

## Rules Requiring Additional Transaction Logic or Triggers

* **Rule 5 (Available Balance Validation)**: Checking that transfer `amount <= balance` spans multiple entity rows and cannot be enforced by standard column constraints alone. It requires database trigger validation or application transaction logic prior to updating balances.
* **Rule 7 (Frozen Account Enforcement)**: Keys cannot evaluate status flags across tables; database trigger logic must verify `is_frozen = FALSE` on both source and destination accounts before inserting a transaction.
* **Rule 8 (Immutable Timestamps)**: Timestamp consistency relies on database trigger routines setting `created_at = CURRENT_TIMESTAMP` and restricting `UPDATE` privileges on committed records.