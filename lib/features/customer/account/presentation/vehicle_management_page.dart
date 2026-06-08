import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:baidoxe/core/theme.dart';
import 'vehicle_pending_page.dart';

class VehicleManagementPage extends StatefulWidget {
  const VehicleManagementPage({Key? key}) : super(key: key);

  @override
  State<VehicleManagementPage> createState() => _VehicleManagementPageState();
}

class _VehicleManagementPageState extends State<VehicleManagementPage> {
  final _formKey = GlobalKey<FormState>();
  
  final _vehicleNameCtrl = TextEditingController();
  final _licensePlateCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();

  String _vehicleType = 'car';
  bool _isLoading = false;
  bool _isDefault = false;

  String? _selectedColor;
  final List<Map<String, dynamic>> _colorOptions = [
    {'name': 'Đỏ', 'color': Colors.red},
    {'name': 'Vàng', 'color': Colors.yellow},
    {'name': 'Lục', 'color': Colors.green},
    {'name': 'Lam', 'color': Colors.blue},
    {'name': 'Đen', 'color': Colors.black},
    {'name': 'Trắng', 'color': Colors.white},
    {'name': 'Bạc', 'color': Colors.grey.shade400},
  ];

  // Các hãng xe gợi ý
  final List<Map<String, String>> _carBrands = [
    {'name': 'Toyota', 'asset': 'assets/vehicles/toyota_default.png'},
    {'name': 'Honda', 'asset': 'assets/vehicles/honda_default.png'},
    {'name': 'Mazda', 'asset': 'assets/vehicles/mazda_default.png'},
    {'name': 'Ford', 'asset': 'assets/vehicles/ford_default.png'},
    {'name': 'Kia', 'asset': 'assets/vehicles/kia_default.png'},
    {'name': 'Hyundai', 'asset': 'assets/vehicles/hyundai_default.png'},
  ];

  String? _selectedAssetPath;
  File? _pickedImage;
  String? _base64Image;

