import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/app_size.dart';

/// Экран помощи и поддержки
class HelpScreen extends StatelessWidget {
  HelpScreen({super.key});

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
        title: Text(
          'Помощь',
          style: TextStyle(
            color: AppColors.foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSize.padding(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Приветствие
              _buildWelcomeCard(),
              AppSize.gapH(24),

              // Быстрые действия
              _buildSectionTitle('БЫСТРАЯ ПОМОЩЬ'),
              AppSize.gapH(12),
              _buildQuickActions(context),
              AppSize.gapH(24),

              // FAQ
              _buildSectionTitle('ЧАСТЫЕ ВОПРОСЫ'),
              AppSize.gapH(12),
              _buildFAQSection(context),
              AppSize.gapH(24),

              // Руководства
              _buildSectionTitle('РУКОВОДСТВА'),
              AppSize.gapH(12),
              _buildGuidesSection(context),
              AppSize.gapH(24),

              // Юридические документы
              _buildSectionTitle('ЮРИДИЧЕСКАЯ ИНФОРМАЦИЯ'),
              AppSize.gapH(12),
              _buildLegalSection(context),
              AppSize.gapH(24),

              // Контакты поддержки
              _buildSupportContacts(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: AppSize.padding(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.citrusOrange, AppColors.citrusAmber],
        ),
        borderRadius: AppSize.radius(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.glowOrange.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: AppSize.padding(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: AppSize.radius(12),
                ),
                child: Icon(
                  Icons.support_agent,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              AppSize.gapW(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Чем можем помочь?',
                      style: TextStyle(
                        fontSize: AppSize.s(18),
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    AppSize.gapH(4),
                    Text(
                      'Найдите ответы на вопросы или свяжитесь с нами',
                      style: TextStyle(
                        fontSize: AppSize.s(13),
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: AppSize.s(11),
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: AppColors.mutedForeground,
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: AppSize.radius(16),
        border: Border.all(color: AppColors.subtleBorder),
      ),
      child: Column(
        children: [
          _buildActionTile(
            icon: Icons.play_circle_outline,
            title: 'Как начать',
            subtitle: 'Быстрое знакомство с приложением',
            onTap: () => _showGettingStartedGuide(context),
          ),
          Divider(height: 1, color: AppColors.subtleBorder, indent: 56),
          _buildActionTile(
            icon: Icons.bug_report_outlined,
            title: 'Сообщить о проблеме',
            subtitle: 'Нашли баг? Расскажите нам',
            onTap: () => _showBugReportDialog(context),
          ),
          Divider(height: 1, color: AppColors.subtleBorder, indent: 56),
          _buildActionTile(
            icon: Icons.lightbulb_outline,
            title: 'Предложить идею',
            subtitle: 'Поделитесь своими мыслями',
            onTap: () => _showFeatureRequestDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection(BuildContext context) {
    final faqs = [
      {
        'question': 'Как работает трекер настроения?',
        'answer': 'Отмечайте своё настроение ежедневно с помощью смайликов. Приложение строит графики и показывает паттерны вашего эмоционального состояния. Можно добавлять заметки к каждой записи.',
      },
      {
        'question': 'Данные синхронизируются между устройствами?',
        'answer': 'Да! При входе в аккаунт все данные автоматически синхронизируются с облаком. Вы можете использовать приложение на нескольких устройствах.',
      },
      {
        'question': 'Как использовать ИИ-чат?',
        'answer': 'Перейдите на вкладку "Чат" и начните диалог. ИИ поможет разобраться в чувствах, предложит техники самопомощи или просто поддержит разговор.',
      },
      {
        'question': 'Что такое доверенный контакт?',
        'answer': 'Это близкий человек, которому можно отправить SOS-сообщение в трудный момент. Добавьте контакт в настройках — он получит ваше сообщение при нажатии кнопки экстренной помощи.',
      },
      {
        'question': 'Данные конфиденциальны?',
        'answer': 'Абсолютно. Мы используем шифрование, не передаём данные третьим лицам и соблюдаем политику конфиденциальности. Ваша безопасность — наш приоритет.',
      },
      {
        'question': 'Приложение заменяет терапевта?',
        'answer': 'Нет, Цитрус — инструмент самопомощи. При серьёзных проблемах всегда обращайтесь к квалифицированным специалистам. Мы можем помочь найти помощь в разделе экстренной поддержки.',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: AppSize.radius(16),
        border: Border.all(color: AppColors.subtleBorder),
      ),
      child: ExpansionPanelList.radio(
        elevation: 0,
        expandedHeaderPadding: EdgeInsets.zero,
        dividerColor: AppColors.subtleBorder,
        children: faqs.map((faq) {
          return ExpansionPanelRadio(
            value: faq['question']!,
            backgroundColor: AppColors.surface1,
            headerBuilder: (context, isExpanded) {
              return ListTile(
                title: Text(
                  faq['question']!,
                  style: TextStyle(
                    fontSize: AppSize.s(14),
                    fontWeight: FontWeight.w500,
                    color: AppColors.foreground,
                  ),
                ),
              );
            },
            body: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                faq['answer']!,
                style: TextStyle(
                  fontSize: AppSize.s(13),
                  color: AppColors.mutedForeground,
                  height: 1.5,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGuidesSection(BuildContext context) {
    final guides = [
      {
        'icon': '🧘',
        'title': 'Упражнения дыхания',
        'description': 'Научитесь правильно дышать для снижения тревоги',
      },
      {
        'icon': '📝',
        'title': 'Ведение дневника',
        'description': 'Как эффективно записывать мысли и чувства',
      },
      {
        'icon': '😴',
        'title': 'Сон и восстановление',
        'description': 'Советы по улучшению качества сна',
      },
      {
        'icon': '🎯',
        'title': 'Постановка целей',
        'description': 'SMART-цели для ментального здоровья',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: AppSize.radius(16),
        border: Border.all(color: AppColors.subtleBorder),
      ),
      child: Column(
        children: guides.asMap().entries.map((entry) {
          final guide = entry.value;
          final isLast = entry.key == guides.length - 1;

          return Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showGuideDetail(context, guide),
                  borderRadius: AppSize.radius(16),
                  child: Padding(
                    padding: AppSize.padding(16),
                    child: Row(
                      children: [
                        Text(
                          guide['icon']!,
                          style: TextStyle(fontSize: AppSize.s(24)),
                        ),
                        AppSize.gapW(16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                guide['title']!,
                                style: TextStyle(
                                  fontSize: AppSize.s(14),
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.foreground,
                                ),
                              ),
                              AppSize.gapH(2),
                              Text(
                                guide['description']!,
                                style: TextStyle(
                                  fontSize: AppSize.s(12),
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: AppColors.mutedForeground,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Divider(height: 1, color: AppColors.subtleBorder, indent: 56),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegalSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: AppSize.radius(16),
        border: Border.all(color: AppColors.subtleBorder),
      ),
      child: Column(
        children: [
          _buildActionTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Политика конфиденциальности',
            onTap: () => _launchUrl('https://citrus.app/privacy'),
          ),
          Divider(height: 1, color: AppColors.subtleBorder, indent: 56),
          _buildActionTile(
            icon: Icons.description_outlined,
            title: 'Условия использования',
            onTap: () => _launchUrl('https://citrus.app/terms'),
          ),
          Divider(height: 1, color: AppColors.subtleBorder, indent: 56),
          _buildActionTile(
            icon: Icons.copyright_outlined,
            title: 'Лицензии открытого ПО',
            subtitle: 'Используемые библиотеки',
            onTap: () => _showLicensesDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportContacts(BuildContext context) {
    return Container(
      padding: AppSize.padding(20),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: AppSize.radius(16),
        border: Border.all(color: AppColors.subtleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.headset_mic, color: AppColors.citrusOrange),
              AppSize.gapW(12),
              Text(
                'Служба поддержки',
                style: TextStyle(
                  fontSize: AppSize.s(16),
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
              ),
            ],
          ),
          AppSize.gapH(16),
          _buildContactRow(
            icon: Icons.email_outlined,
            title: 'Email',
            value: 'support@citrus.app',
            onTap: () => _launchUrl('mailto:support@citrus.app'),
          ),
          AppSize.gapH(12),
          _buildContactRow(
            icon: Icons.telegram,
            title: 'Telegram',
            value: '@citrus_support',
            onTap: () => _launchUrl('https://t.me/citrus_support'),
          ),
          AppSize.gapH(12),
          _buildContactRow(
            icon: Icons.access_time,
            title: 'Время работы',
            value: 'Ежедневно 9:00–21:00 МСК',
            onTap: null,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSize.radius(16),
        child: Padding(
          padding: AppSize.paddingH(16, 14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.mutedForeground, size: 22),
              AppSize.gapW(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: AppSize.s(14),
                        fontWeight: FontWeight.w500,
                        color: AppColors.foreground,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: AppSize.s(12),
                          color: AppColors.mutedForeground,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.mutedForeground,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppSize.radius(8),
      child: Padding(
        padding: AppSize.paddingH(0, 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.mutedForeground),
            AppSize.gapW(12),
            Text(
              '$title:',
              style: TextStyle(
                fontSize: AppSize.s(13),
                color: AppColors.mutedForeground,
              ),
            ),
            AppSize.gapW(8),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: AppSize.s(13),
                  fontWeight: FontWeight.w500,
                  color: onTap != null ? AppColors.citrusOrange : AppColors.foreground,
                  decoration: onTap != null ? TextDecoration.underline : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Диалоги и действия

  void _showGettingStartedGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: AppSize.padding(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.mutedForeground.withOpacity(0.3),
                      borderRadius: AppSize.radius(2),
                    ),
                  ),
                ),
                AppSize.gapH(24),
                Text(
                  '🍋 Добро пожаловать в Цитрус!',
                  style: TextStyle(
                    fontSize: AppSize.s(22),
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground,
                  ),
                ),
                AppSize.gapH(16),
                _buildGuideStep(
                  number: '1',
                  title: 'Отмечайте настроение',
                  description: 'Начните с ежедневной оценки своего состояния. Это поможет отслеживать динамику.',
                ),
                _buildGuideStep(
                  number: '2',
                  title: 'Добавьте доверенный контакт',
                  description: 'В настройках укажите близкого человека для экстренной связи.',
                ),
                _buildGuideStep(
                  number: '3',
                  title: 'Попробуйте упражнения',
                  description: 'В разделе "Ещё" найдите техники дыхания и медитации.',
                ),
                _buildGuideStep(
                  number: '4',
                  title: 'Общайтесь с ИИ',
                  description: 'Не стесняйтесь делиться мыслями — ИИ всегда готов поддержать.',
                ),
                _buildGuideStep(
                  number: '5',
                  title: 'Следите за аналитикой',
                  description: 'Просматривайте графики настроения и сна для лучшего понимания себя.',
                ),
                AppSize.gapH(24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.citrusOrange,
                      padding: AppSize.paddingH(0, 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSize.radius(12),
                      ),
                    ),
                    child: Text('Понятно, начнём!'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGuideStep({
    required String number,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: AppSize.paddingOnly(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.citrusOrange.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: AppSize.s(14),
                  fontWeight: FontWeight.w700,
                  color: AppColors.citrusOrange,
                ),
              ),
            ),
          ),
          AppSize.gapW(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppSize.s(15),
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
                AppSize.gapH(4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: AppSize.s(13),
                    color: AppColors.mutedForeground,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBugReportDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface1,
        shape: RoundedRectangleBorder(borderRadius: AppSize.radius(16)),
        title: Text(
          'Сообщить о проблеме',
          style: TextStyle(color: AppColors.foreground),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Опишите что произошло. Мы постараемся исправить это как можно скорее.',
                style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(13)),
              ),
              AppSize.gapH(16),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Описание проблемы...',
                  hintStyle: TextStyle(color: AppColors.mutedForeground),
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(
                    borderRadius: AppSize.radius(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена', style: TextStyle(color: AppColors.mutedForeground)),
          ),
          FilledButton(
            onPressed: () {
              // TODO: Отправка отчёта
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Спасибо! Мы получили ваш отчёт.'),
                  backgroundColor: AppColors.citrusGreen,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.citrusOrange,
            ),
            child: Text('Отправить'),
          ),
        ],
      ),
    );
  }

  void _showFeatureRequestDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface1,
        shape: RoundedRectangleBorder(borderRadius: AppSize.radius(16)),
        title: Text(
          'Предложить идею',
          style: TextStyle(color: AppColors.foreground),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Какую функцию хотели бы видеть? Расскажите подробнее!',
                style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(13)),
              ),
              AppSize.gapH(16),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Ваша идея...',
                  hintStyle: TextStyle(color: AppColors.mutedForeground),
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(
                    borderRadius: AppSize.radius(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена', style: TextStyle(color: AppColors.mutedForeground)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Спасибо за идею! Мы её обязательно рассмотрим.'),
                  backgroundColor: AppColors.citrusGreen,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.citrusOrange,
            ),
            child: Text('Отправить'),
          ),
        ],
      ),
    );
  }

  void _showGuideDetail(BuildContext context, Map<String, String> guide) {
    // TODO: Показать детальное руководство
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Руководство "${guide['title']}" скоро будет доступно'),
        backgroundColor: AppColors.citrusOrange,
      ),
    );
  }

  void _showLicensesDialog(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'Цитрус',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: AppSize.radius(16),
          gradient: LinearGradient(
            colors: [AppColors.citrusOrange, AppColors.citrusAmber],
          ),
        ),
        child: Center(
          child: Text('🍊', style: TextStyle(fontSize: AppSize.s(32))),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
