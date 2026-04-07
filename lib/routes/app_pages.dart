import 'package:get/get.dart';
import 'package:flutter/material.dart';

class AppPages {
  static const INITIAL = '/';

  static final routes = [
    GetPage(
      name: '/',
      page: () => const Scaffold(
        body: Center(child: Text('Smart Parking App - Splash/Auth here')),
      ),
    ),
  ];
}
