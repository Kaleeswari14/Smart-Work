import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:work_management/features/payments/presentation/payments_provider.dart";
import "package:work_management/features/reports/presentation/reports_provider.dart";
import "package:work_management/features/works/presentation/works_provider.dart";

void main() {
  test("ReportsProvider financial calculations & 3-account breakdown test", () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final worksNotifier = container.read(worksListProvider.notifier);
    final paymentsNotifier = container.read(paymentsListProvider.notifier);

    // 1. Add Work 1: 5000 total, 1000 advance
    final work1 = await worksNotifier.addWork(
      customerId: "cust_1",
      customerName: "Ramesh",
      title: "Mobile App",
      description: "Flutter App",
      totalCost: 5000.0,
      advancePaid: 1000.0,
    );

    // 2. Add Work 2: 10000 total, 2000 advance
    final work2 = await worksNotifier.addWork(
      customerId: "cust_2",
      customerName: "Suresh",
      title: "Web Dashboard",
      description: "React Dashboard",
      totalCost: 10000.0,
      advancePaid: 2000.0,
    );

    // 3. Complete Work 1 with final bill 5000
    await worksNotifier.completeWorkWithAction(
      workId: work1.id,
      actionNote: "Delivered build",
      finalCost: 5000.0,
    );
    await worksNotifier.createBill(
      workId: work1.id,
      billNumber: "BILL-001",
      billedAmount: 5000.0,
    );

    // 4. Record Payments:
    // 2000 into Savings for Work 1
    await paymentsNotifier.recordPayment(
      workId: work1.id,
      workTitle: work1.title,
      customerId: work1.customerId,
      customerName: work1.customerName,
      billNumber: "BILL-001",
      amount: 2000.0,
      paymentType: "savings",
    );

    // 3000 into Current for Work 2
    await paymentsNotifier.recordPayment(
      workId: work2.id,
      workTitle: work2.title,
      customerId: work2.customerId,
      customerName: work2.customerName,
      billNumber: "BILL-002",
      amount: 3000.0,
      paymentType: "current",
    );

    // 5. Read BusinessReportData
    final report = container.read(businessReportProvider);

    // Total Revenue = 5000 + 10000 = 15000
    expect(report.totalRevenue, 15000.0);

    // Total Collected = (1000 + 2000 advance) + (2000 + 3000 payments) = 8000
    expect(report.totalCollected, 8000.0);

    // Outstanding Balance = 15000 - 8000 = 7000
    expect(report.outstandingBalance, 7000.0);

    // Completed Works Count = 1 (Work 1)
    expect(report.completedWorksCount, 1);

    // Accounts breakdown:
    expect(report.savingsCollected, 2000.0);
    expect(report.currentCollected, 3000.0);
    expect(report.cashCollected, 3000.0); // 1000 + 2000 advance
  });
}
