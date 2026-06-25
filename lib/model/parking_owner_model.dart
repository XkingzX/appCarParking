// model/parking_owner_model.dart
class ParkingOwnerModel {
  final String id;
  final String companyName;
  final String? taxNumber;
  final String? bankAccountInfo;
  final String? businessLicenseUrl;
  final String status;
  final DateTime? createdAt;
  
  // Thông tin Join từ bảng profiles
  final String? fullName;
  final String? email;

  ParkingOwnerModel({
    required this.id,
    required this.companyName,
    this.taxNumber,
    this.bankAccountInfo,
    this.businessLicenseUrl,
    required this.status,
    this.createdAt,
    this.fullName,
    this.email,
  });

  factory ParkingOwnerModel.fromJson(Map<String, dynamic> json) {
    return ParkingOwnerModel(
      id: json['id'] ?? '',
      companyName: json['company_name'] ?? '',
      taxNumber: json['tax_number'],
      bankAccountInfo: json['bank_account_info'],
      businessLicenseUrl: json['business_license_url'],
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      fullName: json['profiles']?['full_name'],
      email: json['profiles']?['email'], // Tuỳ thuộc việc profiles có lưu email hay ko
    );
  }
}
