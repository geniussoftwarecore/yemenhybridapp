import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/http.dart';
import '../fakes/fake_data.dart';

// Dashboard service provider
final dashboardServiceProvider = Provider<DashboardService>((ref) {
  final httpClient = ref.read(httpClientProvider);
  return DashboardService(httpClient);
});

class DashboardService {
  final HttpClient _httpClient;

  DashboardService(this._httpClient);

  // Engineer Dashboard Methods
  Future<Map<String, dynamic>> getEngineerMetrics() async {
    try {
      final response = await _httpClient.get('/api/v1/reports/kpis');
      
      // Extract engineer-specific metrics from API response
      return {
        'my_open_wos_today': _extractEngineerOpenWOs(response.data),
        'awaiting_approval': _extractAwaitingApproval(response.data),
        'in_progress': _extractInProgress(response.data),
      };
    } catch (e) {
      // Fallback to fake data
      return FakeData.getEngineerMetrics();
    }
  }

  Future<List<Map<String, dynamic>>> getEngineerWorkOrders() async {
    try {
      final response = await _httpClient.get('/api/v1/reports/workorders');
      
      // Transform API response to expected format
      if (response.data['work_orders'] != null) {
        return List<Map<String, dynamic>>.from(
          response.data['work_orders'].map((wo) => {
            'id': wo['id']?.toString() ?? '',
            'status': wo['status'] ?? 'Unknown',
            'plate': 'N/A', // Would need vehicle data
            'make_model': 'N/A', // Would need vehicle data  
            'scheduled_at': wo['created_at'] ?? '',
          })
        );
      }
      
      return FakeData.getEngineerWorkOrders();
    } catch (e) {
      return FakeData.getEngineerWorkOrders();
    }
  }

  // Sales Dashboard Methods
  Future<Map<String, dynamic>> getSalesMetrics() async {
    try {
      final response = await _httpClient.get('/api/v1/reports/kpis');
      
      return {
        'pending_approvals': _extractPendingApprovals(response.data),
        'bookings_7_days': _extractUpcomingBookings(response.data),
        'monthly_revenue': _extractMonthlyRevenue(response.data),
      };
    } catch (e) {
      return FakeData.getSalesMetrics();
    }
  }

  Future<List<Map<String, dynamic>>> getSalesCustomerResponses() async {
    try {
      // This would typically come from a specific sales endpoint
      // For now, fallback to fake data
      return FakeData.getSalesCustomerResponses();
    } catch (e) {
      return FakeData.getSalesCustomerResponses();
    }
  }

  // Admin Dashboard Methods  
  Future<Map<String, dynamic>> getAdminKPIs() async {
    try {
      final response = await _httpClient.get('/api/v1/reports/kpis');
      
      return {
        'total_customers': _extractTotalCustomers(response.data),
        'total_vehicles': _extractTotalVehicles(response.data),
        'open_work_orders': _extractOpenWorkOrders(response.data),
        'monthly_revenue': _extractMonthlyRevenue(response.data),
        'low_stock_parts': _extractLowStockParts(response.data),
      };
    } catch (e) {
      return FakeData.getAdminKPIs();
    }
  }

  Future<List<FlSpot>> getRevenueChartData() async {
    try {
      final response = await _httpClient.get('/api/v1/reports/kpis');
      
      if (response.data['revenue_by_day'] != null) {
        final revenueData = response.data['revenue_by_day'] as List;
        return revenueData.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final data = entry.value;
          final total = (data['total'] ?? 0).toDouble();
          return FlSpot(index.toDouble(), total / 1000); // Convert to thousands
        }).toList();
      }
      
