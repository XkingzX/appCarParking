import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import '../../../../core/theme.dart';
import 'package:baidoxe/features/auth/presentation/bloc/auth_bloc.dart';
import '../../customer/home/presentation/customer_home_page.dart';
import '../../guard/home/presentation/guard_home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Khai báo controller ở cấp độ class
  late final TextEditingController emailController;
  late final TextEditingController passwordController;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    // Bắt buộc phải giải phóng bộ nhớ
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            // In log thành công
            debugPrint('✅ [LOGIN SUCCESS] User: ${state.user.email}, Role: ${state.user.role}');

            // Chuyển hướng dựa trên role
            if (state.user.role == 'guard') {
              Get.offAll(() => const GuardHomePage());
            } else {
              Get.offAll(() => const CustomerHomePage());
            }
          } else if (state is AuthError) {
            // In log lỗi
            debugPrint('❌ [LOGIN ERROR] ${state.message}');
            Get.snackbar(
              'Đăng nhập thất bại',
              state.message,
              backgroundColor: Colors.red,
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 3),
            );
          }
        },
        child: Stack(
          children: [
            // Background Gradient Header
            Container(
              height: size.height * 0.45,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

            // Form Content
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 60.0, left: 24.0, right: 24.0, bottom: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo & Header
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        child: const Icon(
                          Icons.local_parking_rounded,
                          size: 70,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'EggsySmart Parking',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Quản lý đỗ xe thông minh',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8)),
                    ),

                    const SizedBox(height: 48),

                    // Floating White Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withOpacity(0.1),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Đăng nhập',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                          ),
                          const SizedBox(height: 24),

                          // Email Field
                          TextField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.alternate_email),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Password Field
                          TextField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Mật khẩu',
                              prefixIcon: Icon(Icons.lock_outline_rounded),
                              suffixIcon: Icon(Icons.visibility_off_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                            ),
                          ),

                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                debugPrint('🔍 [FORGOT PASSWORD] User requested password reset');
                                Get.snackbar(
                                  'Thông báo',
                                  'Tính năng đang phát triển',
                                  backgroundColor: Colors.orange,
                                  colorText: Colors.white,
                                );
                              },
                              child: const Text('Quên mật khẩu?', style: TextStyle(color: AppTheme.accentBlue, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Login Button
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              return ElevatedButton(
                                onPressed: state is AuthLoading
                                    ? null
                                    : () {
                                  final email = emailController.text.trim();
                                  final password = passwordController.text.trim();

                                  debugPrint('🔄 [LOGIN ATTEMPT] Email: $email');

                                  if (email.isEmpty || password.isEmpty) {
                                    debugPrint('⚠️ [LOGIN VALIDATION] Email hoặc mật khẩu trống');
                                    Get.snackbar(
                                      'Lỗi',
                                      'Vui lòng nhập đầy đủ email và mật khẩu',
                                      backgroundColor: Colors.orange,
                                      colorText: Colors.white,
                                    );
                                    return;
                                  }

                                  if (!email.contains('@') || !email.contains('.')) {
                                    debugPrint('⚠️ [LOGIN VALIDATION] Email không hợp lệ');
                                    Get.snackbar(
                                      'Lỗi',
                                      'Email không hợp lệ',
                                      backgroundColor: Colors.orange,
                                      colorText: Colors.white,
                                    );
                                    return;
                                  }

                                  context.read<AuthBloc>().add(
                                      LoginEvent(email: email, password: password)
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: state is AuthLoading
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                    : const Text('ĐĂNG NHẬP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              );
                            },
                          ),

                          const SizedBox(height: 24),

                          // Register Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Chưa có tài khoản? ", style: TextStyle(color: AppTheme.textLight)),
                              GestureDetector(
                                onTap: () {
                                  debugPrint('🔀 [NAVIGATION] Chuyển đến trang đăng ký');
                                  Get.toNamed('/register');
                                },
                                child: const Text(
                                  'Tạo ngay',
                                  style: TextStyle(
                                    color: AppTheme.accentBlue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Test area footer
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            '-- Developer Test Access --',
                            style: TextStyle(color: AppTheme.textLight, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildTestBtn(Icons.person, 'Customer', () {
                                debugPrint('🧪 [TEST MODE] Đăng nhập với tài khoản Customer mẫu');
                                emailController.text = 'customer@test.com';
                                passwordController.text = '123456';
                                context.read<AuthBloc>().add(
                                    LoginEvent(
                                        email: 'customer@test.com',
                                        password: '123456'
                                    )
                                );
                              }),
                              _buildTestBtn(Icons.security, 'Guard', () {
                                debugPrint('🧪 [TEST MODE] Đăng nhập với tài khoản Guard mẫu');
                                emailController.text = 'guard@test.com';
                                passwordController.text = '123456';
                                context.read<AuthBloc>().add(
                                    LoginEvent(
                                        email: 'guard@test.com',
                                        password: '123456'
                                    )
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestBtn(IconData icon, String label, VoidCallback onTap) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: AppTheme.primaryBlue),
      label: Text(label, style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
      style: TextButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}