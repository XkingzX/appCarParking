import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../../booking/presentation/parking_detail_page.dart';

class CustomerMapPage extends StatefulWidget {
  const CustomerMapPage({Key? key}) : super(key: key);

  @override
  State<CustomerMapPage> createState() => _CustomerMapPageState();
}

class _CustomerMapPageState extends State<CustomerMapPage> {
  final MapController _mapController = MapController();

  LatLng? _currentPosition; // Vị trí thật của người dùng
  LatLng? _searchedPosition; // Vị trí người dùng vừa search

  bool _isLoadingLocation = true;
  List<Map<String, dynamic>> _parkingLots = [];
  int _searchRequestId = 0;
  List<LatLng> _routePoints = [];
  bool _isDirectionsMode = false;
  Map<String, dynamic>? _destinationLot;
  String _originType = 'current';
  bool _showOriginDropdown = false;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    debugPrint("--- DEBUG: Bắt đầu quá trình tải vị trí ---");
    bool serviceEnabled;
    LocationPermission permission;

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
      // 1. TỐI ƯU DATA: Thử lấy vị trí cache cuối cùng trước cho nhanh
      Position? position = await Geolocator.getLastKnownPosition();

      // 2. Nếu không có cache, mới request vị trí hiện tại (sẽ mất vài giây)
      position ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      
      // MOCK POSITION (VŨNG TÀU) - Comment lại để dùng GPS thật

