import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:baidoxe/features/web_admin/web_admin_layout.dart';
import 'package:baidoxe/features/web_admin/widgets/custom_data_table.dart';
import 'package:baidoxe/core/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:baidoxe/model/parking_owner_model.dart';

class OwnerManagementPage extends StatefulWidget {
  final String role;

  const OwnerManagementPage({Key? key, required this.role}) : super(key: key);

  @override
  State<OwnerManagementPage> createState() => _OwnerManagementPageState();
}

class _OwnerManagementPageState extends State<OwnerManagementPage> {
  bool _isLoading = true;
  List<ParkingOwnerModel> _owners = [];

  // Thống kê nhanh
  int _totalUsers = 0;
  int _totalAdmins = 0;
  int _totalOwners = 0;
  int _totalCustomers = 0;
  int _totalGuards = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      setState(() => _isLoading = true);
      final supabase = Supabase.instance.client;

      // Lấy danh sách owner
      final ownersResponse = await supabase.from('parking_owners').select('*, profiles(full_name, email)');
      
      // Lấy thống kê số lượng account (chỉ admin mới xem được tổng quát)
      if (widget.role == 'admin') {
         final usersResponse = await supabase.from('profiles').select('role');
         final roles = (usersResponse as List).map((e) => e['role'].toString()).toList();
         
         _totalUsers = roles.length;
         _totalAdmins = roles.where((r) => r == 'admin').length;
         _totalOwners = roles.where((r) => r == 'parking_owner').length;
         _totalCustomers = roles.where((r) => r == 'user' || r == 'customer').length;
         _totalGuards = roles.where((r) => r == 'guard').length;
      }

      if (mounted) {
        setState(() {
          _owners = (ownersResponse as List).map((e) => ParkingOwnerModel.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải danh sách chủ bãi đỗ: $e');
      if (mounted) setState(() => _isLoading = false);
      Get.snackbar('Lỗi', 'Không thể tải danh sách chủ bãi đỗ', backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  Future<void> _updateStatus(String ownerId, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('parking_owners')
          .update({'status': newStatus})
          .eq('id', ownerId);
          
      Get.snackbar('Thành công', 'Đã cập nhật trạng thái chủ bãi', backgroundColor: Colors.green, colorText: Colors.white);
      _fetchData(); // Reload
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể cập nhật trạng thái', backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  void _showOwnerDetails(ParkingOwnerModel owner) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chi tiết Chủ Bãi Đỗ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tên: ${owner.fullName ?? 'Không rõ'}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Email: ${owner.email ?? 'Không rõ'}'),
            const SizedBox(height: 12),
            Text('Công ty: ${owner.companyName}'),
            Text('Mã số thuế: ${owner.taxNumber ?? 'Không có'}'),
            Text('Tài khoản NH: ${owner.bankAccountInfo ?? 'Không có'}'),
            Text('Trạng thái hiện tại: ${owner.status.toUpperCase()}'),
          ],
        ),
        actions: [
          if (widget.role == 'admin') ...[
            if (owner.status != 'verified')
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _updateStatus(owner.id, 'verified');
                },
                child: const Text('Duyệt (Verify)', style: TextStyle(color: Colors.green)),
              ),
            if (owner.status != 'rejected')
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _updateStatus(owner.id, 'rejected');
                },
                child: const Text('Từ chối (Reject)', style: TextStyle(color: Colors.red)),
              ),
          ],
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WebAdminLayout(
      role: widget.role,
      currentRoute: '/web-admin/owner',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quản lý Người Dùng & Chủ Bãi',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 20),

          // User Statistics Card
          if (widget.role == 'admin')
            Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Tổng tài khoản', _totalUsers.toString(), Colors.blue),
                  _buildStatItem('Admin', _totalAdmins.toString(), Colors.purple),
                  _buildStatItem('Chủ bãi', _totalOwners.toString(), Colors.orange),
                  _buildStatItem('Khách hàng', _totalCustomers.toString(), Colors.green),
                  _buildStatItem('Bảo vệ', _totalGuards.toString(), Colors.redAccent),
                ],
              ),
            ),

          const Text(
            'Danh sách Chủ Bãi Đỗ (Parking Owners)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          if (_isLoading)
            const Expanded(child: Center(child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(color: AppTheme.primaryBlue),
            )))
          else if (_owners.isEmpty)
            const Expanded(child: Center(child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Text('Chưa có thông tin chủ bãi đỗ nào được đăng ký.', style: TextStyle(color: Colors.grey, fontSize: 16)),
            )))
          else
            Expanded(
              child: CustomDataTable(
                columns: const ['Doanh nghiệp', 'Đại diện', 'Mã số thuế', 'Trạng thái', 'Hành động'],
                rows: _owners.map((owner) {
                  Color statusColor;
                  if (owner.status == 'verified') statusColor = Colors.green;
                  else if (owner.status == 'rejected') statusColor = Colors.red;
                  else statusColor = Colors.orange;

                  return [
                    Text(owner.companyName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${owner.fullName}\n${owner.email}', style: const TextStyle(fontSize: 12)),
                    Text(owner.taxNumber ?? 'N/A'),
                    Chip(
                      label: Text(owner.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                      backgroundColor: statusColor.withOpacity(0.1),
                      side: BorderSide(color: statusColor.withOpacity(0.2)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_red_eye_rounded, color: AppTheme.accentBlue),
                      tooltip: 'Xem chi tiết & Phê duyệt',
                      onPressed: () => _showOwnerDetails(owner),
                    ),
                  ];
                }).toList(),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppTheme.textLight, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
