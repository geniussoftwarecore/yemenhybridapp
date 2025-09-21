import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/app_localizations.dart';
import 'providers/customer_provider.dart';
import 'models/customer.dart';
import 'screens/customer_form_screen.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCity;
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final customersAsync = ref.watch(customerListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.customers),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToCustomerForm(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchSection(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.refresh(customerListProvider.future);
              },
              child: customersAsync.when(
                data: (customers) => _buildCustomersList(customers),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildErrorWidget(error.toString()),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCustomerForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search customers by name, phone, or email...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _performSearch();
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _selectedCity,
                    decoration: const InputDecoration(
                      labelText: 'Filter by City',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All Cities')),
                      DropdownMenuItem(value: 'Sana\'a', child: Text('Sana\'a')),
                      DropdownMenuItem(value: 'Aden', child: Text('Aden')),
                      DropdownMenuItem(value: 'Taiz', child: Text('Taiz')),
                      DropdownMenuItem(value: 'Hodeidah', child: Text('Hodeidah')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCity = value;
                      });
                      _performSearch();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomersList(List<Customer> customers) {
    if (customers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No customers found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the + button to add a new customer',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final customer = customers[index];
        return _buildCustomerCard(customer);
      },
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (customer.phone != null) 
              Text('📞 ${customer.phone}'),
            if (customer.email != null) 
              Text('📧 ${customer.email}'),
            if (customer.city != null) 
              Text('📍 ${customer.city}'),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleCustomerAction(value, customer),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: ListTile(
                leading: Icon(Icons.visibility),
                title: Text('View'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'vehicles',
              child: ListTile(
                leading: Icon(Icons.directions_car),
                title: Text('Vehicles'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
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
        onTap: () => _navigateToCustomerForm(context, customer: customer),
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
            'Error loading customers',
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
            onPressed: () => ref.refresh(customerListProvider.future),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _performSearch() {
    final filters = CustomerSearchFilters(
      query: _searchQuery.isNotEmpty ? _searchQuery : null,
      city: _selectedCity,
    );
    ref.read(customerSearchFiltersProvider.notifier).state = filters;
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCity = null;
      _searchController.clear();
    });
    ref.read(customerSearchFiltersProvider.notifier).state = CustomerSearchFilters();
  }

  void _navigateToCustomerForm(BuildContext context, {Customer? customer}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomerFormScreen(customer: customer),
      ),
    ).then((_) {
      // Refresh the list when returning from form
      ref.refresh(customerListProvider.future);
    });
  }

  void _handleCustomerAction(String action, Customer customer) {
    switch (action) {
      case 'view':
        _showCustomerDetails(customer);
        break;
      case 'edit':
        _navigateToCustomerForm(context, customer: customer);
        break;
      case 'vehicles':
        // TODO: Navigate to vehicles screen filtered by customer
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicles view coming soon')),
        );
        break;
      case 'delete':
        _confirmDelete(customer);
        break;
    }
  }

  void _showCustomerDetails(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (customer.phone != null) 
              _buildDetailRow('Phone', customer.phone!),
            if (customer.email != null) 
              _buildDetailRow('Email', customer.email!),
            if (customer.address != null) 
              _buildDetailRow('Address', customer.address!),
            if (customer.city != null) 
              _buildDetailRow('City', customer.city!),
            if (customer.notes != null) 
              _buildDetailRow('Notes', customer.notes!),
            if (customer.createdAt != null)
              _buildDetailRow('Created', _formatDate(customer.createdAt!)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToCustomerForm(context, customer: customer);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
                // Refresh the list to ensure UI updates
                ref.refresh(customerListProvider.future);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${customer.name} deleted successfully')),
                  );
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