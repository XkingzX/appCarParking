import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:baidoxe/core/theme.dart';
import 'package:baidoxe/model/slot_model.dart';
import 'package:baidoxe/services/supabase_service.dart';
import 'payment_page.dart';

class SlotSelectionPage extends StatefulWidget {
  final Map<String, dynamic> parkingLot;
  final Map<String, dynamic> selectedPricing;

  const SlotSelectionPage({
    Key? key,
    required this.parkingLot,
    required this.selectedPricing,
  }) : super(key: key);

  @override
  State<SlotSelectionPage> createState() => _SlotSelectionPageState();
}

class _SlotSelectionPageState extends State<SlotSelectionPage> {
  final SupabaseService _service = SupabaseService();
  final ScrollController _scrollController = ScrollController();

  SlotModel? _selectedSlot;
  List<SlotModel> _slots = [];
  
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  
  String _selectedZone = 'A';
  final int _limit = 20;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    _fetchSlots(isRefresh: true);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        if (!_isLoadingMore && _hasMoreData) {
          _fetchSlots(isRefresh: false);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchSlots({required bool isRefresh}) async {
    if (isRefresh) {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _offset = 0;
          _hasMoreData = true;
          _slots.clear();
          _selectedSlot = null;
        });
      }
    } else {
      if (mounted) setState(() => _isLoadingMore = true);
    }

    try {
      final parkingLotId = widget.parkingLot['id'];
      final response = await _service.getSlotsPaginated(
        parkingLotId,
        _selectedZone,
        _offset,
        _limit,
      );

      final newSlots = response.map((e) => SlotModel.fromJson(e)).toList();

      if (mounted) {
        setState(() {
          if (isRefresh) {
            _slots = newSlots;
          } else {
            _slots.addAll(newSlots);
          }
          
          _offset += newSlots.length;
          _hasMoreData = newSlots.length == _limit;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching slots: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  int get _availableCount => _slots.where((s) => s.isAvailable).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.parkingLot['name'] ?? 'PARK ZONE'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Zone tabs
          _buildZoneTabs(),

          // Legends
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLegend(context, Theme.of(context).cardColor, Theme.of(context).colorScheme.onSurface, 'Trống'),
                _buildLegend(context, AppTheme.accentBlue, Colors.white, 'Đang chọn'),
                _buildLegend(context, Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade300, Theme.of(context).colorScheme.onSurface, 'Đã kín', isOccupied: true),
              ],
            ),
          ),

          // Available count
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppTheme.accentBlue),
                  const SizedBox(width: 6),
                  Text(
                    'Còn $_availableCount chỗ trống (khu $_selectedZone)',
                    style: const TextStyle(
                      color: AppTheme.accentBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),

          // Parking Layout (2D Scrollable)
          Expanded(
            child: Stack(
              children: [
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _slots.isEmpty
                        ? Center(
                            child: Text(
                              'Không có slot trong khu $_selectedZone',
                              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _fetchSlots(isRefresh: true),
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.only(bottom: 100, top: 16),
                              itemCount: (_slots.length / 2).ceil() + (_isLoadingMore ? 1 : 0),
                              itemBuilder: (context, rowIndex) {
                                if (rowIndex >= (_slots.length / 2).ceil()) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }
                                return _buildParkingRow(rowIndex);
                              },
                            ),
                          ),

                // Entry Text
                if (!_isLoading && _slots.isNotEmpty)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Icon(Icons.keyboard_arrow_up, color: Colors.green.shade600),
                        Text(
                          'ENTRY',
                          style: TextStyle(
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Bottom Book Button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(
                        Theme.of(context).brightness == Brightness.dark
                            ? 0.3
                            : 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5))
              ],
            ),
            child: ElevatedButton(
              onPressed: _selectedSlot != null
                  ? () {
                      Get.to(() => PaymentPage(
                            parkingLot: widget.parkingLot,
                            selectedPricing: widget.selectedPricing,
                            selectedSlotName: _selectedSlot!.slotName,
                            selectedSlotId: _selectedSlot!.id,
                          ));
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: _selectedSlot != null
                    ? AppTheme.primaryBlue
                    : Colors.grey.shade400,
              ),
              child: const Text('ĐẶT CHỖ',
                  style: TextStyle(
                      fontSize: 16,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneTabs() {
    // Tạm thời hiển thị 2 khu A, B
    final zones = ['A', 'B'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: zones
            .map((zone) => _buildTabItem(context, 'Khu $zone', _selectedZone == zone, zone))
            .toList(),
      ),
    );
  }

  Widget _buildTabItem(BuildContext context, String text, bool isSelected, String zone) {
    return GestureDetector(
      onTap: () {
        if (_selectedZone != zone) {
          setState(() {
            _selectedZone = zone;
          });
          _fetchSlots(isRefresh: true);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppTheme.accentBlue : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).textTheme.bodySmall?.color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildParkingRow(int rowIndex) {
    final leftIndex = rowIndex * 2;
    final rightIndex = rowIndex * 2 + 1;

    final leftSlot = leftIndex < _slots.length ? _slots[leftIndex] : null;
    final rightSlot = rightIndex < _slots.length ? _slots[rightIndex] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Left slot
          if (leftSlot != null)
            _buildSlot(context, leftSlot, isLeft: true)
          else
            const SizedBox(width: 100, height: 60),

          // Center Pathway
          Container(
            width: 80,
            height: 60,
            alignment: Alignment.center,
            child: rowIndex == 1
                ? RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      '$_availableCount SLOTS FREE',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        fontSize: 12,
                      ),
                    ),
                  )
                : CustomPaint(
                    size: const Size(2, 40),
                    painter: DashedLinePainter(),
                  ),
          ),

          // Right slot
          if (rightSlot != null)
            _buildSlot(context, rightSlot, isLeft: false)
          else
            const SizedBox(width: 100, height: 60),
        ],
      ),
    );
  }

  Widget _buildSlot(BuildContext context, SlotModel slot, {required bool isLeft}) {
    final isOccupied = !slot.isAvailable;
    final isSelected = _selectedSlot?.id == slot.id;

    return GestureDetector(
      onTap: () {
        if (!isOccupied) {
          setState(() {
            _selectedSlot = slot;
          });
        }
      },
      child: Container(
        width: 100,
        height: 60,
        decoration: BoxDecoration(
          color: isOccupied
              ? (Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade800
                  : Colors.grey.shade300)
              : (isSelected ? AppTheme.accentBlue : Theme.of(context).cardColor),
          border: Border.all(
            color: isSelected ? AppTheme.accentBlue : Colors.grey.withOpacity(0.3),
            width: 1.5,
          ),
          borderRadius: isLeft
              ? const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                )
              : const BorderRadius.only(
                  topRight: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: AppTheme.accentBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isOccupied)
              RotatedBox(
                quarterTurns: isLeft ? 1 : 3,
                child: Icon(
                  Icons.directions_car,
                  color: Colors.grey.shade600,
                  size: 40,
                ),
              )
            else
              Text(
                slot.slotName,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.accentBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context, Color color, Color textColor, String label, {bool isOccupied = false}) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: isOccupied ? Icon(Icons.directions_car, size: 16, color: Colors.grey.shade600) : null,
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 5, dashSpace = 5, startY = 0;
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 2;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
