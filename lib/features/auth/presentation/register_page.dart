// register_page.dart (phiên bản 2 ô riêng biệt)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import '../../../../core/theme.dart';
import 'package:baidoxe/features/auth/presentation/bloc/auth_bloc.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RegisterPageContent();
  }
}

class RegisterPageContent extends StatefulWidget {
  const RegisterPageContent({super.key});

  @override
  State<RegisterPageContent> createState() => _RegisterPageContentState();
}

class _RegisterPageContentState extends State<RegisterPageContent> {
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            debugPrint('🔙 [NAVIGATION] Quay lại trang đăng nhập');
            Get.back();
          },
        ),
        title: const Text('Đăng ký',
          style: TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 1.5,
        ),),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            debugPrint('✅ [REGISTER SUCCESS] User: ${state.user.email}');
            Get.snackbar(
              'Đăng ký thành công 🎉',
              'Chào mừng bạn đến với Gay Parking!',
              backgroundColor: Colors.green,
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 3),
            );

            Future.delayed(const Duration(seconds: 2), () {
              Get.offAllNamed('/login');
            });
          } else if (state is AuthError) {
            debugPrint('❌ [REGISTER ERROR] ${state.message}');
            Get.snackbar(
              'Đăng ký thất bại',
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
              height: size.height * 0.35,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 20.0, left: 24.0, right: 24.0, bottom: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),

                    // Floating Card
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
                          // Email
                          TextField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email *',
                              prefixIcon: Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                              hintText: 'Vui lòng nhập email hợp lệ',
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Password
                          TextField(
                            controller: passwordController,
                            obscureText: obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Mật khẩu *',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscurePassword ? Icons.visibility_off : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    obscurePassword = !obscurePassword;
                                  });
                                },
                              ),
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                              hintText: 'Mật khẩu phải có ít nhất 6 ký tự',
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Confirm Password
                          TextField(
                            controller: confirmPasswordController,
                            obscureText: obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'Nhập lại mật khẩu *',
                              prefixIcon: const Icon(Icons.lock_reset_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    obscureConfirmPassword = !obscureConfirmPassword;
                                  });
                                },
                              ),
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 52),

                          // Register Button
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              return ElevatedButton(
                                onPressed: state is AuthLoading
                                    ? null
                                    : () {
                                  _handleRegister(context);
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
                                    : const Text('ĐĂNG KÝ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              );
                            },
                          ),

                          const SizedBox(height: 24),
                          const Row(
                            children: [
                              Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text('HOẶC', style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Google Sign Up
                          OutlinedButton.icon(
                            onPressed: () {
                              debugPrint('🔐 [GOOGLE AUTH] Người dùng chọn đăng ký với Google');
                              Get.snackbar(
                                'Thông báo',
                                'Tính năng đang phát triển',
                                backgroundColor: Colors.orange,
                                colorText: Colors.white,
                              );
                            },
                            icon: const Icon(Icons.login, color: Colors.red),
                            label: const Text('Tiếp tục với Google', style: TextStyle(fontSize: 16, color: AppTheme.textDark, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.white,
                              side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Login Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Đã có tài khoản? ", style: TextStyle(color: AppTheme.textLight)),
                              GestureDetector(
                                onTap: () {
                                  debugPrint('🔀 [NAVIGATION] Chuyển đến trang đăng nhập');
                                  Get.back();
                                },
                                child: const Text(
                                  'Đăng nhập',
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleRegister(BuildContext context) {
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    debugPrint('🔄 [REGISTER ATTEMPT] Email: $email, Phone: $phone');

    // Validation
    if (email.isEmpty) {
      debugPrint('⚠️ [REGISTER VALIDATION] Thiếu email');
      Get.snackbar('Lỗi', 'Vui lòng nhập email', backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    // Kiểm tra định dạng email
    bool isValidEmail = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
    if (!isValidEmail) {
      debugPrint('⚠️ [REGISTER VALIDATION] Email không hợp lệ');
      Get.snackbar('Lỗi', 'Email không hợp lệ', backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    if (password.isEmpty) {
      debugPrint('⚠️ [REGISTER VALIDATION] Thiếu mật khẩu');
      Get.snackbar('Lỗi', 'Vui lòng nhập mật khẩu', backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    if (password.length < 6) {
      debugPrint('⚠️ [REGISTER VALIDATION] Mật khẩu quá ngắn');
      Get.snackbar('Lỗi', 'Mật khẩu phải có ít nhất 6 ký tự', backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    if (password != confirmPassword) {
      debugPrint('⚠️ [REGISTER VALIDATION] Mật khẩu không khớp');
      Get.snackbar('Lỗi', 'Mật khẩu xác nhận không khớp', backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    // Set full_name = email (hoặc có thể là email nếu muốn)
    final fullName = email.split('@')[0]; // Lấy phần trước @ làm tên hiển thị

    context.read<AuthBloc>().add(
        RegisterEvent(
          email: email,
          password: password,
          fullName: fullName,
          phone: phone,
        )
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}