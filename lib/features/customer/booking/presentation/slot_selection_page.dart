import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:baidoxe/core/theme.dart';
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
  int? selectedSlot;
  int _totalRows = 8; // 16 slots initially
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  final List<int> _occupiedSlots = [2, 5, 8, 11, 14]; // Mock data

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50) {
      _loadMoreSlots();
    }
  }

  Future<void> _loadMoreSlots() async {
    if (_isLoading || _totalRows >= 24) return; // limit to 48 slots max for demo
    setState(() {
      _isLoading = true;
    });
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      setState(() {
        _totalRows += 4; // load 8 more slots
        _isLoading = false;
      });
    }
  }

  String _getSlotName(int index, bool isLeft) {
    String prefix = isLeft ? 'A' : 'B';
    return '$prefix${index + 1}';
  }

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
          // Tabs
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
          
          // Parking Layout
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 100, top: 16), // space for ENTRY text
                  itemCount: _totalRows + 1, // +1 for loading indicator
                  itemBuilder: (context, rowIndex) {
                    if (rowIndex == _totalRows) {
                      return _isLoading 
                          ? const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : const SizedBox(height: 40);
                    }
                    return _buildParkingRow(rowIndex);
                  },
                ),
                
                // Entry Text sticky at bottom of list area
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
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.1), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: ElevatedButton(
              onPressed: selectedSlot != null
                  ? () {
                      Get.to(() => PaymentPage(
                        parkingLot: widget.parkingLot,
                        selectedPricing: widget.selectedPricing,
                        selectedSlotName: _getSlotName(
                            selectedSlot!,
                            selectedSlot! % 2 == 0 // left is even index (0,2,4) based on logic below
                        ),
                      ));
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: selectedSlot != null ? AppTheme.primaryBlue : Colors.grey.shade400,
              ),
              child: const Text('ĐẶT CHỖ', style: TextStyle(fontSize: 16, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTabItem(context, 'Khu A', true),
          _buildTabItem(context, 'Khu B', false),
          _buildTabItem(context, 'Khu C', false),
          _buildTabItem(context, 'Khu VIP', false),
        ],
      ),
    );
  }

  Widget _buildTabItem(BuildContext context, String text, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
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
          color: isSelected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).textTheme.bodySmall?.color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildParkingRow(int rowIndex) {
    int leftSlotIndex = rowIndex * 2;
    int rightSlotIndex = rowIndex * 2 + 1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Left Slot (Row A)
          _buildSlot(context, leftSlotIndex, _getSlotName(leftSlotIndex, true), isLeft: true),
          
          // Center Pathway
          Container(
            width: 80,
            height: 60, // Match slot height roughly
            alignment: Alignment.center,
            child: rowIndex == 2 // Just show text in the middle somewhere
                ? RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      '4 SLOTS FREE',
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
          
          // Right Slot (Row B)
          _buildSlot(context, rightSlotIndex, _getSlotName(rightSlotIndex, false), isLeft: false),
        ],
      ),
    );
  }

  Widget _buildSlot(BuildContext context, int index, String label, {required bool isLeft}) {
    bool isOccupied = _occupiedSlots.contains(index);
    bool isSelected = selectedSlot == index;

    return GestureDetector(
      onTap: () {
        if (!isOccupied) {
          setState(() {
            selectedSlot = index;
          });
        }
      },
      child: Container(
        width: 100,
        height: 60,
        decoration: BoxDecoration(
          color: isOccupied ? (Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade200) : (isSelected ? AppTheme.accentBlue : Theme.of(context).cardColor),
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
              ? [BoxShadow(color: AppTheme.accentBlue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isOccupied)
              // Car Top View
              RotatedBox(
                quarterTurns: isLeft ? 1 : 3, // point inwards or outwards
                child: Icon(
                  Icons.directions_car,
                  color: AppTheme.primaryBlue,
                  size: 40,
                ),
              )
            else
              Text(
                label,
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
          child: isOccupied 
            ? Icon(Icons.directions_car, size: 16, color: AppTheme.primaryBlue)
            : null,
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
