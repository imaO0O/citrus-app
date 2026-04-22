import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/theme/app_colors.dart';
import '../../../core/config/api_config.dart';
import 'reset_password_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _codeSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите корректный email'),
          backgroundColor: AppColors.destructive,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        setState(() => _codeSent = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Код отправлен на ваш email'),
              backgroundColor: AppColors.citrusGreen,
            ),
          );
          // Переходим на экран ввода кода
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ResetPasswordPage(email: email),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка: ${response.statusCode}'),
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
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Иконка
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [AppColors.citrusOrange, AppColors.citrusAmber],
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.lock_reset, color: Colors.white, size: 32),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Сброс пароля',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.foreground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Введите email вашего аккаунта. Мы отправим код подтверждения для установки нового пароля.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.mutedForeground,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Email
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Введите ваш email',
                          filled: true,
                          fillColor: AppColors.inputFieldBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppColors.radius),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          prefixIcon: Icon(Icons.email_outlined, color: AppColors.mutedForeground, size: 20),
                        ),
                        style: TextStyle(fontSize: 15, color: AppColors.foreground),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Кнопка отправки
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: _isLoading
                          ? null
                          : const LinearGradient(
                              colors: [AppColors.citrusOrange, AppColors.citrusAmber],
                            ),
                      color: _isLoading ? AppColors.citrusOrange.withOpacity(0.3) : null,
                      borderRadius: BorderRadius.circular(AppColors.radius),
                      boxShadow: _isLoading
                          ? null
                          : [
                              BoxShadow(
                                color: AppColors.glowOrange,
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppColors.radius),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          : const Text(
                              'Отправить код',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Назад
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Вспомнили пароль? ',
                        style: TextStyle(color: AppColors.mutedForeground, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Text(
                          'Войти',
                          style: TextStyle(
                            color: AppColors.citrusOrange,
                            fontSize: 14,
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
    );
  }
}
