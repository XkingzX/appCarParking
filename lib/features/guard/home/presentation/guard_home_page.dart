import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../scanner/presentation/scanner_page.dart';

class GuardHomePage extends StatelessWidget {
  const GuardHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng điều khiển (Bảo vệ)'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Xử lý đăng xuất
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
                  child: _buildStatCard('Đang đỗ', '45/50', Colors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard('Trống', '5', Colors.green),
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
                    icon: Icons.search,
                    title: 'Nhập Biển Số',
                    color: Colors.purple,
                    onTap: () {
                      // Mở popup nhập biển số
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {required IconData icon, required String title, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
