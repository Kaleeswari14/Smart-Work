# Personal Learning Guide & Mentor Notes (`learning_guide.md`)

Welcome to your personal development learning journal! In this project, every technology and architectural concept is broken down in simple Tanglish with real-world analogies, conceptual explanations, code mappings, and quick quizzes to test your understanding.

---

## 📚 Module 1: Core Technologies & Why We Use Them
* **Flutter:** Google UI Framework for multi-platform apps.
* **Dart:** Programming language used to write Flutter apps.
* **Riverpod:** State management.
* **GoRouter:** Declarative navigation.
* **Supabase:** PostgreSQL backend & realtime sync.

---

## 📚 Module 2: Project Architecture & Localization (Phase 1)
* **Feature-First Architecture:** Files organized by business feature (`features/customers`, `features/works`, etc.).
* **ProviderScope:** Main EB power switch for Riverpod.
* **Localization Dictionary:** Dynamic translation without app restart.

---

## 📚 Module 3: Frontend Screens, Live Timer & Empty States (Phase 2)
* **EmptyStateView:** Professional placeholders when no data exists.
* **ModalBottomSheet:** Slide-up forms from bottom without losing page context.
* **Status Dropdown Pill Button:** Compact, direct lifecycle switching.
* **Payments Dashboard Separation:** Independent financial source of truth for bill numbers and collections into Savings, Current, and Cash.

---

## 📚 Module 4: Cloud Database, PostgreSQL & Security (Phase 3)

### 1. Database & Tables (Locker & Ledgers)
* **What is a Database?** Oru periya digital locker. App close aanalum, phone switch off aanalum data permanently irukkum.
* **What is a Table?** Oru Excel Sheet mathiri. Example: `customers` table-la ella vaadikkaiyaalar peyar, phone irukkum. `works` table-la ella velaigal irukkum.

### 2. Primary Key vs Foreign Key (Aadhaar Number & Kudumba Link)
* **Primary Key (`id` UUID):** Ovvoru customer-kum irukkura thani Aadhaar number mathiri. Oru customer-oda ID mathavangalukku irukkaadhu.
* **Foreign Key (`customer_id`):** Oru velai entha customer-kooda link aagi irukku nu kaatra appa-pillai link. Idhanaala oru customer-ku pala velaigal (One-to-Many) connect aagum.

### 3. What is a Migration (`.sql` file)?
* Namma notebook-la ezhudhura blue-print mathiri. Step-by-step-ah tables, columns, indexes create panna Supabase-kitta thara instructions thaan `.sql` migration files.

### 4. Row Level Security (RLS) - The Digital Security Guard
* **What is it?** Namma bank locker room-la security guard irupparu la? Namma identity card-ah paathu namma locker-ah mattum open panna viduvaaru. Mathavanga locker-ah paaka vida maataaru. Athu thaan RLS!
* Owner mattum thaan data delete panna mudiyum; Admin velai create panna mudiyum.

---

## 🧠 Understanding Check Quizzes

### Quiz 4:
1. `customers` table-la irukura `id`-kum, `works` table-la irukura `customer_id`-kum enna relationship?
2. Row Level Security (RLS) off panna enna aagum? Yen atha eppavume ON-la vachirukkanum?
3. Payments table-la 3 payment types (Savings, Current, Cash) store panna namma use panra SQL constraint enna?
