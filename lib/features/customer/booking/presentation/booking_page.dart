import 'package:flutter/material.dart';

class CustomerBookingPage extends StatelessWidget {
  const CustomerBookingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Đặt chỗ của tôi'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Đang đỗ'),
              Tab(text: 'Lịch sử'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Đang đỗ
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_parking, size: 64, color: Colors.blue),
                  const SizedBox(height: 16),
                  const Text('Bạn chưa có lịch đỗ xe nào đang hoạt động.', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Gia hạn thời gian'),
                  ),
                ],
              ),
            ),
            // Lịch sử
            ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: Text('Bãi đỗ xe trung tâm - Slot A${index + 1}'),
                    subtitle: const Text('10/10/2023 14:00 - 16:00'),
                    trailing: const Text('50.000đ', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