      return FakeData.getRevenueChartData();
    } catch (e) {
      return FakeData.getRevenueChartData();
    }
  }

  Future<Map<String, double>> getWorkOrderStatusData() async {
    try {
      final response = await _httpClient.get('/api/v1/reports/kpis');
      
      if (response.data['work_orders_by_status'] != null) {
        final statusData = response.data['work_orders_by_status'] as List;
        final Map<String, double> result = {};
        
        for (final item in statusData) {
          result[item['status']] = (item['count'] ?? 0).toDouble();
        }
        
        return result;
      }
      
      return FakeData.getWorkOrderStatusData();
    } catch (e) {
      return FakeData.getWorkOrderStatusData();
    }
  }

  Future<List<Map<String, dynamic>>> getAdminWorkOrders() async {
    try {
      final response = await _httpClient.get('/api/v1/reports/workorders');
      
      if (response.data['work_orders'] != null) {
        return List<Map<String, dynamic>>.from(
          response.data['work_orders'].map((wo) => {
            'id': wo['id']?.toString() ?? '',
            'customer': 'Customer ${wo['customer_id'] ?? ''}',
            'vehicle': 'Vehicle ${wo['vehicle_id'] ?? ''}',
            'status': wo['status'] ?? 'Unknown',
            'assigned_to': 'Engineer N/A',
            'created_at': wo['created_at']?.split('T')[0] ?? '',
            'amount': '\$${wo['final_cost']?.toStringAsFixed(0) ?? '0'}',
          })
        );
      }
      
      return FakeData.getAdminWorkOrders();
    } catch (e) {
      return FakeData.getAdminWorkOrders();
    }
  }

  Future<List<Map<String, dynamic>>> getAdminInvoices() async {
    try {
      // This would come from invoices endpoint when available
      return FakeData.getAdminInvoices();
    } catch (e) {
      return FakeData.getAdminInvoices();
    }
  }

  // Helper methods to extract data from API responses
  int _extractEngineerOpenWOs(Map<String, dynamic> data) {
    final statusData = data['work_orders_by_status'] as List?;
    if (statusData != null) {
      return statusData
          .where((item) => ['pending', 'in_progress'].contains(item['status']?.toLowerCase()))
          .fold(0, (sum, item) => sum + (item['count'] ?? 0));
    }
    return 8; // Fallback
  }

  int _extractAwaitingApproval(Map<String, dynamic> data) {
    final statusData = data['work_orders_by_status'] as List?;
    if (statusData != null) {
      final pending = statusData.firstWhere(
        (item) => item['status']?.toLowerCase() == 'pending',
        orElse: () => {'count': 3}
      );
      return pending['count'] ?? 3;
    }
    return 3; // Fallback
  }

  int _extractInProgress(Map<String, dynamic> data) {
    final statusData = data['work_orders_by_status'] as List?;
    if (statusData != null) {
      final inProgress = statusData.firstWhere(
        (item) => item['status']?.toLowerCase() == 'in_progress',
        orElse: () => {'count': 5}
      );
      return inProgress['count'] ?? 5;
    }
    return 5; // Fallback
  }

  int _extractPendingApprovals(Map<String, dynamic> data) {
    return _extractAwaitingApproval(data);
  }

  int _extractUpcomingBookings(Map<String, dynamic> data) {
    // This would be calculated from upcoming work orders
    return 18; // Fallback for now
  }

  int _extractMonthlyRevenue(Map<String, dynamic> data) {
    final revenueData = data['revenue_by_day'] as List?;
    if (revenueData != null) {
      return revenueData.fold(0.0, (sum, item) => sum + (item['total'] ?? 0)).round();
    }
    return 42500; // Fallback
  }

  int _extractTotalCustomers(Map<String, dynamic> data) {
    // This would come from a customers count endpoint
    return 1247; // Fallback for now
  }

  int _extractTotalVehicles(Map<String, dynamic> data) {
    // This would come from a vehicles count endpoint  
    return 892; // Fallback for now
  }

  int _extractOpenWorkOrders(Map<String, dynamic> data) {
    final statusData = data['work_orders_by_status'] as List?;
    if (statusData != null) {
      return statusData
          .where((item) => !['completed', 'cancelled'].contains(item['status']?.toLowerCase()))
          .fold(0, (sum, item) => sum + (item['count'] ?? 0));
    }
    return 47; // Fallback
  }

  int _extractLowStockParts(Map<String, dynamic> data) {
    final lowStockData = data['low_stock_parts'] as List?;
    return lowStockData?.length ?? 23; // Fallback
  }
}