import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../../core/localization/app_localizations.dart";
import "../../../shared/widgets/empty_state_view.dart";
import "../../customers/presentation/customers_provider.dart";
import "../../payments/presentation/payments_provider.dart";
import "../../reports/presentation/reports_provider.dart";
import "../../works/presentation/works_provider.dart";
import "main_shell_screen.dart";

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(customersListProvider);
    final works = ref.watch(worksListProvider);
    final report = ref.watch(businessReportProvider);

    // Live Metrics Calculations
    final activeWorksCount =
        works.where((w) => w.status == "in_progress" || w.status == "pending").length;
    final totalCustomersCount = customers.length;
    final completedWorks = works.where((w) => w.status == "completed").toList();
    final completedWorksCount = completedWorks.length;
    final pendingDues = report.outstandingBalance;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref.read(customersListProvider.notifier).refresh(),
          ref.read(worksListProvider.notifier).refresh(),
          ref.read(paymentsListProvider.notifier).refresh(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr("overview"),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: "Refresh Data",
                  onPressed: () {
                    ref.read(customersListProvider.notifier).refresh();
                    ref.read(worksListProvider.notifier).refresh();
                    ref.read(paymentsListProvider.notifier).refresh();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // KPI Metric Cards (Live Real-Time Data)
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context: context,
                    title: context.tr("active_works_count"),
                    value: activeWorksCount.toString(),
                    icon: Icons.assignment_outlined,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    context: context,
                    title: context.tr("total_customers_count"),
                    value: totalCustomersCount.toString(),
                    icon: Icons.people_outline,
                    color: Colors.teal.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context: context,
                    title: context.tr("today_completed"),
                    value: "$completedWorksCount Works",
                    icon: Icons.task_alt,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    context: context,
                    title: context.tr("pending_dues"),
                    value: "₹ ${pendingDues.toStringAsFixed(2)}",
                    icon: Icons.account_balance_wallet_outlined,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Quick Actions
            Text(
              context.tr("quick_actions"),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    context: context,
                    icon: Icons.person_add_outlined,
                    label: context.tr("new_customer"),
                    onTap: () => ref.read(navigationIndexProvider.notifier).setIndex(1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickActionButton(
                    context: context,
                    icon: Icons.add_task,
                    label: context.tr("new_work"),
                    onTap: () => ref.read(navigationIndexProvider.notifier).setIndex(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickActionButton(
                    context: context,
                    icon: Icons.payment,
                    label: context.tr("record_payment"),
                    onTap: () => ref.read(navigationIndexProvider.notifier).setIndex(3),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Recent Activities Section (Live Data)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr("recent_activities"),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (works.isNotEmpty)
                  TextButton(
                    onPressed: () => ref.read(navigationIndexProvider.notifier).setIndex(2),
                    child: const Text("View All"),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (works.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
                  child: EmptyStateView(
                    icon: Icons.history,
                    title: context.tr("no_data"),
                    description: context.tr("no_recent_activities"),
                  ),
                ),
              )
            else
              ...works.take(4).map((work) {
                final isCompleted = work.status == "completed";
                final isInProgress = work.status == "in_progress";
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onTap: () => ref.read(navigationIndexProvider.notifier).setIndex(2),
                    leading: CircleAvatar(
                      backgroundColor: isCompleted
                          ? Colors.blue.withValues(alpha: 0.12)
                          : (isInProgress
                              ? const Color(0xFF0D9488).withValues(alpha: 0.12)
                              : Colors.amber.withValues(alpha: 0.12)),
                      child: Icon(
                        isCompleted
                            ? Icons.check_circle_outline
                            : (isInProgress ? Icons.play_arrow : Icons.hourglass_top),
                        color: isCompleted
                            ? Colors.blue.shade700
                            : (isInProgress ? const Color(0xFF0D9488) : Colors.amber.shade900),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      work.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Text(
                      "${work.customerName} • ${work.formattedDuration}",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "₹ ${work.totalCost.toStringAsFixed(0)}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          work.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isCompleted
                                ? Colors.blue.shade700
                                : (isInProgress ? const Color(0xFF0D9488) : Colors.amber.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
