import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:baidoxe/core/theme.dart';

class VehiclePendingPage extends StatelessWidget {
  const VehiclePendingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Icon or Animation
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_empty_rounded,
                  size: 100,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 32),
              
              // Text Content
              const Text(
                'Đang chờ xác minh',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Hệ thống đang kiểm tra thông tin giấy phép lái xe và giấy tờ tùy thân của bạn.\nQuá trình này dự kiến mất từ 5 - 10 phút.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textLight,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              
              // Loading Indicator
              const CircularProgressIndicator(color: Colors.orange),
              
              const Spacer(),
              
              // Button
              ElevatedButton(
                onPressed: () {
                  // Quay về trang chủ / Dashboard
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: AppTheme.primaryBlue,
                ),
                child: const Text('QUAY VỀ TÀI KHOẢN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
