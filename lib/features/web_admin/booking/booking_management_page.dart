import 'package:flutter/material.dart';
import 'package:baidoxe/features/web_admin/web_admin_layout.dart';
import 'package:baidoxe/features/web_admin/widgets/custom_data_table.dart';
import 'package:baidoxe/core/theme.dart';

class BookingManagementPage extends StatelessWidget {
  final String role;

  const BookingManagementPage({Key? key, required this.role}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WebAdminLayout(
      role: role,
      currentRoute: '/web-admin/booking',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quản lý Đặt chỗ',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 20),
          CustomDataTable(
            columns: const ['Mã Đặt', 'Khách hàng', 'Bãi đỗ', 'Thời gian', 'Trạng thái', 'Thanh toán'],
            rows: [
              [
                const Text('#BK1002'),
                const Text('Nguyễn Khách A'),
                const Text('Bãi đỗ xe trung tâm'),
                const Text('10:00 - 12:00, 25/10'),
                const Chip(label: Text('Hoàn thành', style: TextStyle(color: Colors.green)), backgroundColor: Colors.greenAccent),
                const Text('Đã thanh toán'),
              ],
            ],
          )
        ],
      ),
    );
  }
}
