import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:baidoxe/core/theme.dart';
import '../controllers/saved_places_controller.dart';
import '../../booking/presentation/parking_detail_page.dart';
import 'package:timeago/timeago.dart' as timeago;

class SavedPlacesPage extends StatelessWidget {
  const SavedPlacesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = SavedPlacesController.to;
    timeago.setLocaleMessages('vi', timeago.ViMessages());

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Đã lưu 🔖'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Obx(() {
        if (controller.savedPlaces.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bookmark_border, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text('Chưa có bãi đỗ nào được lưu', style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: controller.savedPlaces.length,
          itemBuilder: (context, index) {
            final item = controller.savedPlaces[index];
            final lot = item['parking_lot'];
            final savedAt = DateTime.parse(item['saved_at']);
            final timeAgoStr = timeago.format(savedAt, locale: 'vi');
            
            String distanceStr = '';
            final distanceKm = lot['exact_distance_km'];
            if (distanceKm != null) {
              if (distanceKm < 1.0) {
                distanceStr = '${(distanceKm * 1000).toInt()}m';
              } else {
                distanceStr = '${(distanceKm as double).toStringAsFixed(1)}km';
              }
            } else {
              distanceStr = '---';
            }

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () {
                    Get.to(() => ParkingDetailPage(parkingLot: lot));
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.bookmark, color: isDark ? Colors.blue.shade300 : AppTheme.primaryBlue, size: 24),
                        ),
                        const SizedBox(width: 16),
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      lot['name'] ?? 'Bãi xe chưa có tên',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                                    onPressed: () {
                                      controller.removeSaved(lot['id'].toString());
                                    },
                                  )
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(distanceStr, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text('Lưu $timeAgoStr', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Folder Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('[${item['folder']}]', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.w600)),
                              ),
                              // Note
                              if (item['note'] != null && item['note'].toString().isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  '"${item['note']}"',
                                  style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontStyle: FontStyle.italic),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
