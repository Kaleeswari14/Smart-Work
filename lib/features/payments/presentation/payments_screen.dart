import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../../core/localization/app_localizations.dart";
import "../../../shared/widgets/empty_state_view.dart";
import "../../works/presentation/works_provider.dart";
import "../data/pdf_invoice_service.dart";
import "payments_provider.dart";

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  int _selectedTabIndex = 0; // 0 = Pending Collection, 1 = Collected History

  void _showGenerateBillDialog(WorkItem work) {
    final billNoController = TextEditingController(
      text: "BILL-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}",
    );
    final defaultAmt = work.balanceDue > 0 ? work.balanceDue : work.totalCost;
    final amountController = TextEditingController(
      text: defaultAmt > 0 ? defaultAmt.toStringAsFixed(2) : "",
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.receipt_long, color: Color(0xFF1E3A8A)),
              const SizedBox(width: 8),
              Text(context.tr("generate_bill")),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${work.customerName} • ${work.title}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                if (work.actionNote.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    "Action: ${work.actionNote}",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                  ),
                ],
                const Divider(height: 20),
                TextField(
                  controller: billNoController,
                  decoration: InputDecoration(
                    labelText: context.tr("bill_number"),
                    prefixIcon: const Icon(Icons.receipt),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Billed Amount (₹)",
                    prefixText: "₹ ",
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
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final billNo = billNoController.text.trim();
                final amt = double.tryParse(amountController.text) ?? defaultAmt;
                if (billNo.isNotEmpty && amt > 0) {
                  ref.read(worksListProvider.notifier).createBill(
                        workId: work.id,
                        billNumber: billNo,
                        billedAmount: amt,
                      );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Bill $billNo created for ₹ $amt! You can now collect payment."),
                    ),
                  );
                }
              },
              child: Text(context.tr("save")),
            ),
          ],
        );
      },
    );
  }

  void _showCollectPaymentDialog(WorkItem work) {
    final billNo = work.billNumber ?? "BILL-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";
    final amountController = TextEditingController(
      text: work.balanceDue > 0 ? work.balanceDue.toStringAsFixed(2) : (work.billedAmount?.toStringAsFixed(2) ?? work.totalCost.toStringAsFixed(2)),
    );
    String selectedAccount = "savings"; // savings, current, cash

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.payments_outlined, color: Color(0xFF0D9488)),
                  const SizedBox(width: 8),
                  Text(context.tr("collect_payment"), style: const TextStyle(fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${work.customerName} - ${work.title}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Bill No: $billNo",
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A)),
                    ),
                    Text(
                      "Balance Due: ₹ ${work.balanceDue.toStringAsFixed(2)}",
                      style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const Divider(height: 20),

                    // Amount to Collect
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: context.tr("amount_to_collect"),
                        prefixText: "₹ ",
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 3 Payment Types: Savings, Current, Cash
                    DropdownButtonFormField<String>(
                      value: selectedAccount,
                      decoration: InputDecoration(
                        labelText: context.tr("payment_account"),
                        prefixIcon: const Icon(Icons.account_balance),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: "savings",
                          child: Text(context.tr("type_savings")),
                        ),
                        DropdownMenuItem(
                          value: "current",
                          child: Text(context.tr("type_current")),
                        ),
                        DropdownMenuItem(
                          value: "cash",
                          child: Text(context.tr("type_cash")),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedAccount = val);
                        }
                      },
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
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final amt = double.tryParse(amountController.text) ?? work.balanceDue;
                    if (amt > 0) {
                      // 1. Record in Payments History
                      ref.read(paymentsListProvider.notifier).recordPayment(
                            workId: work.id,
                            workTitle: work.title,
                            customerId: work.customerId,
                            customerName: work.customerName,
                            billNumber: billNo,
                            amount: amt,
                            paymentType: selectedAccount,
                          );

                      // 2. Mark collected in Works
                      ref.read(worksListProvider.notifier).markPaymentCollected(
                            workId: work.id,
                            amount: amt,
                            accountType: selectedAccount,
                          );

                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Payment of ₹ $amt recorded to $selectedAccount!"),
                        ),
                      );
                    }
                  },
                  child: Text(context.tr("save")),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final works = ref.watch(worksListProvider);
    final paymentHistory = ref.watch(paymentsListProvider);

    // Calculations
    final totalCollectedFromHistory = paymentHistory.fold(0.0, (sum, p) => sum + p.amount);
    final totalAdvances = works.fold(0.0, (sum, w) => sum + w.advancePaid);
    final totalCollected = totalCollectedFromHistory + totalAdvances;
    final totalOutstanding = works.fold(0.0, (sum, w) => sum + w.balanceDue);

    // Pending collection works: works that are completed OR have balanceDue > 0
    final pendingWorks = works.where((w) => w.status == "completed" || w.balanceDue > 0).toList();

    return Column(
      children: [
        // Top Financial KPI Summary Cards
        Container(
          margin: const EdgeInsets.all(16.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr("total_collected"),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "₹ ${totalCollected.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D9488),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 36, width: 1, color: Colors.grey.shade300),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr("outstanding_balance"),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "₹ ${totalOutstanding.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 2 Tabs: Pending Collection (Vara Vendiyavai) vs Collected History (Vandha Panam)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SegmentedButton<int>(
            segments: [
              ButtonSegment(
                value: 0,
                label: Text("${context.tr("pending_collection")} (${pendingWorks.length})"),
                icon: const Icon(Icons.pending_actions, size: 16),
              ),
              ButtonSegment(
                value: 1,
                label: Text("${context.tr("collected_history")} (${paymentHistory.length})"),
                icon: const Icon(Icons.history, size: 16),
              ),
            ],
            selected: {_selectedTabIndex},
            onSelectionChanged: (val) {
              setState(() => _selectedTabIndex = val.first);
            },
          ),
        ),

        const SizedBox(height: 12),

        // Tab View Content
        Expanded(
          child: _selectedTabIndex == 0
              ? _buildPendingCollectionView(pendingWorks)
              : _buildCollectedHistoryView(paymentHistory),
        ),
      ],
    );
  }

  Widget _buildPendingCollectionView(List<WorkItem> pendingWorks) {
    if (pendingWorks.isEmpty) {
      return EmptyStateView(
        icon: Icons.check_circle_outline,
        title: context.tr("no_data"),
        description: context.tr("no_pending_payments"),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: pendingWorks.length,
      itemBuilder: (ctx, index) {
        final work = pendingWorks[index];
        final isBilled = work.billingStatus == "billed";

        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      work.customerName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isBilled
                            ? (work.balanceDue > 0 ? Colors.amber.withValues(alpha: 0.15) : Colors.green.withValues(alpha: 0.15))
                            : Colors.blue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isBilled
                            ? (work.balanceDue > 0 ? "PAYMENT PENDING" : "PAID")
                            : "BILLING READY",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isBilled
                              ? (work.balanceDue > 0 ? Colors.amber.shade900 : Colors.green.shade800)
                              : Colors.blue.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  work.title,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                if (work.actionNote.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    "Action: ${work.actionNote}",
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700, fontStyle: FontStyle.italic),
                  ),
                ],
                const Divider(height: 20),

                // Financial Overview
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBilled ? "Bill: ${work.billNumber}" : "Total Cost: ₹ ${work.totalCost.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Paid/Adv: ₹ ${(work.advancePaid + work.collectedPayment).toStringAsFixed(2)}",
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(isBilled ? "Balance Due" : "Billed Amount Due", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        Text(
                          "₹ ${(work.balanceDue > 0 ? work.balanceDue : work.totalCost).toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Action Buttons based on Billing Status
                if (!isBilled) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(40),
                    ),
                    icon: const Icon(Icons.receipt, size: 16),
                    label: Text(context.tr("generate_bill")),
                    onPressed: () => _showGenerateBillDialog(work),
                  ),
                ] else ...[
                  if (work.balanceDue > 0) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D9488),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(40),
                            ),
                            icon: const Icon(Icons.payment, size: 16),
                            label: Text(context.tr("collect_payment")),
                            onPressed: () => _showCollectPaymentDialog(work),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                          ),
                          icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF1E3A8A)),
                          tooltip: "Print Invoice",
                          onPressed: () => PdfInvoiceService.printOrShareInvoice(work: work),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                "Payment Settled in Full (${work.paymentAccount?.toUpperCase() ?? ''})",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.1),
                          ),
                          icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF0D9488)),
                          tooltip: "Print Invoice",
                          onPressed: () => PdfInvoiceService.printOrShareInvoice(work: work),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCollectedHistoryView(List<PaymentRecord> history) {
    if (history.isEmpty) {
      return EmptyStateView(
        icon: Icons.history,
        title: context.tr("no_data"),
        description: context.tr("no_collected_history"),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: history.length,
      itemBuilder: (ctx, index) {
        final item = history[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10.0),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.12),
                  child: const Icon(Icons.check, color: Color(0xFF0D9488), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${item.customerName} - ${item.workTitle}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Bill: ${item.billNumber} • ${item.paymentDate.day}/${item.paymentDate.month}/${item.paymentDate.year}",
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "₹ ${item.amount.toStringAsFixed(2)}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0D9488)),
                    ),
                    const SizedBox(height: 2),
                    _buildAccountBadge(item.paymentType),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountBadge(String type) {
    Color bg;
    Color fg;
    String label;
    switch (type) {
      case "savings":
        bg = Colors.blue.withValues(alpha: 0.12);
        fg = Colors.blue.shade800;
        label = "SAVINGS";
        break;
      case "current":
        bg = Colors.purple.withValues(alpha: 0.12);
        fg = Colors.purple.shade800;
        label = "CURRENT";
        break;
      default:
        bg = Colors.teal.withValues(alpha: 0.12);
        fg = Colors.teal.shade800;
        label = "CASH";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}
