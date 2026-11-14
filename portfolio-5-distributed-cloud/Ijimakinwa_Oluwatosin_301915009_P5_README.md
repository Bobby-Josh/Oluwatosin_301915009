# Portfolio 5 Distributed and Cloud Database Exercise

## Current setup

PayPulse currently runs locally inside a single Ubuntu GitHub Codespace bound to `127.0.0.1` with port forwarding disabled. Two independent local database servers are verified: PostgreSQL 16 (`paypulse_portfolio`), which stores authoritative relational tables (`customer`, `biller`, `account`, `transaction`), and a single standalone MongoDB 8.0.38 process (`paypulse_events.account_events`, stored in `/workspaces/mongodb-data` outside the repository), which holds four sample `Transfer` and `BillPayment` documents. No multi-node topology, replication, sharding, or cloud deployment has been configured or verified.

## Proposed replication

To eliminate the single point of failure in a future production deployment, PayPulse could migrate `paypulse_events` from a standalone process to a proposed three-member voting, data-holding MongoDB [replica set](https://www.mongodb.com/docs/manual/replication/) across separate hosts and availability zones:

| Member | Starting role | Location |
| :--- | :--- | :--- |
| `mongo-node-1` | Primary | Host A / Availability Zone 1 |
| `mongo-node-2` | Secondary | Host B / Availability Zone 2 |
| `mongo-node-3` | Secondary | Host C / Availability Zone 3 |

For example, when PayPulse records a `BillPayment` event (such as `EVT-2026-002` for Eko Electric Utility), the application writes to `mongo-node-1`, and the two secondaries asynchronously replicate the entry from the primary's oplog.

## Failure and consistency

If the primary fails, the two surviving voting members hold a [replica set election](https://www.mongodb.com/docs/v8.0/core/replica-set-elections/)—requiring two of three votes for a majority—and promote one secondary to primary. Client writes experience a brief interruption during the election. If a network partition leaves fewer than two voting members reachable, no majority exists, so the cluster cannot elect a primary and rejects writes until a majority reconnects.

Using [`w: "majority"` write concern](https://www.mongodb.com/docs/v8.0/reference/write-concern/) ensures committed activity events are written to at least two members before acknowledgement, though secondaries can still exhibit brief replication lag when serving reads. Operational ledger decisions—such as verifying `amount <= balance` and `is_frozen = FALSE`—must remain in PostgreSQL (`paypulse_portfolio`), as MongoDB replication does not replicate PostgreSQL or automatically synchronise the two databases.

## Sharding and cloud deployment

Replication *copies* the same event documents across nodes for fault tolerance, whereas [sharding](https://www.mongodb.com/docs/manual/sharding/) *splits* large collections horizontally across multiple shard clusters using a shard key. PayPulse's four-document `account_events` dataset is far too small to justify sharding and fits easily on a single replica set.

Moving to a managed cloud service such as MongoDB Atlas would require role-based authentication, TLS encryption in transit and encryption at rest, IP allowlists or private endpoints to restrict network access, and scheduled [cluster backup and restore](https://www.mongodb.com/docs/atlas/backup-restore-cluster/). However, cloud deployment introduces ongoing multi-node hosting costs, network latency, and dual-database coordination overhead because MongoDB and PostgreSQL still operate without shared cross-database transactions.