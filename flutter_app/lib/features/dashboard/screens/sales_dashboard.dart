import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/metric_card.dart';
import '../widgets/data_table_widget.dart';
import '../widgets/quick_action_button.dart';

class SalesDashboard extends ConsumerStatefulWidget {
  const SalesDashboard({super.key});

  @override
  ConsumerState<SalesDashboard> createState() => _SalesDashboardState();
}

class _SalesDashboardState extends ConsumerState<SalesDashboard> {
  bool _isLoading = false;
  bool _isTableLoading = false;
  int _currentPage = 1;
  final int _totalPages = 2;
  String _searchQuery = '';

  // Sample data - replace with actual data from providers
  final List<Map<String, dynamic>> _customerResponses = [
    {
      'id': 'CR-001',
      'customer': 'Ahmed Ali',
      'vehicle': 'Toyota Camry - ABC-123',
      'quote_amount': '\$1,250',
      'sent_date': '2025-09-19',
      'status': 'Pending',
      'follow_up': '2025-09-22',
    },
    {
      'id': 'CR-002',
      'customer': 'Sarah Mohammed',
      'vehicle': 'Honda Civic - DEF-456',
      'quote_amount': '\$890',
      'sent_date': '2025-09-18',
      'status': 'Reviewed',
      'follow_up': '2025-09-21',
    },
    {
      'id': 'CR-003',
      'customer': 'Mohammed Hassan',
      'vehicle': 'BMW X5 - GHI-789',
      'quote_amount': '\$2,100',
      'sent_date': '2025-09-20',
      'status': 'Approved',
      'follow_up': '2025-09-23',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.salesDashboard),
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
              
              // Customer Response Table
              _buildCustomerResponseTable(),
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
          title: 'Pending Approvals',
          value: '12',
          icon: Icons.pending_actions,
          color: Colors.orange,
          subtitle: '4 urgent',
          isLoading: _isLoading,
          onTap: () {
            // Navigate to pending approvals
          },
        ),
        MetricCard(
          title: 'Bookings Next 7 Days',
          value: '18',
          icon: Icons.calendar_today,
          color: Colors.blue,
          subtitle: '+3 from last week',
          isLoading: _isLoading,
          onTap: () {
            // Navigate to upcoming bookings
          },
        ),
        MetricCard(
          title: 'Monthly Revenue',
          value: '\$42.5K',
          icon: Icons.attach_money,
          color: Colors.green,
          subtitle: '+15% vs last month',
          isLoading: _isLoading,
          onTap: () {
            // Navigate to revenue details
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
          title: 'Review & Send Offer',
          icon: Icons.rate_review,
          color: Colors.purple,
          onPressed: () {
            _showReviewOfferDialog();
          },
        ),
        QuickActionButton(
          title: 'Create Invoice',
          icon: Icons.receipt_long,
          color: Colors.teal,
          onPressed: () {
            _showCreateInvoiceDialog();
          },
        ),
      ],
    );
  }

  Widget _buildCustomerResponseTable() {
    final filteredResponses = _customerResponses.where((response) {
      if (_searchQuery.isEmpty) return true;
      return response['customer'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
             response['vehicle'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
             response['status'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return DataTableWidget<Map<String, dynamic>>(
      title: 'Awaiting Customer Response',
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Customer')),
        DataColumn(label: Text('Vehicle')),
        DataColumn(label: Text('Quote')),
        DataColumn(label: Text('Sent')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Follow Up')),
        DataColumn(label: Text('Actions')),
      ],
      data: filteredResponses,
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
          _loadCustomerResponses();
        });
      },
      searchHint: 'Search by customer, vehicle, or status...',
      rowBuilder: (response) {
        return DataRow(
          cells: [
            DataCell(Text(response['id'])),
            DataCell(Text(response['customer'])),
            DataCell(Text(response['vehicle'])),
            DataCell(Text(response['quote_amount'])),
            DataCell(Text(response['sent_date'])),
            DataCell(_buildStatusChip(response['status'])),
            DataCell(Text(response['follow_up'])),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.phone, size: 20),
                    onPressed: () => _callCustomer(response['id']),
                    tooltip: 'Call',
                  ),
                  IconButton(
                    icon: const Icon(Icons.email, size: 20),
                    onPressed: () => _emailCustomer(response['id']),
                    tooltip: 'Email',
                  ),
                  IconButton(
                    icon: const Icon(Icons.visibility, size: 20),
                    onPressed: () => _viewQuote(response['id']),
                    tooltip: 'View Quote',
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
      case 'pending':
        color = Colors.orange;
        break;
      case 'reviewed':
        color = Colors.blue;
        break;
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
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
    
    await _loadCustomerResponses();
    
    setState(() {
      _isTableLoading = false;
    });
  }

  Future<void> _loadCustomerResponses() async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));
    // Load customer responses from API based on current page
  }

  void _showReviewOfferDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review & Send Offer'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select a pending work order to review and send offer to customer.'),
            SizedBox(height: 16),
            Text('Features to implement:'),
            Text('• Review work order details'),
            Text('• Calculate quote amount'),
            Text('• Add notes and terms'),
            Text('• Send to customer via email/SMS'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement review offer logic
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showCreateInvoiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Invoice'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create a new invoice for approved work order.'),
            SizedBox(height: 16),
            Text('Features to implement:'),
            Text('• Select approved work order'),
            Text('• Add invoice items and pricing'),
            Text('• Apply taxes and discounts'),
            Text('• Generate and send invoice'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement create invoice logic
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _callCustomer(String id) {
    // Implement call customer functionality
    print('Call customer: $id');
  }

  void _emailCustomer(String id) {
    // Implement email customer functionality
    print('Email customer: $id');
  }

  void _viewQuote(String id) {
    // Navigate to view quote screen
    print('View quote: $id');
  }
}