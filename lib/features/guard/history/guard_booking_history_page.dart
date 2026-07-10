import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class GuardBookingHistoryPage extends StatefulWidget {
  const GuardBookingHistoryPage({Key? key}) : super(key: key);

  @override
  State<GuardBookingHistoryPage> createState() => _GuardBookingHistoryPageState();
}

class _GuardBookingHistoryPageState extends State<GuardBookingHistoryPage> {
  bool _isLoading = true;
  String _parkingLotId = '';
  List<Map<String, dynamic>> _bookings = [];
  String _selectedStatus = 'all'; // all, pending, paid, cancelled, completed

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args != null && args['parkingLotId'] != null) {
      _parkingLotId = args['parkingLotId'];
    }
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    if (_parkingLotId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('bookings')
          .select('*, profiles:user_id(full_name), slots!inner(parking_lot_id)')
          .eq('slots.parking_lot_id', _parkingLotId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _bookings = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching history: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredBookings {
    if (_selectedStatus == 'all') return _bookings;
    return _bookings.where((b) => b['status'] == _selectedStatus).toList();
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    try {
      return DateFormat('HH:mm, dd/MM').format(DateTime.parse(isoDate).toLocal());
    } catch (_) {
      return isoDate;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      case 'confirmed': return Colors.blue;
      default: return Colors.orange; // pending
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trạng thái & Lịch sử', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchBookings();
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildFilterChip('Tất cả', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Đang chờ', 'pending'),
                const SizedBox(width: 8),
                _buildFilterChip('Đang đỗ (Confirmed)', 'confirmed'),
                const SizedBox(width: 8),
                _buildFilterChip('Hoàn thành', 'completed'),
                const SizedBox(width: 8),
                _buildFilterChip('Đã huỷ', 'cancelled'),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBookings.isEmpty
                    ? const Center(child: Text('Không có dữ liệu.'))
                    : ListView.builder(
                        itemCount: _filteredBookings.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final b = _filteredBookings[index];
                          final status = b['status'] ?? 'pending';
                          final statusColor = _getStatusColor(status);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Mã: #${b['id'].toString().substring(0, 8)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                      )
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 20, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text(b['profiles']?['full_name'] ?? 'Khách vãng lai', style: const TextStyle(fontSize: 15)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 20, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text('${_formatDate(b['start_time'])} - ${_formatDate(b['end_time'])}', style: const TextStyle(fontSize: 15)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.attach_money, size: 20, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text('${b['total_amount'] ?? 0} VNĐ', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedStatus == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedStatus = value);
        }
      },
      selectedColor: Colors.blue.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue[800] : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
