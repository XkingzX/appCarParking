import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../home/presentation/customer_home_page.dart';

class BookingSuccessPage extends StatelessWidget {
  const BookingSuccessPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 100, color: Colors.green),
              const SizedBox(height: 24),
              const Text('Đặt chỗ thành công!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text(
                'Vị trí của bạn là A3 tại Bãi đỗ trung tâm.\nVui lòng check-in trong vòng 30 phút.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              
              // QR Code Placeholder
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(Icons.qr_code_2, size: 150),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Mã vé: #TICKET-12345', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  Get.offAll(() => const CustomerHomePage());
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Về trang chủ', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
