# Security & Access Control Documentation (`security_documentation.md`)

This document outlines authentication policies, role permissions, Row Level Security (RLS) enforcement, and data encryption.

---

## 🛡️ Role-Based Access Matrix

| Entity / Action | Owner | Admin | Unauthenticated / Public |
| :--- | :---: | :---: | :---: |
| **Login / Auth** | ✅ | ✅ | ❌ |
| **View Profiles** | ✅ | ✅ | ❌ |
| **Update Own Profile** | ✅ | ✅ | ❌ |
| **View Customers** | ✅ | ✅ | ❌ |
| **Create / Edit Customers** | ✅ | ✅ | ❌ |
| **Delete Customer** | ✅ (Owner Only) | ❌ | ❌ |
| **View Works** | ✅ | ✅ | ❌ |
| **Create / Update Works** | ✅ | ✅ | ❌ |
| **Delete Work** | ✅ (Owner Only) | ❌ | ❌ |
| **View Payments** | ✅ | ✅ | ❌ |
| **Record Payment (Savings/Current/Cash)** | ✅ | ✅ | ❌ |
| **Delete Payment** | ✅ (Owner Only) | ❌ | ❌ |
| **View Audit Logs** | ✅ | ✅ | ❌ |

---

## 🔒 Row Level Security (RLS) Policies (Implemented in `002_rls_policies.sql`)
- **Profiles Table:** RLS enabled. Authenticated users can view all profiles; only profile owner can edit own profile details.
- **Customers Table:** RLS enabled. Authenticated users can read/write; deletion strictly restricted to `is_owner()`.
- **Works Table:** RLS enabled. Authenticated users can read/write; deletion strictly restricted to `is_owner()`.
- **Work Sessions Table:** RLS enabled. Authenticated users can read/insert session timers.
- **Payments Table:** RLS enabled. Authenticated users can read/insert payment records; deletion strictly restricted to `is_owner()`.
- **Audit Logs Table:** RLS enabled. Authenticated users can view audit trail; creation automated via server triggers.
