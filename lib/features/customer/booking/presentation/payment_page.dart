import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'booking_success_page.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({Key? key}) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String selectedDuration = '1 Giờ';
  String selectedPayment = 'Ví nội bộ';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Thông tin đặt bãi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildRowItem('Bãi đỗ xe:', 'Bãi đỗ trung tâm'),
                    const SizedBox(height: 8),
                    _buildRowItem('Vị trí:', 'A3'),
                    const SizedBox(height: 8),
                    _buildRowItem('Biển số xe:', '29A-123.45'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Thời gian đỗ dự kiến', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedDuration,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: ['1 Giờ', '2 Giờ', '4 Giờ', 'Qua đêm'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedDuration = newValue!;
                });
              },
            ),
            const SizedBox(height: 24),
            const Text('Phương thức thanh toán', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            RadioListTile(
              title: const Text('Ví nội bộ (Số dư: 150.000đ)'),
              value: 'Ví nội bộ',
              groupValue: selectedPayment,
              onChanged: (val) {
                setState(() {
                  selectedPayment = val.toString();
                });
              },
            ),
            RadioListTile(
              title: const Text('Thẻ tín dụng / Ghi nợ'),
              value: 'Thẻ tín dụng',
              groupValue: selectedPayment,
              onChanged: (val) {
                setState(() {
                  selectedPayment = val.toString();
                });
              },
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Tổng cộng:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('20.000đ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Get.to(() => const BookingSuccessPage());
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Xác nhận thanh toán', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowItem(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
