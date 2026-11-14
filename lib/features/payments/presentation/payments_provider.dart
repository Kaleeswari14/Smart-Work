import "dart:async";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "../data/payments_repository.dart";

class PaymentRecord {
  final String id;
  final String workId;
  final String workTitle;
  final String customerId;
  final String customerName;
  final String billNumber;
  final double amount;
  final String paymentType; // "savings", "current", "cash"
  final DateTime paymentDate;

  const PaymentRecord({
    required this.id,
    required this.workId,
    required this.workTitle,
    required this.customerId,
    required this.customerName,
    required this.billNumber,
    required this.amount,
    required this.paymentType,
    required this.paymentDate,
  });
}

final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) => PaymentsRepository());

final paymentsListProvider =
    NotifierProvider<PaymentsListNotifier, List<PaymentRecord>>(() => PaymentsListNotifier());

class PaymentsListNotifier extends Notifier<List<PaymentRecord>> {
  Timer? _syncTimer;
  RealtimeChannel? _realtimeChannel;

  @override
  List<PaymentRecord> build() {
    _loadInitialPayments();
    _setupAutoSyncAndRealtime();
    ref.onDispose(() {
      _syncTimer?.cancel();
      _realtimeChannel?.unsubscribe();
    });
    return [];
  }

  void _setupAutoSyncAndRealtime() {
    final repo = ref.read(paymentsRepositoryProvider);
    if (!repo.isConnected) return;

    try {
      final client = Supabase.instance.client;
      _realtimeChannel = client.channel("public:payments_changes").onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: "public",
        table: "payments",
        callback: (_) {
          refresh();
        },
      )..subscribe();
    } catch (_) {}

    _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final currentRepo = ref.read(paymentsRepositoryProvider);
      if (currentRepo.isConnected) {
        refresh();
      }
    });
  }

  Future<void> _loadInitialPayments() async {
    final repo = ref.read(paymentsRepositoryProvider);
    final remote = await repo.fetchPayments();
    if (remote.isNotEmpty) {
      state = remote;
    }
  }

  Future<void> refresh() async {
    final repo = ref.read(paymentsRepositoryProvider);
    final remote = await repo.fetchPayments();
    state = remote;
  }

  Future<PaymentRecord> recordPayment({
    required String workId,
    required String workTitle,
    required String customerId,
    required String customerName,
    required String billNumber,
    required double amount,
    required String paymentType, // savings, current, cash
  }) async {
    final localRecord = PaymentRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      workId: workId,
      workTitle: workTitle,
      customerId: customerId,
      customerName: customerName,
      billNumber: billNumber,
      amount: amount,
      paymentType: paymentType,
      paymentDate: DateTime.now(),
    );

    // Optimistic local state update
    state = [localRecord, ...state];

    final repo = ref.read(paymentsRepositoryProvider);
    if (repo.isConnected) {
      final remoteRecord = await repo.recordPayment(
        workId: workId,
        workTitle: workTitle,
        customerId: customerId,
        customerName: customerName,
        billNumber: billNumber,
        amount: amount,
        paymentType: paymentType,
      );

      if (remoteRecord != null) {
        state = [
          for (final r in state)
            if (r.id == localRecord.id) remoteRecord else r,
        ];
        return remoteRecord;
      }
    }
    return localRecord;
  }
}
