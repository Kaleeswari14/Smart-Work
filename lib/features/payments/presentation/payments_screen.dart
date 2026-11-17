import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "../../../core/localization/app_localizations.dart";
import "../../../shared/widgets/empty_state_view.dart";
import "../../customers/presentation/customers_provider.dart";
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
  String _searchQuery = "";
  String _selectedCategoryFilter = "all"; // all, advance, bill, cash, online
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
    final notesController = TextEditingController();
    String selectedAccount = "savings"; // savings, current, cash
    String selectedCategory = work.balanceDue <= 0 ? "Full Settlement" : "Bill Collection";

    // Resolve customer phone
    final customers = ref.read(customersListProvider);
    final matchedCust = customers.where((c) =>
        c.id == work.customerId ||
        c.name.trim().toLowerCase() == work.customerName.trim().toLowerCase()).firstOrNull;
    final customerPhone = matchedCust?.phone ?? "";

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
                    if (customerPhone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 12, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(customerPhone, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ],
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
                    const SizedBox(height: 12),

                    // Payment Category Selector
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: "Payment Type / வகை",
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "Bill Collection",
                          child: Text("Bill Collection (பில் வசூல்)"),
                        ),
                        DropdownMenuItem(
                          value: "Advance Payment",
                          child: Text("Advance Payment (முன்பணம்)"),
                        ),
                        DropdownMenuItem(
                          value: "Full Settlement",
                          child: Text("Full Settlement (முழு தீர்வு)"),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedCategory = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

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
                    const SizedBox(height: 12),

                    // Optional Notes Field
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: "Payment Notes / குறிப்பு (Optional)",
                        hintText: "e.g. GPay ref #, Cash handed over, etc.",
                        prefixIcon: Icon(Icons.note_alt_outlined),
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
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final amt = double.tryParse(amountController.text) ?? work.balanceDue;
                    if (amt > 0) {
                      // 1. Record in Payments History with customer phone, notes, and category
                      ref.read(paymentsListProvider.notifier).recordPayment(
                            workId: work.id,
                            workTitle: work.title,
                            customerId: work.customerId,
                            customerName: work.customerName,
                            customerPhone: customerPhone,
                            billNumber: billNo,
                            amount: amt,
                            paymentType: selectedAccount,
                            notes: notesController.text.trim(),
                            paymentCategory: selectedCategory,
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
    final customers = ref.watch(customersListProvider);

    // Build unified payments list (combining recorded collections + advance payments from work items)
    final List<PaymentRecord> combinedHistory = [];
    final existingAdvanceWorkIds = paymentHistory
        .where((p) => p.paymentCategory.toLowerCase().contains("advance"))
        .map((p) => p.workId)
        .toSet();

    for (final p in paymentHistory) {
      final matchedWork = works.where((w) => w.id == p.workId).firstOrNull;
      final cName = (p.customerName.isNotEmpty && p.customerName != "Unknown Customer")
          ? p.customerName
          : (matchedWork?.customerName ?? "Customer");
      final matchedCust = customers.where((c) =>
          (p.customerId.isNotEmpty && c.id == p.customerId) ||
          c.name.trim().toLowerCase() == cName.trim().toLowerCase()).firstOrNull;

      combinedHistory.add(p.copyWith(
        customerName: cName,
        customerPhone: p.customerPhone.isNotEmpty ? p.customerPhone : (matchedCust?.phone ?? ""),
        workTitle: (p.workTitle.isNotEmpty && p.workTitle != "Unknown Work")
            ? p.workTitle
            : (matchedWork?.title ?? "Work Order"),
        billNumber: p.billNumber.isNotEmpty ? p.billNumber : (matchedWork?.billNumber ?? ""),
      ));
    }

    for (final work in works) {
      if (work.advancePaid > 0 && !existingAdvanceWorkIds.contains(work.id)) {
        final matchedCust = customers.where((c) =>
            c.id == work.customerId ||
            c.name.trim().toLowerCase() == work.customerName.trim().toLowerCase()).firstOrNull;

        combinedHistory.add(PaymentRecord(
          id: "adv_${work.id}",
          workId: work.id,
          workTitle: work.title,
          customerId: work.customerId,
          customerName: work.customerName,
          customerPhone: matchedCust?.phone ?? "",
          billNumber: work.billNumber ?? "ADVANCE",
          amount: work.advancePaid,
          paymentType: "cash",
          paymentDate: work.inProgressStartTime ?? DateTime.now(),
          notes: work.actionNote.isNotEmpty ? "Advance paid • ${work.actionNote}" : "Advance received at work creation",
          paymentCategory: "Advance Payment",
        ));
      }
    }

    combinedHistory.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

    // Calculations
    final totalCollected = combinedHistory.fold(0.0, (sum, p) => sum + p.amount);
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
                label: Text("${context.tr("collected_history")} (${combinedHistory.length})"),
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
              : _buildCollectedHistoryView(combinedHistory, customers, works),
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

  Widget _buildCollectedHistoryView(
    List<PaymentRecord> history,
    List<CustomerItem> customers,
    List<WorkItem> works,
  ) {
    if (history.isEmpty) {
      return EmptyStateView(
        icon: Icons.history,
        title: context.tr("no_data"),
        description: context.tr("no_collected_history"),
      );
    }

    final query = _searchQuery.trim().toLowerCase();
    final filteredHistory = history.where((p) {
      // 1. Category Filter
      if (_selectedCategoryFilter == "advance" && !p.paymentCategory.toLowerCase().contains("advance")) {
        return false;
      }
      if (_selectedCategoryFilter == "bill" && p.paymentCategory.toLowerCase().contains("advance")) {
        return false;
      }
      if (_selectedCategoryFilter == "cash" && p.paymentType.toLowerCase() != "cash") {
        return false;
      }
      if (_selectedCategoryFilter == "online" && p.paymentType.toLowerCase() == "cash") {
        return false;
      }

      // 2. Search Query
      if (query.isNotEmpty) {
        final inCustomer = p.customerName.toLowerCase().contains(query);
        final inPhone = p.customerPhone.toLowerCase().contains(query);
        final inWork = p.workTitle.toLowerCase().contains(query);
        final inBill = p.billNumber.toLowerCase().contains(query);
        final inNotes = p.notes.toLowerCase().contains(query);
        final inCategory = p.paymentCategory.toLowerCase().contains(query);
        final inAmount = p.amount.toString().contains(query);
        return inCustomer || inPhone || inWork || inBill || inNotes || inCategory || inAmount;
      }

      return true;
    }).toList();

    final dateFormat = DateFormat("dd MMM yyyy, hh:mm a");

    return Column(
      children: [
        // Search & Filter Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Column(
            children: [
              // Search Input
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: "Search customer, phone, bill, notes, amount...",
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = "");
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip("all", "All (${history.length})"),
                    const SizedBox(width: 6),
                    _buildFilterChip("advance", "Advance Only"),
                    const SizedBox(width: 6),
                    _buildFilterChip("bill", "Bills Only"),
                    const SizedBox(width: 6),
                    _buildFilterChip("cash", "Cash"),
                    const SizedBox(width: 6),
                    _buildFilterChip("online", "Bank / UPI"),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // Payments List
        Expanded(
          child: filteredHistory.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          "No payments match your search or filter",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  itemCount: filteredHistory.length,
                  itemBuilder: (ctx, index) {
                    final item = filteredHistory[index];
                    final matchedCust = customers.where((c) =>
                        (item.customerId.isNotEmpty && c.id == item.customerId) ||
                        c.name.trim().toLowerCase() == item.customerName.trim().toLowerCase()).firstOrNull;
                    final matchedWork = works.where((w) => w.id == item.workId).firstOrNull;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showPaymentDetailsDialog(item, matchedCust, matchedWork),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Customer Name, Phone & Category Badge
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: item.paymentCategory.toLowerCase().contains("advance")
                                        ? Colors.amber.shade100
                                        : const Color(0xFF0D9488).withValues(alpha: 0.12),
                                    child: Icon(
                                      item.paymentCategory.toLowerCase().contains("advance")
                                          ? Icons.bookmark_added_outlined
                                          : Icons.receipt_long,
                                      color: item.paymentCategory.toLowerCase().contains("advance")
                                          ? Colors.amber.shade900
                                          : const Color(0xFF0D9488),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.customerName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        if (item.customerPhone.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Icon(Icons.phone, size: 12, color: Colors.grey.shade600),
                                              const SizedBox(width: 4),
                                              Text(
                                                item.customerPhone,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade700,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  _buildCategoryBadge(item.paymentCategory),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // 2. Work Order Title & Bill / Reference
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.build_circle_outlined, size: 14, color: Color(0xFF1E3A8A)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        "${item.workTitle} ${item.billNumber.isNotEmpty ? '• ${item.billNumber}' : ''}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blueGrey.shade800,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),

                              // 3. Amount, Payment Account & Date
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "₹ ${item.amount.toStringAsFixed(2)}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Color(0xFF0D9488),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today, size: 11, color: Colors.grey.shade500),
                                          const SizedBox(width: 4),
                                          Text(
                                            dateFormat.format(item.paymentDate),
                                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  _buildAccountBadge(item.paymentType),
                                ],
                              ),

                              // 4. Notes / Remarks Box
                              const SizedBox(height: 10),
                              if (item.notes.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.blueGrey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blueGrey.shade100),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.note_alt_outlined, size: 14, color: Color(0xFF1E3A8A)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          item.notes,
                                          style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade900),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_note, size: 18, color: Color(0xFF1E3A8A)),
                                        tooltip: "Edit Note",
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _showEditNotesDialog(item),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    InkWell(
                                      onTap: () => _showEditNotesDialog(item),
                                      borderRadius: BorderRadius.circular(4),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        child: Row(
                                          children: const [
                                            Icon(Icons.add_comment_outlined, size: 13, color: Color(0xFF1E3A8A)),
                                            SizedBox(width: 4),
                                            Text(
                                              "+ Add Notes (குறிப்பு)",
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF1E3A8A),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedCategoryFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : Colors.grey.shade800,
      ),
      selectedColor: const Color(0xFF1E3A8A),
      backgroundColor: Colors.grey.shade100,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      onSelected: (_) {
        setState(() => _selectedCategoryFilter = value);
      },
    );
  }

  void _showEditNotesDialog(PaymentRecord item) {
    final noteController = TextEditingController(text: item.notes);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.edit_note, color: Color(0xFF1E3A8A)),
              SizedBox(width: 8),
              Text("Payment Notes / குறிப்பு", style: TextStyle(fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${item.customerName} • ₹ ${item.amount.toStringAsFixed(2)}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              if (item.customerPhone.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text("Phone: ${item.customerPhone}", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Notes / குறிப்பு",
                  hintText: "Enter notes (e.g. GPay ref, Cash note, Advance for materials...)",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
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
                final notes = noteController.text.trim();
                ref.read(paymentsListProvider.notifier).updatePaymentNotes(item.id, notes);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Payment notes updated successfully!")),
                );
              },
              child: Text(context.tr("save")),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentDetailsDialog(PaymentRecord item, CustomerItem? customer, WorkItem? work) {
    final dateFormat = DateFormat("dd MMM yyyy, hh:mm a");
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.receipt_long, color: Color(0xFF0D9488)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Payment Receipt Details",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer Section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, size: 16, color: Color(0xFF1E3A8A)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.customerName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E3A8A)),
                            ),
                          ),
                        ],
                      ),
                      if (item.customerPhone.isNotEmpty || (customer?.phone.isNotEmpty ?? false)) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone, size: 14, color: Colors.grey.shade700),
                            const SizedBox(width: 6),
                            Text(
                              item.customerPhone.isNotEmpty ? item.customerPhone : (customer?.phone ?? ""),
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                            ),
                          ],
                        ),
                      ],
                      if (customer?.address.isNotEmpty ?? false) ...[
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.grey.shade700),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                customer!.address,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Amount & Category Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Amount Paid", style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Text(
                            "₹ ${item.amount.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildCategoryBadge(item.paymentCategory),
                          const SizedBox(height: 4),
                          _buildAccountBadge(item.paymentType),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Work & Bill details
                _buildDetailRow("Work Order", item.workTitle),
                _buildDetailRow("Bill / Ref", item.billNumber.isNotEmpty ? item.billNumber : "N/A"),
                _buildDetailRow("Date & Time", dateFormat.format(item.paymentDate)),

                const Divider(height: 20),

                // Notes / Remarks Box
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Payment Notes / குறிப்பு:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      icon: const Icon(Icons.edit, size: 14),
                      label: const Text("Edit Note", style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showEditNotesDialog(item);
                      },
                    ),
                  ],
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    item.notes.isNotEmpty
                        ? item.notes
                        : "No notes entered yet. Click 'Edit Note' to add notes (e.g. GPay ref, cash note).",
                    style: TextStyle(
                      fontSize: 12,
                      color: item.notes.isNotEmpty ? Colors.black87 : Colors.grey.shade600,
                      fontStyle: item.notes.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (work != null)
              OutlinedButton.icon(
                icon: const Icon(Icons.picture_as_pdf, size: 16),
                label: const Text("Invoice"),
                onPressed: () => PdfInvoiceService.printOrShareInvoice(work: work),
              ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge(String category) {
    Color bg;
    Color fg;
    String label;
    final catLower = category.toLowerCase();
    if (catLower.contains("advance")) {
      bg = Colors.amber.shade50;
      fg = Colors.amber.shade900;
      label = "ADVANCE PAYMENT";
    } else if (catLower.contains("settle") || catLower.contains("full")) {
      bg = Colors.green.shade50;
      fg = Colors.green.shade800;
      label = "FULL SETTLEMENT";
    } else {
      bg = Colors.teal.shade50;
      fg = Colors.teal.shade800;
      label = "BILL COLLECTION";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
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