  @override
  void dispose() {
    _vehicleNameCtrl.dispose();
    _licensePlateCtrl.dispose();
    _brandCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final bytes = await file.readAsBytes();
      final base64Str = base64Encode(bytes);
      
      setState(() {
        _pickedImage = file;
        _base64Image = base64Str;
        _selectedAssetPath = null; // Bỏ asset nếu chụp hình thật
      });
    }
  }

  Future<void> _saveVehicle() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedColor == null) {
        Get.snackbar('Lỗi', 'Vui lòng chọn màu xe', backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      setState(() => _isLoading = true);
      
      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId == null) {
          Get.snackbar('Lỗi', 'Vui lòng đăng nhập lại');
          return;
        }

        // Nếu người dùng chọn xe mặc định, thì update các xe khác thành false trước
        if (_isDefault) {
          await Supabase.instance.client
              .from('vehicles')
              .update({'is_default': false})
              .eq('user_id', userId);
        }

        // Ưu tiên hình chụp base64, nếu không có thì dùng asset path
        final imageUrlToSave = _base64Image ?? _selectedAssetPath ?? 'assets/vehicles/default.png';

        await Supabase.instance.client.from('vehicles').insert({
          'user_id': userId,
          'type': _vehicleType,
          'name': _vehicleNameCtrl.text,
          'license_plate': _licensePlateCtrl.text,
          'brand': _brandCtrl.text,
          'color': _selectedColor,
          'is_default': _isDefault,
          'image_url': imageUrlToSave,
          'verification_status': 'pending',
        });

        Get.snackbar(
          'Thành công',
          'Đã lưu thông tin phương tiện',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        
        Get.back(); // Quay lại trang trước thay vì trang pending trống
      } catch (e) {
        Get.snackbar('Lỗi', 'Không thể lưu: $e', backgroundColor: Colors.red, colorText: Colors.white);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Thêm phương tiện mới'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Loại phương tiện
                _buildSectionTitle('Loại phương tiện'),
                Row(
                  children: [
                    Expanded(
                      child: _buildTypeCard(
                        icon: Icons.directions_car,
                        label: 'Ô tô',
                        value: 'car',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTypeCard(
                        icon: Icons.two_wheeler,
                        label: 'Xe máy',
                        value: 'motorcycle',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Hãng xe (Autocomplete)
                _buildSectionTitle('Hãng xe / Mẫu xe'),
                TypeAheadField<Map<String, String>>(
                  controller: _brandCtrl,
                  builder: (context, controller, focusNode) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Nhập hãng xe (VD: Toyota, Honda...)',
                        prefixIcon: Icon(Icons.search),
                      ),
                    );
                  },
                  suggestionsCallback: (pattern) {
                    return _carBrands.where((brand) =>
                        brand['name']!.toLowerCase().contains(pattern.toLowerCase())).toList();
                  },
                  itemBuilder: (context, suggestion) {
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.directions_car, color: Colors.grey.shade600), // Dùng icon dự phòng nếu asset lỗi
                      ),
                      title: Text(suggestion['name']!),
                    );
                  },
                  onSelected: (suggestion) {
                    _brandCtrl.text = suggestion['name']!;
                    // Tự động điền brand làm name luôn nếu name đang trống
                    if (_vehicleNameCtrl.text.isEmpty) {
                      _vehicleNameCtrl.text = suggestion['name']!;
                    }
                    setState(() {
                      _selectedAssetPath = suggestion['asset'];
                      _pickedImage = null;
                      _base64Image = null;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Biển số xe & Tên xe
                _buildTextField(
                  controller: _licensePlateCtrl,
                  label: 'Biển số xe',
                  icon: Icons.pin,
                  validator: (v) => v!.isEmpty ? 'Vui lòng nhập biển số' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _vehicleNameCtrl,
                  label: 'Tên xe/Biệt danh (Tùy chọn)',
                  icon: Icons.car_repair,
                ),
                const SizedBox(height: 24),

                // Hình ảnh xe
                _buildSectionTitle('Hình ảnh phương tiện'),
                _buildImageContainer(),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.center,
                  child: TextButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Thêm mẫu xe của bạn'),
                  ),
                ),
                const SizedBox(height: 24),

                // Chọn màu sắc
                _buildSectionTitle('Màu xe'),
                _buildColorPicker(),
                const SizedBox(height: 24),

                // Xe mặc định
                CheckboxListTile(
                  value: _isDefault,
                  onChanged: (val) => setState(() => _isDefault = val ?? false),
                  title: const Text('Đặt làm phương tiện mặc định', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Hệ thống sẽ tự chọn xe này khi bạn đỗ xe'),
                  activeColor: AppTheme.primaryBlue,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 32),

                // Nút Lưu
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveVehicle,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('LƯU PHƯƠNG TIỆN', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageContainer() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _pickedImage != null
            ? Image.file(_pickedImage!, fit: BoxFit.cover)
            : _selectedAssetPath != null
                ? Image.asset(
                    _selectedAssetPath!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_car, size: 80, color: Colors.grey.shade400),
                        const Text('Chưa có ảnh mô hình'),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('Chưa chọn ảnh', style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
      ),
    );
  }

  Widget _buildColorPicker() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _colorOptions.map((colorItem) {
          final color = colorItem['color'] as Color;
          final name = colorItem['name'] as String;
          final isSelected = _selectedColor == name;

          return GestureDetector(
            onTap: () => setState(() => _selectedColor = name),
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppTheme.accentBlue : Colors.grey.shade300,
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: AppTheme.accentBlue.withOpacity(0.4), blurRadius: 8, spreadRadius: 2)]
                          : null,
                    ),
                    child: isSelected && color == Colors.white
                        ? const Icon(Icons.check, color: Colors.black, size: 20)
                        : isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppTheme.accentBlue : Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }

  Widget _buildTypeCard({required IconData icon, required String label, required String value}) {
    final isSelected = _vehicleType == value;
    return GestureDetector(
      onTap: () => setState(() => _vehicleType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentBlue : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.accentBlue : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppTheme.accentBlue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: isSelected ? Colors.white : Theme.of(context).textTheme.bodySmall?.color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
