import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/metric_card.dart';
import '../widgets/data_table_widget.dart';
import '../widgets/quick_action_button.dart';

class EngineerDashboard extends ConsumerStatefulWidget {
  const EngineerDashboard({super.key});

  @override
  ConsumerState<EngineerDashboard> createState() => _EngineerDashboardState();
}

class _EngineerDashboardState extends ConsumerState<EngineerDashboard> {
  bool _isLoading = false;
  bool _isTableLoading = false;
  int _currentPage = 1;
  final int _totalPages = 3;
  String _searchQuery = '';

  // Sample data - replace with actual data from providers
  final List<Map<String, dynamic>> _workOrders = [
    {
      'id': 'WO-001',
      'status': 'In Progress',
      'plate': 'ABC-123',
      'make_model': 'Toyota Camry',
      'scheduled_at': '2025-09-21 14:00',
    },
    {
      'id': 'WO-002', 
      'status': 'Pending',
      'plate': 'DEF-456',
      'make_model': 'Honda Civic',
      'scheduled_at': '2025-09-22 09:30',
    },
    {
      'id': 'WO-003',
      'status': 'Waiting Parts',
      'plate': 'GHI-789',
      'make_model': 'BMW X5',
      'scheduled_at': '2025-09-23 11:00',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.engineerDashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${l10n.welcome}, ${authState.user?.name ?? ''}!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              
              // Metric Cards
              _buildMetricCards(),
              const SizedBox(height: 24),
              
              // Quick Actions
              _buildQuickActions(),
              const SizedBox(height: 24),
              
              // Work Orders Table
              _buildWorkOrdersTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.9,
      children: [
        MetricCard(
          title: 'My Open WOs',
          value: '8',
          icon: Icons.build_circle,
          color: Colors.blue,
          subtitle: '+2 from yesterday',
          isLoading: _isLoading,
          onTap: () {
            // Navigate to my work orders
          },
        ),
        MetricCard(
          title: 'Awaiting Approval',
          value: '3',
          icon: Icons.pending_actions,
          color: Colors.orange,
          subtitle: 'Pending review',
          isLoading: _isLoading,
          onTap: () {
            // Navigate to pending approvals
          },
        ),
        MetricCard(
          title: 'In Progress',
          value: '5',
          icon: Icons.work,
          color: Colors.green,
          subtitle: 'Active jobs',
          isLoading: _isLoading,
          onTap: () {
            // Navigate to in-progress work orders
          },
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return QuickActionsSection(
      title: 'Quick Actions',
      actions: [
        QuickActionButton(
          title: 'Create Work Order',
          icon: Icons.add_box,
          color: Colors.blue,
          onPressed: () {
            _showCreateWorkOrderDialog();
          },
        ),
        QuickActionButton(
          title: 'Upload BEFORE Photos',
          icon: Icons.camera_alt,
          color: Colors.green,
          onPressed: () {
            _uploadPhotos('BEFORE');
          },
        ),
        QuickActionButton(
          title: 'Upload DURING Photos',
          icon: Icons.photo_camera,
          color: Colors.orange,
          onPressed: () {
            _uploadPhotos('DURING');
          },
        ),
        QuickActionButton(
          title: 'Upload AFTER Photos',
          icon: Icons.camera_enhance,
          color: Colors.purple,
          onPressed: () {
            _uploadPhotos('AFTER');
          },
        ),
      ],
    );
  }

  Widget _buildWorkOrdersTable() {
    final filteredWorkOrders = _workOrders.where((wo) {
      if (_searchQuery.isEmpty) return true;
      return wo['plate'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
             wo['make_model'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
             wo['status'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return DataTableWidget<Map<String, dynamic>>(
      title: 'Assigned Work Orders',
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Plate')),
        DataColumn(label: Text('Make/Model')),
        DataColumn(label: Text('Scheduled')),
        DataColumn(label: Text('Actions')),
      ],
      data: filteredWorkOrders,
      isLoading: _isTableLoading,
      currentPage: _currentPage,
      totalPages: _totalPages,
      onRefresh: _handleTableRefresh,
      onSearch: (query) {
        setState(() {
          _searchQuery = query;
        });
      },
      onPageChanged: (page) {
        setState(() {
          _currentPage = page;
          _loadWorkOrders();
        });
      },
      searchHint: 'Search by plate, make/model, or status...',
      rowBuilder: (workOrder) {
        return DataRow(
          cells: [
            DataCell(Text(workOrder['id'])),
            DataCell(_buildStatusChip(workOrder['status'])),
            DataCell(Text(workOrder['plate'])),
            DataCell(Text(workOrder['make_model'])),
            DataCell(Text(workOrder['scheduled_at'])),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _editWorkOrder(workOrder['id']),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.visibility, size: 20),
                    onPressed: () => _viewWorkOrder(workOrder['id']),
                    tooltip: 'View',
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'in progress':
        color = Colors.blue;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'waiting parts':
        color = Colors.red;
        break;
      case 'completed':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        status,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: color,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isLoading = true;
    });
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _handleTableRefresh() async {
    setState(() {
      _isTableLoading = true;
    });
    
    await _loadWorkOrders();
    
    setState(() {
      _isTableLoading = false;
    });
  }

  Future<void> _loadWorkOrders() async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));
    // Load work orders from API based on current page
  }

  void _showCreateWorkOrderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Work Order'),
        content: const Text('Create work order functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement create work order logic
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _uploadPhotos(String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upload $type Photos'),
        content: Text('Photo upload for $type stage will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement photo upload logic
            },
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }

  void _editWorkOrder(String id) {
    // Navigate to edit work order screen
    print('Edit work order: $id');
  }

  void _viewWorkOrder(String id) {
    // Navigate to view work order screen
    print('View work order: $id');
  }
}