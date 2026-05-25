import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/theme/app_colors.dart';
import '../core/utils/phone_formatter.dart';
import '../core/config/api_config.dart';
import '../core/services/storage_service.dart';
import '../core/utils/app_size.dart';

class EmergencyModal extends StatefulWidget {
  final VoidCallback onClose;
  EmergencyModal({super.key, required this.onClose});

  @override
  State<EmergencyModal> createState() => _EmergencyModalState();
}

class _EmergencyModalState extends State<EmergencyModal> {
  String curatorPhone = '+7-800-123-45-67';
  String inputValue = '';
  bool isEditing = false;
  final TextEditingController _phoneController = TextEditingController();

  // Состояния для техник
  bool _showGroundingExercise = false;

  // Доверенные контакты из БД
  List<Map<String, dynamic>> _trustedContacts = [];

  @override
  void initState() {
    super.initState();
    _loadCuratorPhone();
    _loadTrustedContacts();
  }

  Future<void> _loadCuratorPhone() async {
    final storage = StorageService();
    final saved = await storage.getString('curator_phone');
    if (saved != null && saved.isNotEmpty && mounted) {
      setState(() {
        curatorPhone = saved;
        inputValue = saved;
        _phoneController.text = saved;
      });
    }
  }

  Future<void> _loadTrustedContacts() async {
    final storage = StorageService();
    final savedToken = await storage.getString('auth_token');
    if (savedToken == null || savedToken.isEmpty) {
      debugPrint('No token in Storage, skipping trusted contacts load');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/trusted-contacts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $savedToken',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _trustedContacts = data.cast<Map<String, dynamic>>();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading trusted contacts: $e');
    }
  }

  Future<void> _saveCuratorPhone() async {
    final storage = StorageService();
    await storage.setString('curator_phone', curatorPhone);
  }

  void _handleSave() {
    final trimmed = _phoneController.text.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      curatorPhone = trimmed;
      inputValue = trimmed;
      isEditing = false;
    });
    _saveCuratorPhone();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Не удалось совершить звонок на $phoneNumber'),
            backgroundColor: AppColors.destructive,
          ),
        );
      }
    }
  }

  Future<void> _sendSosMessage() async {
    // Собираем все доверенные контакты — если их несколько, отправляем
    // одно SMS на всех получателей сразу.
    final phones = <String>[];

    for (final contact in _trustedContacts) {
      final raw = contact['phone'];
      if (raw is String && raw.trim().isNotEmpty) {
        final normalized = raw.replaceAll(RegExp(r'[^0-9+]'), '');
        if (normalized.isNotEmpty) phones.add(normalized);
      }
    }

    // Fallback на SharedPreferences, если из БД не пришло ничего
    if (phones.isEmpty) {
      final storage = StorageService();
      final stored = await storage.getString('trusted_contact');
      if (stored != null && stored.isNotEmpty) {
        final normalized = stored.replaceAll(RegExp(r'[^0-9+]'), '');
        if (normalized.isNotEmpty) phones.add(normalized);
      }
    }

    if (phones.isEmpty) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface2,
            title: Text('Доверенный контакт не настроен'),
            content: Text(
              'Для отправки SOS укажите доверенный контакт в настройках приложения.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Понятно'),
              ),
            ],
          ),
        );
      }
      return;
    }

    // Несколько получателей — через запятую (Android SMS-приложения это
    // поддерживают). Тело собираем вручную с percent-кодированием, иначе
    // Uri.queryParameters использует form-urlencoding и заменяет пробелы
    // на «+» — некоторые приложения (Samsung Messages) показывают их
    // буквально.
    final recipients = phones.join(',');
    final body = Uri.encodeComponent(
      '🆘 SOS! Мне нужна помощь. Я отправляю это из приложения Citrus.',
    );
    final smsUri = Uri.parse('sms:$recipients?body=$body');

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Не удалось отправить SMS'),
            backgroundColor: AppColors.destructive,
          ),
        );
      }
    }
  }

  void _startGroundingExercise() {
    setState(() {
      _showGroundingExercise = true;
    });
  }

  void _stopGroundingExercise() {
    setState(() {
      _showGroundingExercise = false;
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black.withOpacity(0.85),
        child: GestureDetector(
          onTap: () {},
          child: SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                constraints: BoxConstraints(maxWidth: 500),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(24, 16, 24, 16),
                        child: Column(
                          children: [
                            _buildAlertMessage(),
                            AppSize.gapH(16),
                            if (_showGroundingExercise)
                              _buildGroundingExercise()
                            else ...[
                              _buildContacts(),
                              AppSize.gapH(12),
                              _buildSosButton(),
                              AppSize.gapH(16),
                              _buildQuickTechniques(),
                              AppSize.gapH(16),
                              _buildTipsList(),
                            ],
                            AppSize.gapH(12),
                            _buildCloseButton(),
                          ],
                        ),
                      ),
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

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromRGBO(230, 57, 70, 0.2),
            Color.fromRGBO(230, 57, 70, 0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.destructive.withOpacity(0.15)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.destructive.withOpacity(0.2),
              borderRadius: AppSize.radius(16),
              border: Border.all(color: AppColors.destructive.withOpacity(0.3)),
            ),
            child: Center(child: Text('\u{1F198}', style: TextStyle(fontSize: AppSize.s(24)))),
          ),
          AppSize.gapW(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\u042D\u043A\u0441\u0442\u0440\u0435\u043D\u043D\u0430\u044F \u043F\u043E\u043C\u043E\u0449\u044C',
                  style: TextStyle(
                    fontSize: AppSize.s(16),
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground,
                  ),
                ),
                AppSize.gapH(4),
                Text(
                  '\u0422\u044B \u043D\u0435 \u043E\u0434\u0438\u043D, \u043F\u043E\u043C\u043E\u0449\u044C \u0440\u044F\u0434\u043E\u043C',
                  style: TextStyle(fontSize: AppSize.s(12), color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: AppSize.radius(12),
              ),
              child: Icon(Icons.close, color: AppColors.mutedForeground, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertMessage() {
    return Container(
      padding: AppSize.padding(16),
      decoration: BoxDecoration(
        color: AppColors.destructive.withOpacity(0.08),
        borderRadius: AppSize.radius(16),
        border: Border.all(color: AppColors.destructive.withOpacity(0.2)),
      ),
      child: Text(
        '\u0415\u0441\u043B\u0438 \u0442\u044B \u0432 \u043A\u0440\u0438\u0437\u0438\u0441\u043D\u043E\u0439 \u0441\u0438\u0442\u0443\u0430\u0446\u0438\u0438 \u2014 \u043D\u0435\u043C\u0435\u0434\u043B\u0435\u043D\u043D\u043E \u043E\u0431\u0440\u0430\u0442\u0438\u0441\u044C \u0437\u0430 \u043F\u043E\u043C\u043E\u0449\u044C\u044E. \u0422\u044B \u0432\u0430\u0436\u0435\u043D, \u0438 \u0442\u0435\u0431\u0435 \u043F\u043E\u043C\u043E\u0433\u0443\u0442 24/7.',
        style: TextStyle(
          fontSize: AppSize.s(13),
          color: Color(0xFFFFADA5),
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildContacts() {
    return Column(
      children: [
        _buildContactCard(
          name: 'Телефон доверия',
          number: '8-800-2000-122',
          desc: 'Бесплатно · Круглосуточно',
          icon: Icons.phone,
          color: AppColors.destructive,
          onTap: () => _makePhoneCall('88002000122'),
        ),
        AppSize.gapH(8),
        _buildContactCard(
          name: 'Служба 112',
          number: '112',
          desc: 'Экстренные службы',
          icon: Icons.phone,
          color: AppColors.citrusOrange,
          onTap: () => _makePhoneCall('112'),
        ),
        AppSize.gapH(8),
        _buildContactCard(
          name: 'Психолог ВУЗа',
          number: 'Записаться',
          desc: 'Поддержка студентов',
          icon: Icons.people,
          color: AppColors.citrusPurple,
          onTap: () => _makePhoneCall('88002000122'), // Заглушка
        ),
        AppSize.gapH(8),
        _buildCuratorCard(),
      ],
    );
  }

  Widget _buildContactCard({
    required String name,
    required String number,
    required String desc,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: AppSize.paddingOnly(bottom: 8),
        padding: AppSize.paddingH(16, 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: AppSize.radius(16),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: AppSize.radius(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            AppSize.gapW(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: AppSize.s(13),
                      fontWeight: FontWeight.w700,
                      color: AppColors.foreground,
                    ),
                  ),
                  AppSize.gapH(2),
                  Text(
                    number,
                    style: TextStyle(
                      fontSize: AppSize.s(12),
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  AppSize.gapH(2),
                  Text(
                    desc,
                    style: TextStyle(fontSize: AppSize.s(10), color: AppColors.mutedForeground),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: AppSize.radius(12),
              ),
              child: Icon(Icons.phone, color: color, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCuratorCard() {
    final color = AppColors.citrusGreen;
    return Container(
      padding: AppSize.paddingH(16, 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: AppSize.radius(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: AppSize.radius(12),
            ),
            child: Icon(Icons.school, color: color, size: 22),
          ),
          AppSize.gapW(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Куратор учебной группы',
                  style: TextStyle(
                    fontSize: AppSize.s(13),
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground,
                  ),
                ),
                AppSize.gapH(6),
                if (isEditing)
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          style: TextStyle(fontSize: AppSize.s(12), color: AppColors.foreground),
                          inputFormatters: [PhoneInputFormatter()],
                          decoration: InputDecoration(
                            hintText: '+7 (___) ___-__-__',
                            hintStyle: TextStyle(fontSize: AppSize.s(12), color: AppColors.dimForeground),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.07),
                            border: OutlineInputBorder(
                              borderRadius: AppSize.radius(12),
                              borderSide: BorderSide(color: color.withOpacity(0.25)),
                            ),
                            contentPadding: AppSize.paddingH(12, 8),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.phone,
                          onChanged: (val) => inputValue = val,
                          onSubmitted: (_) => _handleSave(),
                        ),
                      ),
                      AppSize.gapW(8),
                      GestureDetector(
                        onTap: _handleSave,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: AppSize.radius(8),
                            border: Border.all(color: color.withOpacity(0.3)),
                          ),
                          child: Icon(Icons.check, size: 16),
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        curatorPhone.isEmpty ? 'Номер не указан' : curatorPhone,
                        style: TextStyle(
                          fontSize: AppSize.s(12),
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      Text(
                        'Куратор вашей группы',
                        style: TextStyle(fontSize: AppSize.s(10), color: AppColors.mutedForeground),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (!isEditing)
            curatorPhone.isNotEmpty
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => _makePhoneCall(curatorPhone.replaceAll(RegExp(r'[^0-9+]'), '')),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: AppSize.radius(12),
                          ),
                          child: Icon(Icons.phone, color: color, size: 16),
                        ),
                      ),
                      AppSize.gapW(6),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            inputValue = curatorPhone;
                            _phoneController.text = curatorPhone;
                            isEditing = true;
                          });
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.07),
                            borderRadius: AppSize.radius(12),
                          ),
                          child: Icon(Icons.edit, color: AppColors.mutedForeground, size: 14),
                        ),
                      ),
                    ],
                  )
                : GestureDetector(
                    onTap: () {
                      setState(() => isEditing = true);
                    },
                    child: Container(
                      padding: AppSize.paddingH(12, 6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: AppSize.radius(12),
                        border: Border.all(color: color.withOpacity(0.2)),
                      ),
                      child: Text(
                        'Добавить',
                        style: TextStyle(
                          fontSize: AppSize.s(11),
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ),
        ],
      ),
    );
  }

  Widget _buildSosButton() {
    return GestureDetector(
      onTap: _sendSosMessage,
      child: Container(
        width: double.infinity,
        padding: AppSize.paddingH(0, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.destructive, Color(0xFFFF5B5B)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: AppSize.radius(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.destructive.withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
            AppSize.gapW(8),
            Flexible(
              child: Text(
                '🆘 Отправить SOS',
                style: TextStyle(
                  fontSize: AppSize.s(14),
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTechniques() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppSize.paddingOnly(bottom: 8),
          child: Text(
            'БЫСТРАЯ ТЕХНИКА САМОПОМОЩИ',
            style: TextStyle(
              fontSize: AppSize.s(10),
              fontWeight: FontWeight.w700,
              color: AppColors.dimForeground,
              letterSpacing: 0.8,
            ),
          ),
        ),
        GestureDetector(
          onTap: _startGroundingExercise,
          child: Container(
            width: double.infinity,
            padding: AppSize.padding(14),
            decoration: BoxDecoration(
              color: AppColors.citrusGreen.withOpacity(0.06),
              borderRadius: AppSize.radius(16),
              border: Border.all(color: AppColors.citrusGreen.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.citrusGreen.withOpacity(0.12),
                    borderRadius: AppSize.radius(12),
                  ),
                  child: Icon(Icons.favorite, color: AppColors.citrusGreen, size: 22),
                ),
                AppSize.gapW(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '5-4-3-2-1',
                        style: TextStyle(
                          fontSize: AppSize.s(13),
                          fontWeight: FontWeight.w700,
                          color: AppColors.foreground,
                        ),
                      ),
                      AppSize.gapH(2),
                      Text(
                        '5 видишь · 4 потрогать · 3 слышишь',
                        style: TextStyle(fontSize: AppSize.s(10), color: AppColors.mutedForeground),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.mutedForeground, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroundingExercise() {
    return Container(
      padding: AppSize.padding(20),
      decoration: BoxDecoration(
        color: AppColors.citrusGreen.withOpacity(0.06),
        borderRadius: AppSize.radius(20),
        border: Border.all(color: AppColors.citrusGreen.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Техника 5-4-3-2-1',
                style: TextStyle(
                  fontSize: AppSize.s(14),
                  fontWeight: FontWeight.w700,
                  color: AppColors.foreground,
                ),
              ),
              GestureDetector(
                onTap: _stopGroundingExercise,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: AppSize.radius(8),
                  ),
                  child: Icon(Icons.close, size: 16, color: AppColors.mutedForeground),
                ),
              ),
            ],
          ),
          AppSize.gapH(16),
          _buildGroundingStep(
            number: 5,
            icon: Icons.visibility,
            text: 'Назови 5 вещей, которые ты ВИДИШЬ',
            color: AppColors.citrusPurple,
          ),
          AppSize.gapH(8),
          _buildGroundingStep(
            number: 4,
            icon: Icons.back_hand,
            text: 'Назови 4 вещи, которые ты можешь ПОТРОГАТЬ',
            color: AppColors.citrusGreen,
          ),
          AppSize.gapH(8),
          _buildGroundingStep(
            number: 3,
            icon: Icons.hearing,
            text: 'Назови 3 звука, которые ты СЛЫШИШЬ',
            color: AppColors.citrusOrange,
          ),
          AppSize.gapH(8),
          _buildGroundingStep(
            number: 2,
            icon: Icons.air,
            text: 'Назови 2 запаха, которые ты ЧУВСТВУЕШЬ',
            color: AppColors.citrusPurple,
          ),
          AppSize.gapH(8),
          _buildGroundingStep(
            number: 1,
            icon: Icons.favorite,
            text: 'Назови 1 вещь, которая ты чувствуешь на ВКУС',
            color: AppColors.destructive,
          ),
          AppSize.gapH(16),
          Text(
            'Эта техника помогает вернуться в настоящий момент и снизить тревогу.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppSize.s(11),
              color: AppColors.mutedForeground,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroundingStep({
    required int number,
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: AppSize.radius(10),
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: AppSize.s(16),
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ),
        AppSize.gapW(10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: AppSize.s(12),
              color: AppColors.foreground,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTipsList() {
    final tips = [
      'Холодная вода на запястья или лицо',
      'Позвони близкому человеку',
      'Выйди на свежий воздух',
      'Напиши о своих чувствах в дневник',
    ];

    return Container(
      padding: AppSize.padding(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: AppSize.radius(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Что делать прямо сейчас:',
            style: TextStyle(
              fontSize: AppSize.s(11),
              fontWeight: FontWeight.w700,
              color: AppColors.mutedForeground,
            ),
          ),
          AppSize.gapH(8),
          ...tips.map((tip) => Padding(
            padding: AppSize.paddingOnly(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '→',
                  style: TextStyle(color: AppColors.citrusPurple, fontSize: AppSize.s(12)),
                ),
                AppSize.gapW(6),
                Expanded(
                  child: Text(
                    tip,
                    style: TextStyle(fontSize: AppSize.s(12), color: AppColors.mutedForeground),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildCloseButton() {
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        width: double.infinity,
        padding: AppSize.paddingH(0, 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: AppSize.radius(16),
        ),
        child: Text(
          'Закрыть',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppSize.s(13),
            fontWeight: FontWeight.w700,
            color: AppColors.mutedForeground,
          ),
        ),
      ),
    );
  }
}
