# Database Architecture & Schema Documentation (`database_documentation.md`)

This document outlines the PostgreSQL schema, table definitions, relationships, indexes, triggers, and migrations managed via Supabase.

---

## 🗄️ Relational Entity Diagram Overview
```text
profiles (Owner & Admin auth users)
  ├── customers
  │     ├── works (Orders / Tasks)
  │     │     ├── work_sessions (Auto Session Timers)
  │     │     └── payments (Financial Audit Ledger: Savings, Current, Cash)
  │     └── audit_logs (Activity Trail)
  └── audit_logs (System-wide Logs)
```

---

## 📋 Table Definitions (Phase 3 Implemented)

### 1. `profiles`
* `id` (UUID, Primary Key, references `auth.users(id)` ON DELETE CASCADE)
* `email` (TEXT, unique, not null)
* `full_name` (TEXT, not null)
* `role` (TEXT, check in ('owner', 'admin'))
* `created_at` (TIMESTAMPTZ, default now())
* `updated_at` (TIMESTAMPTZ, default now())

### 2. `customers`
* `id` (UUID, Primary Key, default `gen_random_uuid()`)
* `name` (TEXT, not null)
* `phone` (TEXT, default '')
* `email` (TEXT, default '')
* `address` (TEXT, default '')
* `created_by` (UUID, references profiles.id ON DELETE SET NULL)
* `created_at` (TIMESTAMPTZ, default now())
* `updated_at` (TIMESTAMPTZ, default now())

### 3. `works`
* `id` (UUID, Primary Key, default `gen_random_uuid()`)
* `customer_id` (UUID, references customers.id ON DELETE CASCADE)
* `title` (TEXT, not null)
* `description` (TEXT, default '')
* `action_note` (TEXT, default '', stores work action details entered on completion)
* `total_cost` (NUMERIC(12, 2), default 0.00)
* `advance_paid` (NUMERIC(12, 2), default 0.00)
* `collected_payment` (NUMERIC(12, 2), default 0.00)
* `status` (TEXT, check in ('pending', 'in_progress', 'completed', 'cancelled'))
* `billing_status` (TEXT, check in ('unbilled', 'billed'))
* `bill_number` (TEXT)
* `billed_amount` (NUMERIC(12, 2))
* `payment_status` (TEXT, check in ('pending', 'collected'))
* `payment_account` (TEXT, check in ('savings', 'current', 'cash'))
* `total_seconds` (BIGINT, default 0)
* `in_progress_start_time` (TIMESTAMPTZ)
* `created_by` (UUID, references profiles.id ON DELETE SET NULL)
* `created_at` (TIMESTAMPTZ, default now())
* `updated_at` (TIMESTAMPTZ, default now())

### 4. `work_sessions` (Timer Records)
* `id` (UUID, Primary Key, default `gen_random_uuid()`)
* `work_id` (UUID, references works.id ON DELETE CASCADE)
* `start_time` (TIMESTAMPTZ, default now())
* `end_time` (TIMESTAMPTZ)
* `duration_seconds` (BIGINT, default 0)
* `notes` (TEXT, default '')
* `created_at` (TIMESTAMPTZ, default now())

### 5. `payments` (Financial Ledger)
* `id` (UUID, Primary Key, default `gen_random_uuid()`)
* `work_id` (UUID, references works.id ON DELETE CASCADE)
* `customer_id` (UUID, references customers.id ON DELETE CASCADE)
* `bill_number` (TEXT, not null)
* `amount` (NUMERIC(12, 2), not null, check amount > 0)
* `payment_type` (TEXT, check in ('savings', 'current', 'cash'))
* `payment_date` (TIMESTAMPTZ, default now())
* `notes` (TEXT, default '')
* `recorded_by` (UUID, references profiles.id ON DELETE SET NULL)
* `created_at` (TIMESTAMPTZ, default now())

### 6. `audit_logs` (System Audit Trail)
* `id` (UUID, Primary Key, default `gen_random_uuid()`)
* `entity_type` (TEXT, not null)
* `entity_id` (TEXT, not null)
* `action` (TEXT, not null)
* `details` (JSONB, default '{}')
* `performed_by` (UUID, references profiles.id ON DELETE SET NULL)
* `created_at` (TIMESTAMPTZ, default now())

---

## 🚀 Migration Files Created
1. `supabase/migrations/001_initial_schema.sql`
2. `supabase/migrations/002_rls_policies.sql`
3. `supabase/migrations/001_rollback.sql`
