import 'dart:async';
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
  Timer? _debounce;

  LatLng? _currentPosition; // Vị trí thật của người dùng
  LatLng? _searchedPosition; // Vị trí người dùng vừa search

  bool _isLoadingLocation = true;
  List<Map<String, dynamic>> _parkingLots = [];

  List<Map<String, dynamic>> get _displayedLots {
    final lots = _parkingLots.where((lot) {
      final dist = lot['exact_distance_km'] ?? 999.0;
      bool isVisible = false;
      try {
        final bounds = _mapController.camera.visibleBounds;
        final lat = lot['latitude'];
        final lon = lot['longitude'];
        if (lat != null && lon != null) {
          isVisible = bounds.contains(LatLng(lat, lon));
        }
      } catch (e) {
        // Bản đồ chưa khởi tạo xong
      }
      return dist <= 20.0 || isVisible;
    }).toList();
    lots.sort((a, b) => (a['exact_distance_km'] ?? 999.0).compareTo(b['exact_distance_km'] ?? 999.0));
    return lots;
  }
  int _searchRequestId = 0;
  List<LatLng> _routePoints = [];
  bool _isDirectionsMode = false;
  Map<String, dynamic>? _destinationLot;
  String _originType = 'current';
  bool _showOriginDropdown = false;
  double? _routeDistanceKm;
  int? _routeDurationMin;

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

        // Lấy toàn bộ bãi đỗ trong bán kính 20km ngay khi mở app
        _fetchInitialParkingLots(_currentPosition!.latitude, _currentPosition!.longitude);
      }
    } catch (e) {
      debugPrint("Lỗi lấy GPS: $e");
      if (mounted) {
        setState(() { _isLoadingLocation = false; });
      }
    }
  }

  void _onMapPositionChanged(MapCamera camera, bool hasGesture) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _loadParkingLotsInBounds(camera.visibleBounds);
      }
    });
  }

  Future<void> _loadParkingLotsInBounds(LatLngBounds bounds) async {
    try {
      final response = await Supabase.instance.client
          .from('parking_lots')
          .select()
          .gte('latitude', bounds.south)
          .lte('latitude', bounds.north)
          .gte('longitude', bounds.west)
          .lte('longitude', bounds.east)
          .limit(50); // Giới hạn 50 bãi đỗ mỗi lần fetch để tối ưu

      if (mounted && response != null) {
        final List<Map<String, dynamic>> newLots = List<Map<String, dynamic>>.from(response);
        
        setState(() {
          // Lưu trữ tích lũy (Upsert) để bãi đỗ không bị biến mất khi vuốt sang chỗ khác
          for (var lot in newLots) {
            final id = lot['id'];
            final index = _parkingLots.indexWhere((element) => element['id'] == id);
            if (index == -1) {
              _parkingLots.add(lot);
            }
          }
        });
        
        _updateDistancesLocally();
      }
    } catch (e) {
      debugPrint('Lỗi fetch bãi đỗ từ Supabase (Bounding Box): $e');
    }
  }

  Future<void> _fetchInitialParkingLots(double lat, double lng) async {
    try {
      final response = await Supabase.instance.client.rpc(
        'get_nearby_parking_lots',
        params: {
          'user_lat': lat,
          'user_lon': lng,
          'max_distance_meters': 20000,
          'limit_count': 50,
        },
      );
      if (mounted && response != null) {
        final List<Map<String, dynamic>> newLots = List<Map<String, dynamic>>.from(response);
        setState(() {
          for (var lot in newLots) {
            final id = lot['id'];
            if (!_parkingLots.any((e) => e['id'] == id)) {
              _parkingLots.add(lot);
            }
          }
        });
        _updateDistancesLocally();
      }
    } catch (e) {
      debugPrint('Lỗi fetch bãi đỗ ban đầu: $e');
    }
  }

  // Dùng để cảnh báo nếu vùng search hoàn toàn trống rỗng
  Future<void> _checkNearbyAfterSearch(LatLng searchPos) async {
    try {
      final response = await Supabase.instance.client.rpc(
        'get_nearby_parking_lots',
        params: {
          'user_lat': searchPos.latitude,
          'user_lon': searchPos.longitude,
          'max_distance_meters': 20000,
          'limit_count': 1,
        },
      );
      if (mounted && (response == null || (response as List).isEmpty)) {
        Get.snackbar(
          'Thông báo',
          'Không tồn tại bãi đỗ xe nào trong phạm vi 20km quanh đây.',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      debugPrint('Lỗi check nearby: $e');
    }
  }

  void _updateDistancesLocally() {
    final startLatLng = _originType == 'searched' && _searchedPosition != null 
        ? _searchedPosition 
        : _currentPosition;
    
    if (startLatLng == null) return;

    setState(() {
      for (int i = 0; i < _parkingLots.length; i++) {
        final lot = _parkingLots[i];
        final destLat = lot['latitude'];
        final destLon = lot['longitude'];
        if (destLat == null || destLon == null) continue;

        // Tính khoảng cách tức thời không cần gọi HTTP để tránh spam
        final distanceMeters = const Distance().as(
          LengthUnit.Meter,
          startLatLng,
          LatLng(destLat, destLon),
        );
        
        _parkingLots[i] = {
          ...lot,
          'exact_distance_km': distanceMeters / 1000.0,
        };
      }
    });
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

  // GỌI API NOMINATIM ĐỂ GỢI Ý ĐỊA ĐIỂM CHÍNH XÁC HƠN Ở VIỆT NAM
  Future<List<Map<String, dynamic>>> _searchPlaces(String query) async {
    if (query.isEmpty) return [];

    try {
      final queryParams = {
        'q': '$query, Việt Nam',
        'format': 'json',
        'limit': '5',
        'countrycodes': 'vn',
        'addressdetails': '1',
      };

      final url = Uri.https('nominatim.openstreetmap.org', '/search', queryParams);

      debugPrint("=== API REQUEST: Đang gọi URL: $url ===");

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'BaidoxeApp/1.0 (Android/Flutter)',
          'Accept-Language': 'vi-VN,vi;q=0.9',
        }
      ).timeout(const Duration(seconds: 10));

      debugPrint("=== API RESPONSE STATUS: ${response.statusCode} ===");

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        debugPrint("=== API KẾT QUẢ: Tìm thấy ${data.length} địa điểm ===");

        return data.map((e) {
          return {
            'display_name': e['display_name'] ?? 'Địa điểm không xác định',
            'lat': double.tryParse(e['lat']?.toString() ?? '0') ?? 0.0,
            'lon': double.tryParse(e['lon']?.toString() ?? '0') ?? 0.0,
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
          
          final distanceMeters = routes[0]['distance'] as num?;
          final durationSeconds = routes[0]['duration'] as num?;
          
          if (mounted) {
            setState(() {
              _routePoints = coordinates.map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();
              if (distanceMeters != null) {
                _routeDistanceKm = distanceMeters.toDouble() / 1000.0;
              }
              if (durationSeconds != null) {
                _routeDurationMin = (durationSeconds.toDouble() / 60.0).round();
              }
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.1), blurRadius: 10, offset: const Offset(0, 5)),
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
                              ? Theme.of(context).cardColor 
                              : (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (_searchedPosition != null && _currentPosition != null)
                                ? Colors.blue.shade300
                                : Colors.grey.withOpacity(0.3),
                            width: (_searchedPosition != null && _currentPosition != null) ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _originType == 'current' ? 'Vị trí hiện tại của bạn' : 'Điểm vừa tìm kiếm',
                                style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurface),
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
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
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
                                      _updateDistancesLocally();
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
                                      _updateDistancesLocally();
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
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: Text(
                        _destinationLot?['name'] ?? 'Bãi đỗ xe',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
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
              onPositionChanged: _onMapPositionChanged,
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
                  ..._displayedLots.map((lot) => Marker(
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
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.1), blurRadius: 10, offset: const Offset(0, 5)),
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

                          setState(() {
                            _routePoints.clear();
                            _isDirectionsMode = false;
                            _destinationLot = null;
                            _routeDistanceKm = null;
                            _routeDurationMin = null;
                          });

                          // Kiểm tra và hiển thị thông báo 20km nếu không có bãi đỗ
                          _checkNearbyAfterSearch(newPos);
                          
                          // Lấy trước bãi đỗ trong 20km quanh điểm search
                          _fetchInitialParkingLots(lat, lon);

                          // Chuyển map đến vị trí search, map sẽ tự động gọi onPositionChanged để fetch dữ liệu
                          _mapController.move(newPos, 14.0);
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
                                onPressed: () async {
                                  FocusScope.of(context).unfocus();
                                  final text = textEditingController.text;
                                  if (text.isNotEmpty) {
                                    final results = await _searchPlaces(text);
                                    if (results.isNotEmpty) {
                                      final selection = results.first;
                                      final lat = selection['lat'];
                                      final lon = selection['lon'];
                                      final newPos = LatLng(lat, lon);

                                      setState(() {
                                        _searchedPosition = newPos;
                                        _originType = 'searched';
                                        _routePoints.clear();
                                        _isDirectionsMode = false;
                                        _destinationLot = null;
                                        _routeDistanceKm = null;
                                        _routeDurationMin = null;
                                      });

                                      _checkNearbyAfterSearch(newPos);
                                      _fetchInitialParkingLots(lat, lon);
                                      _mapController.move(newPos, 14.0);
                                    }
                                  }
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
                              color: Theme.of(context).cardColor,
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
          if (_displayedLots.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 180,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _displayedLots.length,
                  itemBuilder: (context, index) {
                    final lot = _displayedLots[index];
                    final distance = lot['exact_distance_km'] ?? (lot['distance_meters'] != null
                        ? (lot['distance_meters'] as num).toDouble() / 1000
                        : 0.0);
                    final originText = _originType == 'current' ? 'từ vị trí của bạn' : 'từ điểm đang xem';

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
                        color: Theme.of(context).cardColor,
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
                                        '${distance.toStringAsFixed(1)} km $originText',
                                        style: TextStyle(
                                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.blueGrey, 
                                          fontSize: 13
                                        )
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
                  _mapController.move(_currentPosition!, 15.0);
                },
              ),
            ),
        ],
      ),
    );
  }
}
