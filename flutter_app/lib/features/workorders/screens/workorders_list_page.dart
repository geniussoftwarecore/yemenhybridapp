import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workorder.dart';
import '../providers/workorder_provider.dart';
import 'workorder_create_page.dart';
import 'workorder_details_page.dart';

class WorkOrdersListPage extends ConsumerStatefulWidget {
  const WorkOrdersListPage({super.key});

  @override
  ConsumerState<WorkOrdersListPage> createState() => _WorkOrdersListPageState();
}

class _WorkOrdersListPageState extends ConsumerState<WorkOrdersListPage> {
  WorkOrderStatus? _selectedStatus;
  String _searchQuery = '';
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  Widget build(BuildContext context) {
    final workOrdersAsync = ref.watch(workOrderListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToCreate(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filters
          _buildSearchAndFilters(),
          // Work orders list
          Expanded(
            child: workOrdersAsync.when(
              data: (workOrders) => _buildWorkOrdersList(workOrders),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorWidget(error),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreate(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search work orders...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _applyFilters();
            },
          ),
          const SizedBox(height: 8),
          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusChip(null, 'All'),
                ...WorkOrderStatus.values.map((status) => 
                  _buildStatusChip(status, status.displayName),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(WorkOrderStatus? status, String label) {
    final isSelected = _selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedStatus = selected ? status : null;
          });
          _applyFilters();
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.3),
      ),
    );
  }

  Widget _buildWorkOrdersList(List<WorkOrder> workOrders) {
    if (workOrders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No work orders found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Create your first work order',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(workOrderListProvider);
      },
      child: ListView.builder(
        itemCount: workOrders.length,
        itemBuilder: (context, index) {
          final workOrder = workOrders[index];
          return _buildWorkOrderCard(workOrder);
        },
      ),
    );
  }

  Widget _buildWorkOrderCard(WorkOrder workOrder) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(workOrder.status),
          child: Icon(
            _getStatusIcon(workOrder.status),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          'WO-${workOrder.id?.toString().padLeft(4, '0') ?? 'NEW'}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(workOrder.complaint ?? 'No complaint specified'),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildStatusChipSmall(workOrder.status),
                const SizedBox(width: 8),
                if (workOrder.estTotal != null)
                  Text(
                    '\$${workOrder.estTotal!.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
              ],
            ),
            if (workOrder.scheduledAt != null)
              Text(
                'Scheduled: ${_formatDate(workOrder.scheduledAt!)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _navigateToDetails(workOrder),
      ),
    );
  }

  Widget _buildStatusChipSmall(WorkOrderStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 12,
          color: _getStatusColor(status),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildErrorWidget(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading work orders',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.refresh(workOrderListProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(WorkOrderStatus status) {
    switch (status) {
      case WorkOrderStatus.newOrder:
        return Colors.blue;
      case WorkOrderStatus.awaitingApproval:
        return Colors.orange;
      case WorkOrderStatus.readyToStart:
        return Colors.purple;
      case WorkOrderStatus.inProgress:
        return Colors.green;
      case WorkOrderStatus.done:
        return Colors.teal;
      case WorkOrderStatus.closed:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(WorkOrderStatus status) {
    switch (status) {
      case WorkOrderStatus.newOrder:
        return Icons.new_label;
      case WorkOrderStatus.awaitingApproval:
        return Icons.pending;
      case WorkOrderStatus.readyToStart:
        return Icons.play_circle;
      case WorkOrderStatus.inProgress:
        return Icons.build;
      case WorkOrderStatus.done:
        return Icons.check_circle;
      case WorkOrderStatus.closed:
        return Icons.archive;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _applyFilters() {
    // Update the filter provider
    ref.read(workOrderSearchFiltersProvider.notifier).state = WorkOrderSearchFilters(
      query: _searchQuery.isEmpty ? null : _searchQuery,
      status: _selectedStatus,
      dateFrom: _dateFrom,
      dateTo: _dateTo,
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Work Orders'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Date range filters
            ListTile(
              title: const Text('Date From'),
              subtitle: Text(_dateFrom?.toString().split(' ')[0] ?? 'Not set'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dateFrom ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() {
                    _dateFrom = date;
                  });
                }
              },
            ),
            ListTile(
              title: const Text('Date To'),
              subtitle: Text(_dateTo?.toString().split(' ')[0] ?? 'Not set'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dateTo ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() {
                    _dateTo = date;
                  });
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _dateFrom = null;
                _dateTo = null;
              });
              Navigator.of(context).pop();
              _applyFilters();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _applyFilters();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _navigateToCreate() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const WorkOrderCreatePage(),
      ),
    );
  }

  void _navigateToDetails(WorkOrder workOrder) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WorkOrderDetailsPage(workOrderId: workOrder.id!),
      ),
    );
  }
}