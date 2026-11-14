import "package:flutter/foundation.dart";
import "../../../core/config/supabase_config.dart";

class AuditRepository {
  final _client = SupabaseConfig.client;

  bool get isConnected => _client != null;

  Future<void> logEvent({
    required String entityType,
    required String entityId,
    required String action,
    Map<String, dynamic> details = const {},
  }) async {
    final client = _client;
    if (client == null) return;

    try {
      final user = client.auth.currentUser;
      await client.from("audit_logs").insert({
        "entity_type": entityType,
        "entity_id": entityId,
        "action": action,
        "details": details,
        "performed_by": user?.id,
      });
    } catch (e) {
      debugPrint("⚠️ Failed to record audit log: $e");
    }
  }

  Future<List<Map<String, dynamic>>> fetchAuditLogs({int limit = 50}) async {
    final client = _client;
    if (client == null) return [];

    try {
      final response = await client
          .from("audit_logs")
          .select()
          .order("created_at", ascending: false)
          .limit(limit);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint("⚠️ Failed to fetch audit logs: $e");
      return [];
    }
  }
}
