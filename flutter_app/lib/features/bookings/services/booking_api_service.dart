// WARNING: This is a disabled version of the booking API service
// The booking endpoints do not exist in the current backend implementation
// To enable bookings functionality:
// 1. Implement /api/v1/bookings endpoints in the backend
// 2. Add booking routes to the FastAPI router
// 3. Rename this file back to booking_api_service.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/http.dart';
import '../../../core/models/api_response.dart';
import '../models/booking.dart';

// Disabled booking API service provider
final bookingApiServiceProvider = Provider<BookingApiService>((ref) {
  return BookingApiService(ref.read(httpClientProvider));
});

class BookingApiService {
  final HttpClient _httpClient;

  BookingApiService(this._httpClient);

  // All methods throw UnimplementedError until backend endpoints are created

  Future<BookingListResponse> getBookings({
    int page = 1,
    int size = 10,
    String? status,
    String? channel,
    DateTime? startDate,
    DateTime? endDate,
    int? customerId,
  }) async {
    throw UnimplementedError('Bookings API not implemented in backend');
  }

  Future<Booking> getBooking(int id) async {
    throw UnimplementedError('Bookings API not implemented in backend');
  }

  Future<Booking> createBooking(Booking booking) async {
    throw UnimplementedError('Bookings API not implemented in backend');
  }

  Future<Booking> updateBooking(int id, Booking booking) async {
    throw UnimplementedError('Bookings API not implemented in backend');
  }

  Future<void> deleteBooking(int id) async {
    throw UnimplementedError('Bookings API not implemented in backend');
  }

  Future<List<Booking>> getTodaysBookings() async {
    throw UnimplementedError('Bookings API not implemented in backend');
  }

  Future<List<Booking>> searchBookings(String query) async {
    throw UnimplementedError('Bookings API not implemented in backend');
  }
}