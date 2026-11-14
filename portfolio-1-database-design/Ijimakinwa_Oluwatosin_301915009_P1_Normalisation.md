# PayPulse Fintech Platform Normalisation

Normalisation is a systematic process for structuring relational database tables to eliminate data redundancy and prevent data modification errors (known as insertion, update, and deletion anomalies).

## Unnormalised Form (UNF)

Unnormalised data contains repeating groups or multi-valued fields stored within a single row.

### Initial Unnormalised Record

In this initial unnormalised state, a single record contains a customer's personal details alongside multi-valued lists of their bank accounts, transactions, and bill payment details.

| Government ID | Customer Name | Accounts (ID, Type, Balance, Is Frozen) | Transactions (Tx ID, Type, Amount, Dest Account, Biller ID, Biller Name) |
| :--- | :--- | :--- | :--- |
| GOV-101 | Alice Smith | (ACC-501, Checking, \$1,000, False), (ACC-502, Savings, \$500, False) | (TX-901, Transfer, \$200, ACC-502, None, None), (TX-902, Payment, \$100, None, BIL-301, PowerCorp) |
| GOV-102 | Bob Jones | (ACC-503, Checking, \$2,500, False) | (TX-903, Payment, \$150, None, BIL-301, PowerCorp) |

**Problems in UNF**:

* Cells contain lists rather than single values, making SQL queries like calculating total account balances or filtering by transaction type inefficient and complex.
* Updating customer details or biller names requires parsing and altering nested text arrays.

## First Normal Form (1NF)

**1NF Definition**: A table is in First Normal Form when every attribute cell contains exactly one single (atomic) value, and each record is uniquely identified by a primary key.

To convert UNF to 1NF, repeating lists are flattened into individual rows so that every column contains atomic data.

### 1NF Table

* **Primary Key**: Composite key `(Government ID, Account ID, Transaction ID)`

| Government ID | Customer Name | Account ID | Account Type | Balance | Is Frozen | Transaction ID | Tx Type | Amount | Dest Account ID | Biller ID | Biller Name |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| GOV-101 | Alice Smith | ACC-501 | Checking | \$1,000 | False | TX-901 | Transfer | \$200 | ACC-502 | NULL | NULL |
| GOV-101 | Alice Smith | ACC-501 | Checking | \$1,000 | False | TX-902 | Payment | \$100 | NULL | BIL-301 | PowerCorp |
| GOV-101 | Alice Smith | ACC-502 | Savings | \$500 | False | NULL | NULL | NULL | NULL | NULL | NULL |
| GOV-102 | Bob Jones | ACC-503 | Checking | \$2,500 | False | TX-903 | Payment | \$150 | NULL | BIL-301 | PowerCorp |

**What Moved and Why**:

* Multi-valued array cells are expanded into distinct individual rows. Each column now holds indivisible atomic data.

**Remaining Redundancies and Anomalies**:

* **Insertion Anomaly**: A new biller (e.g., "WaterCorp") cannot be added to the system without assigning it to an active customer transaction.
* **Deletion Anomaly**: Deleting transaction `TX-902` removes the only current reference to biller `PowerCorp` associated with customer Alice Smith.
* **Update Anomaly**: If `PowerCorp` changes its company name, every transaction row referencing `PowerCorp` must be updated independently.

## Second Normal Form (2NF)

**2NF Definition**: A table is in Second Normal Form when it is in 1NF and contains no partial dependencies. A partial dependency occurs when a non-key attribute depends on only a portion of a composite primary key rather than the entire key.

In the 1NF table with composite key `(Government ID, Account ID, Transaction ID)`:

* `Customer Name` depends solely on `Government ID`.
* `Account Type`, `Balance`, and `Is Frozen` depend solely on `Account ID`.
* `Tx Type`, `Amount`, `Dest Account ID`, `Biller ID`, and `Biller Name` depend solely on `Transaction ID` (along with the initiating `Account ID` recorded as `Source Account ID`).

To achieve 2NF, attributes with partial dependencies are separated into distinct tables organized by their specific functional keys.

### 2NF Table 1: Customer_Account

* **Primary Key**: Composite key `(Government ID, Account ID)`

