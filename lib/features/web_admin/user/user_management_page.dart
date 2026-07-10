import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:baidoxe/features/web_admin/web_admin_layout.dart';
import 'package:baidoxe/features/web_admin/widgets/custom_data_table.dart';
import 'package:baidoxe/core/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserManagementPage extends StatefulWidget {
  final String role;
  
  const UserManagementPage({Key? key, required this.role}) : super(key: key);

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      setState(() => _isLoading = true);
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .order('created_at', ascending: false);
          
      setState(() {
        _users = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('Error fetching users: $e');
      Get.snackbar('Lỗi', 'Không thể tải danh sách người dùng');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showTopUpDialog(Map<String, dynamic> user) {
    final amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nạp tiền vào ví'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Người dùng: ${user['full_name']}'),
            Text('Số dư hiện tại: ${(user['wallet_balance'] ?? 0)} VNĐ'),
            const SizedBox(height: 16),
            TextFormField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Số tiền nạp (VNĐ)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount <= 0) return;
              
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                final currentBalance = (user['wallet_balance'] ?? 0) as num;
                final newBalance = currentBalance + amount;
                
                await Supabase.instance.client
                    .from('profiles')
                    .update({'wallet_balance': newBalance})
                    .eq('id', user['id']);
                
                // Add transaction record
                await Supabase.instance.client
                    .from('transactions')
                    .insert({
                      'user_id': user['id'],
                      'type': 'top_up',
                      'amount': amount,
                      'description': 'Nạp tiền từ Admin',
                      'status': 'success'
                    });
                    
                Get.snackbar('Thành công', 'Đã nạp ${amount}VNĐ cho ${user['full_name']}');
                _fetchUsers();
              } catch (e) {
                Get.snackbar('Lỗi', 'Không thể nạp tiền: $e');
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Xác nhận Nạp'),
          ),
        ],
      ),
    );
  }

  void _showChangeRoleDialog(Map<String, dynamic> user) {
    String selectedRole = user['role'] ?? 'user';
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cấp quyền người dùng'),
        content: DropdownButtonFormField<String>(
          value: selectedRole,
          decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
          items: const [
            DropdownMenuItem(value: 'user', child: Text('Khách hàng (User)')),
            DropdownMenuItem(value: 'guard', child: Text('Bảo vệ (Guard)')),
            DropdownMenuItem(value: 'parking_owner', child: Text('Chủ bãi đỗ (Owner)')),
            DropdownMenuItem(value: 'admin', child: Text('Quản trị viên (Admin)')),
          ],
          onChanged: (v) => selectedRole = v!,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                await Supabase.instance.client
                    .from('profiles')
                    .update({'role': selectedRole})
                    .eq('id', user['id']);
                Get.snackbar('Thành công', 'Đã đổi quyền thành $selectedRole');
                _fetchUsers();
              } catch (e) {
                Get.snackbar('Lỗi', 'Không thể cập nhật quyền');
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WebAdminLayout(
      role: widget.role,
      currentRoute: '/web-admin/users',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quản lý Người Dùng & Ví',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 32),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : CustomDataTable(
                    columns: const ['Họ và Tên', 'Email', 'Role', 'Số dư ví', 'Hành động'],
                    rows: _users.map((user) {
                      return [
                        Text(user['full_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(user['email'] ?? ''),
                        Chip(
                          label: Text(
                            (user['role'] ?? 'user').toString().toUpperCase(), 
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)
                          ),
                          backgroundColor: Colors.blue.withOpacity(0.1),
                        ),
                        Text('${(user['wallet_balance'] ?? 0)} VNĐ', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.account_balance_wallet_rounded, color: Colors.green),
                              tooltip: 'Nạp tiền',
                              onPressed: () => _showTopUpDialog(user),
                            ),
                            IconButton(
                              icon: const Icon(Icons.manage_accounts, color: AppTheme.accentBlue),
                              tooltip: 'Cấp quyền',
                              onPressed: () => _showChangeRoleDialog(user),
                            ),
                          ],
                        ),
                      ];
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
