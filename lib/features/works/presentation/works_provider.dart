import "dart:async";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "../data/works_repository.dart";

class WorkItem {
  final String id;
  final String customerId;
  final String customerName;
  final String title;
  final String description;
  final String actionNote;
  final double totalCost;
  final double advancePaid;
  final double collectedPayment;
  final String status; // pending, in_progress, completed, cancelled
  final String billingStatus; // unbilled, billed
  final String? billNumber;
  final double? billedAmount;
  final String paymentStatus; // pending, collected
  final String? paymentAccount; // savings, current, cash
  final int totalSeconds;
  final DateTime? inProgressStartTime;

  const WorkItem({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.title,
    this.description = "",
    this.actionNote = "",
    this.totalCost = 0.0,
    this.advancePaid = 0.0,
    this.collectedPayment = 0.0,
    this.status = "pending",
    this.billingStatus = "unbilled",
    this.billNumber,
    this.billedAmount,
    this.paymentStatus = "pending",
    this.paymentAccount,
    this.totalSeconds = 0,
    this.inProgressStartTime,
  });

  double get balanceDue {
    final effectiveTotal = billedAmount ?? totalCost;
    final balance = effectiveTotal - (advancePaid + collectedPayment);
    return balance > 0 ? balance : 0.0;
  }

  WorkItem copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? title,
    String? description,
    String? actionNote,
    double? totalCost,
    double? advancePaid,
    double? collectedPayment,
    String? status,
    String? billingStatus,
    String? billNumber,
    double? billedAmount,
    String? paymentStatus,
    String? paymentAccount,
    int? totalSeconds,
    DateTime? inProgressStartTime,
    bool clearStartTime = false,
  }) {
    return WorkItem(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      title: title ?? this.title,
      description: description ?? this.description,
      actionNote: actionNote ?? this.actionNote,
      totalCost: totalCost ?? this.totalCost,
      advancePaid: advancePaid ?? this.advancePaid,
      collectedPayment: collectedPayment ?? this.collectedPayment,
      status: status ?? this.status,
      billingStatus: billingStatus ?? this.billingStatus,
      billNumber: billNumber ?? this.billNumber,
      billedAmount: billedAmount ?? this.billedAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentAccount: paymentAccount ?? this.paymentAccount,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      inProgressStartTime: clearStartTime ? null : (inProgressStartTime ?? this.inProgressStartTime),
    );
  }

  String get formattedDuration {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return "${hours}h ${minutes}m ${seconds}s";
    } else if (minutes > 0) {
      return "${minutes}m ${seconds}s";
    } else {
      return "${seconds}s";
    }
  }
}

final worksRepositoryProvider = Provider<WorksRepository>((ref) => WorksRepository());

final worksListProvider = NotifierProvider<WorksListNotifier, List<WorkItem>>(() => WorksListNotifier());

class WorksListNotifier extends Notifier<List<WorkItem>> {
  Timer? _syncTimer;
  RealtimeChannel? _realtimeChannel;

  @override
  List<WorkItem> build() {
    _loadInitialWorks();
    _setupAutoSyncAndRealtime();
    ref.onDispose(() {
      _syncTimer?.cancel();
      _realtimeChannel?.unsubscribe();
    });
    return [];
  }

  void _setupAutoSyncAndRealtime() {
    final repo = ref.read(worksRepositoryProvider);
    if (!repo.isConnected) return;

    try {
      final client = Supabase.instance.client;
      _realtimeChannel = client.channel("public:works_changes").onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: "public",
        table: "works",
        callback: (_) {
          refresh();
        },
      )..subscribe();
    } catch (_) {}

