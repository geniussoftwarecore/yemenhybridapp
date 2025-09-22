import 'package:fl_chart/fl_chart.dart';

class FakeData {
  // Engineer Dashboard Mock Data
  static Map<String, dynamic> getEngineerMetrics() {
    return {
      'my_open_wos_today': 8,
      'awaiting_approval': 3,
      'in_progress': 5,
    };
  }

  static List<Map<String, dynamic>> getEngineerWorkOrders() {
    return [
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
  }

  // Sales Dashboard Mock Data
  static Map<String, dynamic> getSalesMetrics() {
    return {
      'pending_approvals': 12,
      'bookings_7_days': 18,
      'monthly_revenue': 42500,
    };
  }

  static List<Map<String, dynamic>> getSalesCustomerResponses() {
    return [
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
  }

  // Admin Dashboard Mock Data
  static Map<String, dynamic> getAdminKPIs() {
    return {
      'total_customers': 1247,
      'total_vehicles': 892,
      'open_work_orders': 47,
      'monthly_revenue': 85200,
      'low_stock_parts': 23,
    };
  }

  static List<FlSpot> getRevenueChartData() {
    return [
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
  }

  static Map<String, double> getWorkOrderStatusData() {
    return {
      'In Progress': 12,
      'Pending': 8,
      'Completed': 25,
      'Waiting Parts': 5,
      'Cancelled': 2,
    };
  }

  static List<Map<String, dynamic>> getAdminWorkOrders() {
    return [
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
  }

  static List<Map<String, dynamic>> getAdminInvoices() {
    return [
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
  }

  // API Response simulation with fallback
  static Future<T> simulateApiCall<T>(T Function() fallbackData, {
    Duration delay = const Duration(milliseconds: 500),
    double failureRate = 0.3, // 30% chance of failure to test fallback
  }) async {
    await Future.delayed(delay);
    
    // Simulate random API failures
    if (DateTime.now().millisecondsSinceEpoch % 10 < (failureRate * 10)) {
      throw Exception('API temporarily unavailable');
    }
    
    return fallbackData();
  }
}