// model/traffic_simulation_model.dart
import 'package:flutter/material.dart';

class TrafficSimulationModel {
  final String id;
  final String roadName;
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;
  final int speedKmh;
  final int volumePerHour;
  final String status;
  final String? peakHours;

  TrafficSimulationModel({
    required this.id,
    required this.roadName,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
    required this.speedKmh,
    required this.volumePerHour,
    required this.status,
    this.peakHours,
  });

  factory TrafficSimulationModel.fromJson(Map<String, dynamic> json) {
    return TrafficSimulationModel(
      id: json['id'] ?? '',
      roadName: json['road_name'] ?? '',
      startLat: (json['start_lat'] as num?)?.toDouble() ?? 0.0,
      startLng: (json['start_lng'] as num?)?.toDouble() ?? 0.0,
      endLat: (json['end_lat'] as num?)?.toDouble() ?? 0.0,
      endLng: (json['end_lng'] as num?)?.toDouble() ?? 0.0,
      speedKmh: (json['speed_kmh'] as num?)?.toInt() ?? 0,
      volumePerHour: (json['volume_per_hour'] as num?)?.toInt() ?? 0,
      status: json['status'] ?? 'clear',
      peakHours: json['peak_hours'],
    );
  }

  Color get statusColor {
    switch (status) {
      case 'clear': return Colors.green;
      case 'moderate': return Colors.orange;
      case 'heavy': return Colors.red;
      case 'jam': return Colors.purple;
      default: return Colors.grey;
    }
  }

  String get statusText {
    switch (status) {
      case 'clear': return 'Thông thoáng';
      case 'moderate': return 'Đông đúc';
      case 'heavy': return 'Kẹt xe mạnh';
      case 'jam': return 'Tắc đường';
      default: return 'Không rõ';
    }
  }
}
