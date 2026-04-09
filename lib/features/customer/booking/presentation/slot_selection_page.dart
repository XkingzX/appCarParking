import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'payment_page.dart';

class SlotSelectionPage extends StatefulWidget {
  const SlotSelectionPage({Key? key}) : super(key: key);

  @override
  State<SlotSelectionPage> createState() => _SlotSelectionPageState();
}

class _SlotSelectionPageState extends State<SlotSelectionPage> {
  int? selectedSlot;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn chỗ đỗ xe'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegend(Colors.white, Colors.black, 'Trống'),
                _buildLegend(Colors.blue, Colors.white, 'Đang chọn'),
                _buildLegend(Colors.red[100]!, Colors.red, 'Đã kín'),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: 15,
              itemBuilder: (context, index) {
                // Mock: slots 2, 5, 8 are occupied
                bool isOccupied = index == 2 || index == 5 || index == 8;
                bool isSelected = selectedSlot == index;

                return GestureDetector(
                  onTap: () {
                    if (!isOccupied) {
                      setState(() {
                        selectedSlot = index;
                      });
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isOccupied
                          ? Colors.red[100]
                          : isSelected
                              ? Colors.blue
                              : Colors.white,
                      border: Border.all(
                        color: isOccupied ? Colors.red : Colors.grey,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: isOccupied
                        ? const Icon(Icons.directions_car, color: Colors.red, size: 40)
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              if (!isSelected)
                                Opacity(
                                  opacity: 0.5,
                                  child: Lottie.network(
                                    'https://lottie.host/80a0614f-d05e-4aab-a7eb-62aeb2c32cf8/U3y7vM8IfT.json', // Lottie pulse/radar animation
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const SizedBox(),
                                  ),
                                ),
                              Text(
                                'A${index + 1}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
            ),
            child: ElevatedButton(
              onPressed: selectedSlot != null
                  ? () {
                      Get.to(() => const PaymentPage());
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Tiếp tục thanh toán', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, Color textColor, String label) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
