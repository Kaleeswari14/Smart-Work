import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../../core/localization/app_localizations.dart";
import "../../../core/localization/language_provider.dart";
import "reports_provider.dart";

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(businessReportProvider);
    final activeFilter = ref.watch(reportFilterProvider);
    final monthlySummaries = ref.watch(monthlyReportsProvider);
    final isTanglish = ref.watch(languageProvider).languageCode == "ta";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row with Date Filters
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr("business_reports"),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              PopupMenuButton<ReportDateFilter>(
                initialValue: activeFilter,
                onSelected: (filter) {
                  ref.read(reportFilterProvider.notifier).setFilter(filter);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.filter_list, size: 16, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        _getFilterLabel(activeFilter, isTanglish),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: ReportDateFilter.all,
                    child: Text(isTanglish ? "Muzhumaiyaga (All Time)" : "All Time"),
                  ),
                  PopupMenuItem(
                    value: ReportDateFilter.thisMonth,
                    child: Text(isTanglish ? "Indha Maadham (This Month)" : "This Month"),
                  ),
                  PopupMenuItem(
                    value: ReportDateFilter.thisWeek,
                    child: Text(isTanglish ? "Indha Vaaram (This Week)" : "This Week"),
                  ),
                  PopupMenuItem(
                    value: ReportDateFilter.today,
                    child: Text(isTanglish ? "Indru (Today)" : "Today"),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Collection Rate Progress Bar Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isTanglish ? "Collection Sathavitham (Rate)" : "Collection Realization Rate",
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "${report.collectionRatePercentage.toStringAsFixed(1)}%",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: report.collectionRatePercentage >= 80
                              ? const Color(0xFF0D9488)
                              : (report.collectionRatePercentage >= 50
                                  ? Colors.orange.shade800
                                  : Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: report.collectionRatePercentage / 100,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        report.collectionRatePercentage >= 80
                            ? const Color(0xFF0D9488)
                            : (report.collectionRatePercentage >= 50
                                ? Colors.orange.shade800
                                : Colors.red.shade700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isTanglish
                        ? "₹ ${report.totalCollected.toStringAsFixed(2)} / ₹ ${report.totalRevenue.toStringAsFixed(2)} vasool aagiyulladhu."
                        : "₹ ${report.totalCollected.toStringAsFixed(2)} collected of total ₹ ${report.totalRevenue.toStringAsFixed(2)}.",
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 4 Core Financial Summary Cards
          _buildReportCard(
            title: context.tr("total_earnings"),
            amount: "₹ ${report.totalRevenue.toStringAsFixed(2)}",
            icon: Icons.payments_outlined,
            color: const Color(0xFF1E3A8A),
          ),
          const SizedBox(height: 8),
          _buildReportCard(
            title: context.tr("total_collected"),
            amount: "₹ ${report.totalCollected.toStringAsFixed(2)}",
            icon: Icons.check_circle_outline,
            color: const Color(0xFF0D9488),
          ),
          const SizedBox(height: 8),
          _buildReportCard(
            title: context.tr("outstanding_balance"),
            amount: "₹ ${report.outstandingBalance.toStringAsFixed(2)}",
            icon: Icons.hourglass_top_outlined,
            color: Colors.red.shade700,
          ),
          const SizedBox(height: 8),
          _buildReportCard(
            title: context.tr("completed_works_stat"),
            amount: "${report.completedWorksCount} Works",
            icon: Icons.task_alt,
            color: Colors.deepPurple,
          ),

          const SizedBox(height: 24),

          // Monthly Performance & Income Report Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isTanglish ? "Maadha Varumaanam & Mudindha Velaigal" : "Monthly Performance & Income",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${monthlySummaries.length} Months",
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (monthlySummaries.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    isTanglish
                        ? "Maadha arikkaikku innum data illai."
                        : "No monthly performance data recorded yet.",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ),
              ),
            )
          else
            ...monthlySummaries.map((summary) {
              final isCurrentMonth = summary == monthlySummaries.first;
              return _buildMonthlyReportCard(summary, isTanglish, isCurrentMonth);
            }),

          const SizedBox(height: 24),

          // 3-Account Bank Split Section
          Text(
            isTanglish ? "Account Varisaiyil Collection (3 Accounts)" : "Collection Breakdown by Account",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildAccountCard(
                  title: isTanglish ? "Savings A/C" : "Savings Bank",
                  amount: report.savingsCollected,
                  color: const Color(0xFF2563EB),
                  icon: Icons.account_balance,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAccountCard(
                  title: isTanglish ? "Current A/C" : "Current Bank",
                  amount: report.currentCollected,
                  color: const Color(0xFF0D9488),
                  icon: Icons.business,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAccountCard(
                  title: isTanglish ? "Cash (Kaiyil)" : "Cash in Hand",
                  amount: report.cashCollected,
                  color: const Color(0xFFD97706),
                  icon: Icons.money,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Overview Tip Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_outlined, color: Color(0xFF0D9488), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTanglish ? "Cloud Realtime Sync Active" : "Cloud Realtime Accounting",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isTanglish
                            ? "Works & Payments data live-aa calculate aagi Supabase cloud-il record aagukirathu."
                            : "Financial analytics are dynamically computed from live cloud orders and payments.",
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getFilterLabel(ReportDateFilter filter, bool isTanglish) {
    switch (filter) {
      case ReportDateFilter.today:
        return isTanglish ? "Indru" : "Today";
      case ReportDateFilter.thisWeek:
        return isTanglish ? "Indha Vaaram" : "This Week";
      case ReportDateFilter.thisMonth:
        return isTanglish ? "Indha Maadham" : "This Month";
      case ReportDateFilter.all:
        return isTanglish ? "Muzhumaiyaga" : "All Time";
    }
  }

  Widget _buildAccountCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "₹ ${amount.toStringAsFixed(0)}",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyReportCard(MonthSummary summary, bool isTanglish, bool isCurrentMonth) {
    return Card(
      elevation: isCurrentMonth ? 1.5 : 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isCurrentMonth
              ? const Color(0xFF1E3A8A).withValues(alpha: 0.35)
              : Colors.grey.withValues(alpha: 0.2),
          width: isCurrentMonth ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.calendar_month, size: 20, color: Color(0xFF1E3A8A)),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.monthLabel,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        if (isCurrentMonth)
                          Text(
                            isTanglish ? "Indha Maadham (Current Month)" : "Active Current Month",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.task_alt, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        "${summary.completedWorksCount} Completed",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMiniStat(
                    title: isTanglish ? "Moththa Varumaanam" : "Total Income",
                    value: "₹ ${summary.totalIncome.toStringAsFixed(0)}",
                    color: const Color(0xFF1E3A8A),
                    icon: Icons.payments_outlined,
                  ),
                ),
                Expanded(
                  child: _buildMiniStat(
                    title: isTanglish ? "Vandha Panam" : "Collected",
                    value: "₹ ${summary.totalCollected.toStringAsFixed(0)}",
                    color: const Color(0xFF0D9488),
                    icon: Icons.check_circle_outline,
                  ),
                ),
                Expanded(
                  child: _buildMiniStat(
                    title: isTanglish ? "Meedhi Vara Vendiyadhu" : "Pending Due",
                    value: "₹ ${summary.pendingDues.toStringAsFixed(0)}",
                    color: summary.pendingDues > 0 ? Colors.red.shade700 : Colors.grey.shade600,
                    icon: Icons.hourglass_top_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
