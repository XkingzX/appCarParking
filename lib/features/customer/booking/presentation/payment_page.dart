import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:baidoxe/core/theme.dart';
import 'booking_success_page.dart';

class PaymentPage extends StatefulWidget {
  final Map<String, dynamic> parkingLot;
  final Map<String, dynamic> selectedPricing;
  final String selectedSlotName;

  const PaymentPage({
    Key? key,
    required this.parkingLot,
    required this.selectedPricing,
    required this.selectedSlotName,
  }) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String selectedPayment = '';
  double _balance = 0.0;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  Future<void> _fetchBalance() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('profiles')
          .select('balance')
          .eq('id', userId)
          .single();

      if (mounted) {
        setState(() {
          _balance = (response['balance'] as num?)?.toDouble() ?? 0.0;
          if (_balance > 0) {
            selectedPayment = 'balance'; // Auto select balance if available
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching balance: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmPayment() async {
    if (selectedPayment.isEmpty) return;

    final priceValue = widget.selectedPricing['value'] as num;
    if (selectedPayment == 'balance' && _balance < priceValue) {
      Get.snackbar('Lỗi', 'Số dư không đủ. Vui lòng nạp thêm tiền.', backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Vui lòng đăng nhập lại.');

      // 1. Trừ tiền nếu dùng ví
      if (selectedPayment == 'balance') {
        final newBalance = _balance - priceValue;
        await Supabase.instance.client
            .from('profiles')
            .update({'balance': newBalance})
            .eq('id', userId);
      }

      // 2. Lấy xe đầu tiên của user (giả định) để tạo booking
      // Trong thực tế sẽ cho user chọn xe ở màn hình trước
      String? vehicleId;
      final vehicleResponse = await Supabase.instance.client
          .from('vehicles')
          .select('id')
          .eq('user_id', userId)
          .limit(1);
      
      if (vehicleResponse.isNotEmpty) {
        vehicleId = vehicleResponse.first['id'];
      }

      // 3. (Mock) Tạo booking - Vì slot ID thực tế chưa map đầy đủ trong DB
      // Trong thực tế, cần query slot_id dựa trên widget.selectedSlotName và parking_lot_id
      await Supabase.instance.client.from('bookings').insert({
        'user_id': userId,
        'vehicle_id': vehicleId,
        // 'slot_id': slot_id_thực_tế,
        'start_time': DateTime.now().toIso8601String(),
        'duration': '${widget.selectedPricing['time'].toString().replaceAll(RegExp(r'[^0-9]'), '')} hours', // Mock duration format
        'payment_method': selectedPayment,
        'status': 'confirmed',
        'ticket_number': 'TICKET-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}'
      });

      Get.off(() => BookingSuccessPage(
        slotName: widget.selectedSlotName,
        parkingName: widget.parkingLot['name'],
      ));

    } catch (e) {
      Get.snackbar('Lỗi thanh toán', e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final parkingName = widget.parkingLot['name'] ?? 'Bãi đỗ trung tâm';
    final duration = widget.selectedPricing['time'] ?? '1 Giờ';
    final priceStr = widget.selectedPricing['price'] ?? '20.000đ';

    return Scaffold(
      backgroundColor: AppTheme.primaryWhite,
      appBar: AppBar(
        title: const Text('Thanh toán'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Thông tin đặt bãi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildRowItem('Bãi đỗ xe:', parkingName),
                    const SizedBox(height: 12),
                    _buildRowItem('Vị trí:', widget.selectedSlotName),
                    const SizedBox(height: 12),
                    _buildRowItem('Thời gian:', duration),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            const Text('Phương thức thanh toán', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  _balance > 0
                  ? RadioListTile(
                      title: Text('Ví cá nhân (Số dư: ${_balance.toInt()}đ)'),
                      value: 'balance',
                      groupValue: selectedPayment,
                      activeColor: AppTheme.primaryBlue,
                      onChanged: (val) {
                        setState(() {
                          selectedPayment = val.toString();
                        });
                      },
                    )
                  : ListTile(
                      leading: const Icon(Icons.account_balance_wallet, color: Colors.grey),
                      title: const Text('Ví cá nhân (Chưa liên kết hoặc 0đ)'),
                      subtitle: InkWell(
                        onTap: () {
                          Get.snackbar('Thông báo', 'Tính năng liên kết đang phát triển', backgroundColor: Colors.orange, colorText: Colors.white);
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('+ Liên kết ví cá nhân', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  const Divider(height: 1),
                  RadioListTile(
                    title: const Text('Thẻ tín dụng / Ghi nợ'),
                    value: 'card',
                    groupValue: selectedPayment,
                    activeColor: AppTheme.primaryBlue,
                    onChanged: (val) {
                      setState(() {
                        selectedPayment = val.toString();
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accentBlue.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tổng cộng:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(priceStr, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: selectedPayment.isNotEmpty && !_isProcessing ? _confirmPayment : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: AppTheme.primaryBlue,
                disabledBackgroundColor: Colors.grey.shade400,
              ),
              child: _isProcessing 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Xác nhận thanh toán', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
        Text(title, style: const TextStyle(color: AppTheme.textLight, fontSize: 15)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
