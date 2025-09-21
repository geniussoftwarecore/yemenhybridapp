import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/http.dart';
import '../../../core/models/api_response.dart';
import '../models/booking.dart';

final bookingApiServiceProvider = Provider<BookingApiService>((ref) {
  return BookingApiService(ref.read(httpClientProvider));
});

class BookingApiService {
  final HttpClient _httpClient;

  BookingApiService(this._httpClient);

  Future<BookingListResponse> getBookings({
    int page = 1,
    int size = 10,
    String? status,
    String? channel,
    DateTime? startDate,
    DateTime? endDate,
    int? customerId,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
    };
    if (status != null) queryParams['status'] = status;
    if (channel != null) queryParams['channel'] = channel;
    if (customerId != null) queryParams['customer_id'] = customerId;
    if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
    if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
    
    final response = await _httpClient.get(
      '/api/v1/bookings',
      queryParameters: queryParams,
    );

    return BookingListResponse.fromJson(response.data);
  }

  Future<Booking> getBooking(int id) async {
    final response = await _httpClient.get('/api/v1/bookings/$id');
    return Booking.fromJson(response.data);
  }

  Future<Booking> createBooking(Booking booking) async {
    final response = await _httpClient.post(
      '/api/v1/bookings',
      data: booking.toJson(),
    );
    return Booking.fromJson(response.data);
  }

  Future<Booking> updateBooking(int id, Booking booking) async {
    final response = await _httpClient.put(
      '/api/v1/bookings/$id',
      data: booking.toJson(),
    );
    return Booking.fromJson(response.data);
  }

  Future<void> deleteBooking(int id) async {
    await _httpClient.delete('/api/v1/bookings/$id');
  }

  Future<Booking> updateStatus(int id, BookingStatus status) async {
    final response = await _httpClient.put(
      '/api/v1/bookings/$id/status',
      data: {'status': status.backendValue},
    );
    return Booking.fromJson(response.data);
  }

  Future<Booking> confirmBooking(int id) async {
    final response = await _httpClient.post('/api/v1/bookings/$id/confirm');
    return Booking.fromJson(response.data);
  }

  Future<Booking> cancelBooking(int id, {String? reason}) async {
    final response = await _httpClient.post(
      '/api/v1/bookings/$id/cancel',
      data: {'reason': reason},
    );
    return Booking.fromJson(response.data);
  }

  Future<void> sendBookingNotification(
    int id, {
    required BookingChannel channel,
    String? message,
    String? phoneNumber,
    String? email,
  }) async {
    await _httpClient.post(
      '/api/v1/bookings/$id/send-notification',
      data: {
        'channel': channel.backendValue,
        'message': message,
        'phone_number': phoneNumber,
        'email': email,
      },
    );
  }

  Future<List<Booking>> getTodaysBookings() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    return getBookings(
      startDate: startOfDay,
      endDate: endOfDay,
    );
  }

  Future<List<Booking>> getUpcomingBookings({int days = 7}) async {
    final now = DateTime.now();
    final endDate = now.add(Duration(days: days));

    return getBookings(
      startDate: now,
      endDate: endDate,
      status: 'confirmed',
    );
  }

  Future<List<Booking>> getBookingsByCustomer(int customerId) async {
    return getBookings(customerId: customerId);
  }

  Future<List<Booking>> getBookingsByChannel(BookingChannel channel) async {
    return getBookings(channel: channel.backendValue);
  }

  Future<List<Booking>> searchBookings(String query) async {
    final response = await _httpClient.get(
      '/api/v1/bookings',
      queryParameters: {'search': query},
    );

    return (response.data as List)
        .map((json) => Booking.fromJson(json))
        .toList();
  }

  Future<Map<String, dynamic>> getBookingStats() async {
    final response = await _httpClient.get('/api/v1/bookings/stats');
    return response.data;
  }

  Future<List<Map<String, dynamic>>> getAvailableTimeSlots(DateTime date) async {
    final response = await _httpClient.get(
      '/api/v1/bookings/available-slots',
      queryParameters: {
        'date': date.toIso8601String().split('T')[0], // YYYY-MM-DD format
      },
    );

    return List<Map<String, dynamic>>.from(response.data);
  }

  // WhatsApp integration methods
  Future<void> sendWhatsAppBookingConfirmation(
    int id, {
    required String phoneNumber,
    String? customMessage,
  }) async {
    await sendBookingNotification(
      id,
      channel: BookingChannel.whatsapp,
      message: customMessage ?? 'Your booking has been confirmed.',
      phoneNumber: phoneNumber,
    );
  }

  Future<void> sendEmailBookingConfirmation(
    int id, {
    required String email,
    String? customMessage,
  }) async {
    await sendBookingNotification(
      id,
      channel: BookingChannel.email,
      message: customMessage ?? 'Your booking has been confirmed.',
      email: email,
    );
  }
}