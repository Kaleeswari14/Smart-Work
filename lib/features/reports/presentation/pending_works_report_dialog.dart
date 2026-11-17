import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "package:pdf/pdf.dart";
import "package:pdf/widgets.dart" as pw;
import "package:printing/printing.dart";
import "../../../core/localization/app_localizations.dart";
import "../../../core/localization/language_provider.dart";
import "../../customers/presentation/customers_provider.dart";
import "../../works/presentation/works_provider.dart";

class PendingWorksReportDialog extends ConsumerWidget {
  const PendingWorksReportDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => const PendingWorksReportDialog(),
    );
  }

  Future<void> _sharePdf(
    BuildContext context,
    List<WorkItem> pendingWorks,
    List<CustomerItem> customers,
  ) async {
    try {
      final pdf = pw.Document();
      final dateFormat = DateFormat("dd MMM yyyy, hh:mm a");
      final currentDateStr = dateFormat.format(DateTime.now());

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context ctx) {
            return [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "SMARTIVA TECHNOLOGIES",
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex("#1E3A8A"),
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        "Pending Works & Customer Details Report",
                        style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        "Date: $currentDateStr",
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex("#FFFBEB"),
                          borderRadius: pw.BorderRadius.circular(4),
                          border: pw.Border.all(color: PdfColor.fromHex("#F59E0B")),
                        ),
                        child: pw.Text(
                          "Total Pending: ${pendingWorks.length}",
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex("#B45309"),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Table
              pw.TableHelper.fromTextArray(
                headers: ["#", "Customer Name", "Phone", "Customer Address", "Problem / Scope", "Agreed Cost", "Advance Paid"],
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 10,
                ),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColor.fromHex("#1E3A8A"),
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                data: List<List<String>>.generate(pendingWorks.length, (index) {
                  final work = pendingWorks[index];
                  final customer = customers.where((c) => c.id == work.customerId).firstOrNull;
                  final phone = customer?.phone.isNotEmpty == true ? customer!.phone : "-";
                  final address = customer?.address.isNotEmpty == true ? customer!.address : "-";
                  final problem = work.description.isNotEmpty
                      ? "${work.title}\n(${work.description})"
                      : work.title;
                  return [
                    "${index + 1}",
                    work.customerName,
                    phone,
                    address,
                    problem,
                    "₹ ${work.totalCost.toStringAsFixed(2)}",
                    "₹ ${work.advancePaid.toStringAsFixed(2)}",
                  ];
                }),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                "Generated by Smartiva Work Management System",
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
              ),
            ];
          },
        ),
      );

      final Uint8List pdfBytes = await pdf.save();
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: "Smartiva_Pending_Works_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf",
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error sharing PDF: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _copyTextReport(
    BuildContext context,
    List<WorkItem> pendingWorks,
    List<CustomerItem> customers,
  ) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat("dd-MM-yyyy hh:mm a");
    buffer.writeln("📋 SMARTIVA - PENDING WORKS REPORT");
    buffer.writeln("Date: ${dateFormat.format(DateTime.now())}");
    buffer.writeln("Total Pending: ${pendingWorks.length} Works\n");
    buffer.writeln("----------------------------------------");

    for (int i = 0; i < pendingWorks.length; i++) {
      final work = pendingWorks[i];
      final customer = customers.where((c) => c.id == work.customerId).firstOrNull;
      final phone = customer?.phone.isNotEmpty == true ? customer!.phone : "N/A";
      final address = customer?.address.isNotEmpty == true ? customer!.address : "N/A";

      buffer.writeln("${i + 1}. Customer: ${work.customerName}");
      buffer.writeln("   📞 Phone: $phone");
      buffer.writeln("   📍 Address: $address");
      buffer.writeln("   🔧 Problem/Work: ${work.title}");
      if (work.description.isNotEmpty) {
        buffer.writeln("   📝 Scope: ${work.description}");
      }
      buffer.writeln("   💰 Cost: ₹${work.totalCost.toStringAsFixed(2)} (Adv: ₹${work.advancePaid.toStringAsFixed(2)})");
      buffer.writeln("----------------------------------------");
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "Pending report copied to clipboard! Ready to share on WhatsApp.",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0D9488),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final works = ref.watch(worksListProvider);
    final customers = ref.watch(customersListProvider);
    final isTanglish = ref.watch(languageProvider).languageCode == "ta";
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;

    final pendingWorks = works.where((w) => w.status == "pending").toList();

    final Widget contentWidget;
    if (pendingWorks.isEmpty) {
      contentWidget = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: Colors.green.shade400),
            const SizedBox(height: 12),
            Text(
              isTanglish ? "Tharpodhu Nilaivai Velaigal Edhum Illai!" : "No pending works at the moment!",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              isTanglish ? "Ella velaigalum live alladhu mudinthuvittana." : "All works are either in progress or completed.",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      );
    } else if (isMobile) {
      // Mobile View: Responsive Card List
      contentWidget = ListView.separated(
        itemCount: pendingWorks.length,
        separatorBuilder: (ctx, i) => const SizedBox(height: 10),
        itemBuilder: (ctx, index) {
          final work = pendingWorks[index];
          final customer = customers.where((c) => c.id == work.customerId).firstOrNull;
          final phone = customer?.phone.isNotEmpty == true ? customer!.phone : "-";
          final address = customer?.address.isNotEmpty == true ? customer!.address : "-";

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: const Color(0xFF1E3A8A),
                            child: Text(
                              "${index + 1}",
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              work.customerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Text(
                        "Pending",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (phone != "-")
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF1E3A8A)),
                      const SizedBox(width: 6),
                      Text(
                        phone,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                if (address != "-") ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          address,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.build_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        work.description.isNotEmpty
                            ? "${work.title} (${work.description})"
                        : work.title,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Cost: ₹ ${work.totalCost.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      Text(
                        "Adv: ₹ ${work.advancePaid.toStringAsFixed(2)}",
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      // Desktop / Tablet View: Full Data Table
      contentWidget = Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                const Color(0xFF1E3A8A).withValues(alpha: 0.08),
              ),
              headingTextStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF1E3A8A),
              ),
              dataRowMinHeight: 48,
              dataRowMaxHeight: 70,
              columns: const [
                DataColumn(label: Text("#")),
                DataColumn(label: Text("Customer")),
                DataColumn(label: Text("Phone")),
                DataColumn(label: Text("Address")),
                DataColumn(label: Text("Problem / Scope")),
                DataColumn(label: Text("Agreed Cost")),
              ],
              rows: List<DataRow>.generate(pendingWorks.length, (index) {
                final work = pendingWorks[index];
                final customer = customers.where((c) => c.id == work.customerId).firstOrNull;
                final phone = customer?.phone.isNotEmpty == true ? customer!.phone : "-";
                final address = customer?.address.isNotEmpty == true ? customer!.address : "-";

                return DataRow(
                  color: WidgetStateProperty.resolveWith<Color?>(
                    (Set<WidgetState> states) {
                      return index.isEven ? Colors.grey.shade50 : null;
                    },
                  ),
                  cells: [
                    DataCell(Text("${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                            child: Text(
                              work.customerName.isNotEmpty ? work.customerName[0].toUpperCase() : "C",
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(work.customerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(phone, style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.w500)),
                    ),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: Text(
                          address,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              work.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (work.description.isNotEmpty)
                              Text(
                                work.description,
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "₹ ${work.totalCost.toStringAsFixed(2)}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (work.advancePaid > 0)
                            Text(
                              "(Adv: ₹ ${work.advancePaid.toStringAsFixed(2)})",
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      );
    }

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 850,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        padding: EdgeInsets.all(isMobile ? 14 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.table_chart, color: Colors.amber.shade900, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isTanglish ? "Nilaivai Velaigal Arikkai" : "Pending Works Report",
                              style: TextStyle(
                                fontSize: isMobile ? 15 : 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              "${pendingWorks.length} ${isTanglish ? "Velaigal Nilaivaiyil Ullaana" : "Works Pending"}",
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Divider(height: isMobile ? 18 : 24),

            // Content
            Expanded(
              child: contentWidget,
            ),
            Divider(height: isMobile ? 18 : 24),

            // Actions bar with responsive Wrap
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(context.tr("close")),
                ),
                if (pendingWorks.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0D9488),
                          side: const BorderSide(color: Color(0xFF0D9488)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        icon: const Icon(Icons.copy, size: 15),
                        label: Text(isTanglish ? "WhatsApp Copy" : "Copy Text"),
                        onPressed: () => _copyTextReport(context, pendingWorks, customers),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        icon: const Icon(Icons.share, size: 15),
                        label: Text(isTanglish ? "PDF Share" : "Share PDF"),
                        onPressed: () => _sharePdf(context, pendingWorks, customers),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