| Government ID | Customer Name | Account ID | Account Type | Balance | Is Frozen |
| :--- | :--- | :--- | :--- | :--- | :--- |
| GOV-101 | Alice Smith | ACC-501 | Checking | \$1,000 | False |
| GOV-101 | Alice Smith | ACC-502 | Savings | \$500 | False |
| GOV-102 | Bob Jones | ACC-503 | Checking | \$2,500 | False |

### 2NF Table 2: Transaction_Detail

* **Primary Key**: `Transaction ID`

| Transaction ID | Source Account ID | Destination Account ID | Tx Type | Amount | Biller ID | Biller Name |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| TX-901 | ACC-501 | ACC-502 | Transfer | \$200 | NULL | NULL |
| TX-902 | ACC-501 | NULL | Payment | \$100 | BIL-301 | PowerCorp |
| TX-903 | ACC-503 | NULL | Payment | \$150 | BIL-301 | PowerCorp |

**What Moved and Why**:

* Attributes depending on partial keys are moved into separate tables.
* Account characteristics are decoupled from transaction attributes, eliminating redundant storage of account balances and types across multiple transaction records.

## Third Normal Form (3NF)

**3NF Definition**: A table is in Third Normal Form when it is in 2NF and contains no transitive dependencies. A transitive dependency occurs when a non-key field depends on another non-key field rather than directly on the primary key.

In the 2NF tables:

1. In `Customer_Account`, `Customer Name` depends on `Government ID` (or customer identity), whereas account attributes depend on `Account ID`. Keeping customer details inside the account table repeats customer data whenever a customer opens multiple accounts.
2. In `Transaction_Detail`, `Biller Name` depends on `Biller ID`, which is a non-key column inside the transaction table (`Transaction ID` $\rightarrow$ `Biller ID` $\rightarrow$ `Biller Name`).

To achieve 3NF, transitive dependencies are removed by creating dedicated `Customer` and `Biller` tables.

### 3NF Table 1: Customer

* **Primary Key**: `customer_id`
* **Unique Key**: `government_id`

| customer_id | government_id | full_name |
| :--- | :--- | :--- |
| 1001 | GOV-101 | Alice Smith |
| 1002 | GOV-102 | Bob Jones |

### 3NF Table 2: Account

* **Primary Key**: `account_id`
* **Foreign Key**: `customer_id` (references `Customer.customer_id`)

| account_id | customer_id | account_type | balance | is_frozen |
| :--- | :--- | :--- | :--- | :--- |
| 501 | 1001 | Checking | \$1,000 | False |
| 502 | 1001 | Savings | \$500 | False |
| 503 | 1002 | Checking | \$2,500 | False |

### 3NF Table 3: Biller

* **Primary Key**: `biller_id`

| biller_id | biller_name |
| :--- | :--- |
| 301 | PowerCorp |

### 3NF Table 4: Transaction

* **Primary Key**: `transaction_id`
* **Foreign Keys**: `source_account_id` (references `Account`), `destination_account_id` (references `Account`), `biller_id` (references `Biller`)

| transaction_id | source_account_id | destination_account_id | biller_id | amount | transaction_type |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 901 | 501 | 502 | NULL | \$200 | Transfer |
| 902 | 501 | NULL | 301 | \$100 | Payment |
| 903 | 503 | NULL | 301 | \$150 | Payment |

**What Moved and Why**:

* `Biller Name` is separated into the `Biller` entity so that updating a biller name requires modifying exactly one row in the `Biller` table.
* `Customer Name` is isolated in the `Customer` entity so customer profile updates do not affect individual bank account rows.
* Foreign keys (`customer_id`, `biller_id`, `source_account_id`, `destination_account_id`) establish relational integrity across entities.

## Key Replacement and Design Notes

* **Replacement of Composite Keys**: The composite keys used during early normalisation stages are replaced in the final design by auto-incrementing integer surrogate keys (`customer_id`, `account_id`, `transaction_id`, `biller_id`) to optimize indexing efficiency and simplify join conditions.
* **Surrogate IDs and 3NF Proof**: Assigning an auto-generated ID to a table does not automatically guarantee 3NF. 3NF is established strictly by verifying that all non-key fields depend exclusively on the primary key and that no transitive or partial functional dependencies remain.
* **Omitted Attributes**: The timestamp attribute `created_at` from the `Transaction` entity is omitted from these sample tables to maintain concise tabular layouts, but remains included in the full relational schema.