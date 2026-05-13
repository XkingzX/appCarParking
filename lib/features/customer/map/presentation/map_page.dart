import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  List<Map<String, dynamic>> _parkingLots = [];

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
      // POSITION MOCK (VŨNG TÀU) - Theo yêu cầu
      debugPrint("--- DEBUG: Bỏ qua GPS thực tế, dùng tọa độ giả lập ---");
      Position position = Position(
        longitude: 107.10081371406169, 
        latitude: 10.377059864546746, 
        timestamp: DateTime.now(), 
        accuracy: 1, 
        altitude: 1, 
        heading: 1, 
        speed: 1, 
        speedAccuracy: 1,
        altitudeAccuracy: 1,
        headingAccuracy: 1,
      );
      
      debugPrint("--- DEBUG: Đã lấy được vị trí người dùng. Vĩ độ: ${position.latitude}, Kinh độ: ${position.longitude} ---");
      
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
        _mapController.move(_currentPosition!, 15.0);
        _fetchNearbyParkingLots();
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoadingLocation = false; });
      }
    }
  }

  Future<void> _fetchNearbyParkingLots() async {
    if (_currentPosition == null) return;
    try {
      final response = await Supabase.instance.client.rpc(
        'get_nearby_parking_lots',
        params: {
          'user_lat': _currentPosition!.latitude,
          'user_lon': _currentPosition!.longitude,
          'max_distance_meters': 10000,
          'limit_count': 20,
        },
      );
      if (mounted && response != null) {
        setState(() {
          _parkingLots = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint('Lỗi fetch bãi đỗ từ Supabase: $e');
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
                  ..._parkingLots.map((lot) => Marker(
                        point: LatLng(lot['latitude'], lot['longitude']),
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
              child: Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  // Lọc bãi đỗ từ danh sách hiện tại
                  final suggestions = _parkingLots
                      .map((lot) => lot['name'] as String?)
                      .where((name) => name != null)
                      .cast<String>()
                      .where((name) => name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  
                  // Các gợi ý mặc định phổ biến
                  final defaultSuggestions = [
                    'Lotte Mart Vũng Tàu', 
                    'Đại học Thủ Dầu Một', 
                    'Bãi xe trung tâm Bình Dương',
                    'GO! Dĩ An'
                  ].where((name) => name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  
                  return {...suggestions, ...defaultSuggestions}.toList(); // Dùng Set để loại bỏ trùng lặp
                },
                onSelected: (String selection) {
                  debugPrint("--- DEBUG: Người dùng chọn: '$selection' ---");
                  try {
                    final lot = _parkingLots.firstWhere((lot) => lot['name'] == selection);
                    _mapController.move(LatLng(lot['latitude'], lot['longitude']), 16.0);
                  } catch (e) {
                    debugPrint("Không tìm thấy bãi đỗ này trong danh sách hiện tại");
                  }
                },
                fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    onSubmitted: (String value) {
                      onFieldSubmitted();
                    },
                    decoration: const InputDecoration(
                      hintText: 'Tìm bãi đỗ xe... (VD: Lotte Mart)',
                      icon: Icon(Icons.search),
                      border: InputBorder.none,
                    ),
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Container(
                        width: MediaQuery.of(context).size.width - 32, // Khớp với kích thước thanh tìm kiếm
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final String option = options.elementAt(index);
                            return ListTile(
                              leading: const Icon(Icons.location_on, color: Colors.blue),
                              title: Text(option),
                              onTap: () {
                                onSelected(option);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
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
                itemCount: _parkingLots.length,
                itemBuilder: (context, index) {
                  final lot = _parkingLots[index];
                  // Distance is returned by the RPC
                  final distance = lot['distance_meters'] != null 
                      ? (lot['distance_meters'] as num).toDouble() / 1000 
                      : 0.0;
                  
                  return GestureDetector(
                    onTap: () {
                      Get.to(() => ParkingDetailPage(parkingLot: lot));
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
                                    lot['name'] ?? 'Chưa có tên',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 18),
                                    Text(' ${lot['avg_rating'] ?? 0}'),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            
                            // Dòng 2: Nội dung mô tả ngắn
                            Text(
                              lot['location'] ?? 'Không có địa chỉ',
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
                                    const Text('Xem chi tiết', style: TextStyle(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const Text(
                                  'Từ 10.000đ', 
                                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15)
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
