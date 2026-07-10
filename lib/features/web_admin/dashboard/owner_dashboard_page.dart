import 'package:flutter/material.dart';
import 'package:baidoxe/features/web_admin/web_admin_layout.dart';
import 'package:baidoxe/features/web_admin/widgets/stat_card.dart';
import 'package:baidoxe/core/theme.dart';

class OwnerDashboardPage extends StatelessWidget {
  final String role;

  const OwnerDashboardPage({Key? key, required this.role}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WebAdminLayout(
      role: role,
      currentRoute: '/web-admin/owner-dashboard',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tổng quan bãi đỗ của tôi',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 20),
            
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = 4;
                if (constraints.maxWidth < 600) {
                  crossAxisCount = 1;
                } else if (constraints.maxWidth < 900) {
                  crossAxisCount = 2;
                }
                
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.5,
                  children: const [
                    StatCard(
                      title: 'Bãi đỗ đang quản lý',
                      value: '3',
                      icon: Icons.local_parking,
                      color: Colors.blue,
                    ),
                    StatCard(
                      title: 'Tổng slot',
                      value: '450',
                      icon: Icons.grid_view,
                      color: Colors.orange,
                    ),
                    StatCard(
                      title: 'Slot đang sử dụng',
                      value: '320',
                      icon: Icons.directions_car,
                      color: Colors.redAccent,
                    ),
                    StatCard(
                      title: 'Doanh thu hôm nay',
                      value: '12.5M VNĐ',
                      icon: Icons.attach_money,
                      color: Colors.green,
                      trend: '15%',
                      isUp: true,
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 30),
            
            // Placeholder for recent bookings or detailed parking list
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Hoạt động gần đây',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Chưa có dữ liệu giao dịch.',
                      style: TextStyle(color: AppTheme.textLight),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
