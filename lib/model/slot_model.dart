class SlotModel {
  final String id;
  final String parkingLotId;
  final String slotName;
  final String status; // 'available', 'reserved', 'occupied'
  final String? zone;
  final int? rowIndex;
  final int? colIndex;

  SlotModel({
    required this.id,
    required this.parkingLotId,
    required this.slotName,
    required this.status,
    this.zone,
    this.rowIndex,
    this.colIndex,
  });

  factory SlotModel.fromJson(Map<String, dynamic> json) {
    return SlotModel(
      id: json['id'] ?? '',
      parkingLotId: json['parking_lot_id'] ?? '',
      slotName: json['slot_name'] ?? '',
      status: json['status'] ?? 'available',
      zone: json['zone'],
      rowIndex: json['row_index'],
      colIndex: json['col_index'],
    );
  }

  bool get isAvailable => status == 'available';
  bool get isReserved => status == 'reserved';
  bool get isOccupied => status == 'occupied';
}
