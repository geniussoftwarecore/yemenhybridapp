import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/app_localizations.dart';
import '../models/vehicle.dart';
import '../providers/vehicle_provider.dart';
import '../../customers/models/customer.dart';
import '../../customers/providers/customer_provider.dart';

class VehicleFormScreen extends ConsumerStatefulWidget {
  final Vehicle? vehicle;
  final int? preselectedCustomerId;

  const VehicleFormScreen({
    super.key, 
    this.vehicle,
    this.preselectedCustomerId,
  });

  @override
  ConsumerState<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends ConsumerState<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _vinController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();
  final _engineController = TextEditingController();
  final _notesController = TextEditingController();

  int? _selectedCustomerId;
  bool _isLoading = false;
  bool get _isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    _selectedCustomerId = widget.preselectedCustomerId;
    if (_isEditing) {
      _populateForm();
    }
  }

  void _populateForm() {
    final vehicle = widget.vehicle!;
    _plateController.text = vehicle.plate;
    _vinController.text = vehicle.vin ?? '';
    _makeController.text = vehicle.make;
    _modelController.text = vehicle.model;
    _yearController.text = vehicle.year?.toString() ?? '';
    _colorController.text = vehicle.color ?? '';
    _engineController.text = vehicle.engine ?? '';
    _notesController.text = vehicle.notes ?? '';
    _selectedCustomerId = vehicle.customerId;
  }

  @override
  void dispose() {
    _plateController.dispose();
    _vinController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _engineController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final customersAsync = ref.watch(customerAllProvider);
    final availableMakes = ref.watch(vehicleMakesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Vehicle' : 'Add Vehicle'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vehicle Owner',
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
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a customer';
                          }
                          return null;
                        },
                      ),
                      loading: () => const DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          labelText: 'Loading customers...',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        items: [],
                        onChanged: null,
                      ),
                      error: (error, _) => Text('Error loading customers: $error'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
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
                    TextFormField(
                      controller: _plateController,
                      decoration: const InputDecoration(
                        labelText: 'License Plate *',
                        prefixIcon: Icon(Icons.confirmation_number),
                        border: OutlineInputBorder(),
                        hintText: 'e.g. ABC 123',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'License plate is required';
                        }
                        if (value.trim().length < 2) {
                          return 'License plate must be at least 2 characters';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _vinController,
                      decoration: const InputDecoration(
                        labelText: 'VIN Number',
                        prefixIcon: Icon(Icons.qr_code),
                        border: OutlineInputBorder(),
                        hintText: '17-character VIN',
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (value.length != 17) {
                            return 'VIN must be exactly 17 characters';
                          }
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: _makeController.text.isNotEmpty ? _makeController.text : null,
                            decoration: const InputDecoration(
                              labelText: 'Make *',
                              prefixIcon: Icon(Icons.directions_car),
                              border: OutlineInputBorder(),
                            ),
                            items: availableMakes.map((make) {
                              return DropdownMenuItem<String>(
                                value: make,
                                child: Text(make),
                              );
                            }).toList(),
                            onChanged: (value) {
                              _makeController.text = value ?? '';
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Make is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _modelController,
                            decoration: const InputDecoration(
                              labelText: 'Model *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Model is required';
                              }
                              return null;
                            },
                            textCapitalization: TextCapitalization.words,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _yearController,
                            decoration: const InputDecoration(
                              labelText: 'Year',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final year = int.tryParse(value);
                                if (year == null || year < 1900 || year > DateTime.now().year + 1) {
                                  return 'Invalid year';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _colorController,
                            decoration: const InputDecoration(
                              labelText: 'Color',
                              prefixIcon: Icon(Icons.palette),
                              border: OutlineInputBorder(),
                            ),
                            textCapitalization: TextCapitalization.words,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _engineController,
                            decoration: const InputDecoration(
                              labelText: 'Engine',
                              prefixIcon: Icon(Icons.settings),
                              border: OutlineInputBorder(),
                              hintText: 'e.g. 2.0L',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Additional Notes',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        prefixIcon: Icon(Icons.note),
                        border: OutlineInputBorder(),
                        hintText: 'Any additional information about the vehicle...',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveVehicle,
                    child: Text(_isEditing ? 'Update Vehicle' : 'Create Vehicle'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final vehicle = Vehicle(
        id: widget.vehicle?.id,
        customerId: _selectedCustomerId!,
        plate: _plateController.text.trim(),
        vin: _vinController.text.trim().isNotEmpty ? _vinController.text.trim() : null,
        make: _makeController.text.trim(),
        model: _modelController.text.trim(),
        year: _yearController.text.trim().isNotEmpty ? int.tryParse(_yearController.text.trim()) : null,
        color: _colorController.text.trim().isNotEmpty ? _colorController.text.trim() : null,
        engine: _engineController.text.trim().isNotEmpty ? _engineController.text.trim() : null,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      if (_isEditing) {
        await ref.read(vehicleNotifierProvider.notifier)
            .updateVehicle(widget.vehicle!.id!, vehicle);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vehicle updated successfully')),
          );
        }
      } else {
        await ref.read(vehicleNotifierProvider.notifier)
            .createVehicle(vehicle);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vehicle created successfully')),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ${_isEditing ? 'updating' : 'creating'} vehicle: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}