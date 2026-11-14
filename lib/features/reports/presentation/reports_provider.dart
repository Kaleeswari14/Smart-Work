import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../payments/presentation/payments_provider.dart";
import "../../works/presentation/works_provider.dart";

enum ReportDateFilter {
  all,
  thisMonth,
  thisWeek,
  today,
}

final reportFilterProvider = NotifierProvider<ReportFilterNotifier, ReportDateFilter>(() => ReportFilterNotifier());

class ReportFilterNotifier extends Notifier<ReportDateFilter> {
  @override
  ReportDateFilter build() => ReportDateFilter.all;

  void setFilter(ReportDateFilter filter) {
    state = filter;
  }
}

class BusinessReportData {
  final double totalRevenue;
  final double totalCollected;
  final double outstandingBalance;
  final int completedWorksCount;
  final int activeWorksCount;
  final double savingsCollected;
  final double currentCollected;
  final double cashCollected;
  final ReportDateFilter filter;

  const BusinessReportData({
    required this.totalRevenue,
    required this.totalCollected,
    required this.outstandingBalance,
    required this.completedWorksCount,
    required this.activeWorksCount,
    required this.savingsCollected,
    required this.currentCollected,
    required this.cashCollected,
    required this.filter,
  });

  double get collectionRatePercentage {
    if (totalRevenue <= 0) return 0.0;
    final rate = (totalCollected / totalRevenue) * 100;
    return rate > 100 ? 100.0 : rate;
  }
}

final businessReportProvider = Provider<BusinessReportData>((ref) {
  final works = ref.watch(worksListProvider);
  final payments = ref.watch(paymentsListProvider);
  final filter = ref.watch(reportFilterProvider);

  final now = DateTime.now();

  // Filter works based on selected date filter
  final filteredWorks = works.where((w) {
    if (filter == ReportDateFilter.all) return true;
    final startTime = w.inProgressStartTime ?? now;
    if (filter == ReportDateFilter.today) {
      return startTime.year == now.year &&
          startTime.month == now.month &&
          startTime.day == now.day;
    } else if (filter == ReportDateFilter.thisWeek) {
      final difference = now.difference(startTime).inDays;
      return difference <= 7;
    } else if (filter == ReportDateFilter.thisMonth) {
      return startTime.year == now.year && startTime.month == now.month;
    }
    return true;
  }).toList();

  // Filter payments
  final filteredPayments = payments.where((p) {
    if (filter == ReportDateFilter.all) return true;
    final pDate = p.paymentDate;
    if (filter == ReportDateFilter.today) {
      return pDate.year == now.year &&
          pDate.month == now.month &&
          pDate.day == now.day;
    } else if (filter == ReportDateFilter.thisWeek) {
      final difference = now.difference(pDate).inDays;
      return difference <= 7;
    } else if (filter == ReportDateFilter.thisMonth) {
      return pDate.year == now.year && pDate.month == now.month;
    }
    return true;
  }).toList();

  double totalRevenue = 0.0;
  double totalAdvance = 0.0;
  double totalCollectedPayments = 0.0;
  int completedCount = 0;
  int activeCount = 0;

  for (final w in filteredWorks) {
    final effectiveTotal = w.billedAmount ?? w.totalCost;
    totalRevenue += effectiveTotal;
    totalAdvance += w.advancePaid;

    if (w.status == "completed") {
      completedCount++;
    } else if (w.status == "in_progress" || w.status == "pending") {
      activeCount++;
    }
  }

  double savings = 0.0;
  double current = 0.0;
  double cash = 0.0;

  for (final p in filteredPayments) {
    totalCollectedPayments += p.amount;
    final type = p.paymentType.toLowerCase();
    if (type == "savings") {
      savings += p.amount;
    } else if (type == "current") {
      current += p.amount;
    } else if (type == "cash") {
      cash += p.amount;
    }
  }

  // Also include advance payments in cash/default if not specifically tracked in payments table
  final grandTotalCollected = totalAdvance + totalCollectedPayments;
  final balance = totalRevenue - grandTotalCollected;

  return BusinessReportData(
    totalRevenue: totalRevenue,
    totalCollected: grandTotalCollected,
    outstandingBalance: balance > 0 ? balance : 0.0,
    completedWorksCount: completedCount,
    activeWorksCount: activeCount,
    savingsCollected: savings,
    currentCollected: current,
    cashCollected: cash + totalAdvance, // Advance typically received in cash/direct
    filter: filter,
  );
});

class MonthSummary {
  final String monthKey;
  final String monthLabel;
  final int completedWorksCount;
  final double totalIncome;
  final double totalCollected;
  final double pendingDues;

  const MonthSummary({
    required this.monthKey,
    required this.monthLabel,
    required this.completedWorksCount,
    required this.totalIncome,
    required this.totalCollected,
    required this.pendingDues,
  });
}

final monthlyReportsProvider = Provider<List<MonthSummary>>((ref) {
  final works = ref.watch(worksListProvider);
  final payments = ref.watch(paymentsListProvider);

  final now = DateTime.now();
  final Map<String, List<WorkItem>> worksByMonth = {};
  final Map<String, List<PaymentRecord>> paymentsByMonth = {};

  final monthNames = [
    "",
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December"
  ];

  for (final w in works) {
    final date = w.inProgressStartTime ?? now;
    final key = "${date.year}-${date.month.toString().padLeft(2, '0')}";
    worksByMonth.putIfAbsent(key, () => []).add(w);
  }

  for (final p in payments) {
    final key = "${p.paymentDate.year}-${p.paymentDate.month.toString().padLeft(2, '0')}";
    paymentsByMonth.putIfAbsent(key, () => []).add(p);
  }

  // Ensure current month exists
  final currentKey = "${now.year}-${now.month.toString().padLeft(2, '0')}";
  worksByMonth.putIfAbsent(currentKey, () => []);

  final allKeys = {...worksByMonth.keys, ...paymentsByMonth.keys}.toList()
    ..sort((a, b) => b.compareTo(a));

  final List<MonthSummary> summaries = [];
  for (final key in allKeys) {
    final parts = key.split("-");
    final year = int.tryParse(parts[0]) ?? now.year;
    final month = int.tryParse(parts[1]) ?? now.month;
    final label = "${monthNames[month]} $year";

    final monthWorks = worksByMonth[key] ?? [];
    final monthPayments = paymentsByMonth[key] ?? [];

    final completedCount = monthWorks.where((w) => w.status == "completed").length;

    double income = 0.0;
    double advanceTotal = 0.0;
    for (final w in monthWorks) {
      income += (w.billedAmount ?? w.totalCost);
      advanceTotal += w.advancePaid;
    }

    double collectedFromPayments = 0.0;
    for (final p in monthPayments) {
      collectedFromPayments += p.amount;
    }

    final totalCollected = advanceTotal + collectedFromPayments;
    final pending = (income - totalCollected) > 0 ? (income - totalCollected) : 0.0;

    summaries.add(MonthSummary(
      monthKey: key,
      monthLabel: label,
      completedWorksCount: completedCount,
      totalIncome: income,
      totalCollected: totalCollected,
      pendingDues: pending,
    ));
  }

  return summaries;
});
