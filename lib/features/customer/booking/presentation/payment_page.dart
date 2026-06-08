import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:baidoxe/core/theme.dart';
import 'package:baidoxe/services/supabase_service.dart';
import 'booking_success_page.dart';
import 'package:baidoxe/features/customer/account/presentation/vehicle_management_page.dart' as baidoxe;

class PaymentPage extends StatefulWidget {
  final Map<String, dynamic> parkingLot;
  final Map<String, dynamic> selectedPricing;
  final String selectedSlotName;
  final String selectedSlotId; // UUID thực từ DB

  const PaymentPage({
    Key? key,
    required this.parkingLot,
    required this.selectedPricing,
    required this.selectedSlotName,
    required this.selectedSlotId,
  }) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final SupabaseService _service = SupabaseService();
  String selectedPayment = '';
  double _balance = 0.0;
  bool _isLoading = true;
  bool _isProcessing = false;

  // Vehicle selection
  List<Map<String, dynamic>> _vehicles = [];
  String? _selectedVehicleId;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final Future<Map<String, dynamic>> balanceFuture = Supabase.instance.client
          .from('profiles')
          .select('balance')
          .eq('id', userId)
          .single();

      final Future<List<dynamic>> vehiclesFuture = _service.getUserVehicles(userId);

      final results = await Future.wait([balanceFuture, vehiclesFuture]);
      if (mounted) {
        final balanceData = results[0] as Map<String, dynamic>;
        final vehiclesData = results[1] as List<Map<String, dynamic>>;

        setState(() {
          _balance = (balanceData['balance'] as num?)?.toDouble() ?? 0.0;
          if (_balance > 0) {
            selectedPayment = 'balance';
          }
          _vehicles = vehiclesData;
          
          if (_vehicles.isEmpty) {
            // Hiển thị thông báo và chuyển hướng
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Get.snackbar(
                'Thiếu phương tiện',
                'Vui lòng thêm phương tiện trước khi đặt chỗ.',
                backgroundColor: Colors.redAccent,
                colorText: Colors.white,
                snackPosition: SnackPosition.TOP,
                duration: const Duration(seconds: 4),
              );
              Get.off(() => const baidoxe.VehicleManagementPage());
            });
            return;
          }
          
          if (_vehicles.isNotEmpty) {
            final defaultVehicle = _vehicles.firstWhere(
              (v) => v['is_default'] == true, 
              orElse: () => _vehicles.first
            );
            _selectedVehicleId = defaultVehicle['id'];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching initial data: $e');
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
      Get.snackbar('Lỗi', 'Số dư không đủ. Vui lòng nạp thêm tiền.',
          backgroundColor: Colors.red, colorText: Colors.white);
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

      // 2. Tạo booking qua service (tự generate ticket, convert duration)
      final durationText = widget.selectedPricing['time']?.toString() ?? '1 Giờ';

      final bookingResponse = await _service.createBooking(
        userId: userId,
        slotId: widget.selectedSlotId,
        vehicleId: _selectedVehicleId,
        durationText: durationText,
        paymentMethod: selectedPayment,
      );

      // 3. Navigate to success page với data thực
      Get.off(() => BookingSuccessPage(
            slotName: widget.selectedSlotName,
            parkingName: widget.parkingLot['name'] ?? 'Bãi đỗ xe',
            ticketNumber: bookingResponse['ticket_number'] ?? '',
            bookingId: bookingResponse['id'] ?? '',
            duration: durationText,
            price: widget.selectedPricing['price'] ?? '',
          ));
    } catch (e) {
      Get.snackbar('Lỗi thanh toán', e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                  const Text('Thông tin đặt bãi',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    color: Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildRowItem('Bãi đỗ xe:', parkingName),
                          const SizedBox(height: 12),
                          _buildRowItem(
                              'Vị trí:', widget.selectedSlotName),
                          const SizedBox(height: 12),
                          _buildRowItem('Thời gian:', duration),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Chọn xe
                  if (_vehicles.isNotEmpty) ...[
                    const Text('Chọn xe',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      color: Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: _vehicles.map((vehicle) {
                          final isSelected =
                              _selectedVehicleId == vehicle['id'];
                          return RadioListTile<String>(
                            title: Text(
                                '${vehicle['name']} (${vehicle['license_plate']})'),
                            subtitle: Text(vehicle['type'] ?? ''),
                            value: vehicle['id'],
                            groupValue: _selectedVehicleId,
                            activeColor: Theme.of(context).primaryColor,
                            onChanged: (val) {
                              setState(() {
                                _selectedVehicleId = val;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  const Text('Phương thức thanh toán',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    color: Theme.of(context).cardColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        _balance > 0
                            ? RadioListTile(
                                title: Text(
                                    'Ví cá nhân (Số dư: ${NumberFormat('#,###', 'vi_VN').format(_balance.toInt())}đ)'),
                                value: 'balance',
                                groupValue: selectedPayment,
                                activeColor:
                                    Theme.of(context).primaryColor,
                                onChanged: (val) {
                                  setState(() {
                                    selectedPayment = val.toString();
                                  });
                                },
                              )
                            : ListTile(
                                leading: const Icon(
                                    Icons.account_balance_wallet,
                                    color: Colors.grey),
                                title: const Text(
                                    'Ví cá nhân (Chưa liên kết hoặc 0đ)'),
                                subtitle: InkWell(
                                  onTap: () {
                                    Get.snackbar('Thông báo',
                                        'Tính năng liên kết đang phát triển',
                                        backgroundColor: Colors.orange,
                                        colorText: Colors.white);
                                  },
                                  child: const Padding(
                                    padding:
                                        EdgeInsets.symmetric(vertical: 8.0),
                                    child: Text('+ Liên kết ví cá nhân',
                                        style: TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                        const Divider(height: 1),
                        RadioListTile(
                          title: const Text('Thẻ tín dụng / Ghi nợ'),
                          value: 'card',
                          groupValue: selectedPayment,
                          activeColor: Theme.of(context).primaryColor,
                          onChanged: (val) {
                            setState(() {
                              selectedPayment = val.toString();
                            });
                          },
                        ),
                        const Divider(height: 1),
                        RadioListTile(
                          title: const Text('Tiền mặt'),
                          value: 'cash',
                          groupValue: selectedPayment,
                          activeColor: Theme.of(context).primaryColor,
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
                      border: Border.all(
                          color: AppTheme.accentBlue.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tổng cộng:',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        Text(priceStr,
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: selectedPayment.isNotEmpty && !_isProcessing
                        ? _confirmPayment
                        : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      backgroundColor: Theme.of(context).primaryColor,
                      disabledBackgroundColor: Colors.grey.shade400,
                    ),
                    child: _isProcessing
                        ? const CircularProgressIndicator(
                            color: Colors.white)
                        : const Text('Xác nhận thanh toán',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
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
        Text(title,
            style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 15)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurface),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
