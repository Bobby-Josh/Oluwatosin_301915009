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