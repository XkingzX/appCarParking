import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:baidoxe/core/theme.dart';

class AdminVerificationPage extends StatefulWidget {
  const AdminVerificationPage({Key? key}) : super(key: key);

  @override
  State<AdminVerificationPage> createState() => _AdminVerificationPageState();
}

class _AdminVerificationPageState extends State<AdminVerificationPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingVehicles = [];

  @override
  void initState() {
    super.initState();
    _fetchPendingVehicles();
  }

  Future<void> _fetchPendingVehicles() async {
    try {
      setState(() {
        _isLoading = true;
      });
      // Lấy danh sách các xe có trạng thái pending, kèm theo thông tin user
      final response = await Supabase.instance.client
          .from('vehicles')
          .select('*, profiles(full_name, email)')
          .eq('verification_status', 'pending');

      if (mounted) {
        setState(() {
          _pendingVehicles = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching vehicles: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateStatus(String vehicleId, String status) async {
    try {
      await Supabase.instance.client
          .from('vehicles')
          .update({'verification_status': status})
          .eq('id', vehicleId);
      
      // Xóa khỏi danh sách hiện tại
      setState(() {
        _pendingVehicles.removeWhere((v) => v['id'] == vehicleId);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'verified' ? 'Đã duyệt thành công!' : 'Đã từ chối!'),
          backgroundColor: status == 'verified' ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryWhite,
      appBar: AppBar(
        title: const Text('Admin Panel - Duyệt Phương Tiện'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPendingVehicles,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingVehicles.isEmpty
              ? _buildEmptyState()
              : _buildDataTable(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
          SizedBox(height: 16),
          Text('Tuyệt vời!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text('Không có phương tiện nào đang chờ duyệt.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.indigo.shade50),
          columns: const [
            DataColumn(label: Text('Khách hàng', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Loại xe', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Biển số', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('CCCD', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Bằng lái / Cà vẹt', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Hành động', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: _pendingVehicles.map((vehicle) {
            final profile = vehicle['profiles'] ?? {};
            final customerName = profile['full_name'] ?? 'Unknown';
            final vehicleType = vehicle['type'] == 'car' ? 'Ô tô' : 'Xe máy';
            
            return DataRow(
              cells: [
                DataCell(Text(customerName)),
                DataCell(
                  Row(
                    children: [
                      Icon(vehicle['type'] == 'car' ? Icons.directions_car : Icons.two_wheeler, size: 16),
                      const SizedBox(width: 8),
                      Text(vehicleType),
                    ],
                  ),
                ),
                DataCell(Text(vehicle['license_plate'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(vehicle['cccd'] ?? '')),
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Bằng lái: ${vehicle['driver_license'] ?? ''}', style: const TextStyle(fontSize: 12)),
                      Text('Cà vẹt: ${vehicle['vehicle_registration'] ?? ''}', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                DataCell(
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _updateStatus(vehicle['id'], 'verified'),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Duyệt'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _updateStatus(vehicle['id'], 'rejected'),
                        icon: const Icon(Icons.close, size: 16, color: Colors.red),
                        label: const Text('Từ chối', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
