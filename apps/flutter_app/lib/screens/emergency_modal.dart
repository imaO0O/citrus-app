import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/theme/app_colors.dart';
import '../core/utils/phone_formatter.dart';
import '../core/config/api_config.dart';

class EmergencyModal extends StatefulWidget {
  final VoidCallback onClose;
  const EmergencyModal({super.key, required this.onClose});

  @override
  State<EmergencyModal> createState() => _EmergencyModalState();
}

class _EmergencyModalState extends State<EmergencyModal> {
  String curatorPhone = '+7-800-123-45-67';
  String inputValue = '';
  bool isEditing = false;
  final TextEditingController _phoneController = TextEditingController();

  // Состояния для техник
  bool _showBreathingExercise = false;
  bool _showGroundingExercise = false;
  int _breathPhase = 0; // 0: вдох, 1: задержка, 2: выдох
  int _breathSeconds = 0;
  bool _breathingActive = false;

  // Доверенные контакты из БД
  List<Map<String, dynamic>> _trustedContacts = [];

  @override
  void initState() {
    super.initState();
    _loadCuratorPhone();
    _loadTrustedContacts();
  }

  Future<void> _loadCuratorPhone() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('curator_phone');
    if (saved != null && saved.isNotEmpty) {
      setState(() {
        curatorPhone = saved;
        inputValue = saved;
        _phoneController.text = saved;
      });
    }
  }

  Future<void> _loadTrustedContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('token');
    if (savedToken == null || savedToken.isEmpty) {
      debugPrint('No token in SharedPreferences, skipping trusted contacts load');
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('curator_phone', curatorPhone);
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
    String? trustedPhone;

    // Сначала пробуем из БД
    if (_trustedContacts.isNotEmpty) {
      trustedPhone = _trustedContacts.first['phone'];
    }

    // Fallback на SharedPreferences
    if (trustedPhone == null || trustedPhone.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      trustedPhone = prefs.getString('trusted_contact');
    }

    if (trustedPhone == null || trustedPhone.isEmpty) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface2,
            title: const Text('Доверенный контакт не настроен'),
            content: const Text(
              'Для отправки SOS укажите доверенный контакт в настройках приложения.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Понятно'),
              ),
            ],
          ),
        );
      }
      return;
    }

    final smsUri = Uri.parse(
      'sms:$trustedPhone?body=🆘 SOS! Мне нужна помощь. Я отправляю это из приложения Citrus.',
    );
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось отправить SMS'),
            backgroundColor: AppColors.destructive,
          ),
        );
      }
    }
  }

  void _startBreathingExercise() {
    setState(() {
      _showBreathingExercise = true;
      _breathPhase = 0;
      _breathSeconds = 0;
      _breathingActive = true;
    });
  }

  void _stopBreathingExercise() {
    setState(() {
      _showBreathingExercise = false;
      _breathingActive = false;
    });
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
                constraints: const BoxConstraints(maxWidth: 500),
                decoration: const BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                        child: Column(
                          children: [
                            _buildAlertMessage(),
                            const SizedBox(height: 16),
                            if (_showBreathingExercise)
                              _buildBreathingExercise()
                            else if (_showGroundingExercise)
                              _buildGroundingExercise()
                            else ...[
                              _buildContacts(),
                              const SizedBox(height: 12),
                              _buildSosButton(),
                              const SizedBox(height: 16),
                              _buildQuickTechniques(),
                              const SizedBox(height: 16),
                              _buildTipsList(),
                            ],
                            const SizedBox(height: 12),
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
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
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
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.destructive.withOpacity(0.3)),
            ),
            child: const Center(child: Text('\u{1F198}', style: TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\u042D\u043A\u0441\u0442\u0440\u0435\u043D\u043D\u0430\u044F \u043F\u043E\u043C\u043E\u0449\u044C',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '\u0422\u044B \u043D\u0435 \u043E\u0434\u0438\u043D, \u043F\u043E\u043C\u043E\u0449\u044C \u0440\u044F\u0434\u043E\u043C',
                  style: TextStyle(fontSize: 12, color: AppColors.mutedForeground),
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
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.close, color: AppColors.mutedForeground, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.destructive.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.destructive.withOpacity(0.2)),
      ),
      child: const Text(
        '\u0415\u0441\u043B\u0438 \u0442\u044B \u0432 \u043A\u0440\u0438\u0437\u0438\u0441\u043D\u043E\u0439 \u0441\u0438\u0442\u0443\u0430\u0446\u0438\u0438 \u2014 \u043D\u0435\u043C\u0435\u0434\u043B\u0435\u043D\u043D\u043E \u043E\u0431\u0440\u0430\u0442\u0438\u0441\u044C \u0437\u0430 \u043F\u043E\u043C\u043E\u0449\u044C\u044E. \u0422\u044B \u0432\u0430\u0436\u0435\u043D, \u0438 \u0442\u0435\u0431\u0435 \u043F\u043E\u043C\u043E\u0433\u0443\u0442 24/7.',
        style: TextStyle(
          fontSize: 13,
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
        const SizedBox(height: 8),
        _buildContactCard(
          name: 'Служба 112',
          number: '112',
          desc: 'Экстренные службы',
          icon: Icons.phone,
          color: AppColors.citrusOrange,
          onTap: () => _makePhoneCall('112'),
        ),
        const SizedBox(height: 8),
        _buildContactCard(
          name: 'Психолог ВУЗа',
          number: 'Записаться',
          desc: 'Поддержка студентов',
          icon: Icons.people,
          color: AppColors.citrusPurple,
          onTap: () => _makePhoneCall('88002000122'), // Заглушка
        ),
        const SizedBox(height: 8),
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
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.foreground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    number,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: const TextStyle(fontSize: 10, color: AppColors.mutedForeground),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.school, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Куратор учебной группы',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 6),
                if (isEditing)
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          style: const TextStyle(fontSize: 12, color: AppColors.foreground),
                          inputFormatters: [PhoneInputFormatter()],
                          decoration: InputDecoration(
                            hintText: '+7 (___) ___-__-__',
                            hintStyle: const TextStyle(fontSize: 12, color: AppColors.dimForeground),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.07),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: color.withOpacity(0.25)),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.phone,
                          onChanged: (val) => inputValue = val,
                          onSubmitted: (_) => _handleSave(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _handleSave,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: color.withOpacity(0.3)),
                          ),
                          child: const Icon(Icons.check, size: 16),
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
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      const Text(
                        'Куратор вашей группы',
                        style: TextStyle(fontSize: 10, color: AppColors.mutedForeground),
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
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.phone, color: color, size: 16),
                        ),
                      ),
                      const SizedBox(width: 6),
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
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.edit, color: AppColors.mutedForeground, size: 14),
                        ),
                      ),
                    ],
                  )
                : GestureDetector(
                    onTap: () {
                      setState(() => isEditing = true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withOpacity(0.2)),
                      ),
                      child: Text(
                        'Добавить',
                        style: TextStyle(
                          fontSize: 11,
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.destructive, Color(0xFFFF5B5B)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.destructive.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                '🆘 Отправить SOS',
                style: TextStyle(
                  fontSize: 14,
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
    final techniques = [
      {
        'icon': Icons.air,
        'label': 'Дыхание 4-4-4',
        'desc': 'Вдох 4с · Пауза 4с · Выдох 4с',
        'color': AppColors.citrusPurple,
        'action': _startBreathingExercise,
      },
      {
        'icon': Icons.favorite,
        'label': '5-4-3-2-1',
        'desc': '5 видишь · 4 потрогать · 3 слышишь',
        'color': AppColors.citrusGreen,
        'action': _startGroundingExercise,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'БЫСТРЫЕ ТЕХНИКИ САМОПОМОЩИ',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.dimForeground,
              letterSpacing: 0.8,
            ),
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.4,
          children: techniques.map((t) {
            return GestureDetector(
              onTap: t['action'] as VoidCallback,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (t['color'] as Color).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: (t['color'] as Color).withOpacity(0.12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(t['icon'] as IconData, color: t['color'] as Color, size: 20),
                    const SizedBox(height: 6),
                    Text(
                      t['label'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t['desc'] as String,
                      style: const TextStyle(fontSize: 10, color: AppColors.mutedForeground),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBreathingExercise() {
    final phaseNames = ['Вдох', 'Задержка', 'Выдох'];
    final phaseColors = [
      AppColors.citrusPurple,
      AppColors.citrusOrange,
      AppColors.citrusGreen,
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: phaseColors[_breathPhase].withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: phaseColors[_breathPhase].withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Дыхание 4-4-4',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.foreground,
                ),
              ),
              GestureDetector(
                onTap: _stopBreathingExercise,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.close, size: 16, color: AppColors.mutedForeground),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: phaseColors[_breathPhase].withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: phaseColors[_breathPhase].withOpacity(0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$_breathSeconds',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: phaseColors[_breathPhase],
                  ),
                ),
                Text(
                  phaseNames[_breathPhase],
                  style: TextStyle(
                    fontSize: 12,
                    color: phaseColors[_breathPhase],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPhaseIndicator(0, phaseColors),
              const SizedBox(width: 8),
              _buildPhaseIndicator(1, phaseColors),
              const SizedBox(width: 8),
              _buildPhaseIndicator(2, phaseColors),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _breathingActive ? _breathingActive ? null : null : _startBreathingExercise,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.citrusPurple,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _breathingActive ? 'Идёт упражнение...' : 'Начать',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseIndicator(int index, List<Color> colors) {
    final isActive = _breathPhase == index;
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isActive ? colors[index] : colors[index].withOpacity(0.2),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          ['Вдох', 'Задержка', 'Выдох'][index],
          style: TextStyle(
            fontSize: 10,
            color: isActive ? colors[index] : AppColors.mutedForeground,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildGroundingExercise() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.citrusGreen.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.citrusGreen.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Техника 5-4-3-2-1',
                style: TextStyle(
                  fontSize: 14,
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.close, size: 16, color: AppColors.mutedForeground),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildGroundingStep(
            number: 5,
            icon: Icons.visibility,
            text: 'Назови 5 вещей, которые ты ВИДИШЬ',
            color: AppColors.citrusPurple,
          ),
          const SizedBox(height: 8),
          _buildGroundingStep(
            number: 4,
            icon: Icons.back_hand,
            text: 'Назови 4 вещи, которые ты можешь ПОТРОГАТЬ',
            color: AppColors.citrusGreen,
          ),
          const SizedBox(height: 8),
          _buildGroundingStep(
            number: 3,
            icon: Icons.hearing,
            text: 'Назови 3 звука, которые ты СЛЫШИШЬ',
            color: AppColors.citrusOrange,
          ),
          const SizedBox(height: 8),
          _buildGroundingStep(
            number: 2,
            icon: Icons.air,
            text: 'Назови 2 запаха, которые ты ЧУВСТВУЕШЬ',
            color: AppColors.citrusPurple,
          ),
          const SizedBox(height: 8),
          _buildGroundingStep(
            number: 1,
            icon: Icons.favorite,
            text: 'Назови 1 вещь, которая ты чувствуешь на ВКУС',
            color: AppColors.destructive,
          ),
          const SizedBox(height: 16),
          const Text(
            'Эта техника помогает вернуться в настоящий момент и снизить тревогу.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
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
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Что делать прямо сейчас:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 8),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '→',
                  style: TextStyle(color: AppColors.citrusPurple, fontSize: 12),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    tip,
                    style: const TextStyle(fontSize: 12, color: AppColors.mutedForeground),
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
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'Закрыть',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.mutedForeground,
          ),
        ),
      ),
    );
  }
}
