// auth_bloc.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:baidoxe/model/user_model.dart';
import 'package:baidoxe/services/supabase_service.dart';

// Events
abstract class AuthEvent {}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;
  LoginEvent({required this.email, required this.password});
}

class RegisterEvent extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  final String phone;
  RegisterEvent({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phone,
  });
}

class LogoutEvent extends AuthEvent {}

// States
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  AuthAuthenticated({required this.user});
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError({required this.message});
}
class SessionRestoredEvent extends AuthEvent {
  final UserModel user;
  SessionRestoredEvent({required this.user});
}
// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SupabaseService _supabaseService = SupabaseService();
  AuthBloc() : super(AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<RegisterEvent>(_onRegister);
    on<LogoutEvent>(_onLogout);

    // 2. Đăng ký xử lý Event mới
    on<SessionRestoredEvent>((event, emit) {
      emit(AuthAuthenticated(user: event.user));
    });

    _checkCurrentSession();
  }

  void _checkCurrentSession() {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      debugPrint('🔐 [SESSION CHECK] Đã có session active cho user: ${session.user.email}');
      _loadUserProfile(session.user.id);
    } else {
      debugPrint('🔐 [SESSION CHECK] Không có session active');
    }
  }

  Future<void> _loadUserProfile(String userId) async {
    try {
      final userProfile = await _getUserProfile(userId);
      if (userProfile != null) {
        final user = UserModel(
          id: userId,
          email: userProfile['email'] ?? '',
          fullName: userProfile['full_name'] ?? '',
          phone: userProfile['phone'] ?? '',
          role: userProfile['role'] ?? 'user',
          balance: userProfile['balance'] ?? 0,
        );
        add(LoginEvent(email: user.email, password: ''));
      }
    } catch (e) {
      debugPrint('❌ [LOAD PROFILE ERROR] $e');
    }
  }

  // THÊM METHOD NÀY VÀO ĐÂY
  Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    try {
      debugPrint('🔍 [SUPABASE SERVICE] Đang lấy profile cho user: $userId');

      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        // Đảm bảo balance là số
        if (response.containsKey('balance') && response['balance'] is String) {
          response['balance'] = num.tryParse(response['balance'] as String) ?? 0;
        }
        debugPrint('✅ [SUPABASE SERVICE] Tìm thấy profile: ${response['full_name']}');
        return response;
      } else {
        debugPrint('⚠️ [SUPABASE SERVICE] Không tìm thấy profile cho user: $userId');

        // Thử tạo profile mới nếu chưa có
        final userData = Supabase.instance.client.auth.currentUser;
        if (userData != null) {
          debugPrint('🔄 [SUPABASE SERVICE] Đang thử tạo profile mới...');
          final newProfile = {
            'id': userId,
            'email': userData.email,
            'phone': '',
            'full_name': userData.email?.split('@').first ?? 'User',
            'role': 'user',
            'balance': 0,
            'created_at': DateTime.now().toIso8601String(),
          };

          await Supabase.instance.client
              .from('profiles')
              .insert(newProfile);

          debugPrint('✅ [SUPABASE SERVICE] Tạo profile mới thành công');
          return newProfile;
        }
        return null;
      }
    } catch (e) {
      debugPrint('❌ [SUPABASE SERVICE] Lỗi khi lấy profile: $e');

      // Trả về profile tạm thời để đăng nhập vẫn thành công
      return {
        'id': userId,
        'email': userId,
        'full_name': 'User',
        'phone': '',
        'role': 'user',
        'balance': 0,
      };
    }
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    debugPrint('📡 [SUPABASE] Bắt đầu đăng nhập với email: ${event.email}');

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: event.email,
        password: event.password,
      );

      if (response.user == null) {
        debugPrint('❌ [SUPABASE] User null after login');
        emit(AuthError(message: 'Đăng nhập thất bại'));
        return;
      }

      debugPrint('✅ [SUPABASE] Đăng nhập thành công - User ID: ${response.user!.id}');
      debugPrint('📧 [SUPABASE] Email: ${response.user!.email}');

      // Lấy thông tin profile với xử lý lỗi kiểu dữ liệu
      Map<String, dynamic>? userProfile;
      try {
        userProfile = await _getUserProfile(response.user!.id);
        debugPrint('👤 [SUPABASE] Profile loaded - Name: ${userProfile?['full_name']}, Role: ${userProfile?['role']}');
      } catch (e) {
        debugPrint('⚠️ [SUPABASE] Lỗi load profile: $e');
      }

      // Xử lý balance an toàn
      num balanceNum = 0;
      if (userProfile?['balance'] != null) {
        final balanceValue = userProfile!['balance'];
        if (balanceValue is num) {
          balanceNum = balanceValue;
        } else if (balanceValue is String) {
          balanceNum = num.tryParse(balanceValue) ?? 0;
        } else if (balanceValue is int) {
          balanceNum = balanceValue;
        }
      }

      final user = UserModel(
        id: response.user!.id,
        email: response.user!.email ?? event.email,
        fullName: userProfile?['full_name']?.toString() ?? event.email.split('@')[0],
        phone: userProfile?['phone']?.toString() ?? '',
        role: userProfile?['role']?.toString() ?? 'user',
        balance: balanceNum,
      );

      debugPrint('✅ [LOGIN] User created - Balance: ${user.balance} (${user.balance.runtimeType})');
      emit(AuthAuthenticated(user: user));

    } catch (e) {
      debugPrint('❌ [SUPABASE] Lỗi đăng nhập: $e');
      debugPrint('❌ [SUPABASE] Stack trace: ${StackTrace.current}');
      emit(AuthError(message: 'Sai email hoặc mật khẩu'));
    }
  }

  Future<void> _onRegister(RegisterEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    debugPrint('📡 [SUPABASE] Bắt đầu đăng ký tài khoản mới');
    debugPrint('📝 [SUPABASE] Thông tin đăng ký:');
    debugPrint('   - Email: ${event.email}');
    debugPrint('   - Họ tên: ${event.fullName}');
    debugPrint('   - SĐT: ${event.phone}');

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: event.email,
        password: event.password,
        data: {
          'full_name': event.fullName,
          'phone': event.phone,
          'role': 'user',
          'balance': 0,
        },
      );

      debugPrint('✅ [SUPABASE] Đăng ký Auth thành công - User ID: ${response.user?.id}');

      if (response.user != null) {
        // Đảm bảo balance là number, không phải string
        final profileData = {
          'id': response.user!.id,
          'email': event.email,
          'phone': event.phone,
          'full_name': event.fullName,
          'role': 'user',
          'balance': 0,
          'created_at': DateTime.now().toIso8601String(),
        };

        debugPrint('📝 [SUPABASE] Đang tạo profile: $profileData');

        try {
          await _supabaseService.createUserProfile(profileData);
          debugPrint('✅ [SUPABASE] Tạo profile thành công');
        } catch (profileError) {
          debugPrint('⚠️ [SUPABASE] Lỗi tạo profile: $profileError');
          // Không throw lỗi, vẫn cho đăng ký thành công
        }

        final user = UserModel(
          id: response.user!.id,
          email: event.email,
          fullName: event.fullName,
          phone: event.phone,
          role: 'user',
          balance: 0,
        );

        debugPrint('🎉 [SUPABASE] Đăng ký hoàn tất! User: ${user.fullName}');
        emit(AuthAuthenticated(user: user));
      } else {
        debugPrint('⚠️ [SUPABASE] User null sau khi đăng ký');
        emit(AuthError(message: 'Đăng ký thất bại, vui lòng thử lại'));
      }

    } catch (e) {
      debugPrint('❌ [SUPABASE] Lỗi đăng ký chi tiết: $e');

      String errorMessage = 'Đăng ký thất bại';
      if (e.toString().contains('already registered')) {
        errorMessage = 'Email đã được đăng ký';
        debugPrint('⚠️ [SUPABASE] Email đã tồn tại trong hệ thống');
      } else if (e.toString().contains('password')) {
        errorMessage = 'Mật khẩu không hợp lệ';
      }

      emit(AuthError(message: errorMessage));
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    debugPrint('🚪 [SUPABASE] Đang đăng xuất...');
    await Supabase.instance.client.auth.signOut();
    debugPrint('✅ [SUPABASE] Đã đăng xuất thành công');
    emit(AuthUnauthenticated());
  }
}