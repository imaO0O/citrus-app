import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/theme/app_colors.dart';
import '../../../core/config/api_config.dart';
import '../../../core/utils/app_size.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;

  ResetPasswordPage({super.key, required this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final code = _codeController.text.trim();
    final newPassword = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Введите код из email'),
          backgroundColor: AppColors.destructive,
        ),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Пароль должен быть не менее 6 символов'),
          backgroundColor: AppColors.destructive,
        ),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Пароли не совпадают'),
          backgroundColor: AppColors.destructive,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'code': code,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Пароль успешно изменён!'),
              backgroundColor: AppColors.citrusGreen,
            ),
          );
          // Возвращаемся на экран входа
          Navigator.of(context).pop(); // ResetPasswordPage
          Navigator.of(context).pop(); // ForgotPasswordPage
        }
      } else {
        final body = jsonDecode(response.body);
        final message = body is Map ? (body['body'] ?? body['message'] ?? 'Ошибка') : 'Ошибка';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message.toString()),
              backgroundColor: AppColors.destructive,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка соединения: $e'),
            backgroundColor: AppColors.destructive,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.foreground),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSize.padding(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Иконка
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: AppSize.radius(20),
                      gradient: LinearGradient(
                        colors: [AppColors.citrusOrange, AppColors.citrusAmber],
                      ),
                    ),
                    child: Center(
                      child: Icon(Icons.key, color: Colors.white, size: 32),
                    ),
                  ),
                  AppSize.gapH(24),
                  Text(
                    'Новый пароль',
                    style: TextStyle(
                      fontSize: AppSize.s(28),
                      fontWeight: FontWeight.w700,
                      color: AppColors.foreground,
                    ),
                  ),
                  AppSize.gapH(8),
                  Text(
                    'Введите код из email и задайте новый пароль для аккаунта ${widget.email}',
                    style: TextStyle(
                      fontSize: AppSize.s(14),
                      color: AppColors.mutedForeground,
                      height: 1.5,
                    ),
                  ),
                  AppSize.gapH(32),

                  // Код
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Код подтверждения',
                        style: TextStyle(
                          fontSize: AppSize.s(12),
                          fontWeight: FontWeight.w500,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                      AppSize.gapH(6),
                      TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: AppSize.s(24),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 8,
                          color: AppColors.citrusOrange,
                        ),
                        decoration: InputDecoration(
                          hintText: '000000',
                          hintStyle: TextStyle(
                            fontSize: AppSize.s(24),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 8,
                            color: AppColors.mutedForeground.withOpacity(0.3),
                          ),
                          filled: true,
                          fillColor: AppColors.inputFieldBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSize.s(AppColors.radius)),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: AppSize.paddingH(16, 14),
                        ),
                        maxLength: 6,
                      ),
                    ],
                  ),
                  AppSize.gapH(16),

                  // Новый пароль
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Новый пароль',
                        style: TextStyle(
                          fontSize: AppSize.s(12),
                          fontWeight: FontWeight.w500,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                      AppSize.gapH(6),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Минимум 6 символов',
                          filled: true,
                          fillColor: AppColors.inputFieldBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSize.s(AppColors.radius)),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: AppSize.paddingH(16, 14),
                          prefixIcon: Icon(Icons.lock_outlined, color: AppColors.mutedForeground, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: AppColors.mutedForeground,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        style: TextStyle(fontSize: AppSize.s(15), color: AppColors.foreground),
                      ),
                    ],
                  ),
                  AppSize.gapH(16),

                  // Подтверждение пароля
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Подтвердите пароль',
                        style: TextStyle(
                          fontSize: AppSize.s(12),
                          fontWeight: FontWeight.w500,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                      AppSize.gapH(6),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          hintText: 'Повторите пароль',
                          filled: true,
                          fillColor: AppColors.inputFieldBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSize.s(AppColors.radius)),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: AppSize.paddingH(16, 14),
                          prefixIcon: Icon(Icons.lock_outlined, color: AppColors.mutedForeground, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: AppColors.mutedForeground,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        style: TextStyle(fontSize: AppSize.s(15), color: AppColors.foreground),
                      ),
                    ],
                  ),
                  AppSize.gapH(24),

                  // Кнопка
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: _isLoading
                          ? null
                          : LinearGradient(
                              colors: [AppColors.citrusOrange, AppColors.citrusAmber],
                            ),
                      color: _isLoading ? AppColors.citrusOrange.withOpacity(0.3) : null,
                      borderRadius: BorderRadius.circular(AppSize.s(AppColors.radius)),
                      boxShadow: _isLoading
                          ? null
                          : [
                              BoxShadow(
                                color: AppColors.glowOrange,
                                blurRadius: 20,
                                offset: Offset(0, 4),
                              ),
                            ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSize.s(AppColors.radius)),
                        ),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          : Text(
                              'Сбросить пароль',
                              style: TextStyle(fontSize: AppSize.s(16), fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
