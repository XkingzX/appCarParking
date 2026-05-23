import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:baidoxe/core/theme.dart';
import '../controllers/saved_places_controller.dart';
import '../../booking/presentation/parking_detail_page.dart';

class FavoritePage extends StatelessWidget {
  const FavoritePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = SavedPlacesController.to;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Yêu thích ❤️'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Obx(() {
        if (controller.favoritePlaces.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text('Chưa có bãi đỗ yêu thích nào', style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.82,
          ),
          itemCount: controller.favoritePlaces.length,
          itemBuilder: (context, index) {
            final item = controller.favoritePlaces[index];
            final lot = item['parking_lot'];
            
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

            return GestureDetector(
              onTap: () {
                Get.to(() => ParkingDetailPage(parkingLot: lot));
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail
                    Stack(
                      children: [
                        Image.network(
                          'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?q=80&w=1000&auto=format&fit=crop',
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              controller.removeFavorite(lot['id'].toString());
                            },
                            child: CircleAvatar(
                              backgroundColor: Colors.white.withOpacity(0.9),
                              radius: 16,
                              child: const Icon(Icons.favorite, color: Colors.pink, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lot['name'] ?? 'Bãi xe',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 14),
                                Text(' ${lot['avg_rating'] ?? '5.0'} • ', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                                Text(distanceStr, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('Đã ghé ${item['visit_count']} lần', style: TextStyle(fontSize: 12, color: isDark ? Colors.blue.shade300 : AppTheme.accentBlue, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
