import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/storage_service.dart';
import '../bloc/auth_bloc.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';
import '../../../core/utils/app_size.dart';

class LoginPage extends StatefulWidget {
  LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  final StorageService _storage = StorageService();

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final savedEmail = await _storage.getString('saved_email');
    final savedPassword = await _storage.getString('saved_password');
    final rememberMe = await _storage.getString('remember_me');
    
    if (savedEmail != null && rememberMe == 'true') {
      setState(() {
        _emailController.text = savedEmail;
        if (savedPassword != null) {
          _passwordController.text = savedPassword;
        }
        _rememberMe = true;
      });
    }
  }

  Future<void> _saveCredentials() async {
    if (_rememberMe) {
      await _storage.setString('saved_email', _emailController.text.trim());
      await _storage.setString('saved_password', _passwordController.text);
    } else {
      await _storage.remove('saved_email');
      await _storage.remove('saved_password');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        print('LoginPage BlocListener: state = $state');
        if (state is AuthAuthenticated) {
          print('LoginPage: Успешный вход, переходим на главную');
          _saveCredentials();
          // После успешного входа переходим на главную
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/');
          });
        } else if (state is AuthError) {
          print('LoginPage: Ошибка входа: ${state.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.destructive,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSize.s(AppColors.radius)),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: AppSize.padding(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: AppSize.radius(24),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.citrusOrange, AppColors.citrusAmber],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.glowOrange,
                              blurRadius: 30,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '🍊',
                            style: TextStyle(fontSize: AppSize.s(40)),
                          ),
                        ),
                      ),
                      AppSize.gapH(24),
                      Text(
                        'Цитрус',
                        style: TextStyle(
                          fontSize: AppSize.s(32),
                          fontWeight: FontWeight.w700,
                          color: AppColors.foreground,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      AppSize.gapH(8),
                      Text(
                        'Ваш персональный помощник',
                        style: TextStyle(
                          fontSize: AppSize.s(14),
                          color: AppColors.mutedForeground,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      AppSize.gapH(48),
                      
                      // Email field
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'Введите ваш email',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите email';
                          }
                          if (!value.contains('@')) {
                            return 'Введите корректный email';
                          }
                          return null;
                        },
                      ),
                      AppSize.gapH(16),
                      
                      // Password field
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Пароль',
                        hint: 'Введите ваш пароль',
                        prefixIcon: Icons.lock_outlined,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.mutedForeground,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите пароль';
                          }
                          if (value.length < 6) {
                            return 'Пароль должен быть не менее 6 символов';
                          }
                          return null;
                        },
                      ),
                      AppSize.gapH(16),
                      
                      // Remember me checkbox
                      Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                              activeColor: AppColors.citrusOrange,
                              checkColor: Colors.white,
                              side: BorderSide(color: AppColors.mutedForeground),
                            ),
                          ),
                          AppSize.gapW(8),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _rememberMe = !_rememberMe;
                              });
                            },
                            child: Text(
                              'Запомнить меня',
                              style: TextStyle(
                                fontSize: AppSize.s(14),
                                color: AppColors.foreground,
                              ),
                            ),
                          ),
                          Spacer(),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ForgotPasswordPage(),
                                ),
                              );
                            },
                            child: Text(
                              'Забыли пароль?',
                              style: TextStyle(
                                fontSize: AppSize.s(13),
                                color: AppColors.citrusOrange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      AppSize.gapH(24),
                      
                      // Login button
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          print('LoginPage BlocBuilder: state = $state');
                          if (state is AuthLoading) {
                            return Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.citrusOrange.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(AppSize.s(AppColors.radius)),
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }
                          return Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.citrusOrange, AppColors.citrusAmber],
                              ),
                              borderRadius: BorderRadius.circular(AppSize.s(AppColors.radius)),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.glowOrange,
                                  blurRadius: 20,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppSize.s(AppColors.radius)),
                                ),
                              ),
                              child: Text(
                                'Войти',
                                style: TextStyle(
                                  fontSize: AppSize.s(16),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      AppSize.gapH(24),
                      
                      // Register link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Нет аккаунта? ',
                            style: TextStyle(
                              color: AppColors.mutedForeground,
                              fontSize: AppSize.s(14),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RegisterPage(),
                                ),
                              );
                            },
                            child: Text(
                              'Зарегистрироваться',
                              style: TextStyle(
                                color: AppColors.citrusOrange,
                                fontSize: AppSize.s(14),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppSize.s(12),
            fontWeight: FontWeight.w500,
            color: AppColors.foreground,
          ),
        ),
        AppSize.gapH(8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: TextStyle(
            color: AppColors.foreground,
            fontSize: AppSize.s(14),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.mutedForeground,
              fontSize: AppSize.s(14),
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: AppColors.mutedForeground,
              size: 20,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.surface1,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSize.s(AppColors.radius)),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSize.s(AppColors.radius)),
              borderSide: BorderSide(
                color: AppColors.subtleBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSize.s(AppColors.radius)),
              borderSide: BorderSide(
                color: AppColors.citrusOrange,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSize.s(AppColors.radius)),
              borderSide: BorderSide(
                color: AppColors.destructive,
              ),
            ),
            contentPadding: AppSize.paddingH(16, 16),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Future<void> _handleLogin() async {
    print('=== Вход ===');
    print('Email: ${_emailController.text.trim()}');
    print('Пароль: ${_passwordController.text}');
    print('Запомнить меня: $_rememberMe');
    
    if (_formKey.currentState!.validate()) {
      print('Форма валидна, отправляем...');
      
      // Сохраняем флаг remember_me перед входом
      await _storage.setString('remember_me', _rememberMe.toString());
      
      // Если не хотим запоминать - очищаем сохранённые credentials
      if (!_rememberMe) {
        await _storage.remove('saved_email');
        await _storage.remove('saved_password');
      }
      
      context.read<AuthBloc>().add(AuthLogin(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ));
    } else {
      print('Форма не валидна');
    }
  }
}
