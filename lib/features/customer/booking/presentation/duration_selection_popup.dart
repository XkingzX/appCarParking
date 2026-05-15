import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:baidoxe/core/theme.dart';

class DurationSelectionPopup extends StatefulWidget {
  final List<Map<String, dynamic>> originalPrices;

  const DurationSelectionPopup({Key? key, required this.originalPrices}) : super(key: key);

  static Future<Map<String, dynamic>?> show(BuildContext context, List<Map<String, dynamic>> originalPrices) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DurationSelectionPopup(originalPrices: originalPrices),
    );
  }

  @override
  State<DurationSelectionPopup> createState() => _DurationSelectionPopupState();
}

class _DurationSelectionPopupState extends State<DurationSelectionPopup> {
  List<Map<String, dynamic>> _processedPrices = [];
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _processPrices();
  }

  void _processPrices() {
    // Tìm giá 1 giờ (nếu có)
    Map<String, dynamic>? oneHourPrice;
    try {
      oneHourPrice = widget.originalPrices.firstWhere((p) => p['time'].toString().toLowerCase().contains('1 giờ'));
    } catch (_) {
      if (widget.originalPrices.isNotEmpty) {
        oneHourPrice = widget.originalPrices[0];
      }
    }

    if (oneHourPrice == null) {
      // Fallback
      _processedPrices = [
        {'time': '1 Giờ', 'price': '20.000đ', 'value': 20000},
        {'time': '2 Giờ', 'price': '40.000đ', 'value': 40000},
        {'time': 'Qua đêm', 'price': '160.000đ', 'value': 160000},
      ];
      return;
    }

    // Process all 3 types
    int baseValue = oneHourPrice['value'] as int;

    _processedPrices = [];

    // 1. 1 Giờ
    _processedPrices.add({
      'time': '1 Giờ',
      'price': '${baseValue}đ',
      'value': baseValue,
    });

    // 2. 2 Giờ
    Map<String, dynamic>? twoHourPrice;
    try {
      twoHourPrice = widget.originalPrices.firstWhere((p) => p['time'].toString().toLowerCase().contains('2 giờ'));
      _processedPrices.add(twoHourPrice);
    } catch (_) {
      _processedPrices.add({
        'time': '2 Giờ',
        'price': '${baseValue * 2}đ',
        'value': baseValue * 2,
      });
    }

    // 3. Qua đêm
    Map<String, dynamic>? overnightPrice;
    try {
      overnightPrice = widget.originalPrices.firstWhere((p) => p['time'].toString().toLowerCase().contains('qua đêm'));
      _processedPrices.add(overnightPrice);
    } catch (_) {
      _processedPrices.add({
        'time': 'Qua đêm',
        'price': '${baseValue * 8}đ',
        'value': baseValue * 8,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Chọn thời gian đỗ',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Get.back(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(_processedPrices.length, (index) {
            final isSelected = _selectedIndex == index;
            final item = _processedPrices[index];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.accentBlue.withOpacity(0.1) : Colors.white,
                  border: Border.all(
                    color: isSelected ? AppTheme.accentBlue : Colors.grey.shade300,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time_filled,
                      color: isSelected ? AppTheme.accentBlue : Colors.grey,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        item['time'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    Text(
                      item['price'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppTheme.accentBlue : AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _selectedIndex != -1
                ? () {
                    Get.back(result: _processedPrices[_selectedIndex]);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: AppTheme.primaryBlue,
            ),
            child: const Text('Xác nhận', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