      position = Position(
        longitude: 107.10081371406169,
        latitude: 10.377059864546746,
        timestamp: DateTime.now(),
        accuracy: 1, altitude: 1, heading: 1, speed: 1, speedAccuracy: 1,
        altitudeAccuracy: 1, headingAccuracy: 1,
      );

      

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position!.latitude, position.longitude);
          _isLoadingLocation = false;
        });
        _mapController.move(_currentPosition!, 15.0);

        // Fetch bãi đỗ xung quanh vị trí thật
        _fetchNearbyParkingLots(_currentPosition!.latitude, _currentPosition!.longitude);
      }
    } catch (e) {
      debugPrint("Lỗi lấy GPS: $e");
      if (mounted) {
        setState(() { _isLoadingLocation = false; });
      }
    }
  }

  Future<void> _fetchNearbyParkingLots(double lat, double lng) async {
    setState(() {
      _routePoints.clear();
      _isDirectionsMode = false;
      _destinationLot = null;
    });
    try {
      final response = await Supabase.instance.client.rpc(
        'get_nearby_parking_lots',
        params: {
          'user_lat': lat,
          'user_lon': lng,
          'max_distance_meters': 20000, // 20km
          'limit_count': 20,
        },
      );

      if (mounted && response != null) {
        setState(() {
          _parkingLots = List<Map<String, dynamic>>.from(response);
        });

        // XỬ LÝ LOGIC: NẾU KHÔNG CÓ BÃI ĐỖ SAU KHI SEARCH
        if (_parkingLots.isEmpty && _searchedPosition != null) {
          Get.snackbar(
            'Thông báo',
            'Không tồn tại bãi đỗ xe nào trong phạm vi 20km quanh đây.',
            backgroundColor: Colors.redAccent,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
            snackPosition: SnackPosition.TOP,
          );
        }
      }
    } catch (e) {
      debugPrint('Lỗi fetch bãi đỗ từ Supabase: $e');
    }
  }

  Future<Iterable<Map<String, dynamic>>> _debouncedSearch(String query) async {
    debugPrint("=== SEARCH START: Đang gõ: '$query' ===");
    if (query.isEmpty) return const Iterable<Map<String, dynamic>>.empty();

    final int requestId = ++_searchRequestId;
    
    // Giảm debounce xuống 400ms để tìm kiếm nhạy bén hơn giống Google Maps
    await Future.delayed(const Duration(milliseconds: 400));
    
    if (requestId != _searchRequestId || !mounted) {
      debugPrint("=== SEARCH CANCELED: Bỏ qua '$query' vì có text mới ===");
      return const Iterable<Map<String, dynamic>>.empty();
    }
    
    debugPrint("=== SEARCH TRIGGER: Gọi API Nominatim cho: '$query' ===");
    return await _searchPlaces(query);
  }

  // GỌI API PHOTON (OSM) ĐỂ GỢI Ý ĐỊA ĐIỂM THÔNG MINH HƠN
  Future<List<Map<String, dynamic>>> _searchPlaces(String query) async {
    if (query.isEmpty) return [];

    try {
      final queryParams = {
        'q': query,
        'limit': '5',
        // Bounding box bao trọn lãnh thổ Việt Nam (Tây, Nam, Đông, Bắc)
        // Giúp Photon tìm kiếm trên toàn quốc mà không bị dính vào 1 tỉnh cụ thể
        'bbox': '102.14,8.18,109.46,23.39',
      };

      final url = Uri.https('photon.komoot.io', '/api', queryParams);

      debugPrint("=== API REQUEST: Đang gọi URL: $url ===");

      // Cần phải có User-Agent, nếu không các API Public sẽ trả về 403 Forbidden
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'BaidoxeApp/1.0 (Android/Flutter)',
          'Accept-Language': 'vi-VN,vi;q=0.9',
        }
      ).timeout(const Duration(seconds: 10));

      debugPrint("=== API RESPONSE STATUS: ${response.statusCode} ===");

      if (response.statusCode == 200) {
        // Photon trả về định dạng GeoJSON
        final Map<String, dynamic> data = json.decode(response.body);
        final List features = data['features'] ?? [];
        debugPrint("=== API KẾT QUẢ: Tìm thấy ${features.length} địa điểm ===");

        return features.map((e) {
          final properties = e['properties'];
          final geometry = e['geometry'];
          final coords = geometry['coordinates']; // [lon, lat]

          final name = properties['name'] ?? '';
          final city = properties['city'] ?? properties['state'] ?? '';
          final street = properties['street'] ?? '';
          
          String displayName = name;
          if (street.isNotEmpty && street != name) displayName += ', $street';
          if (city.isNotEmpty && city != name) displayName += ', $city';
          if (displayName.isEmpty) displayName = 'Địa điểm không xác định';

          return {
            'display_name': displayName,
            'lat': (coords[1] as num).toDouble(), // lat
            'lon': (coords[0] as num).toDouble(), // lon
          };
        }).toList();
      } else {
        debugPrint("=== API RESPONSE LỖI BODY: ${response.body} ===");
      }
    } catch (e) {
      debugPrint("=== API LỖI EXCEPTION: $e ===");
    }

    return [];
  }

  double _calculateDistance(double lat, double lng) {
    if (_currentPosition == null) return 0.0;
    return Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          lat,
          lng,
        ) / 1000;
  }

  Future<void> _drawRouteTo(Map<String, dynamic> destination) async {
    _destinationLot = destination;
    final startLatLng = _originType == 'searched' && _searchedPosition != null 
        ? _searchedPosition 
        : _currentPosition;
        
    final startLat = startLatLng?.latitude;
    final startLon = startLatLng?.longitude;
    final destLat = destination['latitude'];
    final destLon = destination['longitude'];

    if (startLat == null || startLon == null || destLat == null || destLon == null) return;

    final url = Uri.parse('http://router.project-osrm.org/route/v1/driving/$startLon,$startLat;$destLon,$destLat?geometries=geojson');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'];
        if (routes != null && routes.isNotEmpty) {
          final geometry = routes[0]['geometry'];
          final coordinates = geometry['coordinates'] as List;
          
          if (mounted) {
            setState(() {
              _routePoints = coordinates.map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();
            });
          }
        }
      } else {
        Get.snackbar('Lỗi', 'Không thể tải đường đi từ hệ thống', snackPosition: SnackPosition.TOP);
      }
    } catch (e) {
      debugPrint('Error routing: $e');
      Get.snackbar('Lỗi', 'Không thể lấy dữ liệu chỉ đường', snackPosition: SnackPosition.TOP);
    }
  }

  Widget _buildDirectionsPanel() {
    return Container(
      key: const ValueKey('DirectionsPanel'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  setState(() {
                    _isDirectionsMode = false;
                  });
                },
              ),
              const Expanded(
                child: Text(
                  'Chỉ đường lái xe',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Column(
                children: [
                  const Icon(Icons.radio_button_checked, color: Colors.blue, size: 20),
                  Container(height: 24, width: 2, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(vertical: 4)),
                  const Icon(Icons.location_on, color: Colors.red, size: 24),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_searchedPosition != null && _currentPosition != null) {
                          setState(() {
                            _showOriginDropdown = !_showOriginDropdown;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: (_searchedPosition != null && _currentPosition != null) 
                              ? Colors.white 
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (_searchedPosition != null && _currentPosition != null)
                                ? Colors.blue.shade300
                                : Colors.grey.shade300,
                            width: (_searchedPosition != null && _currentPosition != null) ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _originType == 'current' ? 'Vị trí hiện tại của bạn' : 'Điểm vừa tìm kiếm',
                                style: const TextStyle(fontSize: 15, color: Colors.black87),
                              ),
                            ),
                            if (_searchedPosition != null && _currentPosition != null)
                              Icon(_showOriginDropdown ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: _showOriginDropdown
                          ? Container(
                              margin: const EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                                ],
                              ),
                              child: Column(
                                children: [
                                  ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.my_location, color: Colors.blue),
                                    title: const Text('Vị trí hiện tại', style: TextStyle(fontSize: 14)),
                                    onTap: () {
                                      setState(() {
                                        _originType = 'current';
                                        _showOriginDropdown = false;
                                      });
                                      if (_destinationLot != null) _drawRouteTo(_destinationLot!);
                                    },
                                  ),
                                  const Divider(height: 1),
                                  ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.place, color: Colors.green),
                                    title: const Text('Điểm đang tìm kiếm', style: TextStyle(fontSize: 14)),
                                    onTap: () {
                                      setState(() {
                                        _originType = 'searched';
                                        _showOriginDropdown = false;
                                      });
                                      if (_destinationLot != null) _drawRouteTo(_destinationLot!);
                                    },
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        _destinationLot?['name'] ?? 'Bãi đỗ xe',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
                  // 1. Marker GPS thật của tôi (Màu Xanh Dương)
                  if (_currentPosition != null)
                    Marker(
                      point: _currentPosition!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                    ),

                  // 2. Marker điểm vừa Search (Màu Xanh Lá Cây - Cắm cờ)
                  if (_searchedPosition != null)
                     Marker(
                      point: _searchedPosition!,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.tour, color: Colors.green, size: 40),
                    ),

                  // 3. Markers Bãi đỗ xe (Màu Đỏ)
                  ..._parkingLots.map((lot) => Marker(
                        point: LatLng(lot['latitude'], lot['longitude']),
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                      )),
                ],
              ),
              PolylineLayer(
                polylines: [
                  if (_routePoints.isNotEmpty)
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 6.0,
                      color: Colors.blueAccent,
                    ),
                ],
              ),
            ],
          ),

          // Thanh tìm kiếm Autocomplete (Async với API)
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1.0,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: _isDirectionsMode
                  ? _buildDirectionsPanel()
                  : Container(
                      key: const ValueKey('SearchBar'),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
                        ],
                      ),
                      child: Autocomplete<Map<String, dynamic>>(
                        optionsBuilder: (TextEditingValue textEditingValue) async {
                          return await _debouncedSearch(textEditingValue.text);
                        },
                        displayStringForOption: (option) => option['display_name'],
                        onSelected: (Map<String, dynamic> selection) {
                          FocusScope.of(context).unfocus(); // Đóng bàn phím

                          final lat = selection['lat'];
                          final lon = selection['lon'];
                          final newPos = LatLng(lat, lon);

                          setState(() {
                            _searchedPosition = newPos;
                            _originType = 'searched'; // Mặc định chuyển sang searched
                          });

                          // Chuyển map đến vị trí search, zoom out để thấy bán kính 20km
                          _mapController.move(newPos, 12.0);

                          // Lấy bãi đỗ xe XUNG QUANH điểm vừa search
                          _fetchNearbyParkingLots(lat, lon);
                        },
                        fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                          return TextField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            onSubmitted: (String value) {
                              onFieldSubmitted();
                            },
                            decoration: InputDecoration(
                              hintText: 'Tìm địa điểm... (VD: Hà Nội)',
                              prefixIcon: IconButton(
                                icon: const Icon(Icons.search),
                                onPressed: () {
                                  onFieldSubmitted();
                                },
                              ),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_routePoints.isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.menu, color: Colors.blue),
                                      onPressed: () {
                                        setState(() {
                                          _isDirectionsMode = true;
                                        });
                                      },
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      textEditingController.clear();
                                    },
                                  ),
                                ],
                              ),
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
                                width: MediaQuery.of(context).size.width - 32,
                                constraints: const BoxConstraints(maxHeight: 250),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    final option = options.elementAt(index);
                                    return ListTile(
                                      leading: const Icon(Icons.place, color: Colors.green),
                                      title: Text(option['display_name'], maxLines: 2, overflow: TextOverflow.ellipsis),
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

          // Danh sách các bãi đỗ xe (Chỉ hiện khi có dữ liệu)
          if (_parkingLots.isNotEmpty)
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
                    final distance = lot['distance_meters'] != null
                        ? (lot['distance_meters'] as num).toDouble() / 1000
                        : 0.0;

                    return GestureDetector(
                      onTap: () async {
                        final result = await Get.to(() => ParkingDetailPage(
                          parkingLot: lot,
                          userPosition: _searchedPosition ?? _currentPosition,
                        ));
                        if (result != null && result['action'] == 'route') {
                          _drawRouteTo(result['destination']);
                        }
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
                              Text(
                                lot['location'] ?? 'Không có địa chỉ',
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
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
                                    'Từ 20.000đ',
                                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15)
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Divider(height: 1),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.route, size: 18, color: Colors.orange),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${distance.toStringAsFixed(1)} km từ vị trí đang xem',
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

          // Nút về lại vị trí GPS thật
          if (_currentPosition != null)
            Positioned(
              bottom: _parkingLots.isNotEmpty ? 210 : 30, // Điều chỉnh nếu list bãi xe rỗng
              right: 16,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                child: const Icon(Icons.my_location, color: Colors.blue),
                onPressed: () {
                  setState(() {
                    _searchedPosition = null;
                  });
                  _mapController.move(_currentPosition!, 15.0);
                  _fetchNearbyParkingLots(_currentPosition!.latitude, _currentPosition!.longitude);
                },
              ),
            ),
        ],
      ),
    );
  }
}
