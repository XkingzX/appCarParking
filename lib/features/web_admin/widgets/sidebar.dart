import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:baidoxe/core/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Sidebar extends StatefulWidget {
  final String role;
  final String currentRoute;
  final VoidCallback? onClose;

  const Sidebar({
    Key? key,
    required this.role,
    required this.currentRoute,
    this.onClose,
  }) : super(key: key);

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo & Close Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.local_parking_rounded, color: Colors.white, size: 32),
                  SizedBox(width: 12),
                  Text(
                    'Smart Parking',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              if (widget.onClose != null)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: widget.onClose,
                ),
            ],
          ),
        ),
        
        // Menu Items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            children: _buildMenuItems(),
          ),
        ),

        // Logout
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text('Đăng xuất', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                Get.offAllNamed('/login');
              },
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildMenuItems() {
    List<Widget> items = [];

    items.add(_SidebarItem(
      icon: Icons.dashboard_rounded,
      title: 'Dashboard',
      route: widget.role == 'admin' ? '/web-admin/admin-dashboard' : '/web-admin/owner-dashboard',
      isSelected: widget.currentRoute == '/web-admin/admin-dashboard' || widget.currentRoute == '/web-admin/owner-dashboard',
    ));

    if (widget.role == 'admin') {
      items.addAll([
        _buildSectionTitle('QUẢN LÝ BÃI ĐỖ XE'),
        _SidebarItem(icon: Icons.local_parking_rounded, title: 'Danh sách bãi đỗ', route: '/web-admin/parking', isSelected: widget.currentRoute.startsWith('/web-admin/parking')),
        _SidebarItem(icon: Icons.people_alt_rounded, title: 'Chủ bãi đỗ', route: '/web-admin/owner', isSelected: widget.currentRoute.startsWith('/web-admin/owner')),
        
        _buildSectionTitle('NGƯỜI DÙNG & GIAO DỊCH'),
        _SidebarItem(icon: Icons.book_online_rounded, title: 'Đặt chỗ', route: '/web-admin/booking', isSelected: widget.currentRoute.startsWith('/web-admin/booking')),
        _SidebarItem(icon: Icons.account_balance_wallet_rounded, title: 'Doanh thu', route: '/web-admin/revenue', isSelected: widget.currentRoute.startsWith('/web-admin/revenue')),
        
        _buildSectionTitle('BẢN ĐỒ & MÔ PHỎNG'),
        _SidebarItem(icon: Icons.traffic_rounded, title: 'Traffic Simulation', route: '/web-admin/traffic', isSelected: widget.currentRoute.startsWith('/web-admin/traffic')),
      ]);
    } else if (widget.role == 'parking_owner') {
      items.addAll([
        _buildSectionTitle('BÃI ĐỖ CỦA TÔI'),
        _SidebarItem(icon: Icons.local_parking_rounded, title: 'Danh sách bãi đỗ', route: '/web-admin/parking', isSelected: widget.currentRoute.startsWith('/web-admin/parking')),
        _SidebarItem(icon: Icons.book_online_rounded, title: 'Đặt chỗ', route: '/web-admin/booking', isSelected: widget.currentRoute.startsWith('/web-admin/booking')),
        
        _buildSectionTitle('PHÂN TÍCH'),
        _SidebarItem(icon: Icons.account_balance_wallet_rounded, title: 'Doanh thu', route: '/web-admin/revenue', isSelected: widget.currentRoute.startsWith('/web-admin/revenue')),
      ]);
    } else if (widget.role == 'guard') {
      items.addAll([
        _buildSectionTitle('NGHIỆP VỤ'),
        _SidebarItem(icon: Icons.qr_code_scanner_rounded, title: 'Scanner', route: '/web-admin/guard-scanner', isSelected: widget.currentRoute.startsWith('/web-admin/guard-scanner')),
        _SidebarItem(icon: Icons.verified_user_rounded, title: 'Verification', route: '/web-admin/guard-verification', isSelected: widget.currentRoute.startsWith('/web-admin/guard-verification')),
      ]);
    }

    return items;
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 24, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String route;
  final bool isSelected;

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.route,
    required this.isSelected,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: widget.isSelected 
              ? Colors.white.withOpacity(0.15) 
              : isHovered ? Colors.white.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Icon(
            widget.icon, 
            color: widget.isSelected ? Colors.white : Colors.white70,
            size: 22,
          ),
          title: Text(
            widget.title,
            style: TextStyle(
              color: widget.isSelected ? Colors.white : Colors.white70,
              fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 15,
            ),
          ),
          onTap: () {
            if (!widget.isSelected) {
              Get.offNamed(widget.route);
            }
          },
        ),
      ),
    );
  }
}
