import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:baidoxe/core/theme.dart';
import 'slot_selection_page.dart';

class ParkingDetailPage extends StatefulWidget {
  final Map<String, dynamic> parkingLot;
  
  const ParkingDetailPage({Key? key, required this.parkingLot}) : super(key: key);

  @override
  State<ParkingDetailPage> createState() => _ParkingDetailPageState();
}

class _ParkingDetailPageState extends State<ParkingDetailPage> {
  int _selectedPriceIndex = 0;
  final PageController _pageController = PageController();

  // Hình ảnh giả lập theo yêu cầu
  final List<String> _images = [
    'https://images.unsplash.com/photo-1573348722427-f1d6819fdf98?q=80&w=1000&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?q=80&w=1000&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?q=80&w=1000&auto=format&fit=crop',
  ];

  List<Map<String, dynamic>> _pricingList = [];
  bool _isLoadingPrices = true;

  @override
  void initState() {
    super.initState();
    _fetchPrices();
  }

  Future<void> _fetchPrices() async {
    try {
      final response = await Supabase.instance.client
          .from('parking_prices')
          .select()
          .eq('parking_lot_id', widget.parkingLot['id']);
      
      if (mounted) {
        setState(() {
          if (response.isNotEmpty) {
            _pricingList = (response as List).map((e) => {
              'time': e['duration_type'],
              'price': '${(e['price'] as num).toInt()}đ', // Format
              'value': (e['price'] as num).toInt(),
            }).toList();
          } else {
            // Fallback nếu chưa chạy SQL seed
            _pricingList = [
              {'time': '1 Giờ', 'price': '20.000đ', 'value': 20000},
              {'time': '2 Giờ', 'price': '35.000đ', 'value': 35000},
              {'time': 'Qua đêm', 'price': '100.000đ', 'value': 100000},
            ];
          }
          _isLoadingPrices = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching prices: $e');
      if (mounted) {
        setState(() {
          _pricingList = [
            {'time': '1 Giờ', 'price': '20.000đ', 'value': 20000},
            {'time': '2 Giờ', 'price': '35.000đ', 'value': 35000},
            {'time': 'Qua đêm', 'price': '100.000đ', 'value': 100000},
          ];
          _isLoadingPrices = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryWhite,
      appBar: AppBar(
        title: Text(widget.parkingLot['name'] ?? 'Chi tiết bãi đỗ xe'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image Carousel with PageView
                  SizedBox(
                    height: 220,
                    child: Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: _images.length,
                          itemBuilder: (context, index) {
                            return Image.network(
                              _images[index],
                              fit: BoxFit.cover,
                            );
                          },
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
                        const Text('Tiện ích', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
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
                        
                        // Bảng giá
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Chọn khung giờ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                            Text('Nhấn để chọn', style: TextStyle(fontSize: 14, color: AppTheme.textLight)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        _isLoadingPrices 
                        ? const Center(child: CircularProgressIndicator())
                        : SizedBox(
                          height: 130,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _pricingList.length,
                            itemBuilder: (context, index) {
                              final isSelected = _selectedPriceIndex == index;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedPriceIndex = index;
                                  });
                                },
                                child: Container(
                                  width: 110,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppTheme.accentBlue : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected ? AppTheme.accentBlue : Colors.grey.shade300,
                                      width: 2,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppTheme.accentBlue.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            )
                                          ]
                                        : null,
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.access_time_filled,
                                        color: isSelected ? Colors.white : AppTheme.accentBlue,
                                        size: 24,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _pricingList[index]['time'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isSelected ? Colors.white : AppTheme.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _pricingList[index]['price'],
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isSelected ? Colors.white70 : AppTheme.accentBlue,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Đánh giá
                        const Text('Đánh giá & Bình luận', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                        const SizedBox(height: 16),
                        
                        // Review Mock
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
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
                                      const Text('Tien Toi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      Row(
                                        children: List.generate(5, (index) => const Icon(Icons.star, color: Colors.amber, size: 16)),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  const Text('5.0', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Đã trải nghiệm, uy tín, minh bạch, chất lượng hơn so với cùng giá tiền',
                                style: TextStyle(color: AppTheme.textDark, height: 1.4),
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
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 8,
                )
              ],
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: () {
                  Get.to(() => SlotSelectionPage(
                    parkingLot: widget.parkingLot,
                    selectedPricing: _pricingList[_selectedPriceIndex],
                  ));
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: const Text('Chọn vị trí đỗ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
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
            style: const TextStyle(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
