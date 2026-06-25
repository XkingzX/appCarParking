import 'package:get/get.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/register_page.dart';

// Web Admin Imports
import '../features/web_admin/dashboard/admin_dashboard_page.dart';
import '../features/web_admin/dashboard/owner_dashboard_page.dart';
import '../features/web_admin/parking/parking_list_page.dart';
import '../features/web_admin/parking/parking_detail_page.dart';
import '../features/web_admin/parking/parking_form_page.dart';
import '../features/web_admin/owner/owner_management_page.dart';
import '../features/web_admin/booking/booking_management_page.dart';
import '../features/web_admin/revenue/revenue_page.dart';
import '../features/guard/home/presentation/guard_home_page.dart';
import '../features/guard/scanner/presentation/scanner_page.dart';
import '../features/web_admin/presentation/admin_verification_page.dart';
import '../features/web_admin/web_admin_layout.dart';
import '../features/web_admin/simulation/traffic_simulation_page.dart';
import '../features/web_admin/simulation/traffic_simulation_form_page.dart';

class AppPages {
  static const INITIAL = '/login';

  static String _getRole() => Get.arguments?['role'] ?? 'admin';

  static final routes = [
    GetPage(
      name: '/login',
      page: () => const LoginPage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: '/register',
      page: () => const RegisterPage(),
      transition: Transition.rightToLeft,
    ),
    // --- WEB ADMIN ROUTES ---
    GetPage(
      name: '/web-admin/admin-dashboard',
      page: () => AdminDashboardPage(role: _getRole()),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: '/web-admin/owner-dashboard',
      page: () => OwnerDashboardPage(role: _getRole()),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: '/web-admin/parking',
      page: () => ParkingListPage(role: _getRole()),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: '/web-admin/parking/detail',
      page: () => ParkingDetailPage(role: _getRole()),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: '/web-admin/parking/form',
      page: () => ParkingFormPage(role: _getRole()),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: '/web-admin/owner',
      page: () => OwnerManagementPage(role: _getRole()),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: '/web-admin/booking',
      page: () => BookingManagementPage(role: _getRole()),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: '/web-admin/revenue',
      page: () => RevenuePage(role: _getRole()),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: '/web-admin/traffic',
      page: () => TrafficSimulationPage(role: _getRole()),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: '/web-admin/traffic/form',
      page: () => TrafficSimulationFormPage(role: _getRole()),
      transition: Transition.noTransition,
    ),
    // Guard Specific Routes within Web Admin
    GetPage(
      name: '/web-admin/guard-scanner',
      page: () => WebAdminLayout(
        role: 'guard',
        currentRoute: '/web-admin/guard-scanner',
        child: const ScannerPage(isCheckIn: true), // Assuming ScannerPage doesn't take parameters directly in constructor, or we adapt it
      ),
      transition: Transition.noTransition,
    ),
    GetPage(
      name: '/web-admin/guard-verification',
      page: () => WebAdminLayout(
        role: 'guard',
        currentRoute: '/web-admin/guard-verification',
        child: const AdminVerificationPage(),
      ),
      transition: Transition.noTransition,
    ),
  ];
}
