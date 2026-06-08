import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../scanner/presentation/scanner_page.dart';
import 'guard_slot_dashboard.dart' as guard_slot_dashboard;
import 'package:baidoxe/services/supabase_service.dart';

class GuardHomePage extends StatefulWidget {
  const GuardHomePage({Key? key}) : super(key: key);

  @override
  State<GuardHomePage> createState() => _GuardHomePageState();
}

class _GuardHomePageState extends State<GuardHomePage> {
  final SupabaseService _service = SupabaseService();
  bool _isLoading = true;
  String? _parkingLotId;
  String _parkingLotName = 'Bảng điều khiển';
  int _totalSlots = 0;
  int _occupiedSlots = 0;
  int _availableSlots = 0;

  @override
  void initState() {
    super.initState();
    _loadGuardData();
  }

  Future<void> _loadGuardData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final assignment = await _service.getGuardAssignment(userId);
    if (assignment != null) {
      _parkingLotId = assignment['parking_lot_id'];
      _parkingLotName = assignment['parking_lot_name'] ?? 'Bãi đỗ xe';
      
      final stats = await _service.getGuardParkingStats(_parkingLotId!);
      
      if (mounted) {
        setState(() {
          _totalSlots = stats['total'] ?? 0;
          _occupiedSlots = stats['occupied'] ?? 0;
          _availableSlots = stats['available'] ?? 0;
        });
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_parkingLotId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bảng điều khiển')),
        body: const Center(
          child: Text('Tài khoản của bạn chưa được phân công bãi đỗ nào.', style: TextStyle(fontSize: 16)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_parkingLotName),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadGuardData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              Get.offAllNamed('/login');
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thống kê nhanh
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Đang đỗ', '$_occupiedSlots/$_totalSlots', Colors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard('Trống', '$_availableSlots', Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Các nút hành động chính
            const Text('Nghiệp vụ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildActionCard(
                    context,
                    icon: Icons.qr_code_scanner,
                    title: 'Quét QR Xe Vào',
                    color: Colors.blue,
                    onTap: () {
                      Get.to(() => const ScannerPage(isCheckIn: true));
                    },
                  ),
                  _buildActionCard(
                    context,
                    icon: Icons.exit_to_app,
                    title: 'Quét QR Xe Ra',
                    color: Colors.orange,
                    onTap: () {
                      Get.to(() => const ScannerPage(isCheckIn: false));
                    },
                  ),
                  _buildActionCard(
                    context,
                    icon: Icons.local_parking,
                    title: 'Giám sát Bãi Đỗ',
                    color: Colors.purple,
                    onTap: () {
                      Get.to(() => guard_slot_dashboard.GuardSlotDashboard(parkingLotId: _parkingLotId!));
                    },
                  ),
                  _buildActionCard(
                    context,
                    icon: Icons.history,
                    title: 'Lịch sử ca trực',
                    color: Colors.grey,
                    onTap: () {
                      // Xem lịch sử
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
