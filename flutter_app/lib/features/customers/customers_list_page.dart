import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/i18n/app_localizations.dart';
import '../auth/providers/auth_provider.dart';
import 'providers/customer_provider.dart';
import 'models/customer.dart';
import 'dart:async';

class CustomersListPage extends ConsumerStatefulWidget {
  const CustomersListPage({super.key});

  @override
  ConsumerState<CustomersListPage> createState() => _CustomersListPageState();
}

class _CustomersListPageState extends ConsumerState<CustomersListPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _searchQuery = '';
  int _currentPage = 1;
  final int _pageSize = 10;
  
  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);
    final customersAsync = ref.watch(customerListProvider);
    final canAdd = authState.user?.role == 'sales' || authState.user?.role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.customers),
        actions: [
          if (canAdd)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => context.go('/customers/new'),
              tooltip: 'Add Customer',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchSection(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.refresh(customerListProvider.future);
              },
              child: customersAsync.when(
                data: (customers) => Column(
                  children: [
                    Expanded(child: _buildCustomersList(customers, canAdd)),
                    _buildPaginationControls(),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildErrorWidget(error.toString()),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: canAdd ? FloatingActionButton(
        onPressed: () => context.go('/customers/new'),
        child: const Icon(Icons.add),
        tooltip: 'Add Customer',
      ) : null,
    );
  }

  Widget _buildSearchSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search customers by name, phone, or email...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: _onSearchChanged,
        ),
      ),
    );
  }

  void _onSearchChanged(String value) {
    // Cancel the previous timer
    _debounceTimer?.cancel();
    
    // Start a new timer
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = value;
      });
      _performSearch();
    });
  }

  void _performSearch() {
    setState(() {
      _currentPage = 1; // Reset to first page on new search
    });
    final filters = CustomerSearchFilters(
      query: _searchQuery.isNotEmpty ? _searchQuery : null,
      page: _currentPage,
      limit: _pageSize,
    );
    ref.read(customerSearchFiltersProvider.notifier).state = filters;
  }

  Widget _buildCustomersList(List<Customer> customers, bool canEdit) {
    if (customers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.people_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? 'No customers found' : 'No customers yet',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'Try a different search term'
                  : 'Tap the + button to add a new customer',
              style: const TextStyle(color: Colors.grey),
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
        return _buildCustomerCard(customer, canEdit);
      },
    );
  }

  Widget _buildCustomerCard(Customer customer, bool canEdit) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
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
        trailing: canEdit ? PopupMenuButton<String>(
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
            if (ref.read(authProvider).user?.role == 'admin')
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
          ],
        ) : IconButton(
          icon: const Icon(Icons.visibility),
          onPressed: () => context.go('/customers/${customer.id}'),
          tooltip: 'View Customer',
        ),
        onTap: () => context.go('/customers/${customer.id}'),
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

  void _handleCustomerAction(String action, Customer customer) {
    switch (action) {
      case 'view':
        context.go('/customers/${customer.id}');
        break;
      case 'edit':
        context.go('/customers/${customer.id}/edit');
        break;
      case 'vehicles':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicles view coming soon')),
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

  Widget _buildPaginationControls() {
    // Note: This is a simplified pagination UI. 
    // In a real implementation, you'd get total count from the API response
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: _currentPage > 1 ? _goToPreviousPage : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Previous'),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Page $_currentPage',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: _goToNextPage,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Next'),
          ),
        ],
      ),
    );
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      _updateFilters();
    }
  }

  void _goToNextPage() {
    setState(() {
      _currentPage++;
    });
    _updateFilters();
  }

  void _updateFilters() {
    final filters = CustomerSearchFilters(
      query: _searchQuery.isNotEmpty ? _searchQuery : null,
      page: _currentPage,
      limit: _pageSize,
    );
    ref.read(customerSearchFiltersProvider.notifier).state = filters;
  }
}