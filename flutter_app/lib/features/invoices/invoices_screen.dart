import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/app_localizations.dart';
import 'services/invoice_api_service.dart';
import 'models/invoice.dart';
import 'providers/invoice_provider.dart';
import '../workorders/models/workorder.dart';
import '../workorders/providers/workorder_provider.dart';

class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key});

  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> {
  final _searchController = TextEditingController();
  InvoiceStatus? _selectedStatus;
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final invoicesAsync = ref.watch(invoiceListProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.invoices),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateInvoiceDialog(),
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
                      hintText: 'Search invoices...',
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
          // Invoices List
          Expanded(
            child: invoicesAsync.when(
              data: (invoices) {
                if (invoices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No invoices found',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first invoice to get started',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _showCreateInvoiceDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Create Invoice'),
                        ),
                      ],
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(invoiceListProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: invoices.length,
                    itemBuilder: (context, index) {
                      final invoice = invoices[index];
                      return _InvoiceCard(
                        invoice: invoice,
                        onTap: () => _showInvoiceDetails(invoice),
                        onGeneratePdf: () => _generatePdf(invoice),
                        onMarkAsPaid: () => _markAsPaid(invoice),
                        onSendInvoice: () => _sendInvoice(invoice),
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
                      'Error loading invoices',
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
                        ref.invalidate(invoiceListProvider);
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
    ref.invalidate(invoiceListProvider);
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Invoices'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<InvoiceStatus>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: InvoiceStatus.values.map((status) {
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

  void _showCreateInvoiceDialog() {
    showDialog(
      context: context,
      builder: (context) => _CreateInvoiceDialog(),
    );
  }

  void _showInvoiceDetails(Invoice invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _InvoiceDetailsSheet(invoice: invoice),
    );
  }

  Future<void> _generatePdf(Invoice invoice) async {
    if (invoice.id == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ref.read(invoiceApiServiceProvider);
      await apiService.openPdfInBrowser(invoice.id!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF generated and opened for Invoice #${invoice.id}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
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

  Future<void> _markAsPaid(Invoice invoice) async {
    if (invoice.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Paid'),
        content: Text('Mark Invoice #${invoice.id} as paid?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Mark as Paid'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ref.read(invoiceApiServiceProvider);
      await apiService.markAsPaid(invoice.id!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoice #${invoice.id} marked as paid'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(invoiceListProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking as paid: $e'),
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

  Future<void> _sendInvoice(Invoice invoice) async {
    if (invoice.id == null) return;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _SendInvoiceDialog(),
    );

    if (result == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ref.read(invoiceApiServiceProvider);
      await apiService.sendInvoice(
        invoice.id!,
        email: result['email'],
        channel: result['channel'],
        message: result['message'],
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoice #${invoice.id} sent via ${result['channel']?.toUpperCase()}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending invoice: $e'),
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

  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return Colors.grey;
      case InvoiceStatus.sent:
        return Colors.blue;
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.overdue:
        return Colors.red;
      case InvoiceStatus.cancelled:
        return Colors.red;
    }
  }
}

class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onTap;
  final VoidCallback onGeneratePdf;
  final VoidCallback onMarkAsPaid;
  final VoidCallback onSendInvoice;

  const _InvoiceCard({
    required this.invoice,
    required this.onTap,
    required this.onGeneratePdf,
    required this.onMarkAsPaid,
    required this.onSendInvoice,
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
                          'Invoice #${invoice.id}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (invoice.customer != null)
                          Text(
                            invoice.customer!.name,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  _StatusChip(status: invoice.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.attach_money,
                    size: 16,
                    color: Colors.green[600],
                  ),
                  Text(
                    '\$${invoice.total.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.green[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Due: ${_formatDate(invoice.dueAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
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
    switch (invoice.status) {
      case InvoiceStatus.draft:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onGeneratePdf,
                icon: const Icon(Icons.picture_as_pdf, size: 16),
                label: const Text('PDF'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onSendInvoice,
                icon: const Icon(Icons.send, size: 16),
                label: const Text('Send'),
              ),
            ),
          ],
        );
      case InvoiceStatus.sent:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onGeneratePdf,
                icon: const Icon(Icons.picture_as_pdf, size: 16),
                label: const Text('PDF'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onMarkAsPaid,
                icon: const Icon(Icons.payment, size: 16),
                label: const Text('Mark Paid'),
              ),
            ),
          ],
        );
      case InvoiceStatus.overdue:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onSendInvoice,
                icon: const Icon(Icons.send, size: 16),
                label: const Text('Resend'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onMarkAsPaid,
                icon: const Icon(Icons.payment, size: 16),
                label: const Text('Mark Paid'),
              ),
            ),
          ],
        );
      default:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onGeneratePdf,
                icon: const Icon(Icons.picture_as_pdf, size: 16),
                label: const Text('View PDF'),
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
  final InvoiceStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case InvoiceStatus.draft:
        color = Colors.grey;
        break;
      case InvoiceStatus.sent:
        color = Colors.blue;
        break;
      case InvoiceStatus.paid:
        color = Colors.green;
        break;
      case InvoiceStatus.overdue:
        color = Colors.red;
        break;
      case InvoiceStatus.cancelled:
        color = Colors.red;
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

class _InvoiceDetailsSheet extends StatelessWidget {
  final Invoice invoice;

  const _InvoiceDetailsSheet({required this.invoice});

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
                        'Invoice #${invoice.id}',
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
                    // Customer Info
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customer Information',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (invoice.customer != null) ...[
                              Text('Name: ${invoice.customer!.name}'),
                              if (invoice.customer!.email != null)
                                Text('Email: ${invoice.customer!.email}'),
                              if (invoice.customer!.phone != null)
                                Text('Phone: ${invoice.customer!.phone}'),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Invoice Details
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Invoice Details',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text('Status: '),
                                _StatusChip(status: invoice.status),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Issue Date: ${_formatDate(invoice.issuedAt)}'),
                            Text('Due Date: ${_formatDate(invoice.dueAt)}'),
                            if (invoice.paidAt != null)
                              Text('Paid Date: ${_formatDate(invoice.paidAt)}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Invoice Items
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Invoice Items',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (invoice.items != null && invoice.items!.isNotEmpty) ...[
                              ...invoice.items!.map((item) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text('${item.description} (x${item.quantity})'),
                                    ),
                                    Text('\$${(item.price * item.quantity).toStringAsFixed(2)}'),
                                  ],
                                ),
                              )),
                              const Divider(),
                              Row(
                                children: [
                                  const Expanded(child: Text('Subtotal:')),
                                  Text('\$${invoice.subtotal.toStringAsFixed(2)}'),
                                ],
                              ),
                              Row(
                                children: [
                                  const Expanded(child: Text('Tax:')),
                                  Text('\$${invoice.taxAmount.toStringAsFixed(2)}'),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Total:',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '\$${invoice.total.toStringAsFixed(2)}',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[600],
                                    ),
                                  ),
                                ],
                              ),
                            ] else
                              const Text('No items added to this invoice'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _CreateInvoiceDialog extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workOrdersAsync = ref.watch(workOrderListProvider);
    
    return AlertDialog(
      title: const Text('Create Invoice'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Choose how to create the invoice:'),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('From Work Order'),
            subtitle: const Text('Convert completed work order to invoice'),
            onTap: () {
              Navigator.of(context).pop();
              _showWorkOrderSelection(context, ref);
            },
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Manual Invoice'),
            subtitle: const Text('Create invoice from scratch'),
            onTap: () {
              Navigator.of(context).pop();
              // TODO: Navigate to manual invoice creation
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  void _showWorkOrderSelection(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Work Order'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Consumer(
            builder: (context, ref, child) {
              final workOrdersAsync = ref.watch(workOrderListProvider);
              
              return workOrdersAsync.when(
                data: (workOrders) {
                  final completedWorkOrders = workOrders
                      .where((wo) => wo.status == WorkOrderStatus.completed)
                      .toList();
                  
                  if (completedWorkOrders.isEmpty) {
                    return const Center(
                      child: Text('No completed work orders available'),
                    );
                  }
                  
                  return ListView.builder(
                    itemCount: completedWorkOrders.length,
                    itemBuilder: (context, index) {
                      final workOrder = completedWorkOrders[index];
                      return ListTile(
                        title: Text('Work Order #${workOrder.id}'),
                        subtitle: Text(workOrder.customer?.name ?? 'Unknown Customer'),
                        trailing: workOrder.estimate != null
                            ? Text('\$${workOrder.estimate!.toStringAsFixed(2)}')
                            : null,
                        onTap: () async {
                          Navigator.of(context).pop();
                          await _createInvoiceFromWorkOrder(context, ref, workOrder.id!);
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _createInvoiceFromWorkOrder(BuildContext context, WidgetRef ref, int workOrderId) async {
    try {
      final apiService = ref.read(invoiceApiServiceProvider);
      final invoice = await apiService.createInvoiceFromWorkOrder(workOrderId);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoice #${invoice.id} created from work order'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(invoiceListProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating invoice: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _SendInvoiceDialog extends StatefulWidget {
  @override
  _SendInvoiceDialogState createState() => _SendInvoiceDialogState();
}

class _SendInvoiceDialogState extends State<_SendInvoiceDialog> {
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedChannel = 'email';

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Send Invoice'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedChannel,
            decoration: const InputDecoration(
              labelText: 'Channel',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'email', child: Text('Email')),
              DropdownMenuItem(value: 'whatsapp', child: Text('WhatsApp')),
              DropdownMenuItem(value: 'sms', child: Text('SMS')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedChannel = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          if (_selectedChannel == 'email')
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
                hintText: 'customer@example.com',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(
              labelText: 'Custom Message (optional)',
              border: OutlineInputBorder(),
              hintText: 'Add a personal message...',
            ),
            maxLines: 3,
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
              'email': _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
              'channel': _selectedChannel,
              'message': _messageController.text.trim().isNotEmpty ? _messageController.text.trim() : null,
            });
          },
          child: const Text('Send'),
        ),
      ],
    );
  }
}