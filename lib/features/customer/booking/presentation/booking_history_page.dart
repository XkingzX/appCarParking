import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:baidoxe/core/theme.dart';

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({Key? key}) : super(key: key);

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Lịch sử đỗ xe'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: AppTheme.textLight,
          indicatorColor: AppTheme.primaryBlue,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Đang đỗ'),
            Tab(text: 'Lịch sử'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab: Đang đỗ
          _buildCurrentParkingTab(),
          
          // Tab: Lịch sử hoàn thành
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildCurrentParkingTab() {
    // TODO: Fetch real data from Supabase
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBookingCard(
          context,
          parkingName: 'Bãi xe ô tô ĐH Thủ Dầu Một',
          slotName: 'A12',
          vehicleName: 'Honda City',
          licensePlate: '61A-123.45',
          startTime: '14:30 - Hôm nay',
          status: 'Đang đỗ',
          statusColor: Colors.blue,
          price: '20.000đ/giờ',
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    // TODO: Fetch real data from Supabase
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBookingCard(
          context,
          parkingName: 'GO! Di An Parking Lot',
          slotName: 'C05',
          vehicleName: 'Honda City',
          licensePlate: '61A-123.45',
          startTime: '09:00 - 12/05/2026',
          status: 'Hoàn thành',
          statusColor: Colors.green,
          price: 'Tổng: 60.000đ',
        ),
        _buildBookingCard(
          context,
          parkingName: 'Bãi xe trung tâm Bình Dương',
          slotName: 'B02',
          vehicleName: 'Honda City',
          licensePlate: '61A-123.45',
          startTime: '19:00 - 10/05/2026',
          status: 'Hoàn thành',
          statusColor: Colors.green,
          price: 'Tổng: 40.000đ',
        ),
      ],
    );
  }

  Widget _buildBookingCard(
    BuildContext context, {
    required String parkingName,
    required String slotName,
    required String vehicleName,
    required String licensePlate,
    required String startTime,
    required String status,
    required Color statusColor,
    required String price,
  }) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    parkingName,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.onSurface),
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
                    status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.directions_car, size: 20, color: Theme.of(context).textTheme.bodySmall?.color),
                const SizedBox(width: 8),
                Text('$vehicleName ($licensePlate)', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 20, color: Theme.of(context).textTheme.bodySmall?.color),
                const SizedBox(width: 8),
                Text(startTime, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.local_parking, size: 20, color: Theme.of(context).textTheme.bodySmall?.color),
                const SizedBox(width: 8),
                Text('Vị trí đỗ: $slotName', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  price,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).primaryColor),
                ),
                if (status == 'Đang đỗ')
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Navigate to ticket or payment
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: const Size(0, 36),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    child: const Text('Xem vé'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
