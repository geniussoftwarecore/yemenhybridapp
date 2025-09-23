import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workorder.dart';
import '../providers/workorder_provider.dart';
import '../../customers/providers/customer_provider.dart';
import '../../vehicles/providers/vehicle_provider.dart';

class WorkOrderDetailsPage extends ConsumerStatefulWidget {
  final int workOrderId;

  const WorkOrderDetailsPage({
    super.key,
    required this.workOrderId,
  });

  @override
  ConsumerState<WorkOrderDetailsPage> createState() => _WorkOrderDetailsPageState();
}

class _WorkOrderDetailsPageState extends ConsumerState<WorkOrderDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workOrderAsync = ref.watch(workOrderProvider(widget.workOrderId));

    return Scaffold(
      body: workOrderAsync.when(
        data: (workOrder) => _buildWorkOrderDetails(workOrder),
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => Scaffold(
          appBar: AppBar(title: const Text('Work Order Details')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading work order',
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
                  onPressed: () => ref.refresh(workOrderProvider(widget.workOrderId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkOrderDetails(WorkOrder workOrder) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WO-${workOrder.id?.toString().padLeft(4, '0') ?? 'NEW'}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.info), text: 'Summary'),
            Tab(icon: Icon(Icons.list), text: 'Items'),
            Tab(icon: Icon(Icons.photo_library), text: 'Media'),
            Tab(icon: Icon(Icons.timeline), text: 'Timeline'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleAction(value, workOrder),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'duplicate',
                child: ListTile(
                  leading: Icon(Icons.copy),
                  title: Text('Duplicate'),
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
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSummaryTab(workOrder),
          _buildItemsTab(workOrder),
          _buildMediaTab(workOrder),
          _buildTimelineTab(workOrder),
        ],
      ),
    );
  }

  Widget _buildSummaryTab(WorkOrder workOrder) {
    final customerAsync = ref.watch(customerProvider(workOrder.customerId));
    final vehicleAsync = ref.watch(vehicleProvider(workOrder.vehicleId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status and Actions Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildStatusChip(workOrder.status),
                      const Spacer(),
                      if (workOrder.estTotal != null)
                        Text(
                          '\$${workOrder.estTotal!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildActionButtons(workOrder),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Customer Information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.person, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Customer Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  customerAsync.when(
                    data: (customer) => Column(
                      children: [
                        _buildInfoRow('Name', customer.name),
                        if (customer.phone != null) _buildInfoRow('Phone', customer.phone!),
                        if (customer.email != null) _buildInfoRow('Email', customer.email!),
                      ],
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (error, _) => Text('Error loading customer: $error'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Vehicle Information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.directions_car, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Vehicle Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  vehicleAsync.when(
                    data: (vehicle) => Column(
                      children: [
                        _buildInfoRow('Make & Model', '${vehicle.make} ${vehicle.model}'),
                        _buildInfoRow('License Plate', vehicle.plate),
                        if (vehicle.year != null) _buildInfoRow('Year', vehicle.year!.toString()),
                        if (vehicle.color != null) _buildInfoRow('Color', vehicle.color!),
                        if (vehicle.vin != null) _buildInfoRow('VIN', vehicle.vin!),
                      ],
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (error, _) => Text('Error loading vehicle: $error'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Work Order Details
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.assignment, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        'Work Order Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Complaint', workOrder.complaint ?? 'No complaint specified'),
                  if (workOrder.notes != null) _buildInfoRow('Notes', workOrder.notes!),
                  if (workOrder.scheduledAt != null)
                    _buildInfoRow('Scheduled', _formatDateTime(workOrder.scheduledAt!)),
                  if (workOrder.startedAt != null)
                    _buildInfoRow('Started', _formatDateTime(workOrder.startedAt!)),
                  if (workOrder.completedAt != null)
                    _buildInfoRow('Completed', _formatDateTime(workOrder.completedAt!)),
                  _buildInfoRow('Created', _formatDateTime(workOrder.createdAt!)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Estimates
          if (workOrder.estParts != null || workOrder.estLabor != null || workOrder.estTotal != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.calculate, color: Colors.purple),
                        SizedBox(width: 8),
                        Text(
                          'Estimate',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (workOrder.estParts != null)
                      _buildInfoRow('Parts', '\$${workOrder.estParts!.toStringAsFixed(2)}'),
                    if (workOrder.estLabor != null)
                      _buildInfoRow('Labor', '\$${workOrder.estLabor!.toStringAsFixed(2)}'),
                    if (workOrder.estTotal != null)
                      _buildInfoRow('Total', '\$${workOrder.estTotal!.toStringAsFixed(2)}', isTotal: true),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemsTab(WorkOrder workOrder) {
    return Column(
      children: [
        // Add Item Button
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _showAddItemDialog(workOrder),
            icon: const Icon(Icons.add),
            label: const Text('Add Item'),
          ),
        ),
        // Items List
        Expanded(
          child: workOrder.items?.isNotEmpty == true
              ? ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: workOrder.items!.length,
                  itemBuilder: (context, index) {
                    final item = workOrder.items![index];
                    return _buildItemCard(item, workOrder);
                  },
                )
              : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No items added yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add parts or labor items to this work order',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildMediaTab(WorkOrder workOrder) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Media Gallery',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Upload photos for before, during, and after',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTab(WorkOrder workOrder) {
    // Fake timeline data for now
    final timelineEvents = [
      _TimelineEvent(
        title: 'Work Order Created',
        description: 'Work order was created by user',
        timestamp: workOrder.createdAt!,
        icon: Icons.add_task,
        color: Colors.blue,
      ),
      if (workOrder.startedAt != null)
        _TimelineEvent(
          title: 'Work Started',
          description: 'Work order was started',
          timestamp: workOrder.startedAt!,
          icon: Icons.play_arrow,
          color: Colors.green,
        ),
      if (workOrder.completedAt != null)
        _TimelineEvent(
          title: 'Work Completed',
          description: 'Work order was completed',
          timestamp: workOrder.completedAt!,
          icon: Icons.check_circle,
          color: Colors.teal,
        ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: timelineEvents.length,
      itemBuilder: (context, index) {
        final event = timelineEvents[index];
        final isLast = index == timelineEvents.length - 1;
        
        return _buildTimelineItem(event, isLast);
      },
    );
  }

  Widget _buildStatusChip(WorkOrderStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: _getStatusColor(status),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButtons(WorkOrder workOrder) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (workOrder.status == WorkOrderStatus.newOrder) ...[
          ElevatedButton.icon(
            onPressed: () => _requestApproval(workOrder),
            icon: const Icon(Icons.approval, size: 16),
            label: const Text('Request Approval'),
          ),
        ],
        if (workOrder.status == WorkOrderStatus.readyToStart)
          ElevatedButton.icon(
            onPressed: () => _startWorkOrder(workOrder),
            icon: const Icon(Icons.play_arrow, size: 16),
            label: const Text('Start Work'),
          ),
        if (workOrder.status == WorkOrderStatus.inProgress)
          ElevatedButton.icon(
            onPressed: () => _finishWorkOrder(workOrder),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Finish Work'),
          ),
        if (workOrder.status == WorkOrderStatus.done)
          ElevatedButton.icon(
            onPressed: () => _closeWorkOrder(workOrder),
            icon: const Icon(Icons.archive, size: 16),
            label: const Text('Close'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
          ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: isTotal ? 16 : 14,
                color: isTotal ? Colors.green : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(WorkOrderItem item, WorkOrder workOrder) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: item.itemType == ItemType.part ? Colors.blue : Colors.green,
          child: Icon(
            item.itemType == ItemType.part ? Icons.build : Icons.engineering,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(item.name),
        subtitle: Text(
          '${item.itemType.displayName} • Qty: ${item.qty} • Unit: \$${item.unitPrice.toStringAsFixed(2)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\$${item.total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteItem(item, workOrder);
                }
              },
              itemBuilder: (context) => [
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
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(_TimelineEvent event, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: event.color,
              child: Icon(event.icon, color: Colors.white, size: 16),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                event.description,
                style: TextStyle(color: Colors.grey[600]),
              ),
              Text(
                _formatDateTime(event.timestamp),
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _handleAction(String action, WorkOrder workOrder) {
    switch (action) {
      case 'edit':
        // TODO: Navigate to edit page
        break;
      case 'duplicate':
        // TODO: Duplicate work order
        break;
      case 'delete':
        _showDeleteConfirmation(workOrder);
        break;
    }
  }

  void _showDeleteConfirmation(WorkOrder workOrder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Work Order'),
        content: Text('Are you sure you want to delete work order #${workOrder.id}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteWorkOrder(workOrder);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(WorkOrder workOrder) {
    final nameController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    final priceController = TextEditingController();
    ItemType selectedType = ItemType.part;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Item'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<ItemType>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: ItemType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtyController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: 'Unit Price',
                        border: OutlineInputBorder(),
                        prefixText: '\$',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && 
                  qtyController.text.isNotEmpty && 
                  priceController.text.isNotEmpty) {
                Navigator.of(context).pop();
                await _addItem(workOrder, selectedType, nameController.text, 
                    double.parse(qtyController.text), double.parse(priceController.text));
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestApproval(WorkOrder workOrder) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(workOrderNotifierProvider.notifier).requestApproval(workOrder.id!);
      _showSnackBar('Approval requested successfully', Colors.green);
      ref.refresh(workOrderProvider(widget.workOrderId));
    } catch (e) {
      _showSnackBar('Error requesting approval: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startWorkOrder(WorkOrder workOrder) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(workOrderNotifierProvider.notifier).startWorkOrder(workOrder.id!);
      _showSnackBar('Work order started', Colors.green);
      ref.refresh(workOrderProvider(widget.workOrderId));
    } catch (e) {
      _showSnackBar('Error starting work order: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _finishWorkOrder(WorkOrder workOrder) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(workOrderNotifierProvider.notifier).finishWorkOrder(workOrder.id!);
      _showSnackBar('Work order finished', Colors.green);
      ref.refresh(workOrderProvider(widget.workOrderId));
    } catch (e) {
      _showSnackBar('Error finishing work order: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _closeWorkOrder(WorkOrder workOrder) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(workOrderNotifierProvider.notifier).closeWorkOrder(workOrder.id!);
      _showSnackBar('Work order closed', Colors.green);
      ref.refresh(workOrderProvider(widget.workOrderId));
    } catch (e) {
      _showSnackBar('Error closing work order: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteWorkOrder(WorkOrder workOrder) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(workOrderNotifierProvider.notifier).deleteWorkOrder(workOrder.id!);
      _showSnackBar('Work order deleted', Colors.green);
      Navigator.of(context).pop(); // Go back to list
    } catch (e) {
      _showSnackBar('Error deleting work order: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addItem(WorkOrder workOrder, ItemType type, String name, double qty, double price) async {
    setState(() => _isLoading = true);
    try {
      final item = WorkOrderItem(
        itemType: type,
        name: name,
        qty: qty,
        unitPrice: price,
      );
      // TODO: Add item to work order via API
      _showSnackBar('Item added successfully', Colors.green);
      ref.refresh(workOrderProvider(widget.workOrderId));
    } catch (e) {
      _showSnackBar('Error adding item: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteItem(WorkOrderItem item, WorkOrder workOrder) async {
    setState(() => _isLoading = true);
    try {
      // TODO: Delete item via API
      _showSnackBar('Item deleted successfully', Colors.green);
      ref.refresh(workOrderProvider(widget.workOrderId));
    } catch (e) {
      _showSnackBar('Error deleting item: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }
}

class _TimelineEvent {
  final String title;
  final String description;
  final DateTime timestamp;
  final IconData icon;
  final Color color;

  _TimelineEvent({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.icon,
    required this.color,
  });
}