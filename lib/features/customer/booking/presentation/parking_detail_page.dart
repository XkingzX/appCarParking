import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:baidoxe/core/theme.dart';
import 'package:baidoxe/features/customer/account/controllers/saved_places_controller.dart';
import 'slot_selection_page.dart';

class ParkingDetailPage extends StatefulWidget {
  final Map<String, dynamic> parkingLot;
  final LatLng? userPosition;
  
  const ParkingDetailPage({Key? key, required this.parkingLot, this.userPosition}) : super(key: key);

  @override
  State<ParkingDetailPage> createState() => _ParkingDetailPageState();
}

class _ParkingDetailPageState extends State<ParkingDetailPage> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _selectedPricing;
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _durationKey = GlobalKey();
  bool _hasAutoScrolled = false;

  // Heart Animation
  late AnimationController _heartAnimController;
  late Animation<double> _heartScaleAnim;
  bool _showHeartAnimation = false;

  final List<String> _images = [
    'https://images.unsplash.com/photo-1573348722427-f1d6819fdf98?q=80&w=1000&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?q=80&w=1000&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?q=80&w=1000&auto=format&fit=crop',
  ];

  List<Map<String, dynamic>> _pricingList = [];
  bool _isLoadingPrices = true;

  // Duration selector state
  bool _isDurationPanelExpanded = false;
  String _selectedDurationType = 'Giờ';
  int _selectedHours = 1;
  DateTime _startDate = DateTime.now();
  int _basePrice = 20000;

  final List<String> _durationTypes = ['Giờ', 'Qua đêm', 'Cả ngày', 'Tuần', 'Tháng'];

  DateTime _calculateEndDate() {
    switch (_selectedDurationType) {
      case 'Cả ngày': return _startDate.add(const Duration(days: 1));
      case 'Tuần': return _startDate.add(const Duration(days: 7));
      case 'Tháng':
        int y = _startDate.year;
        int m = _startDate.month + 1;
        int d = _startDate.day;
        if (m > 12) { m = 1; y++; }
        int lastDay = DateTime(y, m + 1, 0).day;
        if (d > lastDay) d = lastDay;
        return DateTime(y, m, d, _startDate.hour, _startDate.minute);
      default: return _startDate;
    }
  }

  int _calculateTotalPrice() {
    switch (_selectedDurationType) {
      case 'Giờ': return _basePrice * _selectedHours;
      case 'Qua đêm': return _basePrice * 8;
      case 'Cả ngày': return _basePrice * 24;
      case 'Tuần': return _basePrice * 24 * 7;
      case 'Tháng': return _basePrice * 24 * 30;
      default: return _basePrice;
    }
  }

  String _formatPrice(int price) {
    final f = NumberFormat('#,###', 'vi_VN');
    return '${f.format(price)}đ';
  }

  void _confirmDuration() {
    setState(() {
      _selectedPricing = {
        'time': _selectedDurationType == 'Giờ' ? '$_selectedHours Giờ' : _selectedDurationType,
        'price': _formatPrice(_calculateTotalPrice()),
        'value': _calculateTotalPrice(),
      };
      _isDurationPanelExpanded = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchPrices();
    
    // Setup Heart Animation
    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _heartScaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.elasticOut)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
    ]).animate(_heartAnimController);
    
    _heartAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() { _showHeartAnimation = false; });
      }
    });
  }

  void _triggerHeartAnimation() {
    setState(() { _showHeartAnimation = true; });
    _heartAnimController.forward(from: 0.0);
    
    SavedPlacesController.to.addFavorite(widget.parkingLot);
    
    Get.snackbar(
      'Yêu thích', 
      'Đã thêm vào mục Yêu thích', 
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.pink,
      colorText: Colors.white,
      icon: const Icon(Icons.favorite, color: Colors.white),
      duration: const Duration(seconds: 2),
    );
  }

  void _showSaveBottomSheet() {
    final noteController = TextEditingController();
    String selectedFolder = 'Đi làm';
    
    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setStateSB) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Lưu vào danh sách', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: ['Đi làm', 'Đi chơi', 'Xem sau'].map((folder) {
                    final isSelected = selectedFolder == folder;
                    return ChoiceChip(
                      label: Text(folder),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryBlue.withOpacity(0.1),
                      labelStyle: TextStyle(
                        color: isSelected ? AppTheme.primaryBlue : Theme.of(context).colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        if (selected) setStateSB(() { selectedFolder = folder; });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  decoration: InputDecoration(
                    hintText: 'Thêm ghi chú (vd: Chỗ này tối khá đông)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      SavedPlacesController.to.savePlace(widget.parkingLot, selectedFolder, noteController.text);
                      Get.back();
                      Get.snackbar('Đã lưu', 'Bãi đỗ đã được lưu vào thư mục $selectedFolder', snackPosition: SnackPosition.TOP, backgroundColor: Colors.green, colorText: Colors.white);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Lưu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        }
      ),
      isScrollControlled: true,
    );
  }

  List<Map<String, dynamic>> _processPrices(List<Map<String, dynamic>> original) {
    Map<String, dynamic>? oneHourPrice;
    try {
      oneHourPrice = original.firstWhere((p) => p['time'].toString().toLowerCase().contains('1 giờ'));
    } catch (_) {
      if (original.isNotEmpty) {
        oneHourPrice = original[0];
      }
    }

    if (oneHourPrice == null) {
      return [
        {'time': '1 Giờ', 'price': '20.000đ', 'value': 20000},
        {'time': '2 Giờ', 'price': '40.000đ', 'value': 40000},
        {'time': 'Qua đêm', 'price': '160.000đ', 'value': 160000},
      ];
    }

    int baseValue = oneHourPrice['value'] as int;
    List<Map<String, dynamic>> processed = [];

    processed.add({'time': '1 Giờ', 'price': '${baseValue}đ', 'value': baseValue});

    try {
      processed.add(original.firstWhere((p) => p['time'].toString().toLowerCase().contains('2 giờ')));
    } catch (_) {
      processed.add({'time': '2 Giờ', 'price': '${baseValue * 2}đ', 'value': baseValue * 2});
    }

    try {
      processed.add(original.firstWhere((p) => p['time'].toString().toLowerCase().contains('qua đêm')));
    } catch (_) {
      processed.add({'time': 'Qua đêm', 'price': '${baseValue * 8}đ', 'value': baseValue * 8});
    }
    return processed;
  }

  Future<void> _fetchPrices() async {
    try {
      final response = await Supabase.instance.client
          .from('parking_prices')
          .select()
          .eq('parking_lot_id', widget.parkingLot['id']);
      
      if (mounted) {
        setState(() {
          List<Map<String, dynamic>> fetched = [];
          if (response.isNotEmpty) {
            fetched = (response as List).map((e) {
              return <String, dynamic>{
                'time': e['duration_type'],
                'price': '${(e['price'] as num).toInt()}đ',
                'value': (e['price'] as num).toInt(),
              };
            }).toList();
          }
          _pricingList = _processPrices(fetched);
          if (_pricingList.isNotEmpty) {
            _selectedPricing = _pricingList[0];
            _basePrice = _pricingList[0]['value'] as int;
          }
          _isLoadingPrices = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching prices: $e');
      if (mounted) {
        setState(() {
          _pricingList = _processPrices([]);
          if (_pricingList.isNotEmpty) {
            _selectedPricing = _pricingList[0];
            _basePrice = _pricingList[0]['value'] as int;
          }
          _isLoadingPrices = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _heartAnimController.dispose();
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.parkingLot['name'] ?? 'Chi tiết bãi đỗ xe'),
        centerTitle: true,
        actions: [
          Obx(() {
            final isFav = SavedPlacesController.to.isFavorite(widget.parkingLot['id'].toString());
            final isSaved = SavedPlacesController.to.isSaved(widget.parkingLot['id'].toString());
            
            return PopupMenuButton<String>(
              icon: const Icon(Icons.menu, size: 24),
              onSelected: (value) {
                if (value == 'favorite') {
                  _triggerHeartAnimation();
                } else if (value == 'save') {
                  _showSaveBottomSheet();
                } else if (value == 'copy') {
                  final text = 'Bãi đỗ: ${widget.parkingLot['name'] ?? ''}\nĐịa chỉ: ${widget.parkingLot['location'] ?? ''}';
                  Clipboard.setData(ClipboardData(text: text));
                  Get.snackbar('Thành công', 'Đã copy tên và địa chỉ bãi đỗ', snackPosition: SnackPosition.TOP, backgroundColor: Colors.black87, colorText: Colors.white);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'save',
                  child: Row(children: [Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: isSaved ? AppTheme.primaryBlue : null, size: 20), const SizedBox(width: 8), Text(isSaved ? 'Đã lưu bãi đỗ' : 'Lưu bãi đỗ')]),
                ),
                PopupMenuItem<String>(
                  value: 'favorite',
                  child: Row(children: [Icon(isFav ? Icons.favorite : Icons.favorite_border, color: Colors.pink, size: 20), const SizedBox(width: 8), Text(isFav ? 'Đã yêu thích' : 'Yêu thích')]),
                ),
                const PopupMenuItem<String>(
                  value: 'copy',
                  child: Row(children: [Icon(Icons.copy, size: 20), const SizedBox(width: 8), Text('Sao chép')]),
                ),
              ],
            );
          }),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image Carousel with PageView
                  SizedBox(
                    height: 220,
                    child: Stack(
                      children: [
                        GestureDetector(
                          onDoubleTap: _triggerHeartAnimation,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _images.length,
                            itemBuilder: (context, index) {
                              return Image.network(
                                _images[index],
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        ),
                        // Heart Animation Overlay
                        if (_showHeartAnimation)
                          Center(
                            child: ScaleTransition(
                              scale: _heartScaleAnim,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.redAccent.withOpacity(0.2), // Ripple effect
                                ),
                                child: const Icon(
                                  Icons.favorite,
                                  color: Colors.redAccent,
                                  size: 100,
                                ),
                              ),
                            ),
                          ),
                        // Nút qua lại mũi tên
                        Positioned(
                          right: 16,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: CircleAvatar(
                              backgroundColor: Colors.black.withOpacity(0.5),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                                onPressed: () {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        // Lớp phủ Gradient Tên bãi
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                              ),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              widget.parkingLot['name'] ?? 'Bãi đỗ xe trung tâm',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_on, color: AppTheme.accentBlue, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.parkingLot['location'] ?? 'Chưa có địa chỉ',
                                style: const TextStyle(color: AppTheme.textLight, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Tiện ích
                        Text(key: _durationKey, 'Tiện ích', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildFeatureChip(Icons.roofing, 'Có mái che'),
                            _buildFeatureChip(Icons.videocam, 'Camera 24/7'),
                            _buildFeatureChip(Icons.security, 'Bảo vệ'),
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        // Chọn thời gian đỗ
                        Text('Chọn thời gian đỗ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                        const SizedBox(height: 12),
                        
                        // Summary box (tap to expand)
                        GestureDetector(
                          onTap: () {
                            final willExpand = !_isDurationPanelExpanded;
                            setState(() { _isDurationPanelExpanded = willExpand; });
                            if (willExpand && !_hasAutoScrolled) {
                              _hasAutoScrolled = true;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                final ctx = _durationKey.currentContext;
                                if (ctx != null) {
                                  Scrollable.ensureVisible(
                                    ctx,
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeInOut,
                                    alignment: 0.0,
                                  );
                                }
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.accentBlue, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_filled, color: AppTheme.accentBlue, size: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _selectedPricing != null 
                                        ? '${_selectedPricing!['time']} — ${_selectedPricing!['price']}'
                                        : 'Nhấn để chọn thời gian',
                                    style: TextStyle(
                                      fontSize: 15, fontWeight: FontWeight.w600,
                                      color: _selectedPricing != null ? Theme.of(context).colorScheme.onSurface : Theme.of(context).textTheme.bodySmall?.color,
                                    ),
                                  ),
                                ),
                                Icon(_isDurationPanelExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                        
                        // Expandable panel
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: _isDurationPanelExpanded ? _buildDurationPanel() : const SizedBox.shrink(),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Đánh giá
                        Text('Đánh giá & Bình luận', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                        const SizedBox(height: 16),
                        
                        // Review Mock
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppTheme.primaryBlue,
                                    child: const Text('T', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Tien Toi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
                                      Row(
                                        children: List.generate(5, (index) => const Icon(Icons.star, color: Colors.amber, size: 16)),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Text('5.0', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.onSurface)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Đã trải nghiệm, uy tín, minh bạch, chất lượng hơn so với cùng giá tiền',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Nút chọn vị trí đỗ cố định ở dưới cùng
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 8,
                )
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (_selectedPricing == null) {
                        Get.snackbar('Thông báo', 'Vui lòng chọn thời gian đỗ xe', snackPosition: SnackPosition.TOP);
                        return;
                      }
                      Get.to(() => SlotSelectionPage(
                        parkingLot: widget.parkingLot,
                        selectedPricing: _selectedPricing!,
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      backgroundColor: AppTheme.primaryBlue,
                    ),
                    child: const Text('Chọn vị trí đỗ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Get.back(result: {'action': 'route', 'destination': widget.parkingLot});
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      side: const BorderSide(color: AppTheme.accentBlue, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                    icon: const Icon(Icons.directions, color: AppTheme.accentBlue),
                    label: const Text('Chỉ đường đến bãi đỗ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.accentBlue)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationPanel() {
    final dateFmt = DateFormat('dd/MM/yyyy');
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.1), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Duration type chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _durationTypes.map((type) {
              final isActive = _selectedDurationType == type;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDurationType = type;
                    _startDate = DateTime.now();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.accentBlue : (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isActive ? AppTheme.accentBlue : Colors.grey.withOpacity(0.3)),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Dynamic sub-panel
          if (_selectedDurationType == 'Giờ') ...[
            Text('Chọn số giờ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 12,
                itemBuilder: (ctx, i) {
                  final h = i + 1;
                  final isActive = _selectedHours == h;
                  return GestureDetector(
                    onTap: () => setState(() { _selectedHours = h; }),
                    child: Container(
                      width: 44, height: 44,
                      margin: const EdgeInsets.only(right: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.accentBlue : (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isActive ? AppTheme.accentBlue : Colors.grey.withOpacity(0.3)),
                      ),
                      child: Text('$h', style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? Colors.white : Theme.of(context).colorScheme.onSurface)),
                    ),
                  );
                },
              ),
            ),
          ],

          if (_selectedDurationType == 'Cả ngày' || _selectedDurationType == 'Tuần' || _selectedDurationType == 'Tháng') ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ngày bắt đầu', style: TextStyle(fontSize: 13, color: AppTheme.textLight)),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) setState(() { _startDate = picked; });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.accentBlue, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: AppTheme.accentBlue),
                              const SizedBox(width: 8),
                              Text(dateFmt.format(_startDate), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ngày kết thúc', style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.event, size: 16, color: Colors.grey.shade500),
                            const SizedBox(width: 8),
                            Text(dateFmt.format(_calculateEndDate()), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),
          // Price summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accentBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng tiền:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                Text(_formatPrice(_calculateTotalPrice()), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.accentBlue)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _confirmDuration,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Xác nhận', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.accentBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppTheme.accentBlue),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
