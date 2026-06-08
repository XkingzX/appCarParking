// model/booking_model.dart
class BookingModel {
  final String id;
  final String userId;
  final String? slotId;
  final String? vehicleId;
  final DateTime startTime;
  final String duration; // PostgreSQL interval as string
  final String? paymentMethod;
  final String? ticketNumber;
  final DateTime createdAt;
  final String status;

  // Joined fields (from relationships)
  final String? slotName;
  final String? parkingLotId;
  final String? parkingLotName;
  final String? parkingLotLocation;
  final String? vehicleName;
  final String? licensePlate;
  final String? vehicleType;

  BookingModel({
    required this.id,
    required this.userId,
    this.slotId,
    this.vehicleId,
    required this.startTime,
    required this.duration,
    this.paymentMethod,
    this.ticketNumber,
    required this.createdAt,
    required this.status,
    this.slotName,
    this.parkingLotId,
    this.parkingLotName,
    this.parkingLotLocation,
    this.vehicleName,
    this.licensePlate,
    this.vehicleType,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    // Extract nested slot data
    final slotData = json['slots'] as Map<String, dynamic>?;
    // Extract nested parking_lot data (through slot)
    final parkingLotData = slotData?['parking_lots'] as Map<String, dynamic>?;
    // Extract nested vehicle data
    final vehicleData = json['vehicles'] as Map<String, dynamic>?;

    return BookingModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      slotId: json['slot_id'],
      vehicleId: json['vehicle_id'],
      startTime: DateTime.parse(json['start_time']),
      duration: _parseDuration(json['duration']),
      paymentMethod: json['payment_method'],
      ticketNumber: json['ticket_number'],
      createdAt: DateTime.parse(json['created_at']),
      status: json['status'] ?? 'confirmed',
      slotName: slotData?['slot_name'],
      parkingLotId: slotData?['parking_lot_id'] ?? parkingLotData?['id'],
      parkingLotName: parkingLotData?['name'],
      parkingLotLocation: parkingLotData?['location'],
      vehicleName: vehicleData?['name'],
      licensePlate: vehicleData?['license_plate'],
      vehicleType: vehicleData?['type'],
    );
  }

  /// Parse PostgreSQL interval to readable string
  static String _parseDuration(dynamic duration) {
    if (duration == null) return '1 hours';
    if (duration is String) return duration;
    return duration.toString();
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'slot_id': slotId,
      'vehicle_id': vehicleId,
      'start_time': startTime.toIso8601String(),
      'duration': duration,
      'payment_method': paymentMethod,
      'ticket_number': ticketNumber,
      'status': status,
    };
  }

  /// Get display-friendly status text
  String get statusDisplay {
    switch (status) {
      case 'confirmed':
        return 'Đang đỗ';
      case 'completed':
        return 'Hoàn thành';
      case 'cancelled':
        return 'Đã hủy';
      case 'expired':
        return 'Hết hạn';
      default:
        return status;
    }
  }

  /// Get display-friendly duration text
  String get durationDisplay {
    final dur = duration.toLowerCase().trim();
    
    // Parse PostgreSQL interval format like "01:00:00", "02:00:00", "12:00:00"
    final hmsRegex = RegExp(r'^(\d{2}):(\d{2}):(\d{2})$');
    final hmsMatch = hmsRegex.firstMatch(dur);
    if (hmsMatch != null) {
      final hours = int.parse(hmsMatch.group(1)!);
      if (hours >= 24) return '${hours ~/ 24} ngày';
      if (hours == 12) return 'Qua đêm';
      return '$hours Giờ';
    }

    // Parse text format like "1 hour", "2 hours", "12 hours"
    final hoursRegex = RegExp(r'(\d+)\s*hours?');
    final hoursMatch = hoursRegex.firstMatch(dur);
    if (hoursMatch != null) {
      final hours = int.parse(hoursMatch.group(1)!);
      if (hours >= 24) return '${hours ~/ 24} ngày';
      if (hours == 12) return 'Qua đêm';
      return '$hours Giờ';
    }

    // Parse day format
    final dayRegex = RegExp(r'(\d+)\s*days?');
    final dayMatch = dayRegex.firstMatch(dur);
    if (dayMatch != null) {
      return '${dayMatch.group(1)} ngày';
    }

    return duration;
  }

  /// Parse duration to hours for price calculation
  int get durationInHours {
    final dur = duration.toLowerCase().trim();
    
    // HH:MM:SS format
    final hmsRegex = RegExp(r'^(\d{2}):(\d{2}):(\d{2})$');
    final hmsMatch = hmsRegex.firstMatch(dur);
    if (hmsMatch != null) {
      return int.parse(hmsMatch.group(1)!);
    }
    
    // "X hours" format
    final hoursRegex = RegExp(r'(\d+)\s*hours?');
    final hoursMatch = hoursRegex.firstMatch(dur);
    if (hoursMatch != null) {
      return int.parse(hoursMatch.group(1)!);
    }

    // "X days" format
    final dayRegex = RegExp(r'(\d+)\s*days?');
    final dayMatch = dayRegex.firstMatch(dur);
    if (dayMatch != null) {
      return int.parse(dayMatch.group(1)!) * 24;
    }

    return 1;
  }
}
