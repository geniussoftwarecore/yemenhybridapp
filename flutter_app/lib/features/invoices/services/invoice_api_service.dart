import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/http.dart';
import '../../../core/models/api_response.dart';
import '../models/invoice.dart';

final invoiceApiServiceProvider = Provider<InvoiceApiService>((ref) {
  return InvoiceApiService(ref.read(httpClientProvider));
});

class InvoiceApiService {
  final HttpClient _httpClient;

  InvoiceApiService(this._httpClient);

  Future<InvoiceListResponse> getInvoices({
    int page = 1,
    int size = 10,
    String? status,
    int? customerId,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
    };
    if (status != null) queryParams['status'] = status;
    if (customerId != null) queryParams['customer_id'] = customerId;
    
    final response = await _httpClient.get(
      '/api/v1/invoices',
      queryParameters: queryParams,
    );

    return InvoiceListResponse.fromJson(response.data);
  }

  Future<Invoice> getInvoice(int id) async {
    final response = await _httpClient.get('/api/v1/invoices/$id');
    return Invoice.fromJson(response.data);
  }

  Future<Invoice> createInvoice(Invoice invoice) async {
    final response = await _httpClient.post(
      '/api/v1/invoices',
      data: invoice.toJson(),
    );
    return Invoice.fromJson(response.data);
  }

  // Note: This endpoint may not exist in backend - check before using
  Future<Invoice> createInvoiceFromWorkOrder(int workOrderId) async {
    // Alternative: Create invoice with work_order_id in the data
    final response = await _httpClient.post(
      '/api/v1/invoices',
      data: {'work_order_id': workOrderId},
    );
    return Invoice.fromJson(response.data);
  }

  Future<Invoice> updateInvoice(int id, Invoice invoice) async {
    final response = await _httpClient.put(
      '/api/v1/invoices/$id',
      data: invoice.toJson(),
    );
    return Invoice.fromJson(response.data);
  }

  Future<void> deleteInvoice(int id) async {
    await _httpClient.delete('/api/v1/invoices/$id');
  }

  // Note: Status update endpoint may not exist - use update invoice instead
  Future<Invoice> updateStatus(int id, InvoiceStatus status) async {
    final response = await _httpClient.put(
      '/api/v1/invoices/$id',
      data: {'status': status.backendValue},
    );
    return Invoice.fromJson(response.data);
  }

  // Note: Mark as paid endpoint may not exist - use update status instead
  Future<Invoice> markAsPaid(int id, {DateTime? paidAt}) async {
    final response = await _httpClient.put(
      '/api/v1/invoices/$id',
      data: {
        'status': 'paid',
        'paid_at': paidAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      },
    );
    return Invoice.fromJson(response.data);
  }

  Future<String> generatePdf(int id) async {
    final response = await _httpClient.get('/api/v1/invoices/$id/pdf');
    return response.data['pdf_url'] ?? '';
  }

  Future<void> openPdfInBrowser(int id) async {
    try {
      final pdfUrl = await generatePdf(id);
      if (pdfUrl.isNotEmpty) {
        final uri = Uri.parse(pdfUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          throw 'Could not launch PDF URL: $pdfUrl';
        }
      } else {
        throw 'No PDF URL received from server';
      }
    } catch (e) {
      throw 'Failed to open PDF: $e';
    }
  }

  // Note: Send invoice endpoint may not exist in backend
  Future<void> sendInvoice(int id, {
    String? email,
    String? channel = 'email',
    String? message,
  }) async {
    // This functionality may need to be implemented in backend
    // For now, this is a placeholder
    throw UnimplementedError('Send invoice endpoint not implemented in backend');
  }

  Future<Invoice> addItem(int invoiceId, InvoiceItem item) async {
    final response = await _httpClient.post(
      '/api/v1/invoices/$invoiceId/items',
      data: item.toJson(),
    );
    return Invoice.fromJson(response.data);
  }

  Future<Invoice> updateItem(
    int invoiceId,
    int itemId,
    InvoiceItem item,
  ) async {
    final response = await _httpClient.put(
      '/api/v1/invoices/$invoiceId/items/$itemId',
      data: item.toJson(),
    );
    return Invoice.fromJson(response.data);
  }

  Future<Invoice> removeItem(int invoiceId, int itemId) async {
    final response = await _httpClient.delete(
      '/api/v1/invoices/$invoiceId/items/$itemId',
    );
    return Invoice.fromJson(response.data);
  }

  Future<List<Invoice>> searchInvoices(String query) async {
    final response = await _httpClient.get(
      '/api/v1/invoices',
      queryParameters: {'search': query},
    );

    return (response.data as List)
        .map((json) => Invoice.fromJson(json))
        .toList();
  }

  Future<List<Invoice>> getOverdueInvoices() async {
    final response = await _httpClient.get(
      '/api/v1/invoices',
      queryParameters: {'status': 'overdue'},
    );

    return (response.data as List)
        .map((json) => Invoice.fromJson(json))
        .toList();
  }

  Future<InvoiceListResponse> getRecentInvoices({int limit = 10}) async {
    return getInvoices(size: limit);
  }

  Future<Map<String, dynamic>> getInvoiceStats() async {
    final response = await _httpClient.get('/api/v1/invoices/stats');
    return response.data;
  }
}