import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/i18n/app_localizations.dart';
import 'services/workorder_api_service.dart';
import 'models/workorder.dart';
import 'providers/workorder_provider.dart';
import '../customers/providers/customer_provider.dart';
import '../vehicles/providers/vehicle_provider.dart';

class WorkOrdersScreen extends ConsumerStatefulWidget {
  const WorkOrdersScreen({super.key});

  @override
  ConsumerState<WorkOrdersScreen> createState() => _WorkOrdersScreenState();
}

class _WorkOrdersScreenState extends ConsumerState<WorkOrdersScreen> {
  final _searchController = TextEditingController();
  WorkOrderStatus? _selectedStatus;
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final workOrdersAsync = ref.watch(workOrderListProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.workOrders),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateWorkOrderDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search work orders...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _performSearch();
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => _performSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                if (_selectedStatus != null)
                  Chip(
                    label: Text(_selectedStatus!.displayName),
                    onDeleted: () {
                      setState(() {
                        _selectedStatus = null;
                      });
                      _performSearch();
                    },
                    backgroundColor: _getStatusColor(_selectedStatus!).withOpacity(0.2),
                  ),
              ],
            ),
          ),
          // Work Orders List
          Expanded(
            child: workOrdersAsync.when(
              data: (workOrders) {
                if (workOrders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No work orders found',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first work order to get started',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _showCreateWorkOrderDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Create Work Order'),
                        ),
                      ],
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(workOrderListProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: workOrders.length,
                    itemBuilder: (context, index) {
                      final workOrder = workOrders[index];
                      return _WorkOrderCard(
                        workOrder: workOrder,
                        onTap: () => _showWorkOrderDetails(workOrder),
                        onRequestApproval: () => _requestApproval(workOrder),
                        onSendToCustomer: () => _sendToCustomer(workOrder),
                        onUploadMedia: () => _uploadMedia(workOrder),
                        onViewGallery: () => _viewGallery(workOrder),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading work orders',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.red[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.red[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(workOrderListProvider);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _performSearch() {
    // TODO: Implement search functionality with the provider
    ref.invalidate(workOrderListProvider);
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Work Orders'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<WorkOrderStatus>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: WorkOrderStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status.displayName),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedStatus = null;
              });
              Navigator.of(context).pop();
              _performSearch();
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performSearch();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showCreateWorkOrderDialog() {
    // Navigate to work order form
    // context.push('/workorders/create');
    
    // For now, show a simple dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Work Order'),
        content: const Text('Work order creation form will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showWorkOrderDetails(WorkOrder workOrder) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _WorkOrderDetailsSheet(workOrder: workOrder),
    );
  }

  Future<void> _requestApproval(WorkOrder workOrder) async {
    if (workOrder.id == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ref.read(workOrderApiServiceProvider);
      await apiService.requestApproval(workOrder.id!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Approval requested for work order #${workOrder.id}'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(workOrderListProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting approval: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendToCustomer(WorkOrder workOrder) async {
    if (workOrder.id == null) return;

    // Show channel selection dialog
    final channel = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send to Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose how to send the approval request:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              onTap: () => Navigator.of(context).pop('email'),
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('WhatsApp'),
              onTap: () => Navigator.of(context).pop('whatsapp'),
            ),
            ListTile(
              leading: const Icon(Icons.sms),
              title: const Text('SMS'),
              onTap: () => Navigator.of(context).pop('sms'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (channel == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ref.read(workOrderApiServiceProvider);
      final response = await apiService.sendToCustomer(workOrder.id!, channel: channel);
      
      // Get the public approval link
      final approvalLink = await apiService.getPublicApprovalLink(workOrder.id!);
      
      if (mounted) {
        // Show toast notification with the link
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Approval link sent via ${channel.toUpperCase()}'),
                const SizedBox(height: 4),
                Text('Link: $approvalLink', style: const TextStyle(fontSize: 12)),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Copy Link',
              onPressed: () {
                // Copy to clipboard
                print('Copy to clipboard: $approvalLink');
              },
            ),
          ),
        );
        
        // Also log to developer console as requested
        print('=== APPROVAL LINK SENT ===');
        print('Work Order ID: ${workOrder.id}');
        print('Channel: ${channel.toUpperCase()}');
        print('Approval Link: $approvalLink');
        print('Response: ${response.toJson()}');
        print('=========================');
        
        ref.invalidate(workOrderListProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending to customer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadMedia(WorkOrder workOrder) async {
    if (workOrder.id == null) return;

    // Show phase selection and file picker
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _MediaUploadDialog(),
    );

    if (result == null) return;
    
    final String phase = result['phase'];
    final String? note = result['note'];

    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _isLoading = true;
        });

        final file = result.files.first;
        final apiService = ref.read(workOrderApiServiceProvider);
        
        // For web, we'll use the file bytes and name
        final response = await apiService.uploadMedia(
          workOrder.id!,
          file.path ?? file.name, // Use name as fallback for web
          phase,
          note: note,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Media uploaded successfully to ${phase.toUpperCase()} gallery'),
              backgroundColor: Colors.green,
            ),
          );
          ref.invalidate(workOrderListProvider);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading media: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _viewGallery(WorkOrder workOrder) {
    if (workOrder.id == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _MediaGallerySheet(workOrderId: workOrder.id!),
    );
  }

  Color _getStatusColor(WorkOrderStatus status) {
    switch (status) {
      case WorkOrderStatus.pending:
        return Colors.orange;
      case WorkOrderStatus.inProgress:
        return Colors.blue;
      case WorkOrderStatus.waitingParts:
        return Colors.amber;
      case WorkOrderStatus.waitingApproval:
        return Colors.purple;
      case WorkOrderStatus.waitingCustomer:
        return Colors.indigo;
      case WorkOrderStatus.completed:
        return Colors.green;
      case WorkOrderStatus.cancelled:
        return Colors.red;
      case WorkOrderStatus.invoiced:
        return Colors.teal;
    }
  }
}

class _WorkOrderCard extends StatelessWidget {
  final WorkOrder workOrder;
  final VoidCallback onTap;
  final VoidCallback onRequestApproval;
  final VoidCallback onSendToCustomer;
  final VoidCallback onUploadMedia;
  final VoidCallback onViewGallery;

  const _WorkOrderCard({
    required this.workOrder,
    required this.onTap,
    required this.onRequestApproval,
    required this.onSendToCustomer,
    required this.onUploadMedia,
    required this.onViewGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Work Order #${workOrder.id}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (workOrder.customer != null)
                          Text(
                            workOrder.customer!.name,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        if (workOrder.vehicle != null)
                          Text(
                            '${workOrder.vehicle!.make} ${workOrder.vehicle!.model} (${workOrder.vehicle!.plate})',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                      ],
                    ),
                  ),
                  _StatusChip(status: workOrder.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                workOrder.complaint,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Created: ${_formatDate(workOrder.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                  const Spacer(),
                  if (workOrder.estimate != null) ...[
                    Icon(
                      Icons.attach_money,
                      size: 16,
                      color: Colors.green[600],
                    ),
                    Text(
                      '\$${workOrder.estimate!.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              // Action buttons based on status
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    switch (workOrder.status) {
      case WorkOrderStatus.pending:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onUploadMedia,
                icon: const Icon(Icons.camera_alt, size: 16),
                label: const Text('Upload'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onRequestApproval,
                icon: const Icon(Icons.approval, size: 16),
                label: const Text('Request Approval'),
              ),
            ),
          ],
        );
      case WorkOrderStatus.waitingApproval:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onViewGallery,
                icon: const Icon(Icons.photo_library, size: 16),
                label: const Text('Gallery'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onSendToCustomer,
                icon: const Icon(Icons.send, size: 16),
                label: const Text('Send to Customer'),
              ),
            ),
          ],
        );
      default:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onUploadMedia,
                icon: const Icon(Icons.camera_alt, size: 16),
                label: const Text('Upload'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onViewGallery,
                icon: const Icon(Icons.photo_library, size: 16),
                label: const Text('Gallery'),
              ),
            ),
          ],
        );
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _StatusChip extends StatelessWidget {
  final WorkOrderStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case WorkOrderStatus.pending:
        color = Colors.orange;
        break;
      case WorkOrderStatus.inProgress:
        color = Colors.blue;
        break;
      case WorkOrderStatus.waitingParts:
        color = Colors.amber;
        break;
      case WorkOrderStatus.waitingApproval:
        color = Colors.purple;
        break;
      case WorkOrderStatus.waitingCustomer:
        color = Colors.indigo;
        break;
      case WorkOrderStatus.completed:
        color = Colors.green;
        break;
      case WorkOrderStatus.cancelled:
        color = Colors.red;
        break;
      case WorkOrderStatus.invoiced:
        color = Colors.teal;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _WorkOrderDetailsSheet extends StatelessWidget {
  final WorkOrder workOrder;

  const _WorkOrderDetailsSheet({required this.workOrder});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            color: Colors.white,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Work Order #${workOrder.id}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Customer and Vehicle Info
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customer & Vehicle',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (workOrder.customer != null) ...[
                              Text('Customer: ${workOrder.customer!.name}'),
                              if (workOrder.customer!.phone != null)
                                Text('Phone: ${workOrder.customer!.phone}'),
                            ],
                            if (workOrder.vehicle != null) ...[
                              const SizedBox(height: 8),
                              Text('Vehicle: ${workOrder.vehicle!.make} ${workOrder.vehicle!.model}'),
                              Text('Plate: ${workOrder.vehicle!.plate}'),
                            ],
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
                            Text(
                              'Work Order Details',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Complaint: ${workOrder.complaint}'),
                            if (workOrder.diagnosis != null) ...[
                              const SizedBox(height: 4),
                              Text('Diagnosis: ${workOrder.diagnosis}'),
                            ],
                            if (workOrder.notes != null) ...[
                              const SizedBox(height: 4),
                              Text('Notes: ${workOrder.notes}'),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text('Status: '),
                                _StatusChip(status: workOrder.status),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (workOrder.estimate != null) ...[
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Estimate',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '\$${workOrder.estimate!.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.green[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MediaUploadDialog extends StatefulWidget {
  @override
  _MediaUploadDialogState createState() => _MediaUploadDialogState();
}

class _MediaUploadDialogState extends State<_MediaUploadDialog> {
  String _selectedPhase = 'before';
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upload Media'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedPhase,
            decoration: const InputDecoration(
              labelText: 'Phase',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'before', child: Text('BEFORE')),
              DropdownMenuItem(value: 'during', child: Text('DURING')),
              DropdownMenuItem(value: 'after', child: Text('AFTER')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedPhase = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              border: OutlineInputBorder(),
              hintText: 'Add a note about this media...',
            ),
            maxLines: 2,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop({
              'phase': _selectedPhase,
              'note': _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
            });
          },
          child: const Text('Select Photo'),
        ),
      ],
    );
  }
}

class _MediaGallerySheet extends ConsumerWidget {
  final int workOrderId;

  const _MediaGallerySheet({required this.workOrderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            color: Colors.white,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Media Gallery',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      const TabBar(
                        tabs: [
                          Tab(text: 'BEFORE'),
                          Tab(text: 'DURING'),
                          Tab(text: 'AFTER'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildPhaseGallery(ref, 'before'),
                            _buildPhaseGallery(ref, 'during'),
                            _buildPhaseGallery(ref, 'after'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhaseGallery(WidgetRef ref, String phase) {
    return FutureBuilder(
      future: ref.read(workOrderApiServiceProvider).getWorkOrderMedia(workOrderId, phase: phase),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 48, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text('Error loading ${phase.toUpperCase()} media'),
                Text(snapshot.error.toString()),
              ],
            ),
          );
        }
        
        final mediaList = snapshot.data ?? [];
        
        if (mediaList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('No ${phase.toUpperCase()} photos yet'),
                const Text('Upload photos to see them here'),
              ],
            ),
          );
        }
        
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemCount: mediaList.length,
          itemBuilder: (context, index) {
            final media = mediaList[index];
            return Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.image,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      // TODO: Implement actual image loading
                      // child: Image.network(
                      //   media.url,
                      //   fit: BoxFit.cover,
                      //   errorBuilder: (context, error, stackTrace) {
                      //     return Icon(
                      //       Icons.broken_image,
                      //       size: 48,
                      //       color: Colors.grey[400],
                      //     );
                      //   },
                      // ),
                    ),
                  ),
                  if (media.note != null && media.note!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        media.note!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}