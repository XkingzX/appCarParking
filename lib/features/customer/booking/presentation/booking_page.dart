import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:baidoxe/core/theme.dart';
import 'package:baidoxe/model/booking_model.dart';
import 'package:baidoxe/services/supabase_service.dart';

class CustomerBookingPage extends StatefulWidget {
  const CustomerBookingPage({Key? key}) : super(key: key);

  @override
  State<CustomerBookingPage> createState() => _CustomerBookingPageState();
}

class _CustomerBookingPageState extends State<CustomerBookingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseService _service = SupabaseService();

  List<BookingModel> _activeBookings = [];
  List<BookingModel> _historyBookings = [];
  bool _isLoadingActive = true;
  bool _isLoadingHistory = true;

  // Cache giá để hiển thị
  final Map<String, double> _priceCache = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadActiveBookings(),
      _loadHistoryBookings(),
    ]);
  }

  Future<void> _loadActiveBookings() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _isLoadingActive = false);
      return;
    }

    try {
      final data = await _service.getActiveBookings(userId);
      final bookings = data.map((e) => BookingModel.fromJson(e)).toList();

      // Load prices for each booking
      for (final booking in bookings) {
        if (booking.parkingLotId != null && !_priceCache.containsKey(booking.parkingLotId)) {
          await _loadPriceForParkingLot(booking.parkingLotId!);
        }
      }

      if (mounted) {
        setState(() {
          _activeBookings = bookings;
          _isLoadingActive = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading active bookings: $e');
      if (mounted) setState(() => _isLoadingActive = false);
    }
  }

  Future<void> _loadHistoryBookings() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) setState(() => _isLoadingHistory = false);
      return;
    }

    try {
      final data = await _service.getBookingHistory(userId);
      final bookings = data.map((e) => BookingModel.fromJson(e)).toList();

      // Load prices for each booking
      for (final booking in bookings) {
        if (booking.parkingLotId != null && !_priceCache.containsKey(booking.parkingLotId)) {
          await _loadPriceForParkingLot(booking.parkingLotId!);
        }
      }

      if (mounted) {
        setState(() {
          _historyBookings = bookings;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading history bookings: $e');
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _loadPriceForParkingLot(String parkingLotId) async {
    try {
      final prices = await _service.getParkingPrices(parkingLotId);
      if (prices.isNotEmpty) {
        // Lấy giá 1 giờ làm base price
        for (final p in prices) {
          final type = p['duration_type']?.toString().toLowerCase() ?? '';
          if (type.contains('1 giờ') || type.contains('1 gio')) {
            _priceCache[parkingLotId] = (p['price'] as num).toDouble();
            return;
          }
        }
        // Fallback: lấy giá thấp nhất
        _priceCache[parkingLotId] = (prices.first['price'] as num).toDouble();
      }
    } catch (e) {
      debugPrint('Error loading price: $e');
    }
  }

  String _calculateBookingPrice(BookingModel booking) {
    final basePrice = _priceCache[booking.parkingLotId] ?? 20000;
    final hours = booking.durationInHours;
    final total = (basePrice * hours).toInt();
    final f = NumberFormat('#,###', 'vi_VN');
    return '${f.format(total)}đ';
  }

  Future<void> _cancelBooking(BookingModel booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận hủy'),
        content: Text('Bạn có chắc muốn hủy đặt chỗ tại ${booking.parkingLotName ?? 'bãi đỗ'}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hủy đặt chỗ'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.cancelBooking(booking.id);
      Get.snackbar(
        'Thành công',
        'Đã hủy đặt chỗ',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      await _loadData(); // Refresh both active and history lists
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể hủy đặt chỗ: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Đặt chỗ của tôi'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: AppTheme.textLight,
          indicatorColor: AppTheme.primaryBlue,
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Đang đỗ'),
                  if (_activeBookings.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.accentBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_activeBookings.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Lịch sử'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab: Đang đỗ
          _buildActiveTab(),
          // Tab: Lịch sử
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildActiveTab() {
    if (_isLoadingActive) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activeBookings.isEmpty) {
      return _buildEmptyState(
        icon: Icons.local_parking_rounded,
        title: 'Chưa có đặt chỗ nào',
        subtitle: 'Hãy tìm bãi đỗ xe và đặt chỗ ngay!',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadActiveBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _activeBookings.length,
        itemBuilder: (context, index) {
          return _buildBookingCard(_activeBookings[index], isActive: true);
        },
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_historyBookings.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history_rounded,
        title: 'Chưa có lịch sử',
        subtitle: 'Lịch sử đặt chỗ sẽ hiển thị tại đây.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistoryBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _historyBookings.length,
        itemBuilder: (context, index) {
          return _buildBookingCard(_historyBookings[index], isActive: false);
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.accentBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 56, color: AppTheme.accentBlue),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking, {required bool isActive}) {
    final dateFormat = DateFormat('HH:mm - dd/MM/yyyy');
    final statusColor = _getStatusColor(booking.status);
    final price = _calculateBookingPrice(booking);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Tên bãi + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    booking.parkingLotName ?? 'Bãi đỗ xe',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    booking.statusDisplay,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Xe
            if (booking.vehicleName != null || booking.licensePlate != null)
              Row(
                children: [
                  Icon(Icons.directions_car, size: 20, color: Theme.of(context).textTheme.bodySmall?.color),
                  const SizedBox(width: 8),
                  Text(
                    '${booking.vehicleName ?? 'Xe'} (${booking.licensePlate ?? 'N/A'})',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  ),
                ],
              ),
            if (booking.vehicleName != null || booking.licensePlate != null) const SizedBox(height: 8),

            // Thời gian
            Row(
              children: [
                Icon(Icons.access_time, size: 20, color: Theme.of(context).textTheme.bodySmall?.color),
                const SizedBox(width: 8),
                Text(
                  dateFormat.format(booking.startTime.toLocal()),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    booking.durationDisplay,
                    style: const TextStyle(
                      color: AppTheme.accentBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Slot
            if (booking.slotName != null)
              Row(
                children: [
                  Icon(Icons.local_parking, size: 20, color: Theme.of(context).textTheme.bodySmall?.color),
                  const SizedBox(width: 8),
                  Text(
                    'Vị trí đỗ: ${booking.slotName}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

            // Ticket number
            if (booking.ticketNumber != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.confirmation_number, size: 20, color: Theme.of(context).textTheme.bodySmall?.color),
                  const SizedBox(width: 8),
                  Text(
                    booking.ticketNumber!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),

            // Footer: Giá + Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isActive ? price : 'Tổng: $price',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                if (isActive)
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => _cancelBooking(booking),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: const Size(0, 34),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Hủy', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'expired':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
