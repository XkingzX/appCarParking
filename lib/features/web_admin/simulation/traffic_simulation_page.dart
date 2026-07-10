import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:baidoxe/features/web_admin/web_admin_layout.dart';
import 'package:baidoxe/features/web_admin/widgets/custom_data_table.dart';
import 'package:baidoxe/core/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:baidoxe/model/traffic_simulation_model.dart';

class TrafficSimulationPage extends StatefulWidget {
  final String role;

  const TrafficSimulationPage({Key? key, required this.role}) : super(key: key);

  @override
  State<TrafficSimulationPage> createState() => _TrafficSimulationPageState();
}

class _TrafficSimulationPageState extends State<TrafficSimulationPage> {
  bool _isLoading = true;
  List<TrafficSimulationModel> _simulations = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      setState(() => _isLoading = true);
      final response = await Supabase.instance.client
          .from('traffic_simulations')
          .select('*')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _simulations = (response as List).map((e) => TrafficSimulationModel.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải dữ liệu giao thông: $e');
      if (mounted) setState(() => _isLoading = false);
      Get.snackbar('Lỗi', 'Không thể tải dữ liệu mô phỏng', backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  Future<void> _deleteSimulation(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xoá'),
        content: const Text('Bạn có chắc chắn muốn xoá tuyến đường mô phỏng này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xoá'),
          ),
        ],
      )
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client.from('traffic_simulations').delete().eq('id', id);
        Get.snackbar('Thành công', 'Đã xoá tuyến đường', backgroundColor: Colors.green, colorText: Colors.white);
        _fetchData();
      } catch (e) {
        Get.snackbar('Lỗi', 'Không thể xoá', backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mô phỏng Giao thông (Traffic Simulation)',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              if (widget.role == 'admin')
                ElevatedButton.icon(
                  onPressed: () => Get.toNamed('/web-admin/traffic/form'),
                  icon: const Icon(Icons.add_road_rounded),
                  label: const Text('Thêm Tuyến Đường'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                )
            ],
          ),
          const SizedBox(height: 24),
          
          if (_isLoading)
            const Expanded(child: Center(child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(color: AppTheme.primaryBlue),
            )))
          else if (_simulations.isEmpty)
            const Expanded(child: Center(child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Text('Chưa có dữ liệu mô phỏng.', style: TextStyle(color: Colors.grey, fontSize: 16)),
            )))
          else
            Expanded(
              child: CustomDataTable(
                columns: const ['Tuyến đường', 'Vận tốc (km/h)', 'Lưu lượng', 'Giờ cao điểm', 'Trạng thái', 'Hành động'],
                rows: _simulations.map((sim) {
                  return [
                    Text(sim.roadName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${sim.speedKmh} km/h'),
                    Text('${sim.volumePerHour} xe/h'),
                    Text(sim.peakHours ?? 'Không có'),
                    Chip(
                      label: Text(sim.statusText, style: TextStyle(color: sim.statusColor, fontWeight: FontWeight.bold)),
                      backgroundColor: sim.statusColor.withOpacity(0.1),
                      side: BorderSide(color: sim.statusColor.withOpacity(0.2)),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, color: AppTheme.accentBlue),
                          tooltip: 'Chỉnh sửa',
                          onPressed: () {
                            if (widget.role == 'admin') {
                              Get.toNamed('/web-admin/traffic/form', arguments: {'simulation': sim});
                            } else {
                              Get.snackbar('Cảnh báo', 'Chỉ Admin mới có quyền sửa đổi');
                            }
                          },
                        ),
                        if (widget.role == 'admin')
                          IconButton(
                            icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                            tooltip: 'Xoá',
                            onPressed: () => _deleteSimulation(sim.id),
                          ),
                      ],
                    ),
                  ];
                }).toList(),
              ),
            )
        ],
      ),
    );
  }
}
