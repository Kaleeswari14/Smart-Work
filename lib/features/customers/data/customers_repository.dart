import "package:flutter/foundation.dart";
import "../../../core/config/supabase_config.dart";
import "../presentation/customers_provider.dart";

class CustomersRepository {
  final _client = SupabaseConfig.client;

  bool get isConnected => _client != null;

  Future<List<CustomerItem>> fetchCustomers() async {
    final client = _client;
    if (client == null) {
      debugPrint("ℹ️ Supabase not connected. Skipping remote customer fetch.");
      return [];
    }

    try {
      final response = await client
          .from("customers")
          .select()
          .order("created_at", ascending: false);

      return (response as List).map((row) {
        return CustomerItem(
          id: row["id"] as String,
          name: row["name"] as String? ?? "",
          phone: row["phone"] as String? ?? "",
          email: row["email"] as String? ?? "",
          address: row["address"] as String? ?? "",
        );
      }).toList();
    } catch (e) {
      debugPrint("⚠️ Error fetching customers from Supabase: $e");
      return [];
    }
  }

  Future<CustomerItem?> createCustomer({
    required String name,
    required String phone,
    String email = "",
    String address = "",
  }) async {
    final client = _client;
    if (client == null) {
      return null;
    }

    try {
      final inserted = await client.from("customers").insert({
        "name": name,
        "phone": phone,
        "email": email,
        "address": address,
      }).select().single();

      return CustomerItem(
        id: inserted["id"] as String,
        name: inserted["name"] as String? ?? name,
        phone: inserted["phone"] as String? ?? phone,
        email: inserted["email"] as String? ?? email,
        address: inserted["address"] as String? ?? address,
      );
    } catch (e) {
      debugPrint("⚠️ Error creating customer in Supabase: $e");
      return null;
    }
  }

  Future<bool> updateCustomer(CustomerItem customer) async {
    final client = _client;
    if (client == null) return false;

    try {
      await client.from("customers").update({
        "name": customer.name,
        "phone": customer.phone,
        "email": customer.email,
        "address": customer.address,
      }).eq("id", customer.id);
      return true;
    } catch (e) {
      debugPrint("⚠️ Error updating customer in Supabase: $e");
      return false;
    }
  }

  Future<bool> deleteCustomer(String customerId) async {
    final client = _client;
    if (client == null) return false;

    try {
      await client.from("customers").delete().eq("id", customerId);
      return true;
    } catch (e) {
      debugPrint("⚠️ Error deleting customer in Supabase: $e");
      return false;
    }
  }
}
