import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:baidoxe/features/web_admin/web_admin_layout.dart';
import 'package:baidoxe/features/web_admin/widgets/custom_data_table.dart';
import 'package:baidoxe/core/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:baidoxe/model/parking_lot_model.dart';

class ParkingListPage extends StatefulWidget {
  final String role;

  const ParkingListPage({Key? key, required this.role}) : super(key: key);

  @override
  State<ParkingListPage> createState() => _ParkingListPageState();
}

class _ParkingListPageState extends State<ParkingListPage> {
  bool _isLoading = true;
  List<ParkingLotModel> _parkingLots = [];

  @override
  void initState() {
    super.initState();
    _fetchParkingLots();
  }

  Future<void> _fetchParkingLots() async {
    try {
      setState(() => _isLoading = true);

      final supabase = Supabase.instance.client;

      var query = supabase
          .from('parking_lots')
          .select('*, profiles(full_name)');

      if (widget.role == 'parking_owner') {
        query = query.eq(
          'owner_id',
          supabase.auth.currentUser!.id,
        );
      }

      final response = await query.order(
        'created_at',
        ascending: false,
      );

      if (mounted) {
        setState(() {
          _parkingLots = (response as List)
              .map((e) => ParkingLotModel.fromJson(e))
              .toList();

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải danh sách bãi đỗ: $e');

      if (mounted) {
        setState(() => _isLoading = false);
      }

      Get.snackbar(
        'Lỗi',
        'Không thể tải danh sách bãi đỗ xe',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _deleteParkingLot(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xoá'),
        content: const Text('Bạn có chắc chắn muốn xoá bãi đỗ xe này không? Hành động này không thể hoàn tác.'),
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
        await Supabase.instance.client.from('parking_lots').delete().eq('id', id);
        Get.snackbar('Thành công', 'Đã xoá bãi đỗ xe', backgroundColor: Colors.green, colorText: Colors.white);
        _fetchParkingLots();
      } catch (e) {
        Get.snackbar('Lỗi', 'Không thể xoá bãi đỗ xe', backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Danh sách bãi đỗ xe',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Get.toNamed('/web-admin/parking/form');
                },
                icon: const Icon(Icons.add),
                label: const Text('Thêm bãi đỗ'),
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
          else if (_parkingLots.isEmpty)
            const Expanded(child: Center(child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Text('Chưa có bãi đỗ xe nào.', style: TextStyle(color: Colors.grey, fontSize: 16)),
            )))
          else
            Expanded(
              child: CustomDataTable(
                columns: const ['Tên bãi đỗ', 'Địa chỉ', 'Chủ sở hữu', 'Đánh giá', 'Hành động'],
                rows: _parkingLots.map((parking) {
                  return [
                    Text(parking.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(parking.location ?? 'Chưa cập nhật', maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(parking.ownerName ?? (widget.role == 'parking_owner' ? 'Bạn' : 'Không xác định')),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text('${parking.avgRating} (${parking.totalReviews})'),
                      ],
                    ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.grid_view_rounded, color: Colors.green),
                            tooltip: 'Quản lý Slot',
                            onPressed: () {
                              Get.toNamed('/web-admin/parking/slots', arguments: {
                                'parkingLotId': parking.id,
                                'parkingLotName': parking.name,
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, color: AppTheme.accentBlue),
                            tooltip: 'Sửa',
                            onPressed: () {
                               Get.toNamed('/web-admin/parking/form', arguments: {'parkingLot': parking});
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                            tooltip: 'Xoá',
                            onPressed: () => _deleteParkingLot(parking.id),
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
