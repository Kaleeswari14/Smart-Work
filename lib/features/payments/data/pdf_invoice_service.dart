import "dart:typed_data";
import "package:intl/intl.dart";
import "package:pdf/pdf.dart";
import "package:pdf/widgets.dart" as pw;
import "package:printing/printing.dart";
import "../../customers/presentation/customers_provider.dart";
import "../../works/presentation/works_provider.dart";
import "../presentation/payments_provider.dart";

class PdfInvoiceService {
  static Future<Uint8List> generateInvoicePdf({
    required WorkItem work,
    CustomerItem? customer,
    List<PaymentRecord> payments = const [],
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat("dd MMM yyyy, hh:mm a");
    final currentDateStr = dateFormat.format(DateTime.now());

    final effectiveTotal = work.billedAmount ?? work.totalCost;
    final totalPaid = work.advancePaid + work.collectedPayment;
    final balance = effectiveTotal - totalPaid;
    final isFullyPaid = balance <= 0 && effectiveTotal > 0;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. Header Banner
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "SMARTIVA TECHNOLOGIES",
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex("#1E3A8A"),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        "Professional Business & Work Management",
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: isFullyPaid
                          ? PdfColor.fromHex("#ECFDF5")
                          : PdfColor.fromHex("#FFFBEB"),
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(
                        color: isFullyPaid
                            ? PdfColor.fromHex("#10B981")
                            : PdfColor.fromHex("#F59E0B"),
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          isFullyPaid ? "PAID IN FULL" : "PAYMENT PENDING",
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: isFullyPaid
                                ? PdfColor.fromHex("#047857")
                                : PdfColor.fromHex("#B45309"),
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          "BILL #${work.billNumber ?? work.id.substring(0, work.id.length > 8 ? 8 : work.id.length)}",
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Divider(color: PdfColors.grey300, thickness: 1),
              pw.SizedBox(height: 16),

              // 2. Invoice Meta & Customer Info
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Customer Details
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "BILLED TO:",
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        work.customerName,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (customer != null && customer.phone.isNotEmpty)
                        pw.Text("Phone: ${customer.phone}", style: const pw.TextStyle(fontSize: 10)),
                      if (customer != null && customer.email.isNotEmpty)
                        pw.Text("Email: ${customer.email}", style: const pw.TextStyle(fontSize: 10)),
                      if (customer != null && customer.address.isNotEmpty)
                        pw.Text("Address: ${customer.address}", style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                  // Bill Dates
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        "INVOICE DATE:",
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(currentDateStr, style: const pw.TextStyle(fontSize: 11)),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        "WORK STATUS:",
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.Text(
                        work.status.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex("#0D9488"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 24),

              // 3. Work Scope & Action Details
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex("#F8FAFC"),
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColor.fromHex("#E2E8F0")),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "Work Order: ${work.title}",
                      style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                    ),
                    if (work.description.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        "Description: ${work.description}",
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                    if (work.actionNote.isNotEmpty) ...[
                      pw.SizedBox(height: 6),
                      pw.Text(
                        "Action Taken: ${work.actionNote}",
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex("#1E3A8A")),
                      ),
                    ],
                    if (work.totalSeconds > 0) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        "Logged Work Time: ${work.formattedDuration}",
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                      ),
                    ],
                  ],
                ),
              ),

              pw.SizedBox(height: 24),

              // 4. Financial Line Items Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColor.fromHex("#E2E8F0")),
                columnWidths: {
                  0: const pw.FlexColumnWidth(4),
                  1: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromHex("#F1F5F9")),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text("Description", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text("Amount (INR)", textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(work.title, style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text("Rs. ${effectiveTotal.toStringAsFixed(2)}", textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10)),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 16),

              // 5. Total Calculations Breakdown
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.SizedBox(
                    width: 240,
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text("Total Amount:", style: const pw.TextStyle(fontSize: 10)),
                            pw.Text("Rs. ${effectiveTotal.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text("Advance Paid:", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                            pw.Text("- Rs. ${work.advancePaid.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                          ],
                        ),
                        if (work.collectedPayment > 0) ...[
                          pw.SizedBox(height: 4),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text("Collected Payment:", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                              pw.Text("- Rs. ${work.collectedPayment.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                            ],
                          ),
                        ],
                        pw.Divider(color: PdfColors.grey300, thickness: 0.5),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text("Balance Due:", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: balance > 0 ? PdfColors.red800 : PdfColors.green800)),
                            pw.Text(
                              "Rs. ${(balance > 0 ? balance : 0.0).toStringAsFixed(2)}",
                              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: balance > 0 ? PdfColors.red800 : PdfColors.green800),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (work.paymentAccount != null) ...[
                pw.SizedBox(height: 16),
                pw.Text(
                  "Account Paid Into: ${work.paymentAccount!.toUpperCase()}",
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex("#0D9488")),
                ),
              ],

              pw.Spacer(),

              // 6. Footer Note
              pw.Divider(color: PdfColors.grey300, thickness: 1),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text(
                  "Thank you for your business! This is a computer-generated tax & work invoice.",
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> printOrShareInvoice({
    required WorkItem work,
    CustomerItem? customer,
    List<PaymentRecord> payments = const [],
  }) async {
    final pdfBytes = await generateInvoicePdf(
      work: work,
      customer: customer,
      payments: payments,
    );

    final billNum = work.billNumber ?? work.id.substring(0, work.id.length > 8 ? 8 : work.id.length);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: "Invoice_$billNum.pdf",
    );
  }
}
