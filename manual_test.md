# Manual Testing Gate Log (`manual_test.md`)

This file records all manual test instructions, step-by-step click flows, expected results, user confirmations, pass/fail logs, and retests.
**Rule:** No test is marked as PASSED without the user's explicit confirmation.

---

## 🧪 Test Runs

### Test Run: Phase 0 - Environment Setup & Documentation Gate
* **Date:** 2026-11-13 | **Status:** `PASSED` (Confirmed on 2026-11-13)

### Test Run: Phase 1 - Flutter Project Foundation & Localization Gate
* **Date:** 2026-11-14 | **Status:** `PASSED` (Confirmed on 2026-11-14)

### Test Run: Phase 2 - Frontend Screens & Business Workflow Gate
* **Date:** 2026-11-14 | **Status:** `PASSED` (Confirmed on 2026-11-14)

### Test Run: Phase 3 - Supabase Backend, PostgreSQL Schema & Live Cloud Sync Gate
* **Date:** 2026-11-14 | **Status:** `PASSED` (Confirmed on 2026-11-14)

### Test Run: Phase 4 - Single Owner Authentication, Session Management & Clean Navigation Gate
* **Date:** 2026-11-14 | **Status:** `PASSED` (Confirmed on 2026-11-14)

---

### Test Run: Phase 5 - Advanced Business Reports, Financial Analytics & PDF Invoicing Gate
* **Date:** 2026-11-14
* **Tester:** User (Apprentice Developer)
* **Goal:** Verify:
  1. Live financial reports calculating Total Earnings, Total Collected, Outstanding Balance, and Collection Rate %.
  2. 3-Account breakdown cards dynamically displaying amounts collected in Savings, Current, and Cash.
  3. Date filter menu (All Time, This Month, This Week, Today).
  4. One-tap professional PDF invoice generation & browser printing.
  5. Customer History screen displaying full lifetime ledger (Total Billed, Paid, Balance, timeline of works & payment receipts).

#### Step-by-Step Live Verification:
1. Launch app in Chrome:
   ```powershell
   flutter run -d chrome
   ```
2. **Test Reports Tab:**
   - Tap **Reports** tab.
   - Check the **Collection Rate %** bar.
   - Verify the 4 Financial Summary cards (Total Earnings, Total Collected, Outstanding Balance, Completed Works).
   - Check the **3-Account Breakdown** cards (Savings Bank, Current Bank, Cash in Hand) reflect real collected payments!
   - Tap the top-right filter chip -> change between "All Time", "This Month", "Today".
3. **Test PDF Invoice Generation & Print:**
   - Tap **Payments** tab (or **Works** tab) -> On any completed or billed work card, click the **PDF icon** button (`picture_as_pdf`).
   - Browser print dialog opens with a formatted, professional A4 Invoice (Smartiva Technologies header, Bill #, customer name, work description, cost, advance, paid, balance).
   - You can download as PDF or print!
4. **Test Customer History & Ledger:**
   - Open Side Drawer -> Tap **Settings** -> Tap **Customer History** tile (or click a customer from Customers tab).
   - Select a customer from the dropdown -> see their **Total Billed**, **Total Paid**, and **Balance Due**.
   - Review past works timeline and payment receipts for that specific customer.

* **Expected Result:**
  - Real-time accounting analytics, error-free PDF invoice generation, and complete customer history ledgers.
* **Actual Result:** Passed. User confirmed Phase 5 success and approved starting Phase 6.
* **Status:** `PASSED`

---

### Test Run: Phase 6 - Android Production Release APK Build & Keystore Signing Gate
* **Date:** 2026-11-14
* **Tester:** User (Apprentice Developer)
* **Goal:** Verify:
  1. Signed Release APK generated in `build/app/outputs/flutter-apk/app-release.apk`.
  2. APK installs and runs properly on an Android phone (or adb emulator/device).
  3. App opens with app name "Smartiva Work Management", connects to Supabase over internet, and functions smoothly.

#### Step-by-Step Live Verification:
1. Locate APK file on your PC:
   `G:\work application\build\app\outputs\flutter-apk\app-release.apk`
2. **Install on Android Device:**
   - **Option A (USB Debugging):**
     ```powershell
     adb install -r "G:\work application\build\app\outputs\flutter-apk\app-release.apk"
     ```
   - **Option B (Phone Transfer):**
     Transfer `app-release.apk` to phone (via Google Drive / USB / WhatsApp), tap to install.
3. Open **Smartiva Work Management** app on the phone:
   - Verify login with `admin@smart.com` / `admin@1407`.
   - Verify Works, Customers, Payments, Timer, and Reports load and sync with Supabase cloud.

* **Expected Result:**
  - APK installs cleanly, launches with splash screen, authenticates, and connects to Supabase database.
* **Actual Result:** [Awaiting User Confirmation: SUCCESS or FAILED]
* **Status:** `AWAITING_USER_CONFIRMATION`
