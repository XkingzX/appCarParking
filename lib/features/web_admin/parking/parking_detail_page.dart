import 'package:flutter/material.dart';
import 'package:baidoxe/features/web_admin/web_admin_layout.dart';
import 'package:baidoxe/core/theme.dart';

class ParkingDetailPage extends StatelessWidget {
  final String role;

  const ParkingDetailPage({Key? key, required this.role}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WebAdminLayout(
      role: role,
      currentRoute: '/web-admin/parking',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Chi tiết bãi đỗ',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          SizedBox(height: 20),
          Center(
            child: Text(
              'Trang chi tiết bãi đỗ đang được phát triển.',
              style: TextStyle(color: AppTheme.textLight),
            ),
          )
        ],
      ),
    );
  }
}
