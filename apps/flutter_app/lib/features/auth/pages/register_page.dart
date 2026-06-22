import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/storage_service.dart';
import '../bloc/auth_bloc.dart';
import '../../../core/utils/app_size.dart';

class RegisterPage extends StatefulWidget {
  RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // После успешной регистрации переходим на главную
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/');
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.foreground),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Регистрация',
            style: TextStyle(
              color: AppColors.foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: AppSize.padding(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: AppSize.radius(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.citrusOrange, AppColors.citrusAmber],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.glowOrange,
                              blurRadius: 20,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '🍊',
                            style: TextStyle(fontSize: AppSize.s(32)),
                          ),
                        ),
                      ),
                    ),
                    AppSize.gapH(24),
                    Text(
                      'Создать аккаунт',
                      style: TextStyle(
                        fontSize: AppSize.s(24),
                        fontWeight: FontWeight.w700,
                        color: AppColors.foreground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    AppSize.gapH(8),
                    Text(
                      'Присоединяйтесь к Цитрусу',
                      style: TextStyle(
                        fontSize: AppSize.s(14),
                        color: AppColors.mutedForeground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    AppSize.gapH(32),
                    
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
                    
                    // Name field
                    _buildTextField(
                      controller: _nameController,
                      label: 'Имя',
                      hint: 'Введите ваше имя (необязательно)',
                      prefixIcon: Icons.person_outlined,
                    ),
                    AppSize.gapH(16),
                    
                    // Password field
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Пароль',
                      hint: 'Придумайте пароль (минимум 6 символов)',
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
                    
                    // Confirm password field
                    _buildTextField(
                      controller: _confirmPasswordController,
                      label: 'Подтвердите пароль',
                      hint: 'Введите пароль ещё раз',
                      prefixIcon: Icons.lock_outlined,
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.mutedForeground,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Подтвердите пароль';
                        }
                        if (value != _passwordController.text) {
                          return 'Пароли не совпадают';
                        }
                        return null;
                      },
                    ),
                    AppSize.gapH(16),
                    
                    // Terms checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _agreedToTerms,
                            onChanged: (value) {
                              setState(() {
                                _agreedToTerms = value ?? false;
                              });
                            },
                            activeColor: AppColors.citrusOrange,
                            checkColor: Colors.white,
                            side: BorderSide(color: AppColors.mutedForeground),
                          ),
                        ),
                        AppSize.gapW(8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _agreedToTerms = !_agreedToTerms;
                              });
                            },
                            child: RichText(
                              text: TextSpan(
                                text: 'Я согласен с ',
                                style: TextStyle(
                                  fontSize: AppSize.s(13),
                                  color: AppColors.mutedForeground,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'условиями использования',
                                    style: TextStyle(
                                      color: AppColors.citrusOrange,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' и ',
                                    style: TextStyle(
                                      color: AppColors.mutedForeground,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'политикой конфиденциальности',
                                    style: TextStyle(
                                      color: AppColors.citrusOrange,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSize.gapH(24),
                    
                    // Register button
                    BlocConsumer<AuthBloc, AuthState>(
                      listener: (context, state) {
                        if (state is AuthError) {
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
                      builder: (context, state) {
                        if (state is AuthLoading) {
                          return Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.citrusOrange.withValues(alpha: 0.3),
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
                            onPressed: _agreedToTerms ? _handleRegister : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.transparent,
                              disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSize.s(AppColors.radius)),
                              ),
                            ),
                            child: Text(
                              'Зарегистрироваться',
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
                    
                    // Login link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Уже есть аккаунт? ',
                          style: TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: AppSize.s(14),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            'Войти',
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

  Future<void> _handleRegister() async {
    debugPrint('=== Регистрация ===');
    debugPrint('Email: ${_emailController.text.trim()}');
    debugPrint('Имя: ${_nameController.text.trim()}');

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Необходимо согласиться с условиями использования'),
          backgroundColor: AppColors.destructive,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSize.s(AppColors.radius)),
          ),
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      debugPrint('Форма валидна, отправляем...');
      
      // При регистрации по умолчанию запоминаем сессию
      final storage = StorageService();
      await storage.setString('remember_me', 'true');
      
      if (!mounted) return;
      context.read<AuthBloc>().add(AuthRegister(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim().isEmpty
                ? null
                : _nameController.text.trim(),
          ));
    } else {
      debugPrint('Форма не валидна');
    }
  }
}
