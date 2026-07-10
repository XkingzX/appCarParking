import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:baidoxe/features/web_admin/web_admin_layout.dart';
import 'package:baidoxe/core/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:baidoxe/model/parking_lot_model.dart';

class ParkingFormPage extends StatefulWidget {
  final String role;
  
  const ParkingFormPage({Key? key, required this.role}) : super(key: key);

  @override
  State<ParkingFormPage> createState() => _ParkingFormPageState();
}

class _ParkingFormPageState extends State<ParkingFormPage> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  late TextEditingController _imagesController;
  late TextEditingController _tagsController;
  late TextEditingController _gracePeriodController;
  late TextEditingController _peakMultiplierController;
  
  bool _isLoading = false;
  bool _isDynamicPricing = false;
  ParkingLotModel? _parkingLot;
  
  List<Map<String, dynamic>> _owners = [];
  String? _selectedOwnerId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _locationController = TextEditingController();
    _latController = TextEditingController();
    _lngController = TextEditingController();
    _imagesController = TextEditingController();
    _tagsController = TextEditingController();
    _gracePeriodController = TextEditingController(text: '15');
    _peakMultiplierController = TextEditingController(text: '1.5');
    
    // Nhận data từ GetX Arguments nếu là Edit
    if (Get.arguments != null && Get.arguments['parkingLot'] != null) {
      _parkingLot = Get.arguments['parkingLot'];
      _nameController.text = _parkingLot!.name;
      _locationController.text = _parkingLot!.location ?? '';
      _latController.text = _parkingLot!.latitude.toString();
      _lngController.text = _parkingLot!.longitude.toString();
      _imagesController.text = _parkingLot!.images.join(', ');
      _tagsController.text = _parkingLot!.tags.join(', ');
      _gracePeriodController.text = _parkingLot!.gracePeriodMinutes.toString();
      _isDynamicPricing = _parkingLot!.isDynamicPricing;
      _peakMultiplierController.text = _parkingLot!.peakMultiplier.toString();
      _selectedOwnerId = _parkingLot!.ownerId;
    }

    if (widget.role == 'admin') {
      _fetchOwners();
    }
  }

  Future<void> _fetchOwners() async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('id, full_name, email')
          .eq('role', 'parking_owner');
      setState(() {
        _owners = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('Error fetching owners: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _imagesController.dispose();
    _tagsController.dispose();
    _gracePeriodController.dispose();
    _peakMultiplierController.dispose();
    super.dispose();
  }

  Future<void> _saveParkingLot() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final data = {
        'name': _nameController.text.trim(),
        'location': _locationController.text.trim(),
        'latitude': double.tryParse(_latController.text.trim()) ?? 0.0,
        'longitude': double.tryParse(_lngController.text.trim()) ?? 0.0,
        'images': _imagesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'tags': _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'grace_period_minutes': int.tryParse(_gracePeriodController.text.trim()) ?? 15,
        'is_dynamic_pricing': _isDynamicPricing,
        'peak_multiplier': double.tryParse(_peakMultiplierController.text.trim()) ?? 1.5,
        'owner_id': widget.role == 'admin' ? _selectedOwnerId : supabase.auth.currentUser!.id,
      };

      if (_parkingLot == null) {
        // Create
        await supabase.from('parking_lots').insert(data);
        Get.snackbar('Thành công', 'Đã thêm bãi đỗ xe mới', backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        // Update
        await supabase.from('parking_lots').update(data).eq('id', _parkingLot!.id);
        Get.snackbar('Thành công', 'Đã cập nhật bãi đỗ xe', backgroundColor: Colors.green, colorText: Colors.white);
      }
      
      Get.offNamed('/web-admin/parking');
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể lưu bãi đỗ xe: $e', backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebAdminLayout(
      role: widget.role,
      currentRoute: '/web-admin/parking',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Get.back(),
              ),
              const SizedBox(width: 8),
              Text(
                _parkingLot == null ? 'Thêm bãi đỗ xe mới' : 'Chỉnh sửa bãi đỗ xe',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ]
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Tên bãi đỗ *', border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên' : null,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(labelText: 'Địa chỉ chi tiết', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _latController,
                              decoration: const InputDecoration(labelText: 'Vĩ độ (Latitude) *', border: OutlineInputBorder()),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (v) => v!.isEmpty ? 'Vui lòng nhập vĩ độ' : null,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: TextFormField(
                              controller: _lngController,
                              decoration: const InputDecoration(labelText: 'Kinh độ (Longitude) *', border: OutlineInputBorder()),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (v) => v!.isEmpty ? 'Vui lòng nhập kinh độ' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // New Customization fields
                      TextFormField(
                        controller: _imagesController,
                        decoration: const InputDecoration(
                          labelText: 'Hình ảnh (Cách nhau bằng dấu phẩy)', 
                          hintText: 'VD: https://link.com/img1.jpg, https://link.com/img2.jpg',
                          border: OutlineInputBorder()
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _tagsController,
                        decoration: const InputDecoration(
                          labelText: 'Thẻ tag (Cách nhau bằng dấu phẩy)', 
                          hintText: 'VD: Có mái che, Rửa xe, Camera 24/7',
                          border: OutlineInputBorder()
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _gracePeriodController,
                        decoration: const InputDecoration(
                          labelText: 'Thời gian cọc chờ (phút)', 
                          hintText: 'VD: 15',
                          border: OutlineInputBorder()
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Thời gian phải lớn hơn 0' : null,
                      ),
                      const SizedBox(height: 24),
                      
                      if (widget.role == 'admin') ...[
                        DropdownButtonFormField<String>(
                          value: _selectedOwnerId,
                          decoration: const InputDecoration(labelText: 'Chủ bãi đỗ *', border: OutlineInputBorder()),
                          items: _owners.map((owner) {
                            return DropdownMenuItem<String>(
                              value: owner['id'],
                              child: Text('${owner['full_name'] ?? 'No Name'} (${owner['email'] ?? 'No Email'})'),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedOwnerId = v),
                          validator: (v) => v == null ? 'Vui lòng chọn chủ bãi' : null,
                        ),
                        const SizedBox(height: 32),
                      ],
                      
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text('Định giá Động (Dynamic Pricing)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Bật Định giá động theo giờ cao điểm'),
                        subtitle: const Text('Giá vé sẽ tự động nhân với hệ số vào giờ cao điểm'),
                        value: _isDynamicPricing,
                        onChanged: (val) {
                          setState(() {
                            _isDynamicPricing = val;
                          });
                        },
                      ),
                      if (_isDynamicPricing) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _peakMultiplierController,
                          decoration: const InputDecoration(
                            labelText: 'Hệ số giờ cao điểm (VD: 1.5 = Tăng 50%)', 
                            border: OutlineInputBorder()
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) => _isDynamicPricing && (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Vui lòng nhập hệ số hợp lệ' : null,
                        ),
                      ],
                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveParkingLot,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                          ),
                          child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Lưu thông tin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
