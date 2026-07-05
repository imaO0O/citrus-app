import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/app_size.dart';

/// Политика конфиденциальности и условия — отображаются прямо в приложении.
/// ВАЖНО: это базовый шаблон, перед публикацией стоит показать юристу.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.foreground),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Конфиденциальность и условия',
            style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(17), fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: AppSize.padding(20),
        children: [
          Text('Коротко', style: AppText.displayTitle),
          AppSize.gapH(8),
          Text(
            'Цитрус помогает следить за ментальным состоянием. Мы бережно относимся к твоим данным, '
            'не продаём их и не передаём третьим лицам для рекламы. Ты в любой момент можешь выгрузить '
            'или удалить все свои данные в Настройках.',
            style: AppText.body.copyWith(color: AppColors.mutedForeground),
          ),
          AppSize.gapH(24),

          _section('Какие данные мы собираем', [
            'Аккаунт: email, имя и (по желанию) телефон.',
            'Записи о себе: настроение, сон, дневник, события календаря, результаты психологических тестов, фото-воспоминания, доверенные контакты.',
            'Сообщения ИИ-чату и служебные метрики использования (для работы функций).',
          ]),

          _section('Зачем', [
            'Чтобы показывать твою динамику, аналитику и персональные подсказки.',
            'Чтобы работали напоминания, курсы, чат-поддержка и SOS.',
            'Мы не используем твои записи для рекламы.',
          ]),

          _section('Как храним и защищаем', [
            'Данные хранятся на защищённых серверах; пароль — только в виде необратимого хеша.',
            'Передача данных идёт по защищённому соединению (HTTPS).',
            'Доступ к данным есть только у тебя (по входу в аккаунт).',
          ]),

          _section('ИИ-функции', [
            'Чат и недельные инсайты обрабатываются через сторонний сервис ИИ (GigaChat). '
                'Для ответа туда отправляется текст твоего запроса и обезличенная сводка по показателям.',
            'Не делись в чате тем, что не хотел бы передавать стороннему сервису.',
          ]),

          _section('Твои права', [
            'Экспорт: Настройки → «Экспорт моих данных» (выгрузка всех данных в JSON).',
            'Удаление: Настройки → «Удалить аккаунт» — все данные удаляются безвозвратно.',
          ]),

          _section('Важно о здоровье', [
            'Цитрус — инструмент самопомощи, а не медицинская услуга. Он не ставит диагнозов '
                'и не заменяет врача или психолога.',
            'Если тебе тяжело или есть мысли о причинении себе вреда — воспользуйся кнопкой SOS '
                'и обратись за помощью к специалисту или близким.',
          ]),

          _section('Возраст', [
            'Если тебе меньше 18 лет, используй приложение с согласия родителя или законного представителя.',
          ]),

          _section('Контакты', [
            'Вопросы о данных: support@citrus.app',
          ]),

          AppSize.gapH(16),
          Text(
            'Это базовая версия документа и может обновляться. Дата последнего изменения: 2026-06-23.',
            style: AppText.caption,
          ),
          AppSize.gapH(24),
        ],
      ),
    );
  }

  Widget _section(String title, List<String> points) {
    return Padding(
      padding: AppSize.paddingOnly(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.sectionTitle),
          AppSize.gapH(8),
          ...points.map((p) => Padding(
                padding: AppSize.paddingOnly(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: AppSize.s(7), right: AppSize.s(8)),
                      child: Container(
                        width: AppSize.s(5),
                        height: AppSize.s(5),
                        decoration: BoxDecoration(color: AppColors.citrusOrange, shape: BoxShape.circle),
                      ),
                    ),
                    Expanded(child: Text(p, style: AppText.bodyMuted)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
