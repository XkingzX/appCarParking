import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:baidoxe/core/theme.dart';

class Topbar extends StatelessWidget {
  final String role;
  final VoidCallback onMenuPressed;

  const Topbar({
    Key? key,
    required this.role,
    required this.onMenuPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: AppTheme.textDark),
            onPressed: onMenuPressed,
          ),
          const SizedBox(width: 20),
          
          // Search Bar
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: const Row(
                children: [
                  Icon(Icons.search, color: AppTheme.textLight, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm toàn hệ thống...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        filled: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 20),

          // Theme Toggle
          IconButton(
            icon: const Icon(Icons.dark_mode_outlined, color: AppTheme.textDark),
            tooltip: 'Giao diện Tối/Sáng',
            onPressed: () {
              Get.snackbar('Tính năng đang phát triển', 'Chuyển đổi DarkMode sẽ sớm có mặt!');
            },
          ),
          const SizedBox(width: 10),
          
          // Notifications
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppTheme.textDark),
                onPressed: () {},
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            ],
          ),
          
          const SizedBox(width: 15),
          
          // Profile
          Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'My Account',
                    style: TextStyle(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    role.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.textLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              const CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.accentBlue,
                child: Icon(Icons.person, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
