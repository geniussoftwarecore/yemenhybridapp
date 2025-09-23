import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workorder.dart';
import '../providers/workorder_provider.dart';
import '../../customers/providers/customer_provider.dart';
import '../../vehicles/providers/vehicle_provider.dart';
import '../../customers/models/customer.dart';
import '../../vehicles/models/vehicle.dart';

class WorkOrderCreatePage extends ConsumerStatefulWidget {
  const WorkOrderCreatePage({super.key});

  @override
  ConsumerState<WorkOrderCreatePage> createState() => _WorkOrderCreatePageState();
}

class _WorkOrderCreatePageState extends ConsumerState<WorkOrderCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _complaintController = TextEditingController();
  final _notesController = TextEditingController();
  final _estPartsController = TextEditingController();
  final _estLaborController = TextEditingController();
  
  int? _selectedCustomerId;
  int? _selectedVehicleId;
  DateTime? _scheduledAt;
  bool _isLoading = false;

  @override
  void dispose() {
    _complaintController.dispose();
    _notesController.dispose();
    _estPartsController.dispose();
    _estLaborController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerAllProvider);
    final vehiclesAsync = ref.watch(vehicleListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Work Order'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveWorkOrder,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('SAVE'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer Information',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      customersAsync.when(
                        data: (customers) => DropdownButtonFormField<int>(
                          value: _selectedCustomerId,
                          decoration: const InputDecoration(
                            labelText: 'Customer *',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          items: customers.map((customer) {
                            return DropdownMenuItem<int>(
                              value: customer.id,
                              child: Text('${customer.name} ${customer.phone != null ? '(${customer.phone})' : ''}'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCustomerId = value;
                              _selectedVehicleId = null; // Reset vehicle selection
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select a customer';
                            }
                            return null;
                          },
                        ),
                        loading: () => DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Loading customers...',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          items: const [],
                          onChanged: null,
                        ),
                        error: (error, _) => Text('Error loading customers: $error'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Vehicle Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vehicle Information',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      vehiclesAsync.when(
                        data: (vehicles) {
                          final customerVehicles = _selectedCustomerId != null
                              ? vehicles.where((v) => v.customerId == _selectedCustomerId).toList()
                              : vehicles;
                          
                          return DropdownButtonFormField<int>(
                            value: _selectedVehicleId,
                            decoration: const InputDecoration(
                              labelText: 'Vehicle *',
                              prefixIcon: Icon(Icons.directions_car),
                              border: OutlineInputBorder(),
                            ),
                            items: customerVehicles.map((vehicle) {
                              return DropdownMenuItem<int>(
                                value: vehicle.id,
                                child: Text('${vehicle.make} ${vehicle.model} - ${vehicle.plate}'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedVehicleId = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a vehicle';
                              }
                              return null;
                            },
                          );
                        },
                        loading: () => DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Loading vehicles...',
                            prefixIcon: Icon(Icons.directions_car),
                            border: OutlineInputBorder(),
                          ),
                          items: const [],
                          onChanged: null,
                        ),
                        error: (error, _) => Text('Error loading vehicles: $error'),
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
                      Text(
                        'Work Order Details',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _complaintController,
                        decoration: const InputDecoration(
                          labelText: 'Customer Complaint *',
                          prefixIcon: Icon(Icons.report_problem),
                          border: OutlineInputBorder(),
                          helperText: 'Describe the customer\'s concern or issue',
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the customer complaint';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Additional Notes',
                          prefixIcon: Icon(Icons.notes),
                          border: OutlineInputBorder(),
                          helperText: 'Any additional information or observations',
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Estimate Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Initial Estimate (Optional)',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _estPartsController,
                              decoration: const InputDecoration(
                                labelText: 'Parts Estimate',
                                prefixIcon: Icon(Icons.build),
                                border: OutlineInputBorder(),
                                prefixText: '\$',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final amount = double.tryParse(value);
                                  if (amount == null || amount < 0) {
                                    return 'Enter valid amount';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _estLaborController,
                              decoration: const InputDecoration(
                                labelText: 'Labor Estimate',
                                prefixIcon: Icon(Icons.engineering),
                                border: OutlineInputBorder(),
                                prefixText: '\$',
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final amount = double.tryParse(value);
                                  if (amount == null || amount < 0) {
                                    return 'Enter valid amount';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Estimate:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '\$${_calculateTotal().toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Schedule Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scheduling (Optional)',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.schedule),
                        title: const Text('Scheduled Date & Time'),
                        subtitle: Text(
                          _scheduledAt != null
                              ? '${_scheduledAt!.day}/${_scheduledAt!.month}/${_scheduledAt!.year} at ${_scheduledAt!.hour}:${_scheduledAt!.minute.toString().padLeft(2, '0')}'
                              : 'No schedule set',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _selectDateTime,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateTotal() {
    final parts = double.tryParse(_estPartsController.text) ?? 0.0;
    final labor = double.tryParse(_estLaborController.text) ?? 0.0;
    return parts + labor;
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date == null) return;

    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt ?? DateTime.now()),
    );

    if (time == null) return;

    setState(() {
      _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _saveWorkOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final workOrder = WorkOrder(
        customerId: _selectedCustomerId!,
        vehicleId: _selectedVehicleId!,
        complaint: _complaintController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        scheduledAt: _scheduledAt,
        estParts: double.tryParse(_estPartsController.text),
        estLabor: double.tryParse(_estLaborController.text),
      );

      await ref.read(workOrderNotifierProvider.notifier).createWorkOrder(workOrder);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Work order created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating work order: $e'),
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
}