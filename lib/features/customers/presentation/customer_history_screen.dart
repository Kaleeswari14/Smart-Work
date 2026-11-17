import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "../../../core/localization/app_localizations.dart";
import "../../../core/localization/language_provider.dart";
import "../../../shared/widgets/empty_state_view.dart";
import "../../payments/data/pdf_invoice_service.dart";
import "../../payments/presentation/payments_provider.dart";
import "../../works/presentation/works_provider.dart";
import "customers_provider.dart";

class CustomerHistoryScreen extends ConsumerStatefulWidget {
  const CustomerHistoryScreen({super.key});

  @override
  ConsumerState<CustomerHistoryScreen> createState() => _CustomerHistoryScreenState();
}

class _CustomerHistoryScreenState extends ConsumerState<CustomerHistoryScreen> {
  String? _selectedCustomerId;

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersListProvider);
    final works = ref.watch(worksListProvider);
    final payments = ref.watch(paymentsListProvider);
    final isTanglish = ref.watch(languageProvider).languageCode == "ta";
    final dateFormat = DateFormat("dd MMM yyyy");

    if (customers.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.tr("customer_history_title")),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: EmptyStateView(
              icon: Icons.person_off_outlined,
              title: isTanglish ? "Vaadikkaiyaalargal Illai" : "No Customers Found",
              description: isTanglish
                  ? "History paarka muthalil Customers tab-il customer add seiyavum."
                  : "Add customers first to view their chronological transaction ledgers.",
            ),
          ),
        ),
      );
    }

    // Default to first customer if not set or invalid
    final activeCustomer = customers.firstWhere(
      (c) => c.id == _selectedCustomerId,
      orElse: () => customers.first,
    );

    // Customer works & payments
    final customerWorks = works.where((w) => w.customerId == activeCustomer.id).toList();
    final List<PaymentRecord> customerPayments = [
      ...payments.where((p) =>
          p.customerId == activeCustomer.id ||
          (p.customerName.isNotEmpty &&
              p.customerName.trim().toLowerCase() == activeCustomer.name.trim().toLowerCase())),
    ];

    final existingAdvWorkIds = customerPayments
        .where((p) => p.paymentCategory.toLowerCase().contains("advance"))
        .map((p) => p.workId)
        .toSet();

    for (final w in customerWorks) {
      if (w.advancePaid > 0 && !existingAdvWorkIds.contains(w.id)) {
        customerPayments.add(PaymentRecord(
          id: "adv_${w.id}",
          workId: w.id,
          workTitle: w.title,
          customerId: w.customerId,
          customerName: w.customerName,
          customerPhone: activeCustomer.phone,
          billNumber: w.billNumber ?? "ADVANCE",
          amount: w.advancePaid,
          paymentType: w.paymentAccount ?? "cash",
          paymentDate: w.inProgressStartTime ?? DateTime.now(),
          notes: w.actionNote.isNotEmpty ? "Advance paid • ${w.actionNote}" : "Advance paid at work creation",
          paymentCategory: "Advance Payment",
        ));
      }
    }
    customerPayments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

    double totalBilled = 0.0;
    double totalPaid = 0.0;

    for (final w in customerWorks) {
      totalBilled += (w.billedAmount ?? w.totalCost);
      totalPaid += (w.advancePaid + w.collectedPayment);
    }

    final balanceDue = totalBilled - totalPaid;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr("customer_history_title")),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Customer Selector Dropdown Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: activeCustomer.id,
                    icon: const Icon(Icons.arrow_drop_down),
                    items: customers.map((c) {
                      return DropdownMenuItem(
                        value: c.id,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              child: Text(
                                c.name.isNotEmpty ? c.name[0].toUpperCase() : "C",
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              c.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            if (c.phone.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                "(${c.phone})",
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCustomerId = val;
                        });
                      }
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Lifetime Ledger Summary Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isTanglish ? "Vaadikkaiyaalar Ledger" : "Lifetime Account Ledger",
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${customerWorks.length} Orders",
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D9488)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            label: "Total Billed",
                            amount: "₹ ${totalBilled.toStringAsFixed(2)}",
                            color: const Color(0xFF1E3A8A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricTile(
                            label: "Total Paid",
                            amount: "₹ ${totalPaid.toStringAsFixed(2)}",
                            color: const Color(0xFF0D9488),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricTile(
                            label: "Balance Due",
                            amount: "₹ ${(balanceDue > 0 ? balanceDue : 0.0).toStringAsFixed(2)}",
                            color: balanceDue > 0 ? Colors.red.shade700 : Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Section: Past Works History
            Text(
              isTanglish ? "Velaigal Varalaaru (Works History)" : "Work Orders History",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (customerWorks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Center(
                  child: Text(
                    isTanglish ? "Indha customer-kku innum endha velaiyum seiyyapadavillai." : "No work orders recorded for this customer yet.",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              )
            else
              ...customerWorks.map((work) {
                final isCompleted = work.status == "completed";
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                work.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? Colors.blue.withValues(alpha: 0.15)
                                    : Colors.amber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                work.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isCompleted ? Colors.blue.shade800 : Colors.amber.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (work.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            work.description,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ],
                        if (work.actionNote.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            "Action: ${work.actionNote}",
                            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.blueGrey.shade700),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Cost: ₹ ${(work.billedAmount ?? work.totalCost).toStringAsFixed(2)}  •  Adv: ₹ ${work.advancePaid.toStringAsFixed(2)}",
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                backgroundColor: const Color(0xFF1E3A8A),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 32),
                              ),
                              icon: const Icon(Icons.picture_as_pdf, size: 14),
                              label: const Text("Invoice PDF", style: TextStyle(fontSize: 11)),
                              onPressed: () {
                                PdfInvoiceService.printOrShareInvoice(
                                  work: work,
                                  customer: activeCustomer,
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 20),

            // Section: Payment Receipts
            Text(
              isTanglish ? "Pana Pathivugal (Payment Receipts)" : "Payment Receipts & Audit",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (customerPayments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text(
                    isTanglish ? "Endha payment pathivum illai." : "No payment collections recorded yet.",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              )
            else
              ...customerPayments.map((p) {
                final isAdvance = p.paymentCategory.toLowerCase().contains("advance");
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: isAdvance
                                      ? Colors.amber.shade100
                                      : const Color(0xFF0D9488).withValues(alpha: 0.1),
                                  child: Icon(
                                    isAdvance ? Icons.bookmark_added_outlined : Icons.receipt,
                                    color: isAdvance ? Colors.amber.shade900 : const Color(0xFF0D9488),
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "₹ ${p.amount.toStringAsFixed(2)}",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0D9488)),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isAdvance ? Colors.amber.shade50 : Colors.teal.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: (isAdvance ? Colors.amber.shade800 : Colors.teal.shade800).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    isAdvance ? "ADVANCE" : "COLLECTED",
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: isAdvance ? Colors.amber.shade900 : Colors.teal.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              p.paymentType.toUpperCase(),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${p.workTitle} ${p.billNumber.isNotEmpty ? '• ${p.billNumber}' : ''}  •  ${dateFormat.format(p.paymentDate)}",
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                        if (p.notes.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.note_alt_outlined, size: 12, color: Color(0xFF1E3A8A)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    p.notes,
                                    style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade800, fontStyle: FontStyle.italic),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildMetricTile({
    required String label,
    required String amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
