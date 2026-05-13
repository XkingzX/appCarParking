import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:baidoxe/features/customer/account/presentation/vehicle_management_page.dart';
import 'package:baidoxe/features/customer/booking/presentation/booking_history_page.dart';

class CustomerAccountPage extends StatefulWidget {
  const CustomerAccountPage({Key? key}) : super(key: key);

  @override
  State<CustomerAccountPage> createState() => _CustomerAccountPageState();
}

class _CustomerAccountPageState extends State<CustomerAccountPage> {
  String _fullName = 'Đang tải...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .single();

      if (mounted) {
        setState(() {
          _fullName = response['full_name'] ?? 'Chưa cập nhật tên';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      if (mounted) {
        setState(() {
          _fullName = 'Lỗi tải thông tin';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(
            radius: 50,
            child: Icon(Icons.person, size: 50),
          ),
          const SizedBox(height: 16),
          _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : Text(
                _fullName,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
          const SizedBox(height: 32),
          ListTile(
            leading: const Icon(Icons.car_crash),
            title: const Text('Quản lý phương tiện'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Get.to(() => const VehicleManagementPage());
            },
          ),
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text('Phương thức thanh toán'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Get.snackbar('Thông báo', 'Tính năng đang phát triển', backgroundColor: Colors.orange, colorText: Colors.white);
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Lịch sử đỗ xe'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Get.to(() => const BookingHistoryPage());
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
            onTap: () {
              Get.offAllNamed('/login');
            },
          ),
        ],
      ),
    );
  }
}
