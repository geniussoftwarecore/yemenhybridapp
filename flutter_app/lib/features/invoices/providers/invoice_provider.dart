import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/invoice_api_service.dart';
import '../models/invoice.dart';
import '../../../core/models/api_response.dart';

// Invoice search filters state
final invoiceSearchFiltersProvider = StateProvider<InvoiceSearchFilters>((ref) {
  return InvoiceSearchFilters();
});

// Invoice list provider with search filters
final invoiceListProvider = FutureProvider<List<Invoice>>((ref) async {
  final apiService = ref.read(invoiceApiServiceProvider);
  final filters = ref.watch(invoiceSearchFiltersProvider);
  
  final response = await apiService.getInvoices(
    page: filters.page,
    size: filters.size,
    status: filters.status?.backendValue,
    customerId: filters.customerId,
  );
  
  return response.items;
});

// Invoice notifier for CRUD operations
final invoiceNotifierProvider = StateNotifierProvider<InvoiceNotifier, AsyncValue<List<Invoice>>>((ref) {
  return InvoiceNotifier(ref.read(invoiceApiServiceProvider));
});

class InvoiceNotifier extends StateNotifier<AsyncValue<List<Invoice>>> {
  final InvoiceApiService _apiService;

  InvoiceNotifier(this._apiService) : super(const AsyncValue.loading()) {
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    try {
      state = const AsyncValue.loading();
      final response = await _apiService.getInvoices();
      state = AsyncValue.data(response.items);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await _loadInvoices();
  }

  Future<Invoice> createInvoice(Invoice invoice) async {
    try {
      final newInvoice = await _apiService.createInvoice(invoice);
      // Refresh the list
      await _loadInvoices();
      return newInvoice;
    } catch (error) {
      rethrow;
    }
  }

  Future<Invoice> createInvoiceFromWorkOrder(int workOrderId) async {
    try {
      final newInvoice = await _apiService.createInvoiceFromWorkOrder(workOrderId);
      // Refresh the list
      await _loadInvoices();
      return newInvoice;
    } catch (error) {
      rethrow;
    }
  }

  Future<Invoice> updateInvoice(int id, Invoice invoice) async {
    try {
      final updatedInvoice = await _apiService.updateInvoice(id, invoice);
      // Refresh the list
      await _loadInvoices();
      return updatedInvoice;
    } catch (error) {
      rethrow;
    }
  }

  Future<void> deleteInvoice(int id) async {
    try {
      await _apiService.deleteInvoice(id);
      // Refresh the list
      await _loadInvoices();
    } catch (error) {
      rethrow;
    }
  }

  Future<Invoice> updateStatus(int id, InvoiceStatus status) async {
    try {
      final updatedInvoice = await _apiService.updateStatus(id, status);
      // Refresh the list
      await _loadInvoices();
      return updatedInvoice;
    } catch (error) {
      rethrow;
    }
  }

  Future<Invoice> markAsPaid(int id, {DateTime? paidAt}) async {
    try {
      final updatedInvoice = await _apiService.markAsPaid(id, paidAt: paidAt);
      // Refresh the list
      await _loadInvoices();
      return updatedInvoice;
    } catch (error) {
      rethrow;
    }
  }

  Future<void> sendInvoice(int id, {String? email, String? channel, String? message}) async {
    try {
      await _apiService.sendInvoice(id, email: email, channel: channel, message: message);
      // Refresh the list to update status
      await _loadInvoices();
    } catch (error) {
      rethrow;
    }
  }

  Future<String> generatePdf(int id) async {
    try {
      return await _apiService.generatePdf(id);
    } catch (error) {
      rethrow;
    }
  }

  Future<void> openPdfInBrowser(int id) async {
    try {
      await _apiService.openPdfInBrowser(id);
    } catch (error) {
      rethrow;
    }
  }

  // Method to invalidate all invoice providers
  void invalidateProviders(WidgetRef ref) {
    ref.invalidate(invoiceListProvider);
  }

  Future<List<Invoice>> searchInvoices(String query) async {
    try {
      return await _apiService.searchInvoices(query);
    } catch (error) {
      rethrow;
    }
  }
}

// Individual invoice provider
final invoiceProvider = FutureProvider.family<Invoice, int>((ref, id) async {
  final apiService = ref.read(invoiceApiServiceProvider);
  return apiService.getInvoice(id);
});

// Overdue invoices provider
final overdueInvoicesProvider = FutureProvider<List<Invoice>>((ref) async {
  final apiService = ref.read(invoiceApiServiceProvider);
  return apiService.getOverdueInvoices();
});

// Recent invoices provider
final recentInvoicesProvider = FutureProvider<List<Invoice>>((ref) async {
  final apiService = ref.read(invoiceApiServiceProvider);
  final response = await apiService.getRecentInvoices();
  return response.items;
});

// Invoice statistics provider
final invoiceStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiService = ref.read(invoiceApiServiceProvider);
  return apiService.getInvoiceStats();
});

// Search filters class
class InvoiceSearchFilters {
  final int page;
  final int size;
  final InvoiceStatus? status;
  final int? customerId;
  final String? searchQuery;

  InvoiceSearchFilters({
    this.page = 1,
    this.size = 10,
    this.status,
    this.customerId,
    this.searchQuery,
  });

  InvoiceSearchFilters copyWith({
    int? page,
    int? size,
    InvoiceStatus? status,
    int? customerId,
    String? searchQuery,
  }) {
    return InvoiceSearchFilters(
      page: page ?? this.page,
      size: size ?? this.size,
      status: status ?? this.status,
      customerId: customerId ?? this.customerId,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}