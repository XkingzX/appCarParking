import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:baidoxe/features/web_admin/web_admin_layout.dart';
import 'package:baidoxe/features/web_admin/widgets/custom_data_table.dart';
import 'package:baidoxe/core/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SlotManagementPage extends StatefulWidget {
  final String role;
  
  const SlotManagementPage({Key? key, required this.role}) : super(key: key);

  @override
  State<SlotManagementPage> createState() => _SlotManagementPageState();
}

class _SlotManagementPageState extends State<SlotManagementPage> {
  String _parkingLotId = '';
  String _parkingLotName = '';
  bool _isLoading = true;
  List<Map<String, dynamic>> _slots = [];

  @override
  void initState() {
    super.initState();
    if (Get.arguments != null) {
      _parkingLotId = Get.arguments['parkingLotId'] ?? '';
      _parkingLotName = Get.arguments['parkingLotName'] ?? '';
    }
    _fetchSlots();
  }

  Future<void> _fetchSlots() async {
    if (_parkingLotId.isEmpty) return;
    try {
      setState(() => _isLoading = true);
      final response = await Supabase.instance.client
          .from('slots')
          .select()
          .eq('parking_lot_id', _parkingLotId)
          .order('zone', ascending: true)
          .order('slot_name', ascending: true);
          
      setState(() {
        _slots = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('Error fetching slots: $e');
      Get.snackbar('Lỗi', 'Không thể tải danh sách slots');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddEditSlotDialog({Map<String, dynamic>? slot}) {
    final isEdit = slot != null;
    final nameController = TextEditingController(text: isEdit ? slot['slot_name'] : '');
    final zoneController = TextEditingController(text: isEdit ? slot['zone'] : 'A');
    String status = isEdit ? slot['status'] : 'available';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Sửa Slot' : 'Thêm Slot'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Tên Slot (VD: A01)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: zoneController,
              decoration: const InputDecoration(labelText: 'Khu vực (Zone)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: status,
              decoration: const InputDecoration(labelText: 'Trạng thái', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'available', child: Text('Trống (Available)')),
                DropdownMenuItem(value: 'occupied', child: Text('Đang đỗ (Occupied)')),
                DropdownMenuItem(value: 'reserved', child: Text('Đã đặt (Reserved)')),
                DropdownMenuItem(value: 'maintenance', child: Text('Bảo trì (Maintenance)')),
              ],
              onChanged: (v) => status = v!,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                final data = {
                  'parking_lot_id': _parkingLotId,
                  'slot_name': nameController.text.trim(),
                  'zone': zoneController.text.trim(),
                  'status': status,
                };
                
                if (isEdit) {
                  await Supabase.instance.client.from('slots').update(data).eq('id', slot['id']);
                  Get.snackbar('Thành công', 'Đã cập nhật slot');
                } else {
                  await Supabase.instance.client.from('slots').insert(data);
                  Get.snackbar('Thành công', 'Đã thêm slot mới');
                }
                _fetchSlots();
              } catch (e) {
                Get.snackbar('Lỗi', 'Không thể lưu slot: $e');
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _deleteSlot(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc chắn muốn xoá slot này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client.from('slots').delete().eq('id', id);
        Get.snackbar('Thành công', 'Đã xóa slot');
        _fetchSlots();
      } catch (e) {
        Get.snackbar('Lỗi', 'Không thể xóa slot');
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
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Get.back(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Quản lý Slot: $_parkingLotName',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddEditSlotDialog(),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Thêm Slot', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : CustomDataTable(
                    columns: const ['Zone', 'Slot Name', 'Trạng thái', 'Hành động'],
                    rows: _slots.map((slot) {
                      Color statusColor = Colors.green;
                      if (slot['status'] == 'occupied') statusColor = Colors.red;
                      if (slot['status'] == 'reserved') statusColor = Colors.blue;
                      if (slot['status'] == 'maintenance') statusColor = Colors.grey;

                      return [
                        Text(slot['zone'] ?? 'A', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(slot['slot_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            (slot['status'] ?? '').toString().toUpperCase(),
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showAddEditSlotDialog(slot: slot),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteSlot(slot['id']),
                            ),
                          ],
                        ),
                      ];
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
