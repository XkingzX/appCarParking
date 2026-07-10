import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:baidoxe/features/web_admin/web_admin_layout.dart';
import 'package:baidoxe/core/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:baidoxe/model/traffic_simulation_model.dart';

class TrafficSimulationFormPage extends StatefulWidget {
  final String role;
  
  const TrafficSimulationFormPage({Key? key, required this.role}) : super(key: key);

  @override
  State<TrafficSimulationFormPage> createState() => _TrafficSimulationFormPageState();
}

class _TrafficSimulationFormPageState extends State<TrafficSimulationFormPage> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _startLatController;
  late TextEditingController _startLngController;
  late TextEditingController _endLatController;
  late TextEditingController _endLngController;
  late TextEditingController _peakHoursController;
  
  double _speedKmh = 40.0;
  double _volumePerHour = 100.0;
  String _status = 'clear';
  
  bool _isLoading = false;
  TrafficSimulationModel? _simulation;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _startLatController = TextEditingController();
    _startLngController = TextEditingController();
    _endLatController = TextEditingController();
    _endLngController = TextEditingController();
    _peakHoursController = TextEditingController();
    
    if (Get.arguments != null && Get.arguments['simulation'] != null) {
      _simulation = Get.arguments['simulation'];
      _nameController.text = _simulation!.roadName;
      _startLatController.text = _simulation!.startLat.toString();
      _startLngController.text = _simulation!.startLng.toString();
      _endLatController.text = _simulation!.endLat.toString();
      _endLngController.text = _simulation!.endLng.toString();
      _peakHoursController.text = _simulation!.peakHours ?? '';
      _speedKmh = _simulation!.speedKmh.toDouble();
      _volumePerHour = _simulation!.volumePerHour.toDouble();
      _status = _simulation!.status;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _startLatController.dispose();
    _startLngController.dispose();
    _endLatController.dispose();
    _endLngController.dispose();
    _peakHoursController.dispose();
    super.dispose();
  }

  Future<void> _saveSimulation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final data = {
        'road_name': _nameController.text.trim(),
        'start_lat': double.tryParse(_startLatController.text.trim()) ?? 0.0,
        'start_lng': double.tryParse(_startLngController.text.trim()) ?? 0.0,
        'end_lat': double.tryParse(_endLatController.text.trim()) ?? 0.0,
        'end_lng': double.tryParse(_endLngController.text.trim()) ?? 0.0,
        'speed_kmh': _speedKmh.toInt(),
        'volume_per_hour': _volumePerHour.toInt(),
        'status': _status,
        'peak_hours': _peakHoursController.text.trim(),
      };

      if (_simulation == null) {
        await supabase.from('traffic_simulations').insert(data);
        Get.snackbar('Thành công', 'Đã thêm tuyến đường mô phỏng', backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        await supabase.from('traffic_simulations').update(data).eq('id', _simulation!.id);
        Get.snackbar('Thành công', 'Đã cập nhật mô phỏng giao thông', backgroundColor: Colors.green, colorText: Colors.white);
      }
      
      Get.offNamed('/web-admin/traffic');
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể lưu: $e', backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebAdminLayout(
      role: widget.role,
      currentRoute: '/web-admin/traffic',
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
                _simulation == null ? 'Thêm Tuyến Đường Mô Phỏng' : 'Chỉnh sửa Mô Phỏng',
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
                        decoration: const InputDecoration(labelText: 'Tên tuyến đường *', border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên' : null,
                      ),
                      const SizedBox(height: 24),
                      
                      // Tọa độ
                      const Text('Tọa độ điểm đầu', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _startLatController,
                              decoration: const InputDecoration(labelText: 'Vĩ độ (Lat) *', border: OutlineInputBorder()),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (v) => v!.isEmpty ? 'Bắt buộc' : null,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: TextFormField(
                              controller: _startLngController,
                              decoration: const InputDecoration(labelText: 'Kinh độ (Lng) *', border: OutlineInputBorder()),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (v) => v!.isEmpty ? 'Bắt buộc' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      const Text('Tọa độ điểm cuối', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _endLatController,
                              decoration: const InputDecoration(labelText: 'Vĩ độ (Lat) *', border: OutlineInputBorder()),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (v) => v!.isEmpty ? 'Bắt buộc' : null,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: TextFormField(
                              controller: _endLngController,
                              decoration: const InputDecoration(labelText: 'Kinh độ (Lng) *', border: OutlineInputBorder()),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (v) => v!.isEmpty ? 'Bắt buộc' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Sliders
                      const Text('Thông số Giao thông (Realtime Simulation)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 16),
                      
                      Text('Tốc độ trung bình: ${_speedKmh.toInt()} km/h'),
                      Slider(
                        value: _speedKmh,
                        min: 0,
                        max: 120,
                        divisions: 120,
                        label: '${_speedKmh.toInt()} km/h',
                        activeColor: _speedKmh < 20 ? Colors.red : (_speedKmh < 40 ? Colors.orange : Colors.green),
                        onChanged: (v) => setState(() => _speedKmh = v),
                      ),
                      const SizedBox(height: 16),

                      Text('Lưu lượng: ${_volumePerHour.toInt()} xe/giờ'),
                      Slider(
                        value: _volumePerHour,
                        min: 0,
                        max: 5000,
                        divisions: 100,
                        label: '${_volumePerHour.toInt()} xe/giờ',
                        activeColor: AppTheme.primaryBlue,
                        onChanged: (v) => setState(() => _volumePerHour = v),
                      ),
                      const SizedBox(height: 24),

                      // Status Dropdown
                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(labelText: 'Trạng thái đường', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'clear', child: Text('Thông thoáng (Xanh)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                          DropdownMenuItem(value: 'moderate', child: Text('Đông đúc (Vàng)', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
                          DropdownMenuItem(value: 'heavy', child: Text('Kẹt xe mạnh (Đỏ)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                          DropdownMenuItem(value: 'jam', child: Text('Tắc đường (Tím)', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold))),
                        ],
                        onChanged: (v) => setState(() => _status = v!),
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _peakHoursController,
                        decoration: const InputDecoration(labelText: 'Giờ cao điểm (vd: 07:00-09:00)', border: OutlineInputBorder()),
                      ),

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveSimulation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                          ),
                          child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Lưu Mô Phỏng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
