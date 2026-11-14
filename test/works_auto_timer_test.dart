import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:work_management/features/works/presentation/works_provider.dart";

void main() {
  test("WorksProvider auto-timer & manual time edit test", () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(worksListProvider.notifier);

    // 1. Add new work linked to a customer
    notifier.addWork(
      customerId: "cust_123",
      customerName: "Ramesh Kumar",
      title: "Mobile App Development",
      description: "Build client app",
      totalCost: 15000.0,
      advancePaid: 5000.0,
    );

    var works = container.read(worksListProvider);
    expect(works.length, 1);
    expect(works.first.customerName, "Ramesh Kumar");
    expect(works.first.status, "pending");
    expect(works.first.totalSeconds, 0);

    // 2. Change status to In Progress (Auto timer starts)
    final workId = works.first.id;
    notifier.updateStatus(workId, "in_progress");
    works = container.read(worksListProvider);
    expect(works.first.status, "in_progress");
    expect(works.first.inProgressStartTime, isNotNull);

    // 3. Change status to Completed (Auto timer calculates duration)
    notifier.updateStatus(workId, "completed");
    works = container.read(worksListProvider);
    expect(works.first.status, "completed");
    expect(works.first.inProgressStartTime, isNull);

    // 4. Test Manual Time Edit (Set to 2 hours 30 mins = 9000 seconds)
    notifier.manualUpdateTime(workId, 9000);
    works = container.read(worksListProvider);
    expect(works.first.totalSeconds, 9000);
    expect(works.first.formattedDuration, "2h 30m 0s");
  });
}
