// services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

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

  // Tạo booking mới
  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> bookingData) async {
    try {
      debugPrint('📅 [SUPABASE SERVICE] Đang tạo booking mới...');
      debugPrint('   - Slot ID: ${bookingData['slot_id']}');
      debugPrint('   - Duration: ${bookingData['duration']} phút');
      debugPrint('   - Amount: ${bookingData['amount']}đ');

      final response = await _client
          .from('bookings')
          .insert(bookingData)
          .select()
          .single();

      debugPrint('✅ [SUPABASE SERVICE] Tạo booking thành công - ID: ${response['id']}');
      debugPrint('   - Ticket Number: ${response['ticket_number']}');

      // Cập nhật status của slot thành 'occupied'
      await _client
          .from('slots')
          .update({'status': 'occupied'})
          .eq('id', bookingData['slot_id']);

      debugPrint('🔄 [SUPABASE SERVICE] Đã cập nhật status slot thành occupied');

      return response;
    } catch (e) {
      debugPrint('❌ [SUPABASE SERVICE] Lỗi khi tạo booking: $e');
      rethrow;
    }
  }

  // Lấy booking active của user
  Future<List<Map<String, dynamic>>> getActiveBookings(String userId) async {
    try {
      debugPrint('⏰ [SUPABASE SERVICE] Đang lấy booking active cho user: $userId');

      final now = DateTime.now().toIso8601String();

      final response = await _client
          .from('bookings')
          .select('*, slots(*), parking_lots(*)')
          .eq('user_id', userId)
          .gt('end_time', now)
          .eq('status', 'active')
          .order('start_time');

      debugPrint('✅ [SUPABASE SERVICE] Tìm thấy ${response.length} booking active');
      return response;
    } catch (e) {
      debugPrint('❌ [SUPABASE SERVICE] Lỗi khi lấy booking active: $e');
      return [];
    }
  }

  // Gia hạn booking
  Future<void> extendBooking(String bookingId, int additionalMinutes, int additionalAmount) async {
    try {
      debugPrint('⏱️ [SUPABASE SERVICE] Đang gia hạn booking: $bookingId');
      debugPrint('   - Thêm $additionalMinutes phút');
      debugPrint('   - Phí thêm: $additionalAmountđ');

      // Lấy booking hiện tại
      final booking = await _client
          .from('bookings')
          .select()
          .eq('id', bookingId)
          .single();

      final currentEndTime = DateTime.parse(booking['end_time']);
      final newEndTime = currentEndTime.add(Duration(minutes: additionalMinutes));

      // Cập nhật booking
      await _client.from('bookings').update({
        'end_time': newEndTime.toIso8601String(),
        'total_amount': (booking['total_amount'] as int) + additionalAmount,
      }).eq('id', bookingId);

      debugPrint('✅ [SUPABASE SERVICE] Gia hạn thành công');
      debugPrint('   - Thời gian kết thúc mới: $newEndTime');
    } catch (e) {
      debugPrint('❌ [SUPABASE SERVICE] Lỗi khi gia hạn booking: $e');
      rethrow;
    }
  }

  // Check-in bằng QR (cho Guard)
  Future<Map<String, dynamic>> checkInByQR(String ticketNumber) async {
    try {
      debugPrint('🎫 [SUPABASE SERVICE] Đang check-in với ticket: $ticketNumber');

      final booking = await _client
          .from('bookings')
          .select('*, slots(*), users(*)')
          .eq('ticket_number', ticketNumber)
          .eq('status', 'active')
          .maybeSingle();

      if (booking == null) {
        debugPrint('❌ [SUPABASE SERVICE] Ticket không hợp lệ hoặc đã được sử dụng');
        throw Exception('Ticket không hợp lệ');
      }

      // Cập nhật check-in time
      await _client.from('bookings').update({
        'check_in_time': DateTime.now().toIso8601String(),
        'status': 'checked_in',
      }).eq('id', booking['id']);

      debugPrint('✅ [SUPABASE SERVICE] Check-in thành công cho xe: ${booking['slots']['slot_name']}');

      return booking;
    } catch (e) {
      debugPrint('❌ [SUPABASE SERVICE] Lỗi khi check-in: $e');
      rethrow;
    }
  }

  // Check-out (cho Guard)
  Future<void> checkOut(String bookingId) async {
    try {
      debugPrint('🚪 [SUPABASE SERVICE] Đang check-out cho booking: $bookingId');

      // Cập nhật booking
      await _client.from('bookings').update({
        'check_out_time': DateTime.now().toIso8601String(),
        'status': 'completed',
      }).eq('id', bookingId);

      // Lấy slot_id từ booking
      final booking = await _client
          .from('bookings')
          .select('slot_id')
          .eq('id', bookingId)
          .single();

      // Cập nhật status slot thành available
      await _client
          .from('slots')
          .update({'status': 'available'})
          .eq('id', booking['slot_id']);

      debugPrint('✅ [SUPABASE SERVICE] Check-out thành công');
    } catch (e) {
      debugPrint('❌ [SUPABASE SERVICE] Lỗi khi check-out: $e');
      rethrow;
    }
  }

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