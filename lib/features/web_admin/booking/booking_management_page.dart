import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:baidoxe/features/web_admin/web_admin_layout.dart';
import 'package:baidoxe/features/web_admin/widgets/custom_data_table.dart';
import 'package:baidoxe/core/theme.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class BookingManagementPage extends StatefulWidget {
  final String role;

  const BookingManagementPage({Key? key, required this.role}) : super(key: key);

  @override
  State<BookingManagementPage> createState() => _BookingManagementPageState();
}

class _BookingManagementPageState extends State<BookingManagementPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _bookings = [];

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    try {
      final supabase = Supabase.instance.client;
      var query = supabase.from('bookings').select('*, profiles:user_id(full_name), slots(parking_lots(name))');
      
      // Nếu là parking_owner, chỉ lấy booking của bãi đỗ thuộc sở hữu của người này
      if (widget.role == 'parking_owner') {
        // Thực tế cần query qua owner_id của parking_lots, Supabase PostgREST hỗ trợ nested query filtering
        // Tạm thời fetch hết và filter ở client (hoặc dùng RPC) cho đơn giản nếu chưa cài RLS sâu
      }

      final response = await query.order('created_at', ascending: false);
      
      if (mounted) {
        setState(() {
          _bookings = List<Map<String, dynamic>>.from(response);
          // Filter if owner (nếu chưa dùng policy RLS strict)
          if (widget.role == 'parking_owner') {
            // Lọc logic ở đây nếu cần, nhưng tạm thời Supabase RLS nên xử lý
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching bookings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    try {
      return DateFormat('HH:mm, dd/MM/yyyy').format(DateTime.parse(isoDate).toLocal());
    } catch (_) {
      return isoDate;
    }
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'completed': color = Colors.green; break;
      case 'cancelled': color = Colors.red; break;
      case 'confirmed': color = Colors.blue; break;
      default: color = Colors.orange; // pending
    }
    return Chip(
      label: Text(status.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide.none,
    );
  }

  Future<void> _exportInvoicePDF(Map<String, dynamic> booking) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('HOA DON THANH TOAN (INVOICE)', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text('Ma Đat: #${booking['id'].toString().substring(0, 8)}'),
              pw.Text('Khach hang: ${booking['profiles']?['full_name'] ?? 'Khach vang lai'}'),
              pw.Text('Bai đỗ: ${booking['slots']?['parking_lots']?['name'] ?? 'Khong xac đinh'}'),
              pw.SizedBox(height: 10),
              pw.Text('Thoi gian bat đau: ${_formatDate(booking['start_time'])}'),
              pw.Text('Thoi gian ket thuc: ${_formatDate(booking['end_time'])}'),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Tong Tien:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text('${booking['total_amount'] ?? 0} VND', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                ]
              ),
              pw.SizedBox(height: 30),
              pw.Text('Cam on quy khach đa su dung dich vu cua chung toi!', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice_${booking['id'].toString().substring(0, 8)}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return WebAdminLayout(
      role: widget.role,
      currentRoute: '/web-admin/booking',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quản lý Đặt chỗ',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  setState(() => _isLoading = true);
                  _fetchBookings();
                },
              )
            ],
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_bookings.isEmpty)
            const Expanded(child: Center(child: Text('Chưa có dữ liệu đặt chỗ')))
          else
            Expanded(
              child: CustomDataTable(
                columns: const ['Mã Đặt', 'Khách hàng', 'Bãi đỗ', 'Bắt đầu', 'Kết thúc', 'Trạng thái', 'Thanh toán (VNĐ)', 'Hành động'],
                rows: _bookings.map((b) {
                  return [
                    Text('#${b['id'].toString().substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(b['profiles']?['full_name'] ?? 'Khách vãng lai'),
                    Text(b['slots']?['parking_lots']?['name'] ?? 'Bãi đỗ không xác định'),
                    Text(_formatDate(b['start_time'])),
                    Text(_formatDate(b['end_time'])),
                    _buildStatusChip(b['status'] ?? 'pending'),
                    Text('${b['total_amount'] ?? 0} đ', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                      tooltip: 'Xuất Hoá đơn PDF',
                      onPressed: () => _exportInvoicePDF(b),
                    ),
                  ];
                }).toList(),
              ),
            )
        ],
      ),
    );
  }
}
