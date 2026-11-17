import "package:flutter/foundation.dart";
import "../../../core/config/supabase_config.dart";
import "../presentation/payments_provider.dart";

class PaymentsRepository {
  final _client = SupabaseConfig.client;

  bool get isConnected => _client != null;

  Future<List<PaymentRecord>> fetchPayments() async {
    final client = _client;
    if (client == null) {
      debugPrint("ℹ️ Supabase not connected. Skipping remote payments fetch.");
      return [];
    }

    try {
      dynamic response;
      try {
        response = await client
            .from("payments")
            .select("*, works(title, bill_number, customer_id, customers(name, phone)), customers(name, phone)")
            .order("payment_date", ascending: false);
      } catch (_) {
        response = await client
            .from("payments")
            .select("*, works(title), customers(name)")
            .order("payment_date", ascending: false);
      }

      return (response as List).map((row) {
        final work = row["works"] as Map<String, dynamic>?;
        final customer = row["customers"] as Map<String, dynamic>?;
        final workCustomer = work?["customers"] as Map<String, dynamic>?;

        final workTitle = work?["title"] as String? ?? "Unknown Work";
        final customerName = customer?["name"] as String? ??
            workCustomer?["name"] as String? ??
            "Unknown Customer";
        final customerPhone = customer?["phone"] as String? ??
            workCustomer?["phone"] as String? ??
            "";

        DateTime date = DateTime.now();
        if (row["payment_date"] != null) {
          date = DateTime.tryParse(row["payment_date"].toString()) ?? DateTime.now();
        }

        final billNumber = row["bill_number"] as String? ??
            work?["bill_number"] as String? ??
            "";

        return PaymentRecord(
          id: row["id"] as String,
          workId: row["work_id"] as String? ?? "",
          workTitle: workTitle,
          customerId: row["customer_id"] as String? ?? "",
          customerName: customerName,
          customerPhone: customerPhone,
          billNumber: billNumber,
          amount: (row["amount"] as num?)?.toDouble() ?? 0.0,
          paymentType: row["payment_type"] as String? ?? "cash",
          paymentDate: date,
          notes: row["notes"] as String? ?? "",
          paymentCategory: row["payment_category"] as String? ??
              (row["category"] as String? ?? "Bill Collection"),
        );
      }).toList();
    } catch (e) {
      debugPrint("⚠️ Error fetching payments from Supabase: $e");
      return [];
    }
  }

  Future<PaymentRecord?> recordPayment({
    required String workId,
    required String workTitle,
    required String customerId,
    required String customerName,
    String customerPhone = "",
    required String billNumber,
    required double amount,
    required String paymentType,
    String notes = "",
    String paymentCategory = "Bill Collection",
  }) async {
    final client = _client;
    if (client == null) return null;

    try {
      final payload = <String, dynamic>{
        "work_id": workId,
        "customer_id": customerId,
        "bill_number": billNumber,
        "amount": amount,
        "payment_type": paymentType,
        "notes": notes,
        "payment_date": DateTime.now().toIso8601String(),
      };

      Map<String, dynamic> inserted;
      try {
        final withCat = Map<String, dynamic>.from(payload);
        withCat["payment_category"] = paymentCategory;
        inserted = await client.from("payments").insert(withCat).select().single();
      } catch (_) {
        // Fallback if payment_category column does not exist in remote table
        inserted = await client.from("payments").insert(payload).select().single();
      }

      DateTime date = DateTime.now();
      if (inserted["payment_date"] != null) {
        date = DateTime.tryParse(inserted["payment_date"].toString()) ?? DateTime.now();
      }

      return PaymentRecord(
        id: inserted["id"] as String,
        workId: workId,
        workTitle: workTitle,
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        billNumber: billNumber,
        amount: amount,
        paymentType: paymentType,
        paymentDate: date,
        notes: inserted["notes"] as String? ?? notes,
        paymentCategory: inserted["payment_category"] as String? ?? paymentCategory,
      );
    } catch (e) {
      debugPrint("⚠️ Error recording payment in Supabase: $e");
      return null;
    }
  }

  Future<void> updatePaymentNotes({
    required String paymentId,
    required String notes,
  }) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.from("payments").update({"notes": notes}).eq("id", paymentId);
      debugPrint("✅ Payment $paymentId notes updated: $notes");
    } catch (e) {
      debugPrint("⚠️ Error updating payment notes in Supabase: $e");
    }
  }
}
