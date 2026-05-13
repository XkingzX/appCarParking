import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:baidoxe/core/theme.dart';
import 'vehicle_pending_page.dart';

class VehicleManagementPage extends StatefulWidget {
  const VehicleManagementPage({Key? key}) : super(key: key);

  @override
  State<VehicleManagementPage> createState() => _VehicleManagementPageState();
}

class _VehicleManagementPageState extends State<VehicleManagementPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Các Controllers
  final _vehicleNameCtrl = TextEditingController();
  final _licensePlateCtrl = TextEditingController();
  final _cccdCtrl = TextEditingController();
  final _driverLicenseCtrl = TextEditingController();
  final _vehicleRegistrationCtrl = TextEditingController();

  String _vehicleType = 'car'; // car or motorcycle
  bool _isLoading = false;

  @override
  void dispose() {
    _vehicleNameCtrl.dispose();
    _licensePlateCtrl.dispose();
    _cccdCtrl.dispose();
    _driverLicenseCtrl.dispose();
    _vehicleRegistrationCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveVehicle() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId == null) {
          Get.snackbar('Lỗi', 'Vui lòng đăng nhập lại');
          return;
        }

        await Supabase.instance.client.from('vehicles').insert({
          'user_id': userId,
          'type': _vehicleType,
          'name': _vehicleNameCtrl.text,
          'license_plate': _licensePlateCtrl.text,
          'cccd': _cccdCtrl.text,
          'driver_license': _driverLicenseCtrl.text,
          'vehicle_registration': _vehicleRegistrationCtrl.text,
          'verification_status': 'pending', // Trạng thái chờ
        });

        Get.snackbar(
          'Thành công',
          'Đã gửi thông tin phương tiện',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        
        // Chuyển sang trang Pending
        Get.off(() => const VehiclePendingPage());
      } catch (e) {
        Get.snackbar('Lỗi', 'Không thể lưu: ${e.toString()}', backgroundColor: Colors.red, colorText: Colors.white);
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryWhite,
      appBar: AppBar(
        title: const Text('Quản lý phương tiện'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Vehicle Type Selection
                const Text('Loại phương tiện', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
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

                // Basic Info
                _buildSectionTitle('Thông tin cơ bản'),
                _buildTextField(
                  controller: _vehicleNameCtrl,
                  label: 'Tên xe (VD: Honda City, SH 150i)',
                  icon: Icons.car_repair,
                  validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên xe' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _licensePlateCtrl,
                  label: 'Biển số xe',
                  icon: Icons.pin,
                  validator: (v) => v!.isEmpty ? 'Vui lòng nhập biển số' : null,
                ),
                const SizedBox(height: 24),

                // Documents
                _buildSectionTitle('Giấy tờ cá nhân & Xe (Bắt buộc)'),
                _buildTextField(
                  controller: _cccdCtrl,
                  label: 'Số CMND / CCCD',
                  icon: Icons.badge,
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Vui lòng nhập số CCCD' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _driverLicenseCtrl,
                  label: 'Mã số Bằng lái xe',
                  icon: Icons.card_membership,
                  validator: (v) => v!.isEmpty ? 'Vui lòng nhập bằng lái xe' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _vehicleRegistrationCtrl,
                  label: 'Số Giấy đăng ký xe (Cà vẹt)',
                  icon: Icons.description,
                  validator: (v) => v!.isEmpty ? 'Vui lòng nhập số đăng ký xe' : null,
                ),
                const SizedBox(height: 32),

                // Save Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveVehicle,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('LƯU THÔNG TIN'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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
      onTap: () {
        setState(() {
          _vehicleType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentBlue : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.accentBlue : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppTheme.accentBlue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: isSelected ? Colors.white : AppTheme.textLight),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
