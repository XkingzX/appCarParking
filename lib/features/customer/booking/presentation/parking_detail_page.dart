import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'slot_selection_page.dart';

class ParkingDetailPage extends StatelessWidget {
  const ParkingDetailPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết bãi đỗ xe'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dummy Image
            Container(
              height: 200,
              color: Colors.blue[100],
              child: const Icon(Icons.local_parking, size: 100, color: Colors.blue),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bãi đỗ xe trung tâm', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      Icon(Icons.location_on, color: Colors.grey, size: 16),
                      SizedBox(width: 4),
                      Text('123 Đường ABC, Quận 1', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Rate
                  const Text('Bảng giá', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const ListTile(
                    leading: Icon(Icons.access_time),
                    title: Text('1 Giờ'),
                    trailing: Text('20.000đ', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const ListTile(
                    leading: Icon(Icons.access_time),
                    title: Text('2 Giờ'),
                    trailing: Text('35.000đ', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const ListTile(
                    leading: Icon(Icons.access_time),
                    title: Text('Qua đêm'),
                    trailing: Text('100.000đ', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  
                  const SizedBox(height: 16),
                  const Text('Tiện ích', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(label: const Text('Có mái che'), backgroundColor: Colors.blue[50]),
                      Chip(label: const Text('Camera 24/7'), backgroundColor: Colors.blue[50]),
                      Chip(label: const Text('Bảo vệ'), backgroundColor: Colors.blue[50]),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      Get.to(() => const SlotSelectionPage());
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    child: const Text('Chọn vị trí đỗ'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
