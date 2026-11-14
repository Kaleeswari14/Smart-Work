import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../../core/localization/app_localizations.dart";
import "../../../shared/widgets/empty_state_view.dart";
import "../../works/presentation/works_provider.dart";
import "customers_provider.dart";

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCustomerDetailsDialog(CustomerItem customer, List<WorkItem> allWorks) {
    final customerWorks = allWorks.where((w) => w.customerId == customer.id).toList();
    final totalBilled = customerWorks.fold(0.0, (sum, w) => sum + w.totalCost);
    final totalAdvance = customerWorks.fold(0.0, (sum, w) => sum + w.advancePaid);
    final balanceDue = totalBilled - totalAdvance;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: ListView(
                controller: scrollController,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            child: Text(
                              customer.name.isNotEmpty ? customer.name[0].toUpperCase() : "C",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer.name,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                customer.phone.isNotEmpty ? customer.phone : "No phone",
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Contact Info Card
                  Card(
                    color: Colors.grey.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        children: [
                          if (customer.email.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.email_outlined, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(customer.email, style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                          if (customer.address.isNotEmpty) ...[
                            if (customer.email.isNotEmpty) const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(customer.address, style: const TextStyle(fontSize: 13)),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Financial Balance Summary Bar
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Total Billed", style: TextStyle(fontSize: 11, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text(
                                "₹ ${totalBilled.toStringAsFixed(2)}",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Balance Due", style: TextStyle(fontSize: 11, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text(
                                "₹ ${balanceDue.toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Customer's Works & Activity History Section
                  Text(
                    "${context.tr("works")} & History (${customerWorks.length})",
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  if (customerWorks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Center(
                        child: Text(
                          "No works assigned to this customer yet.",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ...customerWorks.map((w) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            w.status == "completed"
                                ? Icons.check_circle
                                : (w.status == "in_progress" ? Icons.play_circle : Icons.hourglass_empty),
                            color: w.status == "completed"
                                ? Colors.blue.shade700
                                : (w.status == "in_progress" ? const Color(0xFF0D9488) : Colors.amber.shade900),
                          ),
                          title: Text(w.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(
                            "Status: ${w.status.toUpperCase()} • Time: ${w.formattedDuration}",
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: Text(
                            "₹ ${w.totalCost.toStringAsFixed(0)}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddCustomerModal() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final addressController = TextEditingController();

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr("add_customer"),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: context.tr("customer_name"),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: context.tr("phone_number"),
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: context.tr("email_address"),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: context.tr("address"),
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final phone = phoneController.text.trim();
                  if (name.isNotEmpty) {
                    ref.read(customersListProvider.notifier).addCustomer(
                          name: name,
                          phone: phone,
                          email: emailController.text.trim(),
                          address: addressController.text.trim(),
                        );
                    Navigator.pop(ctx);
                  }
                },
                child: Text(context.tr("save")),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditCustomerModal(CustomerItem customer) {
    final nameController = TextEditingController(text: customer.name);
    final phoneController = TextEditingController(text: customer.phone);
    final emailController = TextEditingController(text: customer.email);
    final addressController = TextEditingController(text: customer.address);

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Edit Customer",
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
                controller: nameController,
                decoration: InputDecoration(
                  labelText: context.tr("customer_name"),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: context.tr("phone_number"),
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: context.tr("email_address"),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: context.tr("address"),
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isNotEmpty) {
                    ref.read(customersListProvider.notifier).updateCustomer(
                          customer.copyWith(
                            name: name,
                            phone: phoneController.text.trim(),
                            email: emailController.text.trim(),
                            address: addressController.text.trim(),
                          ),
                        );
                    Navigator.pop(ctx);
                  }
                },
                child: Text(context.tr("save")),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersListProvider);
    final works = ref.watch(worksListProvider);

    final filteredCustomers = _searchController.text.isEmpty
        ? customers
        : customers
            .where((c) =>
                c.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                c.phone.contains(_searchController.text))
            .toList();

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: context.tr("search"),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Expanded(
              child: filteredCustomers.isEmpty
                  ? EmptyStateView(
                      icon: Icons.people_outline,
                      title: context.tr("no_customers_title"),
                      description: context.tr("no_customers_desc"),
                      actionLabel: context.tr("add_customer"),
                      onAction: _showAddCustomerModal,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 80.0),
                      itemCount: filteredCustomers.length,
                      itemBuilder: (ctx, index) {
                        final customer = filteredCustomers[index];
                        final customerWorksCount =
                            works.where((w) => w.customerId == customer.id).length;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10.0),
                          child: ListTile(
                            onTap: () => _showCustomerDetailsDialog(customer, works),
                            leading: CircleAvatar(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              foregroundColor: Theme.of(context).colorScheme.primary,
                              child: Text(
                                customer.name.isNotEmpty ? customer.name[0].toUpperCase() : "C",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(
                              customer.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              customer.phone.isNotEmpty
                                  ? customer.phone
                                  : (customer.email.isNotEmpty ? customer.email : "No contact info"),
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "$customerWorksCount Works",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0D9488),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                // View Customer Details Icon
                                IconButton(
                                  icon: const Icon(Icons.visibility_outlined, size: 20, color: Color(0xFF1E3A8A)),
                                  tooltip: "View Customer",
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _showCustomerDetailsDialog(customer, works),
                                ),
                                const SizedBox(width: 4),
                                // Edit Customer Icon
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF0D9488)),
                                  tooltip: "Edit Customer",
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _showEditCustomerModal(customer),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),

        // Bottom-Right Floating Action Button for Adding Customer
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            heroTag: "fab_add_customer_screen",
            tooltip: context.tr("add_customer"),
            onPressed: _showAddCustomerModal,
            child: const Icon(Icons.person_add),
          ),
        ),
      ],
    );
  }
}
