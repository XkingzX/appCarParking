import 'package:flutter/material.dart';
import 'package:baidoxe/features/web_admin/web_admin_layout.dart';
import 'package:baidoxe/core/theme.dart';

class RevenuePage extends StatelessWidget {
  final String role;

  const RevenuePage({Key? key, required this.role}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WebAdminLayout(
      role: role,
      currentRoute: '/web-admin/revenue',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Báo cáo Doanh thu',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          SizedBox(height: 20),
          Center(
            child: Text(
              'Trang báo cáo doanh thu chi tiết đang được phát triển.',
              style: TextStyle(color: AppTheme.textLight),
            ),
          )
        ],
      ),
    );
  }
}