    _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final currentRepo = ref.read(worksRepositoryProvider);
      if (currentRepo.isConnected) {
        refresh();
      }
    });
  }

  Future<void> _loadInitialWorks() async {
    final repo = ref.read(worksRepositoryProvider);
    final remote = await repo.fetchWorks();
    if (remote.isNotEmpty) {
      state = remote;
    }
  }

  Future<void> refresh() async {
    final repo = ref.read(worksRepositoryProvider);
    final remote = await repo.fetchWorks();
    state = remote;
  }

  Future<WorkItem> addWork({
    required String customerId,
    required String customerName,
    required String title,
    required String description,
    required double totalCost,
    required double advancePaid,
  }) async {
    final localWork = WorkItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
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

    // Optimistic local state update
    state = [localWork, ...state];

    final repo = ref.read(worksRepositoryProvider);
    if (repo.isConnected) {
      final remoteWork = await repo.createWork(
        customerId: customerId,
        customerName: customerName,
        title: title,
        description: description,
        totalCost: totalCost,
        advancePaid: advancePaid,
      );

      if (remoteWork != null) {
        state = [
          for (final w in state)
            if (w.id == localWork.id) remoteWork else w,
        ];
        return remoteWork;
      }
    }
    return localWork;
  }

  Future<void> updateStatus(String workId, String newStatus) async {
    final currentWork = state.firstWhere(
      (w) => w.id == workId,
      orElse: () => state.first,
    );
    final updatedWork = _processStatusChange(currentWork, newStatus);
    state = [
      for (final work in state)
        if (work.id == workId) updatedWork else work,
    ];

    final repo = ref.read(worksRepositoryProvider);
    if (repo.isConnected) {
      await repo.updateStatus(
        workId: workId,
        status: updatedWork.status,
        totalSeconds: updatedWork.totalSeconds,
        inProgressStartTime: updatedWork.inProgressStartTime,
      );
    }
  }

  WorkItem _processStatusChange(WorkItem work, String newStatus) {
    if (newStatus == "in_progress") {
      return work.copyWith(
        status: newStatus,
        inProgressStartTime: DateTime.now(),
      );
    } else if (work.status == "in_progress" &&
        (newStatus == "completed" || newStatus == "cancelled" || newStatus == "pending")) {
      int additionalSeconds = 0;
      if (work.inProgressStartTime != null) {
        additionalSeconds = DateTime.now().difference(work.inProgressStartTime!).inSeconds;
      }
      return work.copyWith(
        status: newStatus,
        totalSeconds: work.totalSeconds + additionalSeconds,
        clearStartTime: true,
      );
    } else {
      return work.copyWith(status: newStatus);
    }
  }

  Future<void> completeWorkWithAction({
    required String workId,
    required String actionNote,
    double? finalCost,
  }) async {
    final currentWork = state.firstWhere(
      (w) => w.id == workId,
      orElse: () => state.first,
    );
    final updatedWork = _finalizeCompletion(currentWork, actionNote, finalCost);
    state = [
      for (final work in state)
        if (work.id == workId) updatedWork else work,
    ];

    final repo = ref.read(worksRepositoryProvider);
    if (repo.isConnected) {
      await repo.completeWorkWithAction(
        workId: workId,
        actionNote: actionNote,
        totalCost: updatedWork.totalCost,
        totalSeconds: updatedWork.totalSeconds,
      );
    }
  }

  WorkItem _finalizeCompletion(WorkItem work, String actionNote, double? finalCost) {
    int additionalSeconds = 0;
    if (work.status == "in_progress" && work.inProgressStartTime != null) {
      additionalSeconds = DateTime.now().difference(work.inProgressStartTime!).inSeconds;
    }
    final effectiveCost = (finalCost != null && finalCost > 0) ? finalCost : work.totalCost;
    return work.copyWith(
      status: "completed",
      actionNote: actionNote,
      totalCost: effectiveCost,
      totalSeconds: work.totalSeconds + additionalSeconds,
      clearStartTime: true,
      billingStatus: "unbilled",
      paymentStatus: "pending",
    );
  }

  Future<void> createBill({
    required String workId,
    required String billNumber,
    required double billedAmount,
  }) async {
    state = [
      for (final work in state)
        if (work.id == workId)
          work.copyWith(
            billNumber: billNumber,
            billedAmount: billedAmount,
            billingStatus: "billed",
            paymentStatus: "pending",
          )
        else
          work,
    ];

    final repo = ref.read(worksRepositoryProvider);
    if (repo.isConnected) {
      await repo.createBill(
        workId: workId,
        billNumber: billNumber,
        billedAmount: billedAmount,
      );
    }
  }

  Future<void> markPaymentCollected({
    required String workId,
    required double amount,
    required String accountType,
  }) async {
    final currentWork = state.firstWhere(
      (w) => w.id == workId,
      orElse: () => state.first,
    );
    final newCollected = currentWork.collectedPayment + amount;

    state = [
      for (final work in state)
        if (work.id == workId)
          work.copyWith(
            collectedPayment: newCollected,
            paymentStatus: "collected",
            paymentAccount: accountType,
          )
        else
          work,
    ];

    final repo = ref.read(worksRepositoryProvider);
    if (repo.isConnected) {
      await repo.markPaymentCollected(
        workId: workId,
        newTotalCollected: newCollected,
        accountType: accountType,
      );
    }
  }

  void addCollectedPayment(String workId, double amount) {
    state = [
      for (final work in state)
        if (work.id == workId)
          work.copyWith(collectedPayment: work.collectedPayment + amount)
        else
          work,
    ];
  }

  Future<void> manualUpdateTime(String workId, int newTotalSeconds) async {
    state = [
      for (final work in state)
        if (work.id == workId) work.copyWith(totalSeconds: newTotalSeconds) else work,
    ];

    final repo = ref.read(worksRepositoryProvider);
    if (repo.isConnected) {
      await repo.updateTime(workId: workId, totalSeconds: newTotalSeconds);
    }
  }

  Future<void> updateWork({
    required String workId,
    required String title,
    required String description,
    required double totalCost,
    required double advancePaid,
  }) async {
    state = [
      for (final work in state)
        if (work.id == workId)
          work.copyWith(
            title: title,
            description: description,
            totalCost: totalCost,
            advancePaid: advancePaid,
          )
        else
          work,
    ];

    final repo = ref.read(worksRepositoryProvider);
    if (repo.isConnected) {
      await repo.updateWorkDetails(
        workId: workId,
        title: title,
        description: description,
        totalCost: totalCost,
        advancePaid: advancePaid,
      );
    }
  }

  Future<void> deleteWork(String workId) async {
    state = state.where((w) => w.id != workId).toList();
    final repo = ref.read(worksRepositoryProvider);
    if (repo.isConnected) {
      await repo.deleteWork(workId);
    }
  }
}
