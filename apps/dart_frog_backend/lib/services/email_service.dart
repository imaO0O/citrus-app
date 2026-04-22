import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

/// Сервис отправки email через Yandex SMTP
///
/// Для работы нужен обычный аккаунт @yandex.ru с включённым доступом:
/// https://mail.yandex.ru/#setup/client — включить «Пароли приложений»
/// Создать пароль приложения для «Почта» и использовать его вместо обычного пароля.
///
/// Переменные окружения:
///   YANDEX_EMAIL     — адрес вида user@yandex.ru
///   YANDEX_APP_PASSWORD — пароль приложения (16 символов без пробелов)
class EmailService {
  static String? _email;
  static String? _appPassword;
  static bool _initialized = false;

  /// Инициализация из переменных окружения
  static void init(String email, String appPassword) {
    _email = email;
    _appPassword = appPassword;
    _initialized = true;
    print('EmailService: initialized for $email');
  }

  static bool get isConfigured => _initialized && _email != null && _appPassword != null;

  /// Отправить код подтверждения для сброса пароля
  static Future<bool> sendPasswordResetCode(String toEmail, String code) async {
    if (!isConfigured) {
      print('EmailService: not configured, skipping email send');
      return false;
    }

    try {
      // Yandex SMTP: smtp.yandex.ru, порт 465 (SSL)
      final yandexSmtp = SmtpServer(
        'smtp.yandex.ru',
        port: 465,
        ssl: true,
        username: _email,
        password: _appPassword,
      );

      final message = Message()
        ..from = Address(_email!, 'Цитрус')
        ..recipients.add(toEmail)
        ..subject = 'Код для сброса пароля — Цитрус'
        ..html = '''
          <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto; padding: 24px; background: #f9fafb; border-radius: 16px;">
            <div style="text-align: center; margin-bottom: 24px;">
              <h1 style="color: #FF8C42; margin: 0; font-size: 28px;">Цитрус</h1>
              <p style="color: #6B7280; margin: 4px 0 0;">Персональный помощник</p>
            </div>
            <div style="background: #ffffff; border-radius: 12px; padding: 24px; border: 1px solid #E5E7EB;">
              <p style="margin: 0 0 16px; color: #111827; font-size: 16px;">Вы запросили сброс пароля.</p>
              <p style="margin: 0 0 8px; color: #6B7280; font-size: 14px;">Ваш код подтверждения:</p>
              <div style="text-align: center; margin: 16px 0;">
                <span style="font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #FF8C42; background: #FFF7ED; padding: 12px 24px; border-radius: 8px; display: inline-block;">$code</span>
              </div>
              <p style="margin: 16px 0 0; color: #6B7280; font-size: 13px;">Код действителен 15 минут. Если вы не запрашивали сброс — просто проигнорируйте это письмо.</p>
            </div>
            <p style="text-align: center; color: #9CA3AF; font-size: 12px; margin-top: 16px;">Это автоматическое письмо, отвечать не нужно.</p>
          </div>
        ''';

      final sendReport = await send(message, yandexSmtp);
      print('EmailService: email sent to $toEmail: $sendReport');
      return true;
    } catch (e) {
      print('EmailService: error sending email: $e');
      return false;
    }
  }
}
