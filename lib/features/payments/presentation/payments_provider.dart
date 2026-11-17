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
  final String customerPhone;
  final String billNumber;
  final double amount;
  final String paymentType; // "savings", "current", "cash"
  final DateTime paymentDate;
  final String notes;
  final String paymentCategory; // "Advance Payment", "Bill Collection", "Full Settlement"

  const PaymentRecord({
    required this.id,
    required this.workId,
    required this.workTitle,
    required this.customerId,
    required this.customerName,
    this.customerPhone = "",
    required this.billNumber,
    required this.amount,
    required this.paymentType,
    required this.paymentDate,
    this.notes = "",
    this.paymentCategory = "Bill Collection",
  });

  PaymentRecord copyWith({
    String? id,
    String? workId,
    String? workTitle,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? billNumber,
    double? amount,
    String? paymentType,
    DateTime? paymentDate,
    String? notes,
    String? paymentCategory,
  }) {
    return PaymentRecord(
      id: id ?? this.id,
      workId: workId ?? this.workId,
      workTitle: workTitle ?? this.workTitle,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      billNumber: billNumber ?? this.billNumber,
      amount: amount ?? this.amount,
      paymentType: paymentType ?? this.paymentType,
      paymentDate: paymentDate ?? this.paymentDate,
      notes: notes ?? this.notes,
      paymentCategory: paymentCategory ?? this.paymentCategory,
    );
  }
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
    String customerPhone = "",
    required String billNumber,
    required double amount,
    required String paymentType, // savings, current, cash
    String notes = "",
    String paymentCategory = "Bill Collection",
  }) async {
    final localRecord = PaymentRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      workId: workId,
      workTitle: workTitle,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      billNumber: billNumber,
      amount: amount,
      paymentType: paymentType,
      paymentDate: DateTime.now(),
      notes: notes,
      paymentCategory: paymentCategory,
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
        customerPhone: customerPhone,
        billNumber: billNumber,
        amount: amount,
        paymentType: paymentType,
        notes: notes,
        paymentCategory: paymentCategory,
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

  Future<void> updatePaymentNotes(String paymentId, String notes) async {
    state = [
      for (final r in state)
        if (r.id == paymentId) r.copyWith(notes: notes) else r,
    ];

    final repo = ref.read(paymentsRepositoryProvider);
    if (repo.isConnected) {
      await repo.updatePaymentNotes(paymentId: paymentId, notes: notes);
    }
  }
}
