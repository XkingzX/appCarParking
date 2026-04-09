import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../booking/presentation/parking_detail_page.dart';

class CustomerMapPage extends StatefulWidget {
  const CustomerMapPage({Key? key}) : super(key: key);

  @override
  State<CustomerMapPage> createState() => _CustomerMapPageState();
}

class _CustomerMapPageState extends State<CustomerMapPage> {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  bool _isLoadingLocation = true;

  final List<Map<String, dynamic>> _mockParkingLots = [
    {
      'name': 'Lawnfield Parks',
      'description': '3891 Ranchview Dr. Richardson, California 62639',
      'lat': 10.7769,
      'lng': 106.7009,
      'slots': 5,
      'price': '\$6.00/hour',
      'rating': 5.0,
    },
    {
      'name': 'Vincom Center Parking',
      'description': 'Bãi đỗ xe trong nhà tầng hầm, an ninh 24/7',
      'lat': 10.7780,
      'lng': 106.7020,
      'slots': 12,
      'price': '30.000đ/giờ',
      'rating': 4.8,
    },
  ];

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    debugPrint("--- DEBUG: Bắt đầu quá trình tải vị trí ---");
    bool serviceEnabled;
    LocationPermission permission;

    // Kiem tra service GPS
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() { _isLoadingLocation = false; });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() { _isLoadingLocation = false; });
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) setState(() { _isLoadingLocation = false; });
      return;
    } 

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      
      debugPrint("--- DEBUG: Đã lấy được vị trí người dùng. Vĩ độ: ${position.latitude}, Kinh độ: ${position.longitude} ---");
      
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
        _mapController.move(_currentPosition!, 15.0);
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoadingLocation = false; });
      }
    }
  }

  double _calculateDistance(double lat, double lng) {
    if (_currentPosition == null) return 0.0;
    return Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          lat,
          lng,
        ) /
        1000;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Bản đồ OpenStreetMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition ?? const LatLng(10.7769, 106.7009),
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.baidoxe',
              ),
              MarkerLayer(
                markers: [
                  if (_currentPosition != null)
                    Marker(
                      point: _currentPosition!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                    ),
                  ..._mockParkingLots.map((lot) => Marker(
                        point: LatLng(lot['lat'], lot['lng']),
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                      )),
                ],
              ),
            ],
          ),

          // Thanh tìm kiếm
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
                ],
              ),
              child: TextField(
                onSubmitted: (value) {
                  debugPrint("--- DEBUG: Người dùng tìm kiếm: '$value' ---");
                  // Map search -> coordinate simulation
                  debugPrint("--- DEBUG: Tọa độ giả định cho '$value': Vĩ độ 10.7760, Kinh độ 106.7000 ---");
                },
                decoration: const InputDecoration(
                  hintText: 'Tìm bãi đỗ xe...',
                  icon: Icon(Icons.search),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          // Loading overlay
          if (_isLoadingLocation)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),

          // Danh sách các bãi đỗ xe hiển thị theo dạng card ngang, ẩn nút mua hiển thị clickable nguyên khối
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 180,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _mockParkingLots.length,
                itemBuilder: (context, index) {
                  final lot = _mockParkingLots[index];
                  final distance = _calculateDistance(lot['lat'], lot['lng']);
                  
                  return GestureDetector(
                    onTap: () {
                      Get.to(() => const ParkingDetailPage());
                    },
                    child: Card(
                      margin: const EdgeInsets.only(right: 16),
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Container(
                        width: 300,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Dòng 1: Tên và Đánh giá
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    lot['name'],
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 18),
                                    Text(' ${lot['rating']}'),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            
                            // Dòng 2: Nội dung mô tả ngắn
                            Text(
                              lot['description'],
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            
                            // Dòng 3: Số slot - Giá tiền
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.directions_car, size: 18, color: Colors.blue[700]),
                                    const SizedBox(width: 4),
                                    Text('${lot['slots']} Slot', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                Text(
                                  lot['price'], 
                                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15)
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 6),
                            const Divider(height: 1),
                            const SizedBox(height: 6),

                            // Dòng 4: Khoảng cách từ vị trí người dùng
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.route, size: 18, color: Colors.orange),
                                    const SizedBox(width: 4),
                                    Text(
                                      _currentPosition != null 
                                      ? '${distance.toStringAsFixed(1)} km từ vị trí của bạn'
                                      : 'Đang tải vị trí...', 
                                      style: const TextStyle(color: Colors.blueGrey, fontSize: 13)
                                    ),
                                  ],
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Nút di chuyển vị trí về lại người dùng (Location FAB)
          if (_currentPosition != null)
            Positioned(
              bottom: 210,
              right: 16,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                child: const Icon(Icons.my_location, color: Colors.blue),
                onPressed: () {
                  _mapController.move(_currentPosition!, 15.0);
                },
              ),
            ),
        ],
      ),
    );
  }
}
