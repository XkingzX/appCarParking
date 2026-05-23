import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:baidoxe/features/customer/account/presentation/vehicle_management_page.dart';
import 'package:baidoxe/features/customer/booking/presentation/booking_history_page.dart';
import 'package:baidoxe/core/theme.dart';
import 'package:baidoxe/features/customer/account/presentation/favorite_page.dart';
import 'package:baidoxe/features/customer/account/presentation/saved_places_page.dart';
import 'package:baidoxe/features/customer/account/controllers/saved_places_controller.dart';

class CustomerAccountPage extends StatefulWidget {
  const CustomerAccountPage({Key? key}) : super(key: key);

  @override
  State<CustomerAccountPage> createState() => _CustomerAccountPageState();
}

class _CustomerAccountPageState extends State<CustomerAccountPage> {
  String _fullName = 'Đang tải...';
  String _email = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      if (mounted) {
        setState(() {
          _email = user.email ?? '';
        });
      }

      final response = await Supabase.instance.client
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _fullName = response['full_name'] ?? 'Chưa cập nhật tên';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      if (mounted) {
        setState(() {
          _fullName = 'Lỗi tải thông tin';
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
    bool showTrailing = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? AppTheme.darkTextMain : AppTheme.textDark;
    
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? defaultColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor ?? defaultColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (showTrailing)
              Icon(Icons.chevron_right, color: isDark ? AppTheme.darkTextSub : AppTheme.textLight, size: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subTextColor = isDark ? AppTheme.darkTextSub : AppTheme.textLight;
    final dividerColor = isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFEDF2F7);
    final cardColor = Theme.of(context).colorScheme.surface;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Hồ sơ của tôi',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: textColor,
            ),
            onPressed: () {
              Get.changeThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // Profile Section
            Row(
              children: [
                // Avatar with camera icon
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: primaryColor.withOpacity(0.1),
                      child: Icon(Icons.person, size: 45, color: primaryColor),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: cardColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(Icons.camera_alt_outlined, size: 16, color: textColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                // Info and Button
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _isLoading 
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _fullName,
                            style: TextStyle(
                              fontSize: 20, 
                              fontWeight: FontWeight.bold, 
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      const SizedBox(height: 4),
                      Text(
                        _email,
                        style: TextStyle(fontSize: 14, color: subTextColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Edit profile
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 14, 
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: const Text('Chỉnh sửa hồ sơ'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // List items Group 1
            _buildListTile(
              context,
              icon: Icons.favorite_border, 
              title: 'Yêu thích', 
              onTap: () {
                Get.to(() => const FavoritePage());
              }
            ),
            _buildListTile(
              context,
              icon: Icons.bookmark_border, 
              title: 'Vị trí đã lưu', 
              onTap: () {
                Get.to(() => const SavedPlacesPage());
              }
            ),
            _buildListTile(
              context,
              icon: Icons.local_parking_outlined, 
              title: 'Quản lý các trang bãi đỗ', 
              onTap: () {
                Get.snackbar('Thông báo', 'Tính năng đang phát triển', backgroundColor: primaryColor, colorText: Colors.white);
              }
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: dividerColor, thickness: 1),
            ),
            
            // List items Group 2
            _buildListTile(
              context,
              icon: Icons.directions_car_outlined, 
              title: 'Quản lý phương tiện', 
              onTap: () => Get.to(() => const VehicleManagementPage()),
            ),
            _buildListTile(
              context,
              icon: Icons.account_balance_wallet_outlined, 
              title: 'Phương thức thanh toán', 
              onTap: () {
                Get.snackbar('Thông báo', 'Tính năng đang phát triển', backgroundColor: primaryColor, colorText: Colors.white);
              }
            ),
            _buildListTile(
              context,
              icon: Icons.history, 
              title: 'Lịch sử đỗ xe', 
              onTap: () => Get.to(() => const BookingHistoryPage()),
            ),
            _buildListTile(
              context,
              icon: Icons.star_border, 
              title: 'Đánh giá & nhận xét', 
              onTap: () {
                Get.snackbar('Thông báo', 'Tính năng đang phát triển', backgroundColor: primaryColor, colorText: Colors.white);
              }
            ),
            _buildListTile(
              context,
              icon: Icons.storefront_outlined, 
              title: 'Đăng ký chủ bãi đỗ', 
              onTap: () {
                Get.snackbar('Thông báo', 'Tính năng đang phát triển', backgroundColor: primaryColor, colorText: Colors.white);
              }
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: dividerColor, thickness: 1),
            ),
            
            // List items Group 3
            _buildListTile(
              context,
              icon: Icons.delete_outline, 
              title: 'Xoá bộ nhớ đệm', 
              onTap: () {
                SavedPlacesController.to.clearAllCache();
              }
            ),
            _buildListTile(
              context,
              icon: Icons.logout, 
              title: 'Đăng xuất', 
              textColor: Colors.red,
              iconColor: Colors.red,
              showTrailing: false,
              onTap: () => Get.offAllNamed('/login'),
            ),
            
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Phiên bản 1.0.0', 
                style: TextStyle(color: subTextColor, fontSize: 13),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
