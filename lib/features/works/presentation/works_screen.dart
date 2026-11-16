import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../../core/localization/app_localizations.dart";
import "../../../shared/widgets/empty_state_view.dart";
import "../../customers/presentation/customers_provider.dart";
import "../../dashboard/presentation/main_shell_screen.dart";
import "../../payments/data/pdf_invoice_service.dart";
import "works_provider.dart";

class WorksScreen extends ConsumerStatefulWidget {
  const WorksScreen({super.key});

  @override
  ConsumerState<WorksScreen> createState() => _WorksScreenState();
}

class _WorksScreenState extends ConsumerState<WorksScreen> {
  String _selectedStatusFilter = "all";

  void _showWorkDetailsDialog(WorkItem work) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      work.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Customer Info Tag
              Row(
                children: [
                  const Icon(Icons.person_pin, size: 18, color: Color(0xFF1E3A8A)),
                  const SizedBox(width: 6),
                  Text(
                    "${context.tr("customer_label")}: ${work.customerName}",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  _buildStatusBadge(work.status),
                ],
              ),
              const SizedBox(height: 16),

              if (work.description.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr("work_description"),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(work.description, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Financial Details Card
              Card(
                elevation: 0,
                color: Colors.blueGrey.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(context.tr("total_cost"), style: const TextStyle(fontSize: 13)),
                          Text(
                            "₹ ${work.totalCost.toStringAsFixed(2)}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(context.tr("advance_amount"), style: const TextStyle(fontSize: 13)),
                          Text(
                            "₹ ${work.advancePaid.toStringAsFixed(2)}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(context.tr("balance_due"), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          Text(
                            "₹ ${(work.totalCost - work.advancePaid).toStringAsFixed(2)}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Duration spent info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: Color(0xFF0D9488), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "${context.tr("duration_spent")}: ",
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      work.formattedDuration,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showEditWorkDialog(WorkItem work) {
    final titleController = TextEditingController(text: work.title);
    final descController = TextEditingController(text: work.description);
    final costController = TextEditingController(text: work.totalCost.toStringAsFixed(2));
    final advanceController = TextEditingController(text: work.advancePaid.toStringAsFixed(2));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Edit Work Details",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: "Work Title",
                    prefixIcon: Icon(Icons.assignment_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: "Description",
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: costController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Total Cost (₹)",
                    prefixText: "₹ ",
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: advanceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Advance Paid (₹)",
                    prefixText: "₹ ",
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    final cost = double.tryParse(costController.text.trim()) ?? work.totalCost;
                    final adv = double.tryParse(advanceController.text.trim()) ?? work.advancePaid;
                    if (title.isNotEmpty) {
                      ref.read(worksListProvider.notifier).updateWork(
                            workId: work.id,
                            title: title,
                            description: descController.text.trim(),
                            totalCost: cost,
                            advancePaid: adv,
                          );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Work updated successfully!")),
                      );
                    }
                  },
                  child: Text(context.tr("save")),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade300),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(context.tr("delete_work")),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _confirmDeleteWork(work);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteWork(WorkItem work) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text(context.tr("delete_work")),
          ],
        ),
        content: Text(
          "${context.tr("confirm_delete_work")}\n\n'${work.title}' (${work.customerName})",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr("cancel")),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(worksListProvider.notifier).deleteWork(work.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Work '${work.title}' deleted successfully.")),
                );
              }
            },
            child: Text(context.tr("delete")),
          ),
        ],
      ),
    );
  }

  void _showAddWorkModal() {
    final customers = ref.read(customersListProvider);

    if (customers.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            icon: const Icon(Icons.person_add_disabled, color: Colors.amber, size: 40),
            title: Text(context.tr("no_customers_title")),
            content: Text(
              context.tr("no_customers_create_first"),
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(context.tr("close")),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.person_add, size: 16),
                label: Text(context.tr("add_customer")),
                onPressed: () {
                  Navigator.pop(ctx);
                  ref.read(navigationIndexProvider.notifier).setIndex(1);
                },
              ),
            ],
          );
        },
      );
      return;
    }

    String selectedCustomerId = customers.first.id;
    String selectedCustomerName = customers.first.name;
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final costController = TextEditingController();
    final advanceController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr("add_work"),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Customer Selector Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedCustomerId,
                      decoration: InputDecoration(
                        labelText: context.tr("select_customer"),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      items: customers.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text(
                            c.phone.isNotEmpty ? "${c.name} (${c.phone})" : c.name,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedCustomerId = val;
                            selectedCustomerName =
                                customers.firstWhere((c) => c.id == val).name;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: context.tr("work_title"),
                        prefixIcon: const Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: context.tr("work_description"),
                        prefixIcon: const Icon(Icons.description_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: costController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: context.tr("total_cost"),
                              prefixText: "₹ ",
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: advanceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: context.tr("advance_amount"),
                              prefixText: "₹ ",
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        final title = titleController.text.trim();
                        if (title.isNotEmpty) {
                          final cost = double.tryParse(costController.text) ?? 0.0;
                          final advance = double.tryParse(advanceController.text) ?? 0.0;
                          ref.read(worksListProvider.notifier).addWork(
                                customerId: selectedCustomerId,
                                customerName: selectedCustomerName,
                                title: title,
                                description: descController.text.trim(),
                                totalCost: cost,
                                advancePaid: advance,
                              );
                          Navigator.pop(ctx);
                        }
                      },
                      child: Text(context.tr("save")),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  void _showEditTimeDialog(WorkItem work) {
    final currentHours = work.totalSeconds ~/ 3600;
    final currentMinutes = (work.totalSeconds % 3600) ~/ 60;
    final hoursController = TextEditingController(text: currentHours.toString());
    final minutesController = TextEditingController(text: currentMinutes.toString());

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(context.tr("edit_time")),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${work.title} (${work.customerName}) - ${context.tr("duration_spent")}",
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: hoursController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: context.tr("enter_hours"),
                        suffixText: "hrs",
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: minutesController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: context.tr("enter_minutes"),
                        suffixText: "mins",
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.tr("cancel")),
            ),
            ElevatedButton(
              onPressed: () {
                final h = int.tryParse(hoursController.text) ?? 0;
                final m = int.tryParse(minutesController.text) ?? 0;
                final totalSec = (h * 3600) + (m * 60);
                ref.read(worksListProvider.notifier).manualUpdateTime(work.id, totalSec);
                Navigator.pop(ctx);
              },
              child: Text(context.tr("save")),
            ),
          ],
        );
      },
    );
  }

  void _showCompleteWorkActionDialog(WorkItem work) {
    final actionController = TextEditingController(text: work.actionNote);
    final costController = TextEditingController(
      text: work.totalCost > 0 ? work.totalCost.toStringAsFixed(2) : "",
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.blue, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr("confirm_complete"),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${work.customerName} • ${work.title}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E3A8A)),
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr("enter_action_notes"),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: actionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "e.g. Engine overhauled, oil changed, brake pads replaced...",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: costController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: context.tr("total_cost"),
                    prefixText: "₹ ",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.tr("cancel")),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final note = actionController.text.trim();
                final cost = double.tryParse(costController.text);
                ref.read(worksListProvider.notifier).completeWorkWithAction(
                      workId: work.id,
                      actionNote: note.isNotEmpty ? note : "Work completed successfully.",
                      finalCost: cost,
                    );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Work marked Completed! Billing is now ready in Payments Dashboard."),
                  ),
                );
              },
              child: Text(context.tr("confirm_complete")),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final works = ref.watch(worksListProvider);
    final filteredWorks = _selectedStatusFilter == "all"
        ? works
        : works.where((w) => w.status == _selectedStatusFilter).toList();

    return Stack(
      children: [
        Column(
          children: [
            // Status Filter Chips & Add Work Header Button
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 4.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip("all", "All / Ellam"),
                    const SizedBox(width: 8),
                    _buildFilterChip("pending", context.tr("status_pending")),
                    const SizedBox(width: 8),
                    _buildFilterChip("in_progress", context.tr("status_in_progress")),
                    const SizedBox(width: 8),
                    _buildFilterChip("completed", context.tr("status_completed")),
                    const SizedBox(width: 8),
                    _buildFilterChip("cancelled", context.tr("status_cancelled")),
                  ],
                ),
              ),
            ),

            Expanded(
              child: filteredWorks.isEmpty
                  ? EmptyStateView(
                      icon: Icons.assignment_outlined,
                      title: context.tr("no_works_title"),
                      description: context.tr("no_works_desc"),
                      actionLabel: context.tr("add_work"),
                      onAction: _showAddWorkModal,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 80.0),
                      itemCount: filteredWorks.length,
                      itemBuilder: (ctx, index) {
                        final work = filteredWorks[index];
                        return _buildWorkCard(work);
                      },
                    ),
            ),
          ],
        ),

        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            heroTag: "fab_add_work_screen",
            tooltip: context.tr("add_work"),
            onPressed: _showAddWorkModal,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkCard(WorkItem work) {
    final isInProgress = work.status == "in_progress";
    final isCompleted = work.status == "completed";
    final isCancelled = work.status == "cancelled";

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Customer Badge, View Icon, & Status Badge
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person, size: 14, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            work.customerName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. View Icon (Eye)
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF1E3A8A)),
                      tooltip: "View Details",
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      onPressed: () => _showWorkDetailsDialog(work),
                    ),
                    const SizedBox(width: 2),
                    // 2. Edit Work Icon (Pencil)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0D9488)),
                      tooltip: "Edit Work",
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      onPressed: () => _showEditWorkDialog(work),
                    ),
                    const SizedBox(width: 2),
                    // 3. Delete Work Icon (Trash)
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade700),
                      tooltip: context.tr("delete_work"),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      onPressed: () => _confirmDeleteWork(work),
                    ),
                    const SizedBox(width: 4),
                    // 4. Status Icon (Icon-only Dropdown)
                    _buildStatusDropdown(work),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Work Title
            Text(
              work.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (work.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                work.description,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],

            // Action Note Display if Completed
            if (work.actionNote.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.task_alt, size: 14, color: Colors.blue),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Action: ${work.actionNote}",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),

            // Financial Summary
            Row(
              children: [
                Text(
                  "₹ ${work.totalCost.toStringAsFixed(2)}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(width: 8),
                Text(
                  "(Adv: ₹ ${work.advancePaid.toStringAsFixed(2)})",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),

            const Divider(height: 20),

            // Middle Row: Auto Time & Duration + Manual Edit Button
            Row(
              children: [
                Icon(
                  Icons.timer,
                  size: 18,
                  color: isInProgress ? const Color(0xFF0D9488) : Colors.grey.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  "${context.tr("duration_spent")}: ",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Text(
                  work.formattedDuration,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isInProgress ? const Color(0xFF0D9488) : Colors.black87,
                  ),
                ),
                if (isInProgress) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      "LIVE",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D9488),
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.timer_outlined, size: 18, color: Colors.blueGrey),
                  tooltip: context.tr("edit_time"),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  onPressed: () => _showEditTimeDialog(work),
                ),
              ],
            ),

            if (isCompleted) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            work.billingStatus == "billed"
                                ? (work.balanceDue > 0 ? Icons.pending_actions : Icons.check_circle)
                                : Icons.receipt_long,
                            size: 16,
                            color: work.billingStatus == "billed"
                                ? (work.balanceDue > 0 ? Colors.red.shade700 : const Color(0xFF0D9488))
                                : Colors.amber.shade900,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              work.billingStatus == "billed"
                                  ? (work.balanceDue > 0
                                      ? "Bill: ${work.billNumber} • Due: ₹ ${work.balanceDue.toStringAsFixed(2)}"
                                      : "Payment Collected")
                                  : "Billing Ready (Bill Podanum)",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: work.billingStatus == "billed"
                                    ? (work.balanceDue > 0 ? Colors.red.shade700 : const Color(0xFF0D9488))
                                    : Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      icon: const Icon(Icons.arrow_forward, size: 14),
                      label: Text(
                        context.tr("nav_payments"),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        // Payments Tab is index 3 in MainShellScreen!
                        ref.read(navigationIndexProvider.notifier).setIndex(3);
                      },
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      style: IconButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                      ),
                      icon: const Icon(Icons.picture_as_pdf, size: 16, color: Color(0xFF1E3A8A)),
                      tooltip: "Download / Print Invoice",
                      onPressed: () {
                        PdfInvoiceService.printOrShareInvoice(work: work);
                      },
                    ),
                  ],
                ),
              ),
            ] else if (isCancelled) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    context.tr("status_cancelled"),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown(WorkItem work) {
    Color bg;
    Color fg;
    IconData icon;
    String label;
    switch (work.status) {
      case "in_progress":
        bg = const Color(0xFF0D9488).withValues(alpha: 0.15);
        fg = const Color(0xFF0D9488);
        icon = Icons.play_circle_filled;
        label = context.tr("status_in_progress");
        break;
      case "completed":
        bg = Colors.blue.withValues(alpha: 0.15);
        fg = Colors.blue.shade800;
        icon = Icons.check_circle;
        label = context.tr("status_completed");
        break;
      case "cancelled":
        bg = Colors.red.withValues(alpha: 0.15);
        fg = Colors.red.shade700;
        icon = Icons.cancel;
        label = context.tr("status_cancelled");
        break;
      default:
        bg = Colors.amber.withValues(alpha: 0.15);
        fg = Colors.amber.shade900;
        icon = Icons.hourglass_empty;
        label = context.tr("status_pending");
    }

    return PopupMenuButton<String>(
      tooltip: context.tr("change_status"),
      initialValue: work.status,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (newStatus) {
        if (newStatus == "completed") {
          _showCompleteWorkActionDialog(work);
        } else if (newStatus != work.status) {
          ref.read(worksListProvider.notifier).updateStatus(work.id, newStatus);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: "pending",
          child: Row(
            children: [
              const Icon(Icons.hourglass_empty, size: 16, color: Colors.amber),
              const SizedBox(width: 8),
              Text(context.tr("status_pending")),
            ],
          ),
        ),
        PopupMenuItem(
          value: "in_progress",
          child: Row(
            children: [
              const Icon(Icons.play_circle_filled, size: 16, color: Color(0xFF0D9488)),
              const SizedBox(width: 8),
              Text(context.tr("status_in_progress")),
            ],
          ),
        ),
        PopupMenuItem(
          value: "completed",
          child: Row(
            children: [
              const Icon(Icons.check_circle, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Text(context.tr("status_completed")),
            ],
          ),
        ),
        PopupMenuItem(
          value: "cancelled",
          child: Row(
            children: [
              const Icon(Icons.cancel, size: 16, color: Colors.red),
              const SizedBox(width: 8),
              Text(context.tr("status_cancelled")),
            ],
          ),
        ),
      ],
      child: Tooltip(
        message: label,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: fg.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 2),
              Icon(Icons.arrow_drop_down, size: 14, color: fg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    IconData icon;
    String label;
    switch (status) {
      case "in_progress":
        bg = const Color(0xFF0D9488).withValues(alpha: 0.15);
        fg = const Color(0xFF0D9488);
        icon = Icons.play_circle_filled;
        label = context.tr("status_in_progress");
        break;
      case "completed":
        bg = Colors.blue.withValues(alpha: 0.15);
        fg = Colors.blue.shade800;
        icon = Icons.check_circle;
        label = context.tr("status_completed");
        break;
      case "cancelled":
        bg = Colors.red.withValues(alpha: 0.15);
        fg = Colors.red.shade700;
        icon = Icons.cancel;
        label = context.tr("status_cancelled");
        break;
      default:
        bg = Colors.amber.withValues(alpha: 0.15);
        fg = Colors.amber.shade900;
        icon = Icons.hourglass_empty;
        label = context.tr("status_pending");
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedStatusFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedStatusFilter = key;
          });
        }
      },
    );
  }
}
