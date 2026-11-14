// File: Oluwatosin_Ijimakinwa_301915009_P4_MongoDB.js
// Database: paypulse_events | Collection: account_events
// Works identically in Local MongoDB and MongoDB Atlas after connecting with mongosh.

// 1. Select the target database (equivalent to `use paypulse_events` in interactive shell)
db = db.getSiblingDB("paypulse_events");

// 2. Verify the collection is empty before inserting
print("=== Pre-Insert Empty Check ===");
printjson(db.account_events.countDocuments({}));

// 3. Insert four fictional PayPulse activity documents once
print("=== Inserting Four Sample Event Documents ===");
printjson(
  db.account_events.insertMany([
    {
      _id: "EVT-2026-001",
      event_type: "Transfer",
      occurred_at: ISODate("2026-11-10T09:15:00Z"),
      customer: {
        government_id: "GOV-1001",
        full_name: "Alice Mensah"
      },
      source_account: {
        account_ref: "ACC-GOV1001-CHK",
        account_type: "Checking"
      },
      details: {
        amount: 250.00,
        currency: "USD",
        destination_account: {
          account_ref: "ACC-GOV1002-CHK",
          account_type: "Checking",
          recipient_government_id: "GOV-1002",
          recipient_name: "Bob Okafor"
        },
        reference_note: "Peer-to-peer transfer"
      }
    },
    {
      _id: "EVT-2026-002",
      event_type: "BillPayment",
      occurred_at: ISODate("2026-11-10T11:30:00Z"),
      customer: {
        government_id: "GOV-1002",
        full_name: "Bob Okafor"
      },
      source_account: {
        account_ref: "ACC-GOV1002-CHK",
        account_type: "Checking"
      },
      details: {
        amount: 75.50,
        currency: "USD",
        biller: {
          biller_name: "Eko Electric Utility",
          service_category: "Electricity"
        },
        bill_reference: "BILL-EKO-4401"
      }
    },
    {
      _id: "EVT-2026-003",
      event_type: "BillPayment",
      occurred_at: ISODate("2026-11-11T14:20:00Z"),
      customer: {
        government_id: "GOV-1001",
        full_name: "Alice Mensah"
      },
      source_account: {
        account_ref: "ACC-GOV1001-SAV",
        account_type: "Savings"
      },
      details: {
        amount: 42.00,
        currency: "USD",
        biller: {
          biller_name: "Lagos Water Works",
          service_category: "Water"
        },
        bill_reference: "BILL-LWW-8812"
      }
    },
    {
      _id: "EVT-2026-004",
      event_type: "Transfer",
      occurred_at: ISODate("2026-11-12T16:45:00Z"),
      customer: {
        government_id: "GOV-1001",
        full_name: "Alice Mensah"
      },
      source_account: {
        account_ref: "ACC-GOV1001-CHK",
        account_type: "Checking"
      },
      details: {
        amount: 300.00,
        currency: "USD",
        destination_account: {
          account_ref: "ACC-GOV1001-SAV",
          account_type: "Savings",
          recipient_government_id: "GOV-1001",
          recipient_name: "Alice Mensah"
        },
        reference_note: "Checking to Savings top-up"
      }
    }
  ])
);

// 4. Query 1: Total document count in account_events
print("=== Query 1: Total Document Count ===");
printjson(db.account_events.countDocuments({}));

// 5. Query 2: Chronologically ordered event history for one customer (GOV-1001)
print("=== Query 2: Ordered Event History for GOV-1001 (Alice Mensah) ===");
printjson(
  db.account_events
    .find({ "customer.government_id": "GOV-1001" })
    .sort({ occurred_at: 1 })
    .toArray()
);

// 6. Query 3: Nested-field filter on biller name inside polymorphic details
print("=== Query 3: Nested-Field Filter (Eko Electric Utility Payments) ===");
printjson(
  db.account_events
    .find({ "details.biller.biller_name": "Eko Electric Utility" })
    .toArray()
);