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
      final response = await client
          .from("payments")
          .select("*, works(title), customers(name)")
          .order("payment_date", ascending: false);

      return (response as List).map((row) {
        final work = row["works"] as Map<String, dynamic>?;
        final customer = row["customers"] as Map<String, dynamic>?;

        final workTitle = work?["title"] as String? ?? "Unknown Work";
        final customerName = customer?["name"] as String? ?? "Unknown Customer";

        DateTime date = DateTime.now();
        if (row["payment_date"] != null) {
          date = DateTime.tryParse(row["payment_date"].toString()) ?? DateTime.now();
        }

        return PaymentRecord(
          id: row["id"] as String,
          workId: row["work_id"] as String? ?? "",
          workTitle: workTitle,
          customerId: row["customer_id"] as String? ?? "",
          customerName: customerName,
          billNumber: row["bill_number"] as String? ?? "",
          amount: (row["amount"] as num?)?.toDouble() ?? 0.0,
          paymentType: row["payment_type"] as String? ?? "cash",
          paymentDate: date,
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
    required String billNumber,
    required double amount,
    required String paymentType,
    String notes = "",
  }) async {
    final client = _client;
    if (client == null) return null;

    try {
      final payload = {
        "work_id": workId,
        "customer_id": customerId,
        "bill_number": billNumber,
        "amount": amount,
        "payment_type": paymentType,
        "notes": notes,
        "payment_date": DateTime.now().toIso8601String(),
      };

      final inserted = await client.from("payments").insert(payload).select().single();

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
        billNumber: billNumber,
        amount: amount,
        paymentType: paymentType,
        paymentDate: date,
      );
    } catch (e) {
      debugPrint("⚠️ Error recording payment in Supabase: $e");
      return null;
    }
  }
}
