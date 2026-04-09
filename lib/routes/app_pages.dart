import 'package:get/get.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/register_page.dart';

class AppPages {
  static const INITIAL = '/login';

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
  ];
}
