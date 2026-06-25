import 'package:flutter/material.dart';
import 'package:baidoxe/features/web_admin/web_admin_layout.dart';
import 'package:baidoxe/features/web_admin/widgets/stat_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:baidoxe/core/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardPage extends StatefulWidget {
  final String role;
  
  const AdminDashboardPage({Key? key, required this.role}) : super(key: key);

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _isLoading = true;
  int _totalParkings = 0;
  int _totalOwners = 0;
  int _totalBookings = 0;
  double _totalRevenue = 0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      setState(() => _isLoading = true);
      
      final supabase = Supabase.instance.client;

      // Fetch Total Parkings
      final parkingsResponse = await supabase.from('parking_lots').select('id');
      _totalParkings = parkingsResponse.length;

      // Fetch Total Owners
      final ownersResponse = await supabase.from('profiles').select('id').eq('role', 'parking_owner');
      _totalOwners = ownersResponse.length;

      // Fetch Total Bookings
      final bookingsResponse = await supabase.from('bookings').select('id');
      _totalBookings = bookingsResponse.length;

      // Calculate Fake Revenue for now (50,000 VND per booking)
      _totalRevenue = _totalBookings * 50000.0;

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching dashboard data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M VNĐ';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K VNĐ';
    }
    return '${amount.toStringAsFixed(0)} VNĐ';
  }

  @override
  Widget build(BuildContext context) {
    return WebAdminLayout(
      role: widget.role,
      currentRoute: '/web-admin/admin-dashboard',
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tổng quan Hệ thống',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: AppTheme.accentBlue),
                    onPressed: _fetchDashboardData,
                    tooltip: 'Làm mới dữ liệu',
                  )
                ],
              ),
              const SizedBox(height: 24),
              
              // KPI Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 4;
                  if (constraints.maxWidth < 600) {
                    crossAxisCount = 1;
                  } else if (constraints.maxWidth < 1000) {
                    crossAxisCount = 2;
                  }
                  
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: constraints.maxWidth < 600 ? 2.5 : 1.6,
                    children: [
                      StatCard(
                        title: 'Tổng doanh thu (Ước tính)',
                        value: _formatCurrency(_totalRevenue),
                        icon: Icons.account_balance_wallet_rounded,
                        color: Colors.green,
                        trend: 'Tăng trưởng',
                        isUp: true,
                      ),
                      StatCard(
                        title: 'Tổng số bãi đỗ',
                        value: '$_totalParkings',
                        icon: Icons.local_parking_rounded,
                        color: AppTheme.accentBlue,
                      ),
                      StatCard(
                        title: 'Chủ bãi đỗ',
                        value: '$_totalOwners',
                        icon: Icons.people_alt_rounded,
                        color: Colors.orange,
                      ),
                      StatCard(
                        title: 'Lượt đặt chỗ',
                        value: '$_totalBookings',
                        icon: Icons.book_online_rounded,
                        color: Colors.purple,
                      ),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              // Charts Section
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _RevenueChartWidget(),
                  ),
                  SizedBox(width: 24),
                  Expanded(
                    flex: 1,
                    child: _OccupancyChartWidget(),
                  ),
                ],
              )
            ],
          ),
    );
  }
}

// Extracted into a StatelessWidget to prevent rebuilding when parent updates (unless keys match)
class _RevenueChartWidget extends StatelessWidget {
  const _RevenueChartWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Doanh thu 7 ngày gần nhất',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true, 
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(color: AppTheme.textLight, fontSize: 12, fontWeight: FontWeight.bold);
                        Widget text;
                        switch (value.toInt()) {
                          case 0: text = const Text('T2', style: style); break;
                          case 2: text = const Text('T4', style: style); break;
                          case 4: text = const Text('T6', style: style); break;
                          case 6: text = const Text('CN', style: style); break;
                          default: text = const Text('', style: style); break;
                        }
                        return SideTitleWidget(
                          meta: meta,
                          child: text,
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 1.5),
                      FlSpot(1, 2.8),
                      FlSpot(2, 2.2),
                      FlSpot(3, 3.9),
                      FlSpot(4, 3.1),
                      FlSpot(5, 4.8),
                      FlSpot(6, 5.5),
                    ],
                    isCurved: true,
                    color: AppTheme.accentBlue,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: AppTheme.accentBlue,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.accentBlue.withOpacity(0.3),
                          AppTheme.accentBlue.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OccupancyChartWidget extends StatelessWidget {
  const _OccupancyChartWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tỷ lệ lấp đầy',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true, 
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: const FlTitlesData(
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                    ),
                  )
                ),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 8, color: Colors.indigo, width: 20, borderRadius: BorderRadius.circular(6))]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 10, color: Colors.indigo, width: 20, borderRadius: BorderRadius.circular(6))]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 14, color: Colors.indigo, width: 20, borderRadius: BorderRadius.circular(6))]),
                  BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 15, color: Colors.indigo, width: 20, borderRadius: BorderRadius.circular(6))]),
                  BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 13, color: Colors.indigo, width: 20, borderRadius: BorderRadius.circular(6))]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
