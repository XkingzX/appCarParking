import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:baidoxe/core/theme.dart';
import 'package:baidoxe/services/supabase_service.dart';

class GuardSlotDashboard extends StatefulWidget {
  final String parkingLotId;

  const GuardSlotDashboard({Key? key, required this.parkingLotId}) : super(key: key);

  @override
  State<GuardSlotDashboard> createState() => _GuardSlotDashboardState();
}

class _GuardSlotDashboardState extends State<GuardSlotDashboard> {
  final SupabaseService _service = SupabaseService();
  List<Map<String, dynamic>> _slots = [];
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchSlotData();
    // Refresh mỗi phút để tính toán thời gian cảnh báo
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchSlotData() async {
    setState(() => _isLoading = true);
    try {
      final slots = await _service.getGuardSlotStatus(widget.parkingLotId);
      if (mounted) {
        setState(() {
          _slots = slots;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching guard slots: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giám sát Bãi đỗ xe'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchSlotData,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _slots.isEmpty
              ? const Center(child: Text('Không có dữ liệu slot.'))
              : _buildDashboard(),
    );
  }

  Widget _buildDashboard() {
    // Nhóm slots theo zone
    final Map<String, List<Map<String, dynamic>>> zonedSlots = {};
    for (var slot in _slots) {
      final zone = slot['zone'] ?? 'Other';
      zonedSlots.putIfAbsent(zone, () => []).add(slot);
    }

    final zones = zonedSlots.keys.toList()..sort();

    return Column(
      children: [
        // Chú giải
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegend(Colors.green, 'Trống'),
              _buildLegend(Colors.blue, 'Đã đặt'),
              _buildLegend(Colors.red, 'Đang đỗ'),
              _buildLegend(Colors.orange, 'Sắp/Đã hết hạn'),
            ],
          ),
        ),
        
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: zones.length,
            itemBuilder: (context, index) {
              final zone = zones[index];
              final slotsInZone = zonedSlots[zone]!;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Khu $zone',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: slotsInZone.length,
                    itemBuilder: (context, slotIndex) {
                      return _buildSlotStatusCard(slotsInZone[slotIndex]);
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildSlotStatusCard(Map<String, dynamic> slot) {
    final status = slot['status'];
    final activeBooking = slot['active_booking'];
    
    Color bgColor = Colors.green; // available
    bool isWarning = false;
    String timeRemainingText = '';

    if (status == 'reserved') {
      bgColor = Colors.blue;
    } else if (status == 'occupied') {
      bgColor = Colors.red;
    }

    // Tính toán thời gian nếu có active booking
    if (activeBooking != null) {
      try {
        final startTime = DateTime.parse(activeBooking['start_time']);
        // Parse duration (giả định interval string like "2 hours" - ta lấy số)
        final durationStr = activeBooking['duration'].toString();
        int hours = 1;
        final match = RegExp(r'(\d+)\s*hour').firstMatch(durationStr);
        if (match != null) {
          hours = int.parse(match.group(1)!);
        } else if (durationStr.contains('day')) {
          hours = 24;
        }

        final endTime = startTime.add(Duration(hours: hours));
        final now = DateTime.now();
        final diff = endTime.difference(now);

        if (diff.inMinutes <= 15) {
          isWarning = true;
          bgColor = Colors.orange; // Cảnh báo sắp hết hạn hoặc quá hạn
        }

        if (diff.isNegative) {
          timeRemainingText = 'Quá hạn ${-diff.inMinutes}p';
        } else {
          timeRemainingText = 'Còn ${diff.inMinutes}p';
        }
      } catch (e) {
        debugPrint('Error parsing time: $e');
      }
    }

    return GestureDetector(
      onTap: () {
        if (activeBooking != null) {
          _showBookingDetails(slot, activeBooking, timeRemainingText);
        } else {
          Get.snackbar('Trống', 'Slot ${slot['slot_name']} đang trống', backgroundColor: Colors.green, colorText: Colors.white);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: isWarning ? Border.all(color: Colors.redAccent, width: 2) : null,
          boxShadow: isWarning
              ? [BoxShadow(color: Colors.orange.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2)]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              slot['slot_name'],
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (activeBooking != null && timeRemainingText.isNotEmpty)
              Text(
                timeRemainingText,
                style: const TextStyle(color: Colors.white, fontSize: 10),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
          ],
        ),
      ),
    );
  }

  void _showBookingDetails(Map<String, dynamic> slot, Map<String, dynamic> booking, String timeRemaining) {
    final vehicle = booking['vehicles'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Chi tiết Slot ${slot['slot_name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trạng thái: ${slot['status']}'),
            const SizedBox(height: 8),
            Text('Biển số xe: ${vehicle != null ? vehicle['license_plate'] : 'Không rõ'}'),
            const SizedBox(height: 8),
            Text('Thời gian: $timeRemaining', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Get.snackbar('Cảnh báo', 'Đã gửi thông báo cho chủ xe!', backgroundColor: Colors.blue, colorText: Colors.white);
            },
            child: const Text('Nhắc nhở xe'),
          ),
        ],
      ),
    );
  }
}
