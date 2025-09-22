import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_localizations.dart';
import '../models/customer.dart';
import '../providers/customer_provider.dart';

class CustomerFormPage extends ConsumerStatefulWidget {
  final String? customerId;

  const CustomerFormPage({
    super.key,
    this.customerId,
  });

  @override
  ConsumerState<CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends ConsumerState<CustomerFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  Customer? _existingCustomer;

  @override
  void initState() {
    super.initState();
    if (widget.customerId != null) {
      _loadCustomer();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadCustomer() async {
    try {
      final customer = await ref.read(customerByIdProvider(int.parse(widget.customerId!)).future);
      setState(() {
        _existingCustomer = customer;
        _nameController.text = customer.name;
        _phoneController.text = customer.phone ?? '';
        _emailController.text = customer.email ?? '';
        _addressController.text = customer.address ?? '';
        _cityController.text = customer.city ?? '';
        _notesController.text = customer.notes ?? '';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading customer: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.customerId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Customer' : 'Add Customer'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveCustomer,
            child: Text(isEditing ? 'UPDATE' : 'SAVE'),
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
              // Personal Information Section
              _buildSection(
                title: 'Personal Information',
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'Enter customer full name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter customer name';
                      }
                      if (value.trim().length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'Enter phone number',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (value.length < 8) {
                          return 'Phone number must be at least 8 digits';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'Enter email address',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Please enter a valid email address';
                        }
                      }
                      return null;
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Address Information Section
              _buildSection(
                title: 'Address Information',
                children: [
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      hintText: 'Enter street address',
                      prefixIcon: Icon(Icons.home),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _cityController.text.isNotEmpty ? _cityController.text : null,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      prefixIcon: Icon(Icons.location_city),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Sana\'a', child: Text('Sana\'a')),
                      DropdownMenuItem(value: 'Aden', child: Text('Aden')),
                      DropdownMenuItem(value: 'Taiz', child: Text('Taiz')),
                      DropdownMenuItem(value: 'Hodeidah', child: Text('Hodeidah')),
                      DropdownMenuItem(value: 'Ibb', child: Text('Ibb')),
                      DropdownMenuItem(value: 'Dhamar', child: Text('Dhamar')),
                      DropdownMenuItem(value: 'Al Mukalla', child: Text('Al Mukalla')),
                      DropdownMenuItem(value: 'Zinjibar', child: Text('Zinjibar')),
                    ],
                    onChanged: (value) {
                      _cityController.text = value ?? '';
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Additional Information Section
              _buildSection(
                title: 'Additional Information',
                children: [
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Enter any additional notes',
                      prefixIcon: Icon(Icons.note),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveCustomer,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Saving...'),
                          ],
                        )
                      : Text(
                          isEditing ? 'UPDATE CUSTOMER' : 'CREATE CUSTOMER',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              if (isEditing) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('CANCEL'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  void _saveCustomer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final customer = Customer(
        id: _existingCustomer?.id,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      if (widget.customerId != null) {
        // Update existing customer
        await ref.read(customerNotifierProvider.notifier).updateCustomer(customer);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${customer.name} updated successfully')),
          );
          context.go('/customers/${customer.id}');
        }
      } else {
        // Create new customer
        final newCustomer = await ref.read(customerNotifierProvider.notifier).createCustomer(customer);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${customer.name} created successfully')),
          );
          context.go('/customers/${newCustomer.id}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving customer: $e'),
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