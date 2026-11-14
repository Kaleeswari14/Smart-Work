import "dart:async";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "../data/customers_repository.dart";

class CustomerItem {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;

  const CustomerItem({
    required this.id,
    required this.name,
    this.phone = "",
    this.email = "",
    this.address = "",
  });

  CustomerItem copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
  }) {
    return CustomerItem(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
    );
  }
}

final customersRepositoryProvider = Provider<CustomersRepository>((ref) => CustomersRepository());

final customersListProvider =
    NotifierProvider<CustomersListNotifier, List<CustomerItem>>(() => CustomersListNotifier());

class CustomersListNotifier extends Notifier<List<CustomerItem>> {
  Timer? _syncTimer;
  RealtimeChannel? _realtimeChannel;

  @override
  List<CustomerItem> build() {
    _loadInitialCustomers();
    _setupAutoSyncAndRealtime();
    ref.onDispose(() {
      _syncTimer?.cancel();
      _realtimeChannel?.unsubscribe();
    });
    return [];
  }

  void _setupAutoSyncAndRealtime() {
    final repo = ref.read(customersRepositoryProvider);
    if (!repo.isConnected) return;

    try {
      final client = Supabase.instance.client;
      _realtimeChannel = client.channel("public:customers_changes").onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: "public",
        table: "customers",
        callback: (_) {
          refresh();
        },
      )..subscribe();
    } catch (_) {}

    _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final currentRepo = ref.read(customersRepositoryProvider);
      if (currentRepo.isConnected) {
        refresh();
      }
    });
  }

  Future<void> _loadInitialCustomers() async {
    final repo = ref.read(customersRepositoryProvider);
    final remote = await repo.fetchCustomers();
    if (remote.isNotEmpty) {
      state = remote;
    }
  }

  Future<void> refresh() async {
    final repo = ref.read(customersRepositoryProvider);
    final remote = await repo.fetchCustomers();
    state = remote;
  }

  Future<CustomerItem> addCustomer({
    required String name,
    required String phone,
    String email = "",
    String address = "",
  }) async {
    final localCustomer = CustomerItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      phone: phone,
      email: email,
      address: address,
    );

    // Optimistic local state update
    state = [localCustomer, ...state];

    final repo = ref.read(customersRepositoryProvider);
    if (repo.isConnected) {
      final remoteCustomer = await repo.createCustomer(
        name: name,
        phone: phone,
        email: email,
        address: address,
      );

      if (remoteCustomer != null) {
        state = [
          for (final c in state)
            if (c.id == localCustomer.id) remoteCustomer else c,
        ];
        return remoteCustomer;
      }
    }
    return localCustomer;
  }

  Future<void> updateCustomer(CustomerItem customer) async {
    state = [
      for (final c in state)
        if (c.id == customer.id) customer else c,
    ];

    final repo = ref.read(customersRepositoryProvider);
    if (repo.isConnected) {
      await repo.updateCustomer(customer);
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    state = state.where((c) => c.id != customerId).toList();

    final repo = ref.read(customersRepositoryProvider);
    if (repo.isConnected) {
      await repo.deleteCustomer(customerId);
    }
  }
}
