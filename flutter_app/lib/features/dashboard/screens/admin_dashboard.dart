import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/metric_card.dart';
import '../widgets/data_table_widget.dart';
import '../widgets/chart_widget.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  bool _isLoading = false;
  bool _isChartsLoading = false;
  bool _isWorkOrdersLoading = false;
  bool _isInvoicesLoading = false;
  int _workOrdersPage = 1;
  int _invoicesPage = 1;
  final int _totalPages = 3;
  String _workOrdersSearch = '';
  String _invoicesSearch = '';

  // Sample data - replace with actual data from providers
  final List<Map<String, dynamic>> _recentWorkOrders = [
    {
      'id': 'WO-001',
      'customer': 'Ahmed Ali',
      'vehicle': 'Toyota Camry',
      'status': 'In Progress',
      'assigned_to': 'Engineer 1',
      'created_at': '2025-09-21',
      'amount': '\$1,250',
    },
    {
      'id': 'WO-002',
      'customer': 'Sarah Mohammed',
      'vehicle': 'Honda Civic',
      'status': 'Completed',
      'assigned_to': 'Engineer 2',
      'created_at': '2025-09-20',
      'amount': '\$890',
    },
    {
      'id': 'WO-003',
      'customer': 'Mohammed Hassan',
      'vehicle': 'BMW X5',
      'status': 'Pending',
      'assigned_to': 'Engineer 1',
      'created_at': '2025-09-19',
      'amount': '\$2,100',
    },
  ];

  final List<Map<String, dynamic>> _recentInvoices = [
    {
      'id': 'INV-001',
      'customer': 'Ahmed Ali',
      'amount': '\$1,250',
      'status': 'Paid',
      'created_at': '2025-09-21',
      'due_date': '2025-10-21',
    },
    {
      'id': 'INV-002',
      'customer': 'Sarah Mohammed',
      'amount': '\$890',
      'status': 'Pending',
      'created_at': '2025-09-20',
      'due_date': '2025-10-20',
    },
    {
      'id': 'INV-003',
      'customer': 'Mohammed Hassan',
      'amount': '\$2,100',
      'status': 'Overdue',
      'created_at': '2025-09-15',
      'due_date': '2025-10-15',
    },
  ];

  // Chart data
  final List<FlSpot> _revenueData = [
    const FlSpot(1, 15),
    const FlSpot(2, 20),
    const FlSpot(3, 18),
    const FlSpot(4, 25),
    const FlSpot(5, 30),
    const FlSpot(6, 28),
    const FlSpot(7, 35),
    const FlSpot(8, 40),
    const FlSpot(9, 38),
    const FlSpot(10, 45),
    const FlSpot(11, 42),
    const FlSpot(12, 50),
    const FlSpot(13, 48),
    const FlSpot(14, 55),
    const FlSpot(15, 52),
    const FlSpot(16, 60),
    const FlSpot(17, 58),
    const FlSpot(18, 65),
    const FlSpot(19, 62),
    const FlSpot(20, 70),
    const FlSpot(21, 68),
    const FlSpot(22, 75),
    const FlSpot(23, 72),
    const FlSpot(24, 80),
    const FlSpot(25, 78),
    const FlSpot(26, 85),
    const FlSpot(27, 82),
    const FlSpot(28, 90),
    const FlSpot(29, 88),
    const FlSpot(30, 95),
  ];

  final Map<String, double> _workOrderStatusData = {
    'In Progress': 12,
    'Pending': 8,
    'Completed': 25,
    'Waiting Parts': 5,
    'Cancelled': 2,
  };

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminDashboard),
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
              
              // KPI Cards
              _buildKPICards(),
              const SizedBox(height: 24),
              
              // Charts Section
              _buildChartsSection(),
              const SizedBox(height: 24),
              
              // Recent Work Orders Table
              _buildRecentWorkOrdersTable(),
              const SizedBox(height: 24),
              
              // Recent Invoices Table
              _buildRecentInvoicesTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKPICards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Performance Indicators',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
          children: [
            MetricCard(
              title: 'Total Customers',
              value: '1,247',
              icon: Icons.people,
              color: Colors.blue,
              subtitle: '+12 this month',
              isLoading: _isLoading,
              onTap: () {
                // Navigate to customers
              },
            ),
            MetricCard(
              title: 'Total Vehicles',
              value: '892',
              icon: Icons.directions_car,
              color: Colors.green,
              subtitle: '+8 this month',
              isLoading: _isLoading,
              onTap: () {
                // Navigate to vehicles
              },
            ),
            MetricCard(
              title: 'Open Work Orders',
              value: '47',
              icon: Icons.build_circle,
              color: Colors.orange,
              subtitle: '12 urgent',
              isLoading: _isLoading,
              onTap: () {
                // Navigate to work orders
              },
            ),
            MetricCard(
              title: 'Monthly Revenue',
              value: '\$85.2K',
              icon: Icons.attach_money,
              color: Colors.purple,
              subtitle: '+18% vs last month',
              isLoading: _isLoading,
              onTap: () {
                // Navigate to revenue details
              },
            ),
            MetricCard(
              title: 'Low-Stock Parts',
              value: '23',
              icon: Icons.warning,
              color: Colors.red,
              subtitle: 'Need reorder',
              isLoading: _isLoading,
              onTap: () {
                // Navigate to inventory
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analytics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: ChartWidget(
                title: 'Revenue by Day (Last 30 Days)',
                isLoading: _isChartsLoading,
                chart: RevenueLineChart(
                  data: _revenueData,
                  isLoading: _isChartsLoading,
                ),
                onRefresh: _refreshCharts,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ChartWidget(
                title: 'Work Orders by Status',
                isLoading: _isChartsLoading,
                chart: WorkOrderStatusPieChart(
                  data: _workOrderStatusData,
                  isLoading: _isChartsLoading,
                ),
                onRefresh: _refreshCharts,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentWorkOrdersTable() {
    final filteredWorkOrders = _recentWorkOrders.where((wo) {
      if (_workOrdersSearch.isEmpty) return true;
      return wo['customer'].toLowerCase().contains(_workOrdersSearch.toLowerCase()) ||
             wo['vehicle'].toLowerCase().contains(_workOrdersSearch.toLowerCase()) ||
             wo['status'].toLowerCase().contains(_workOrdersSearch.toLowerCase());
    }).toList();

    return DataTableWidget<Map<String, dynamic>>(
      title: 'Recent Work Orders',
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Customer')),
        DataColumn(label: Text('Vehicle')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Assigned To')),
        DataColumn(label: Text('Created')),
        DataColumn(label: Text('Amount')),
        DataColumn(label: Text('Actions')),
      ],
      data: filteredWorkOrders,
      isLoading: _isWorkOrdersLoading,
      currentPage: _workOrdersPage,
      totalPages: _totalPages,
      onRefresh: _refreshWorkOrders,
      onSearch: (query) {
        setState(() {
          _workOrdersSearch = query;
        });
      },
      onPageChanged: (page) {
        setState(() {
          _workOrdersPage = page;
          _loadWorkOrders();
        });
      },
      searchHint: 'Search work orders...',
      rowBuilder: (workOrder) {
        return DataRow(
          cells: [
            DataCell(Text(workOrder['id'])),
            DataCell(Text(workOrder['customer'])),
            DataCell(Text(workOrder['vehicle'])),
            DataCell(_buildStatusChip(workOrder['status'])),
            DataCell(Text(workOrder['assigned_to'])),
            DataCell(Text(workOrder['created_at'])),
            DataCell(Text(workOrder['amount'])),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility, size: 20),
                    onPressed: () => _viewWorkOrder(workOrder['id']),
                    tooltip: 'View',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _editWorkOrder(workOrder['id']),
                    tooltip: 'Edit',
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentInvoicesTable() {
    final filteredInvoices = _recentInvoices.where((invoice) {
      if (_invoicesSearch.isEmpty) return true;
      return invoice['customer'].toLowerCase().contains(_invoicesSearch.toLowerCase()) ||
             invoice['status'].toLowerCase().contains(_invoicesSearch.toLowerCase());
    }).toList();

    return DataTableWidget<Map<String, dynamic>>(
      title: 'Recent Invoices',
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Customer')),
        DataColumn(label: Text('Amount')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Created')),
        DataColumn(label: Text('Due Date')),
        DataColumn(label: Text('Actions')),
      ],
      data: filteredInvoices,
      isLoading: _isInvoicesLoading,
      currentPage: _invoicesPage,
      totalPages: _totalPages,
      onRefresh: _refreshInvoices,
      onSearch: (query) {
        setState(() {
          _invoicesSearch = query;
        });
      },
      onPageChanged: (page) {
        setState(() {
          _invoicesPage = page;
          _loadInvoices();
        });
      },
      searchHint: 'Search invoices...',
      rowBuilder: (invoice) {
        return DataRow(
          cells: [
            DataCell(Text(invoice['id'])),
            DataCell(Text(invoice['customer'])),
            DataCell(Text(invoice['amount'])),
            DataCell(_buildInvoiceStatusChip(invoice['status'])),
            DataCell(Text(invoice['created_at'])),
            DataCell(Text(invoice['due_date'])),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility, size: 20),
                    onPressed: () => _viewInvoice(invoice['id']),
                    tooltip: 'View',
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, size: 20),
                    onPressed: () => _sendInvoice(invoice['id']),
                    tooltip: 'Send',
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
      case 'completed':
        color = Colors.green;
        break;
      case 'waiting parts':
        color = Colors.red;
        break;
      case 'cancelled':
        color = Colors.grey;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: color,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildInvoiceStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'paid':
        color = Colors.green;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'overdue':
        color = Colors.red;
        break;
      case 'cancelled':
        color = Colors.grey;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        status,
        style: const TextStyle(
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
      _isChartsLoading = true;
      _isWorkOrdersLoading = true;
      _isInvoicesLoading = true;
    });
    
    // Simulate API calls
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _isLoading = false;
      _isChartsLoading = false;
      _isWorkOrdersLoading = false;
      _isInvoicesLoading = false;
    });
  }

  Future<void> _refreshCharts() async {
    setState(() {
      _isChartsLoading = true;
    });
    
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _isChartsLoading = false;
    });
  }

  Future<void> _refreshWorkOrders() async {
    setState(() {
      _isWorkOrdersLoading = true;
    });
    
    await _loadWorkOrders();
    
    setState(() {
      _isWorkOrdersLoading = false;
    });
  }

  Future<void> _refreshInvoices() async {
    setState(() {
      _isInvoicesLoading = true;
    });
    
    await _loadInvoices();
    
    setState(() {
      _isInvoicesLoading = false;
    });
  }

  Future<void> _loadWorkOrders() async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));
    // Load work orders from API based on current page
  }

  Future<void> _loadInvoices() async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));
    // Load invoices from API based on current page
  }

  void _viewWorkOrder(String id) {
    // Navigate to view work order screen
    print('View work order: $id');
  }

  void _editWorkOrder(String id) {
    // Navigate to edit work order screen
    print('Edit work order: $id');
  }

  void _viewInvoice(String id) {
    // Navigate to view invoice screen
    print('View invoice: $id');
  }

  void _sendInvoice(String id) {
    // Send invoice to customer
    print('Send invoice: $id');
  }
}