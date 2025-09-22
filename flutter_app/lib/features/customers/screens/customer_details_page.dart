import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/customer.dart';
import '../providers/customer_provider.dart';
import 'customer_form_screen.dart';

class CustomerDetailsPage extends ConsumerStatefulWidget {
  final String customerId;

  const CustomerDetailsPage({
    super.key,
    required this.customerId,
  });

  @override
  ConsumerState<CustomerDetailsPage> createState() => _CustomerDetailsPageState();
}

class _CustomerDetailsPageState extends ConsumerState<CustomerDetailsPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);
    final customerAsync = ref.watch(customerByIdProvider(int.parse(widget.customerId)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Details'),
        actions: customerAsync.when(
          data: (customer) => _buildActions(customer, authState.user?.role),
          loading: () => [],
          error: (_, __) => [],
        ),
      ),
      body: customerAsync.when(
        data: (customer) => _buildCustomerDetails(customer, authState.user?.role),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorWidget(error.toString()),
      ),
    );
  }

  List<Widget> _buildActions(Customer customer, String? userRole) {
    final canEdit = userRole == 'sales' || userRole == 'admin';
    
    if (!canEdit) return [];

    return [
      IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () => _navigateToEdit(customer),
        tooltip: 'Edit Customer',
      ),
      PopupMenuButton<String>(
        onSelected: (value) => _handleAction(value, customer),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'vehicles',
            child: ListTile(
              leading: Icon(Icons.directions_car),
              title: Text('View Vehicles'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          if (userRole == 'admin')
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
    ];
  }

  Widget _buildCustomerDetails(Customer customer, String? userRole) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blue,
                    child: Text(
                      customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (customer.email != null)
                          Row(
                            children: [
                              const Icon(Icons.email, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(customer.email!),
                            ],
                          ),
                        if (customer.phone != null)
                          Row(
                            children: [
                              const Icon(Icons.phone, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(customer.phone!),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),

          // Contact Information
          _buildSection(
            title: 'Contact Information',
            children: [
              _buildDetailRow('Name', customer.name),
              if (customer.phone != null)
                _buildDetailRow('Phone', customer.phone!),
              if (customer.email != null)
                _buildDetailRow('Email', customer.email!),
              if (customer.address != null)
                _buildDetailRow('Address', customer.address!),
              if (customer.city != null)
                _buildDetailRow('City', customer.city!),
            ],
          ),

          // Additional Information
          if (customer.notes != null || customer.createdAt != null)
            _buildSection(
              title: 'Additional Information',
              children: [
                if (customer.notes != null)
                  _buildDetailRow('Notes', customer.notes!),
                if (customer.createdAt != null)
                  _buildDetailRow('Created', _formatDate(customer.createdAt!)),
              ],
            ),

          // Quick Actions
          const SizedBox(height: 24),
          _buildQuickActions(customer, userRole),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(Customer customer, String? userRole) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildActionButton(
                  icon: Icons.directions_car,
                  label: 'View Vehicles',
                  onPressed: () => _handleAction('vehicles', customer),
                ),
                _buildActionButton(
                  icon: Icons.build_circle,
                  label: 'Work Orders',
                  onPressed: () => _handleAction('workorders', customer),
                ),
                _buildActionButton(
                  icon: Icons.receipt_long,
                  label: 'Invoices',
                  onPressed: () => _handleAction('invoices', customer),
                ),
                if (userRole == 'sales' || userRole == 'admin')
                  _buildActionButton(
                    icon: Icons.edit,
                    label: 'Edit Customer',
                    onPressed: () => _navigateToEdit(customer),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading customer',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.refresh(customerByIdProvider(int.parse(widget.customerId))),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _navigateToEdit(Customer customer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomerFormScreen(customer: customer),
      ),
    ).then((_) {
      // Refresh customer data when returning from edit
      ref.invalidate(customerByIdProvider(customer.id!));
    });
  }

  void _handleAction(String action, Customer customer) {
    switch (action) {
      case 'vehicles':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicles view coming soon')),
        );
        break;
      case 'workorders':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Work orders view coming soon')),
        );
        break;
      case 'invoices':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoices view coming soon')),
        );
        break;
      case 'delete':
        _confirmDelete(customer);
        break;
    }
  }

  void _confirmDelete(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete ${customer.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(customerNotifierProvider.notifier).deleteCustomer(customer.id!);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${customer.name} deleted successfully')),
                  );
                  context.go('/customers');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting customer: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}