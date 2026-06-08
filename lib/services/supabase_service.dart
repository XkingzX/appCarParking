// services/supabase_service.dart
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // ==================== PROFILES ====================

  // Lấy thông tin user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      debugPrint('🔍 [SUPABASE SERVICE] Đang lấy profile cho user: $userId');

      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        // Đảm bảo balance là số
        if (response.containsKey('balance') && response['balance'] is String) {
          response['balance'] = num.tryParse(response['balance'] as String) ?? 0;
        }
        debugPrint('✅ [SUPABASE SERVICE] Tìm thấy profile: ${response['full_name']}');
        return response;
      } else {
        debugPrint('⚠️ [SUPABASE SERVICE] Không tìm thấy profile cho user: $userId');
        return null;
      }
    } catch (e) {
      debugPrint('❌ [SUPABASE SERVICE] Lỗi khi lấy profile: $e');
      return null;
    }
  }

  // Tạo user profile mới
  Future<void> createUserProfile(Map<String, dynamic> profileData) async {
    try {
      debugPrint('📝 [SUPABASE SERVICE] Đang tạo profile mới...');
      debugPrint('📝 [SUPABASE SERVICE] Data: $profileData');

      // Đảm bảo balance là số
      final dataToInsert = Map<String, dynamic>.from(profileData);
      if (dataToInsert.containsKey('balance')) {
        // Chuyển đổi balance sang số nếu nó là string
        if (dataToInsert['balance'] is String) {
          dataToInsert['balance'] = num.tryParse(dataToInsert['balance'] as String) ?? 0;
        }
      } else {
        dataToInsert['balance'] = 0;
      }

      final response = await _client.from('profiles').insert(dataToInsert);
      debugPrint('✅ [SUPABASE SERVICE] Tạo profile thành công');

    } catch (e) {
      debugPrint('❌ [SUPABASE SERVICE] Lỗi khi tạo profile: $e');
      rethrow;
    }
  }

  // Cập nhật user profile
  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    try {
      debugPrint('✏️ [SUPABASE SERVICE] Đang cập nhật profile cho user: $userId');

      await _client.from('profiles').update(updates).eq('id', userId);

      debugPrint('✅ [SUPABASE SERVICE] Cập nhật profile thành công');
    } catch (e) {
      debugPrint('❌ [SUPABASE SERVICE] Lỗi khi cập nhật profile: $e');
      rethrow;
    }
  }

  // ==================== PARKING LOTS ====================

  // Lấy danh sách bãi đỗ xe
  Future<List<Map<String, dynamic>>> getParkingLots() async {
    try {
      debugPrint('📍 [SUPABASE SERVICE] Đang lấy danh sách bãi đỗ xe...');

      final response = await _client
          .from('parking_lots')
          .select()
          .order('name');

      debugPrint('✅ [SUPABASE SERVICE] Lấy được ${response.length} bãi đỗ xe');
      return response;
    } catch (e) {
      debugPrint('❌ [SUPABASE SERVICE] Lỗi khi lấy danh sách bãi đỗ: $e');
      return [];
    }
  }

  // ==================== PARKING PRICES ====================

  // Lấy giá đỗ xe theo bãi
  Future<List<Map<String, dynamic>>> getParkingPrices(String parkingLotId) async {
    try {
      debugPrint('💰 [SUPABASE SERVICE] Đang lấy giá cho bãi: $parkingLotId');

      final response = await _client
          .from('parking_prices')
          .select()
          .eq('parking_lot_id', parkingLotId)
          .order('price');

      debugPrint('✅ [SUPABASE SERVICE] Lấy được ${response.length} mức giá');
      return response;
    } catch (e) {
      debugPrint('❌ [SUPABASE SERVICE] Lỗi khi lấy giá: $e');
      return [];
    }
  }

  // Lấy giá theo bãi đỗ và loại thời gian
  Future<double?> getPriceByDurationType(String parkingLotId, String durationType) async {
    try {
      final response = await _client
          .from('parking_prices')
          .select('price')
          .eq('parking_lot_id', parkingLotId)
          .eq('duration_type', durationType)
          .maybeSingle();

      if (response != null) {
        return (response['price'] as num?)?.toDouble();
      }
      return null;
    } catch (e) {
      debugPrint('❌ [SUPABASE SERVICE] Lỗi khi lấy giá theo loại: $e');
      return null;
    }
  }

  // ==================== SLOTS ====================

  // Lấy danh sách slot theo bãi đỗ
  Future<List<Map<String, dynamic>>> getSlotsByParkingLot(String parkingLotId) async {
    try {
      debugPrint('🅿️ [SUPABASE SERVICE] Đang lấy danh sách slot cho bãi: $parkingLotId');

      final response = await _client
          .from('slots')
          .select()
          .eq('parking_lot_id', parkingLotId)
          .order('slot_name');

      debugPrint('✅ [SUPABASE SERVICE] Lấy được ${response.length} slot');
      return response;
    } catch (e) {
      debugPrint('❌ [SUPABASE SERVICE] Lỗi khi lấy danh sách slot: $e');
      return [];
    }
  }

  // Lấy danh sách slot trống theo bãi đỗ
  Future<List<Map<String, dynamic>>> getAvailableSlots(String parkingLotId) async {
    try {
      debugPrint('🅿️ [SUPABASE SERVICE] Đang lấy slot trống cho bãi: $parkingLotId');

      final response = await _client
          .from('slots')
          .select()
          .eq('parking_lot_id', parkingLotId)
          .eq('status', 'available')
          .order('slot_name');

      debugPrint('✅ [SUPABASE SERVICE] Tìm thấy ${response.length} slot trống');
      return response;
    } catch (e) {
      debugPrint('❌ [SUPABASE SERVICE] Lỗi khi lấy slot trống: $e');
      return [];
    }
  }

  // ==================== GUARD METHODS ====================

  // Lấy thông tin bãi đỗ mà bảo vệ được phân công
  Future<Map<String, dynamic>?> getGuardAssignment(String guardId) async {
    try {
      debugPrint('🛡️ [SUPABASE SERVICE] Lấy phân công cho Guard: $guardId');
      final response = await _client
          .from('guard_assignments')
          .select('parking_lot_id, parking_lots(name)')
          .eq('guard_id', guardId)
          .maybeSingle();

      if (response != null) {
        return {
          'parking_lot_id': response['parking_lot_id'],
          'parking_lot_name': response['parking_lots']['name'],
        };
      }
      return null;
    } catch (e) {
      debugPrint('❌ [SUPABASE SERVICE] Lỗi lấy phân công Guard: $e');
      return null;
    }
  }

  // Lấy thống kê số lượng xe trong bãi
  Future<Map<String, int>> getGuardParkingStats(String parkingLotId) async {
    try {
      final response = await _client
          .from('slots')
          .select('status')
          .eq('parking_lot_id', parkingLotId);

      int total = response.length;
      int occupied = response.where((s) => s['status'] == 'occupied' || s['status'] == 'reserved').length;
      int available = response.where((s) => s['status'] == 'available').length;

      return {
        'total': total,
        'occupied': occupied,
        'available': available,
      };
    } catch (e) {
      debugPrint('❌ [SUPABASE SERVICE] Lỗi lấy thống kê bãi đỗ: $e');
      return {'total': 0, 'occupied': 0, 'available': 0};
    }
  }
  // Lấy danh sách slot kèm thông tin booking cho Guard
  Future<List<Map<String, dynamic>>> getGuardSlotStatus(String parkingLotId) async {
    try {
      debugPrint('🛡️ [SUPABASE SERVICE] Đang lấy trạng thái slot cho Guard (Bãi: $parkingLotId)');

      // Query slots and left join active bookings
      final response = await _client
          .from('slots')
          .select('''
            *,
            bookings!bookings_slot_id_fkey (
              id, start_time, duration, status,
              vehicles!bookings_vehicle_id_fkey (license_plate)
            )
          ''')
          .eq('parking_lot_id', parkingLotId)
          .order('slot_name');
          
      // Lọc ra booking active ở phía client hoặc có thể xử lý ở backend nếu complex
      final slots = List<Map<String, dynamic>>.from(response);
      for (var slot in slots) {
        if (slot['bookings'] != null) {
          final bookings = List<Map<String, dynamic>>.from(slot['bookings']);
          // Lấy booking đang confirmed
          final activeBooking = bookings.where((b) => b['status'] == 'confirmed').toList();
          slot['active_booking'] = activeBooking.isNotEmpty ? activeBooking.first : null;
        }
      }

      debugPrint('✅ [SUPABASE SERVICE] Lấy được ${slots.length} slot cho Guard');
      return slots;
    } catch (e) {
      debugPrint('❌ [SUPABASE SERVICE] Lỗi lấy thông tin slot Guard: $e');
      return [];
    }
  }

  // Lấy danh sách slot phân trang (Lazy Loading)
  Future<List<Map<String, dynamic>>> getSlotsPaginated(String parkingLotId, String zone, int offset, int limit) async {
    try {
      debugPrint('🅿️ [SUPABASE SERVICE] Đang tải slots phân trang: Bãi $parkingLotId, Khu $zone (offset: $offset)');

      final query = _client
          .from('slots')
          .select()
          .eq('parking_lot_id', parkingLotId);
          
      if (zone.isNotEmpty && zone != 'All') {
        query.eq('zone', zone);
      }

      final response = await query
          .order('slot_name')
          .range(offset, offset + limit - 1);

      debugPrint('✅ [SUPABASE SERVICE] Tải thêm được ${response.length} slots');
      return response;
    } catch (e) {
      debugPrint('❌ [SUPABASE SERVICE] Lỗi tải slots phân trang: $e');
      return [];
    }
  }

  // ==================== VEHICLES ====================

  // Lấy danh sách xe của user
  Future<List<Map<String, dynamic>>> getUserVehicles(String userId) async {
    try {
      debugPrint('🚗 [SUPABASE SERVICE] Đang lấy danh sách xe cho user: $userId');

      final response = await _client
          .from('vehicles')
          .select()
          .eq('user_id', userId);

      debugPrint('✅ [SUPABASE SERVICE] Lấy được ${response.length} xe');
      return response;
    } catch (e) {
      debugPrint('❌ [SUPABASE SERVICE] Lỗi khi lấy danh sách xe: $e');
      return [];
    }
  }

  // Thêm xe mới
  Future<void> addVehicle(Map<String, dynamic> vehicleData) async {
    try {
      debugPrint('➕ [SUPABASE SERVICE] Đang thêm xe mới: ${vehicleData['license_plate']}');

      await _client.from('vehicles').insert(vehicleData);

      debugPrint('✅ [SUPABASE SERVICE] Thêm xe thành công');
    } catch (e) {
      debugPrint('❌ [SUPABASE SERVICE] Lỗi khi thêm xe: $e');
      rethrow;
    }
  }

  // ==================== BOOKINGS ====================

  /// Tạo ticket number unique
  String _generateTicketNumber() {
    final now = DateTime.now();
    final random = Random().nextInt(9999).toString().padLeft(4, '0');
    return 'PKG-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}-$random';
  }

  /// Chuyển đổi duration text thành PostgreSQL interval format
  /// VD: "1 Giờ" → "1 hours", "2 Giờ" → "2 hours", "Qua đêm" → "12 hours"
  String _convertDurationToInterval(String durationText) {
    final lower = durationText.toLowerCase().trim();

    // Đã là format interval rồi
    if (lower.contains('hours') || lower.contains('days') || lower.contains('months')) {
      return lower;
    }

    // Parse "X Giờ" format
    final hoursRegex = RegExp(r'(\d+)\s*giờ', caseSensitive: false);
    final hoursMatch = hoursRegex.firstMatch(lower);
    if (hoursMatch != null) {
      return '${hoursMatch.group(1)} hours';
    }

    // Special cases
    if (lower.contains('qua đêm')) return '12 hours';
    if (lower.contains('cả ngày')) return '1 days';
    if (lower.contains('tuần')) return '7 days';
    if (lower.contains('tháng')) return '30 days';

    return '1 hours'; // default
  }

  // Tạo booking mới
  Future<Map<String, dynamic>> createBooking({
    required String userId,
    required String slotId,
    String? vehicleId,
    required String durationText,
    required String paymentMethod,
  }) async {
    try {
      debugPrint('📅 [SUPABASE SERVICE] Đang tạo booking mới...');
      debugPrint('   - Slot ID: $slotId');
      debugPrint('   - Duration: $durationText');
      debugPrint('   - Payment: $paymentMethod');

      final ticketNumber = _generateTicketNumber();
      final intervalDuration = _convertDurationToInterval(durationText);

      final bookingData = {
        'user_id': userId,
        'slot_id': slotId,
        'vehicle_id': vehicleId,
        'start_time': DateTime.now().toIso8601String(),
        'duration': intervalDuration,
        'payment_method': paymentMethod,
        'ticket_number': ticketNumber,
        'status': 'confirmed',
      };

      // Insert booking - trigger handle_booking_slot_status sẽ tự update slot status
      final response = await _client
          .from('bookings')
          .insert(bookingData)
          .select()
          .single();

      debugPrint('✅ [SUPABASE SERVICE] Tạo booking thành công - ID: ${response['id']}');
      debugPrint('   - Ticket: $ticketNumber');

      return response;
    } catch (e) {
      debugPrint('❌ [SUPABASE SERVICE] Lỗi khi tạo booking: $e');
      rethrow;
    }
  }

  // Lấy booking đang active (confirmed) của user
  Future<List<Map<String, dynamic>>> getActiveBookings(String userId) async {
    try {
      debugPrint('⏰ [SUPABASE SERVICE] Đang lấy booking active cho user: $userId');

      final response = await _client
          .from('bookings')
          .select('''
            *,
            slots!bookings_slot_id_fkey (
              id,
              slot_name,
              parking_lot_id,
              status,
              parking_lots (
                id,
                name,
                location
              )
            ),
            vehicles!bookings_vehicle_id_fkey (
              id,
              name,
              license_plate,
              type
            )
          ''')
          .eq('user_id', userId)
          .eq('status', 'confirmed')
          .order('start_time', ascending: false);

      debugPrint('✅ [SUPABASE SERVICE] Tìm thấy ${response.length} booking active');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ [SUPABASE SERVICE] Lỗi khi lấy booking active: $e');
      return [];
    }
  }

  // Lấy lịch sử booking (completed, cancelled, expired) của user
  Future<List<Map<String, dynamic>>> getBookingHistory(String userId) async {
    try {
      debugPrint('📋 [SUPABASE SERVICE] Đang lấy lịch sử booking cho user: $userId');

      final response = await _client
          .from('bookings')
          .select('''
            *,
            slots!bookings_slot_id_fkey (
              id,
              slot_name,
              parking_lot_id,
              status,
              parking_lots (
                id,
                name,
                location
              )
            ),
            vehicles!bookings_vehicle_id_fkey (
              id,
              name,
              license_plate,
              type
            )
          ''')
          .eq('user_id', userId)
          .inFilter('status', ['completed', 'cancelled', 'expired'])
          .order('created_at', ascending: false);

      debugPrint('✅ [SUPABASE SERVICE] Tìm thấy ${response.length} booking lịch sử');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ [SUPABASE SERVICE] Lỗi khi lấy lịch sử booking: $e');
      return [];
    }
  }

  // Hủy booking
  Future<void> cancelBooking(String bookingId) async {
    try {
      debugPrint('❌ [SUPABASE SERVICE] Đang hủy booking: $bookingId');

      await _client
          .from('bookings')
          .update({'status': 'cancelled'})
          .eq('id', bookingId);

      // Trigger handle_booking_slot_status sẽ tự update slot status về available
      debugPrint('✅ [SUPABASE SERVICE] Hủy booking thành công');
    } catch (e) {
      debugPrint('❌ [SUPABASE SERVICE] Lỗi khi hủy booking: $e');
      rethrow;
    }
  }

  // Check-in bằng QR (cho Guard)
  Future<Map<String, dynamic>> checkInByQR(String ticketNumber) async {
    try {
      debugPrint('🎫 [SUPABASE SERVICE] Đang check-in với ticket: $ticketNumber');

      final booking = await _client
          .from('bookings')
          .select('''
            *,
            slots!bookings_slot_id_fkey (
              id,
              slot_name,
              parking_lot_id,
              parking_lots (name)
            ),
            vehicles!bookings_vehicle_id_fkey (
              id,
              name,
              license_plate
            )
          ''')
          .eq('ticket_number', ticketNumber)
          .eq('status', 'confirmed')
          .maybeSingle();

      if (booking == null) {
        debugPrint('❌ [SUPABASE SERVICE] Ticket không hợp lệ hoặc đã được sử dụng');
        throw Exception('Ticket không hợp lệ');
      }

      debugPrint('✅ [SUPABASE SERVICE] Check-in thành công');
      return booking;
    } catch (e) {
      debugPrint('❌ [SUPABASE SERVICE] Lỗi khi check-in: $e');
      rethrow;
    }
  }

  // Check-out - đánh dấu completed (cho Guard)
  Future<void> checkOut(String bookingId) async {
    try {
      debugPrint('🚪 [SUPABASE SERVICE] Đang check-out cho booking: $bookingId');

      // Cập nhật booking status → trigger sẽ tự free slot
      await _client.from('bookings').update({
        'status': 'completed',
      }).eq('id', bookingId);

      debugPrint('✅ [SUPABASE SERVICE] Check-out thành công');
    } catch (e) {
      debugPrint('❌ [SUPABASE SERVICE] Lỗi khi check-out: $e');
      rethrow;
    }
  }

  // ==================== REALTIME ====================

  // Subscribe vào realtime cho slots
  void subscribeToSlots(String parkingLotId, Function(List<Map<String, dynamic>>) onUpdate) {
    debugPrint('🔌 [SUPABASE SERVICE] Đang kết nối realtime cho slots của bãi: $parkingLotId');

    _client
        .channel('slots_channel')
        .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'slots',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'parking_lot_id',
        value: parkingLotId,
      ),
      callback: (payload) async {
        debugPrint('🔄 [SUPABASE SERVICE] Real-time update: Slot status thay đổi');
        final slots = await getSlotsByParkingLot(parkingLotId);
        onUpdate(slots);
      },
    )
        .subscribe();
  }

  // Unsubscribe realtime
  void unsubscribeFromSlots() {
    debugPrint('🔌 [SUPABASE SERVICE] Ngắt kết nối realtime');
    _client.removeChannel(_client.channel('slots_channel'));
  }
}