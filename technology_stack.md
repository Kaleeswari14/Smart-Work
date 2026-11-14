# Technology Stack Architecture (`technology_stack.md`)

This document details the architectural choices, tools, packages, and technical reasoning behind the application.

---

## 1. Frontend Architecture
* **Framework:** Flutter SDK (Stable Channel, 3.x)
* **Language:** Dart (3.x)
* **Architecture Pattern:** Feature-First Layered Architecture
  * `data/`: Repositories, Supabase API calls, DTO models.
  * `domain/`: Pure Dart business models and entities.
  * `presentation/`: UI Screens, Widgets, Riverpod State Notifiers.
* **State Management:** `flutter_riverpod` (v2.x)
* **Routing:** `go_router` (v14.x)
* **UI & Theming:** Material Design 3 (`useMaterial3: true`), responsive design, Dark & Light modes.
* **Localization:** Flutter Localization with English (`en`) and Tanglish (`ta_IN`/custom) key-value translation files.

---

## 2. Backend & Cloud Infrastructure
* **BaaS Platform:** Supabase (Cloud hosted or self-hosted)
* **Database Engine:** PostgreSQL 15+
* **Authentication:** Supabase GoTrue Auth (Email/Username with salted bcrypt password hashing)
* **Authorization & Security:** PostgreSQL Row Level Security (RLS) policies
* **Realtime Engine:** Supabase Realtime via WebSockets (Postgres Changes broadcast)

---

## 3. DevOps & Build Pipeline
* **VCS:** Git & GitHub
* **Android Build Tools:** Android Gradle Plugin (AGP), Gradle, Java JDK 17
* **Signing:** Android JKS Keystore (Debug vs Release signing separation)
