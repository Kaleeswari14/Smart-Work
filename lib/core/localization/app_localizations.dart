import "package:flutter/foundation.dart";
import "package:flutter/material.dart";

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale("en"));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    "en": {
      // General & Navigation
      "app_title": "Smartiva",
      "tagline": "Professional Business & Task Tracker",
      "language_toggle": "Switch to Tanglish",
      "current_language": "English",
      "dashboard": "Dashboard",
      "customers": "Customers",
      "works": "Works",
      "payments": "Payments",
      "reports": "Reports",
      "settings": "Settings",
      "history": "History",
      "login": "Login",
      "logout": "Logout",
      "cancel": "Cancel",
      "save": "Save",
      "close": "Close",
      "delete": "Delete",
      "search": "Search...",
      "no_data": "No Data Available",

      // Auth Screen
      "login_title": "Welcome Back",
      "login_subtitle": "Sign in to manage works and payments",
      "username_label": "Username or Email",
      "password_label": "Password",
      "role_label": "Role",
      "owner_role": "Owner",
      "admin_role": "Admin",
      "login_button": "Sign In",
      "forgot_password": "Forgot Password?",
      "download_apk": "Download Android App (APK)",
      "download_apk_desc": "Install Smartiva directly on your Android mobile",

      // Dashboard Screen
      "overview": "Overview",
      "active_works_count": "Active Works",
      "total_customers_count": "Total Customers",
      "today_hours": "Today's Hours",
      "today_completed": "Completed Works",
      "pending_dues": "Pending Collection",
      "quick_actions": "Quick Actions",
      "new_work": "New Work",
      "new_customer": "New Customer",
      "record_payment": "Collect Payment",
      "recent_activities": "Recent Activities",
      "no_recent_activities": "No recent activities recorded yet.",

      // Customers Screen
      "customer_list": "Customer Directory",
      "add_customer": "Add Customer",
      "customer_name": "Customer Name",
      "phone_number": "Phone Number",
      "email_address": "Email Address",
      "address": "Address / Location",
      "no_customers_title": "No Customers Added Yet",
      "no_customers_desc": "Start by clicking 'Add Customer' button to register your first client.",

      // Works Screen & Status Dropdown
      "work_orders": "Work Orders & Tasks",
      "add_work": "Create New Work",
      "select_customer": "Select Customer",
      "customer_label": "Customer",
      "no_customers_create_first": "No customers found! Please add a customer first before creating a work order.",
      "work_title": "Work Title",
      "work_description": "Description / Scope",
      "total_cost": "Agreed Cost (₹)",
      "advance_amount": "Advance Paid (₹)",
      "balance_due": "Balance Due (₹)",
      "work_status": "Status",
      "status_pending": "Pending",
      "status_in_progress": "In Progress",
      "status_completed": "Completed",
      "status_cancelled": "Cancelled",
      "no_works_title": "No Works Created Yet",
      "no_works_desc": "Create a work order. Click the status button to switch between Pending, In Progress, Completed, or Cancelled.",
      "duration_spent": "Time Spent",
      "edit_time": "Edit Time",
      "enter_hours": "Hours",
      "enter_minutes": "Minutes",
      "change_status": "Change Status",
      "auto_timer_active": "Tracking time live while In Progress...",
      "action_taken": "Action Taken",
      "action_notes": "Completion Action Details",
      "enter_action_notes": "Enter work action details before completing *",
      "confirm_complete": "Confirm Completion",
      "delete_work": "Delete Work",
      "confirm_delete_work": "Are you sure you want to delete this work order?",
      "billing_ready": "Billing Ready (Pending Bill)",
      "bill_created": "Bill Created",
      "generate_bill": "Generate Bill",
      "create_bill": "Create Bill",
      "nav_payments": "Payments Dashboard",

      // Payments Dashboard & Collection
      "payment_dashboard": "Payments Dashboard",
      "pending_collection": "Pending Collection",
      "collected_history": "Collected History",
      "collect_payment": "Collect Payment",
      "total_collected": "Total Collected",
      "outstanding_balance": "Total Outstanding",
      "bill_number": "Bill / Invoice No",
      "amount_to_collect": "Amount to Collect (₹)",
      "payment_account": "Payment Account / Method",
      "type_savings": "Savings",
      "type_current": "Current",
      "type_cash": "Cash",
      "no_pending_payments": "No pending bills! All completed works have been collected.",
      "no_collected_history": "No payments collected yet. Collections recorded in this dashboard will appear here.",

      // Customer History Screen
      "customer_history_title": "Customer History & Audits",
      "no_history_title": "No Audit History",
      "no_history_desc": "System logs, work completions, and payment receipts will generate an audit trail here.",

      // Reports Screen
      "business_reports": "Financial & Work Reports",
      "total_earnings": "Total Billed",
      "completed_works_stat": "Completed Works",
      "monthly_report": "Monthly Performance Report",
      "monthly_income": "Monthly Income",
      "empty_reports_desc": "Reports will calculate automatically once real work orders and payments are logged.",

      // Settings Screen
      "system_settings": "Application Settings",
      "preferences": "Preferences",
      "language_preference": "Language / Mozhi",
      "theme_mode": "Theme Mode",
      "theme_light": "Light Mode",
      "theme_dark": "Dark Mode",
      "profile_section": "User Profile",
      "account_type": "Account Type",
      "app_version": "Version 1.0.0 (Smartiva)",
    },
    "ta": {
      // General & Navigation
      "app_title": "Smartiva",
      "tagline": "Thozhil Matrum Velaigal Kankanippu",
      "language_toggle": "Switch to English",
      "current_language": "Tanglish (Tamil)",
      "dashboard": "Mukkiya Pakkam",
      "customers": "Vaadikkaiyaalargal",
      "works": "Velaigal",
      "payments": "Panam & Kadan",
      "reports": "Arikkaigal",
      "settings": "Amaippugal",
      "history": "Varalaaru",
      "login": "Ulle Nulai",
      "logout": "Veliyeiru",
      "cancel": "Rathu Sei",
      "save": "Semithidu",
      "close": "Moodu",
      "delete": "Azhi",
      "search": "Thedu...",
      "no_data": "Thagavalgal Edhum Illai",

      // Auth Screen
      "login_title": "Meendum Varuga",
      "login_subtitle": "Velaigalai matrum panathai nirvagikka ulle nulaiyavum",
      "username_label": "Username alladhu Email",
      "password_label": "Kadavusol (Password)",
      "role_label": "Padhavi (Role)",
      "owner_role": "Urimaiyaalar (Owner)",
      "admin_role": "Nirvaagi (Admin)",
      "login_button": "Ulle Nulai",
      "forgot_password": "Password Marandhu Vittadha?",
      "download_apk": "Android App Download Pannu (APK)",
      "download_apk_desc": "Unga Android phone-il Smartiva-va install seiyavum",

      // Dashboard Screen
      "overview": "Oru Paarvai",
      "active_works_count": "Nadakkum Velaigal",
      "total_customers_count": "Moththa Vaadikkaiyaalargal",
      "today_hours": "Indraiya Neram",
      "today_completed": "Mudindha Velaigal",
      "pending_dues": "Vara Vendiya Panam",
      "quick_actions": "Viraivaana Seyalgal",
      "new_work": "Pudhu Vela",
      "new_customer": "Pudhu Vaadikkaiyaalar",
      "record_payment": "Panam Vaangu",
      "recent_activities": "Kadaisi Seyalgal",
      "no_recent_activities": "Kadaisi seyalgal edhum innum padhivagavillai.",

      // Customers Screen
      "customer_list": "Vaadikkaiyaalar Pattiyal",
      "add_customer": "Vaadikkaiyaalar Ser",
      "customer_name": "Vaadikkaiyaalar Peyar",
      "phone_number": "Phone Number",
      "email_address": "Email Id",
      "address": "Mugavari (Address)",
      "no_customers_title": "Vaadikkaiyaalargal Yaarum Illai",
      "no_customers_desc": "'Vaadikkaiyaalar Ser' button amukki ungaloda modhal client-a register pannunga.",

      // Works Screen & Status Dropdown
      "work_orders": "Velaigal & Tasks",
      "add_work": "Pudhu Vela Thodangu",
      "select_customer": "Vaadikkaiyaalarai Therndhedu",
      "customer_label": "Vaadikkaiyaalar",
      "no_customers_create_first": "Vaadikkaiyaalar yaarum illai! Vela serkka mudhalil 'Vaadikkaiyaalar Ser' button amukki client-a add pannunga.",
      "work_title": "Vela Peyar / Title",
      "work_description": "Vela Vivaram",
      "total_cost": "Pesappatta Kattanam (₹)",
      "advance_amount": "Advance Thogai (₹)",
      "balance_due": "Meedhi Vara Vendiyadhu (₹)",
      "work_status": "Nilai (Status)",
      "status_pending": "Nilaivai (Pending)",
      "status_in_progress": "Nadakkiradhu (In Progress)",
      "status_completed": "Mudinthadhu (Completed)",
      "status_cancelled": "Rathu Seiyappattadhu (Cancelled)",
      "no_works_title": "Velaigal Edhum Illai",
      "no_works_desc": "Pudhu vela create pannunga. Status badge-a amukki Pending, In Progress, Completed, Cancelled-ku maathikalam.",
      "duration_spent": "Selitta Neram",
      "edit_time": "Neram Maatru",
      "enter_hours": "Mani (Hours)",
      "enter_minutes": "Nimidam (Mins)",
      "change_status": "Nilai Maatru",
      "auto_timer_active": "In Progress-la irukkumbodhu neram automatic-ah track aagudhu...",
      "action_taken": "Seitha Action",
      "action_notes": "Vela Mudintha Action Kurippu",
      "enter_action_notes": "Velai mudikkum mun seitha action vivaram enter pannunga *",
      "confirm_complete": "Mudinthathai Confirm Pannu",
      "delete_work": "Vela Neekku",
      "confirm_delete_work": "Indha velaiyai nichayamaga neekka venduma?",
      "billing_ready": "Billing Ready (Bill Podanum)",
      "bill_created": "Bill Pottachu",
      "generate_bill": "Bill Podu",
      "create_bill": "Bill Podu",
      "nav_payments": "Panam Dashboard",

      // Payments Dashboard & Collection
      "payment_dashboard": "Panam & Kadan Nirvaagam",
      "pending_collection": "Vara Vendiya Panam",
      "collected_history": "Vandha Panam Varalaaru",
      "collect_payment": "Panam Vaangu",
      "total_collected": "Vandha Moththa Panam",
      "outstanding_balance": "Vara Vendiya Meedhi",
      "bill_number": "Bill / Invoice En",
      "amount_to_collect": "Vaangum Thogai (₹)",
      "payment_account": "Panam Account / Vakai",
      "type_savings": "Savings",
      "type_current": "Current",
      "type_cash": "Cash (Rokkamaaga)",
      "no_pending_payments": "Vara vendiya kadan edhum illai! Ella mudintha velaikkum panam vandhuvittadhu.",
      "no_collected_history": "Panam innum collect seiyavillai. Vaangum panam ingey varisaiyaaga theriyum.",

      // Customer History Screen
      "customer_history_title": "Vaadikkaiyaalar Varalaaru",
      "no_history_title": "Varalaaru Edhum Illai",
      "no_history_desc": "System logs, mudintha velaigal matrum receipt-gal ingey audit trail-aga varum.",

      // Reports Screen
      "business_reports": "Panam & Vela Arikkaigal",
      "total_earnings": "Moththa Bill Thogai",
      "completed_works_stat": "Mudintha Velaigal",
      "monthly_report": "Maadha Varumaana Arikkai",
      "monthly_income": "Maadha Varumaanam",
      "empty_reports_desc": "Unmaiyana velaigal matrum payments serkkumpodhu arikkaigal automatic-ah calculation aagum.",

      // Settings Screen
      "system_settings": "App Amaippugal",
      "preferences": "Viruppangal",
      "language_preference": "Mozhi (Language)",
      "theme_mode": "Vannam (Theme)",
      "theme_light": "Velicham (Light Mode)",
      "theme_dark": "Iravu (Dark Mode)",
      "profile_section": "Ungal Profile",
      "account_type": "Kanaku Vakai",
      "app_version": "Pathippu 1.0.0 (Phase 2 Frontend)",
    },
  };

  String translate(String key) {
    final langCode = locale.languageCode == "ta" ? "ta" : "en";
    return _localizedValues[langCode]?[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ["en", "ta"].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension TranslationExtension on BuildContext {
  String tr(String key) => AppLocalizations.of(this).translate(key);
}
