import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/booking_api_service.dart';
import '../models/booking.dart';
import '../../../core/models/api_response.dart';

// Booking search filters state
final bookingSearchFiltersProvider = StateProvider<BookingSearchFilters>((ref) {
  return BookingSearchFilters();
});

// Booking list provider with search filters
final bookingListProvider = FutureProvider<List<Booking>>((ref) async {
  final apiService = ref.read(bookingApiServiceProvider);
  final filters = ref.watch(bookingSearchFiltersProvider);
  
  final response = await apiService.getBookings(
    page: filters.page,
    size: filters.size,
    status: filters.status?.backendValue,
    channel: filters.channel?.backendValue,
    startDate: filters.startDate,
    endDate: filters.endDate,
    customerId: filters.customerId,
  );
  
  return response.items;
});

// Booking notifier for CRUD operations
final bookingNotifierProvider = StateNotifierProvider<BookingNotifier, AsyncValue<List<Booking>>>((ref) {
  return BookingNotifier(ref.read(bookingApiServiceProvider));
});

class BookingNotifier extends StateNotifier<AsyncValue<List<Booking>>> {
  final BookingApiService _apiService;

  BookingNotifier(this._apiService) : super(const AsyncValue.loading()) {
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    try {
      state = const AsyncValue.loading();
      final response = await _apiService.getBookings();
      state = AsyncValue.data(response.items);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await _loadBookings();
  }

  Future<Booking> createBooking(Booking booking) async {
    try {
      final newBooking = await _apiService.createBooking(booking);
      // Refresh the list
      await _loadBookings();
      return newBooking;
    } catch (error) {
      rethrow;
    }
  }

  Future<Booking> updateBooking(int id, Booking booking) async {
    try {
      final updatedBooking = await _apiService.updateBooking(id, booking);
      // Refresh the list
      await _loadBookings();
      return updatedBooking;
    } catch (error) {
      rethrow;
    }
  }

  Future<void> deleteBooking(int id) async {
    try {
      await _apiService.deleteBooking(id);
      // Refresh the list
      await _loadBookings();
    } catch (error) {
      rethrow;
    }
  }

  Future<Booking> updateStatus(int id, BookingStatus status) async {
    try {
      final updatedBooking = await _apiService.updateStatus(id, status);
      // Refresh the list
      await _loadBookings();
      return updatedBooking;
    } catch (error) {
      rethrow;
    }
  }

  Future<Booking> confirmBooking(int id) async {
    try {
      final updatedBooking = await _apiService.confirmBooking(id);
      // Refresh the list
      await _loadBookings();
      return updatedBooking;
    } catch (error) {
      rethrow;
    }
  }

  Future<Booking> cancelBooking(int id, {String? reason}) async {
    try {
      final updatedBooking = await _apiService.cancelBooking(id, reason: reason);
      // Refresh the list
      await _loadBookings();
      return updatedBooking;
    } catch (error) {
      rethrow;
    }
  }

  Future<void> sendBookingNotification(
    int id, {
    required BookingChannel channel,
    String? message,
    String? phoneNumber,
    String? email,
  }) async {
    try {
      await _apiService.sendBookingNotification(
        id,
        channel: channel,
        message: message,
        phoneNumber: phoneNumber,
        email: email,
      );
    } catch (error) {
      rethrow;
    }
  }

  // Method to invalidate all booking providers
  void invalidateProviders(WidgetRef ref) {
    ref.invalidate(bookingListProvider);
  }

  Future<List<Booking>> searchBookings(String query) async {
    try {
      return await _apiService.searchBookings(query);
    } catch (error) {
      rethrow;
    }
  }
}

// Individual booking provider
final bookingProvider = FutureProvider.family<Booking, int>((ref, id) async {
  final apiService = ref.read(bookingApiServiceProvider);
  return apiService.getBooking(id);
});

// Today's bookings provider
final todaysBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final apiService = ref.read(bookingApiServiceProvider);
  final response = await apiService.getTodaysBookings();
  return response.items;
});

// Upcoming bookings provider
final upcomingBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final apiService = ref.read(bookingApiServiceProvider);
  final response = await apiService.getUpcomingBookings();
  return response.items;
});

// Bookings by customer provider
final bookingsByCustomerProvider = FutureProvider.family<List<Booking>, int>((ref, customerId) async {
  final apiService = ref.read(bookingApiServiceProvider);
  final response = await apiService.getBookingsByCustomer(customerId);
  return response.items;
});

// Bookings by channel provider
final bookingsByChannelProvider = FutureProvider.family<List<Booking>, BookingChannel>((ref, channel) async {
  final apiService = ref.read(bookingApiServiceProvider);
  final response = await apiService.getBookingsByChannel(channel);
  return response.items;
});

// Booking statistics provider
final bookingStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiService = ref.read(bookingApiServiceProvider);
  return apiService.getBookingStats();
});

// Available time slots provider
final availableTimeSlotsProvider = FutureProvider.family<List<Map<String, dynamic>>, DateTime>((ref, date) async {
  final apiService = ref.read(bookingApiServiceProvider);
  return apiService.getAvailableTimeSlots(date);
});

// Search filters class
class BookingSearchFilters {
  final int page;
  final int size;
  final BookingStatus? status;
  final BookingChannel? channel;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? customerId;
  final String? searchQuery;

  BookingSearchFilters({
    this.page = 1,
    this.size = 10,
    this.status,
    this.channel,
    this.startDate,
    this.endDate,
    this.customerId,
    this.searchQuery,
  });

  BookingSearchFilters copyWith({
    int? page,
    int? size,
    BookingStatus? status,
    BookingChannel? channel,
    DateTime? startDate,
    DateTime? endDate,
    int? customerId,
    String? searchQuery,
  }) {
    return BookingSearchFilters(
      page: page ?? this.page,
      size: size ?? this.size,
      status: status ?? this.status,
      channel: channel ?? this.channel,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      customerId: customerId ?? this.customerId,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}