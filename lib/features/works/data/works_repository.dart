import "package:flutter/foundation.dart";
import "../../../core/config/supabase_config.dart";
import "../presentation/works_provider.dart";

class WorksRepository {
  final _client = SupabaseConfig.client;

  bool get isConnected => _client != null;

  Future<List<WorkItem>> fetchWorks() async {
    final client = _client;
    if (client == null) {
      debugPrint("ℹ️ Supabase not connected. Skipping remote works fetch.");
      return [];
    }

    try {
      final response = await client
          .from("works")
          .select("*, customers(name)")
          .order("created_at", ascending: false);

      return (response as List).map((row) {
        final customer = row["customers"] as Map<String, dynamic>?;
        final customerName = customer?["name"] as String? ?? "Unknown Customer";

        DateTime? startTime;
        if (row["in_progress_start_time"] != null) {
          startTime = DateTime.tryParse(row["in_progress_start_time"].toString());
        }

        return WorkItem(
          id: row["id"] as String,
          customerId: row["customer_id"] as String? ?? "",
          customerName: customerName,
          title: row["title"] as String? ?? "",
          description: row["description"] as String? ?? "",
          actionNote: row["action_note"] as String? ?? "",
          totalCost: (row["total_cost"] as num?)?.toDouble() ?? 0.0,
          advancePaid: (row["advance_paid"] as num?)?.toDouble() ?? 0.0,
          collectedPayment: (row["collected_payment"] as num?)?.toDouble() ?? 0.0,
          status: row["status"] as String? ?? "pending",
          billingStatus: row["billing_status"] as String? ?? "unbilled",
          billNumber: row["bill_number"] as String?,
          billedAmount: (row["billed_amount"] as num?)?.toDouble(),
          paymentStatus: row["payment_status"] as String? ?? "pending",
          paymentAccount: row["payment_account"] as String?,
          totalSeconds: (row["total_seconds"] as num?)?.toInt() ?? 0,
          inProgressStartTime: startTime,
        );
      }).toList();
    } catch (e) {
      debugPrint("⚠️ Error fetching works from Supabase: $e");
      return [];
    }
  }

  Future<WorkItem?> createWork({
    required String customerId,
    required String customerName,
    required String title,
    required String description,
    required double totalCost,
    required double advancePaid,
  }) async {
    final client = _client;
    if (client == null) return null;

    try {
      final payload = {
        "customer_id": customerId,
        "title": title,
        "description": description,
        "action_note": "",
        "total_cost": totalCost,
        "advance_paid": advancePaid,
        "collected_payment": 0.0,
        "status": "pending",
        "billing_status": "unbilled",
        "payment_status": "pending",
        "total_seconds": 0,
      };

      final inserted = await client.from("works").insert(payload).select().single();

      return WorkItem(
        id: inserted["id"] as String,
        customerId: customerId,
        customerName: customerName,
        title: title,
        description: description,
        actionNote: "",
        totalCost: totalCost,
        advancePaid: advancePaid,
        collectedPayment: 0.0,
        status: "pending",
        billingStatus: "unbilled",
        paymentStatus: "pending",
        totalSeconds: 0,
      );
    } catch (e) {
      debugPrint("⚠️ Error creating work in Supabase: $e");
      return null;
    }
  }

  Future<bool> updateStatus({
    required String workId,
    required String status,
    required int totalSeconds,
    DateTime? inProgressStartTime,
  }) async {
    final client = _client;
    if (client == null) return false;

    try {
      await client.from("works").update({
        "status": status,
        "total_seconds": totalSeconds,
        "in_progress_start_time": inProgressStartTime?.toIso8601String(),
      }).eq("id", workId);
      return true;
    } catch (e) {
      debugPrint("⚠️ Error updating work status in Supabase: $e");
      return false;
    }
  }

  Future<bool> completeWorkWithAction({
    required String workId,
    required String actionNote,
    required double totalCost,
    required int totalSeconds,
  }) async {
    final client = _client;
    if (client == null) return false;

    try {
      await client.from("works").update({
        "status": "completed",
        "action_note": actionNote,
        "total_cost": totalCost,
        "total_seconds": totalSeconds,
        "in_progress_start_time": null,
        "billing_status": "unbilled",
        "payment_status": "pending",
      }).eq("id", workId);
      return true;
    } catch (e) {
      debugPrint("⚠️ Error completing work in Supabase: $e");
      return false;
    }
  }

  Future<bool> createBill({
    required String workId,
    required String billNumber,
    required double billedAmount,
  }) async {
    final client = _client;
    if (client == null) return false;

    try {
      await client.from("works").update({
        "bill_number": billNumber,
        "billed_amount": billedAmount,
        "billing_status": "billed",
        "payment_status": "pending",
      }).eq("id", workId);
      return true;
    } catch (e) {
      debugPrint("⚠️ Error creating bill in Supabase: $e");
      return false;
    }
  }

  Future<bool> markPaymentCollected({
    required String workId,
    required double newTotalCollected,
    required String accountType,
  }) async {
    final client = _client;
    if (client == null) return false;

    try {
      await client.from("works").update({
        "collected_payment": newTotalCollected,
        "payment_status": "collected",
        "payment_account": accountType,
      }).eq("id", workId);
      return true;
    } catch (e) {
      debugPrint("⚠️ Error recording payment collection in Supabase: $e");
      return false;
    }
  }

  Future<bool> updateTime({
    required String workId,
    required int totalSeconds,
  }) async {
    final client = _client;
    if (client == null) return false;

    try {
      await client.from("works").update({
        "total_seconds": totalSeconds,
      }).eq("id", workId);
      return true;
    } catch (e) {
      debugPrint("⚠️ Error updating work duration in Supabase: $e");
      return false;
    }
  }

  Future<bool> updateWorkDetails({
    required String workId,
    required String title,
    required String description,
    required double totalCost,
    required double advancePaid,
  }) async {
    final client = _client;
    if (client == null) return false;

    try {
      await client.from("works").update({
        "title": title,
        "description": description,
        "total_cost": totalCost,
        "advance_paid": advancePaid,
      }).eq("id", workId);
      return true;
    } catch (e) {
      debugPrint("⚠️ Error updating work details in Supabase: $e");
      return false;
    }
  }

  Future<bool> deleteWork(String workId) async {
    final client = _client;
    if (client == null) return false;

    try {
      await client.from("works").delete().eq("id", workId);
      return true;
    } catch (e) {
      debugPrint("⚠️ Error deleting work in Supabase: $e");
      return false;
    }
  }
}
