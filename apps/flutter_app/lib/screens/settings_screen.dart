import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/theme/app_colors.dart';
import '../core/utils/theme_service.dart';
import '../core/utils/phone_formatter.dart';
import '../core/config/api_config.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../core/repository/auth_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _dailyReminders = true;
  List<Map<String, dynamic>> _trustedContacts = [];
  String? _editingContactId;
  final TextEditingController _trustedNameController = TextEditingController();
  final TextEditingController _trustedPhoneController = TextEditingController();

  String? _token;

  Future<String?> _getToken(BuildContext context) async {
    if (_token != null) return _token;
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _token = authState.user.token;
      return _token;
    }
    return null;
  }

  Future<Map<String, String>> _headers(BuildContext context) async {
    final token = await _getToken(context);
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  @override
  void initState() {
    super.initState();
    // Загрузка после build, когда context доступен
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getToken(context).then((_) => _loadTrustedContacts());
    });
  }

  @override
  void dispose() {
    _trustedNameController.dispose();
    _trustedPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final user = state is AuthAuthenticated ? state.user : null;
                      return _buildProfileCard(user);
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'ПРИЛОЖЕНИЕ',
                    children: [
                      _buildThemeSelector(),
                      _buildToggleItem(
                        icon: Icons.notifications_outlined,
                        label: 'Уведомления',
                        value: _notificationsEnabled,
                        onChanged: (v) => setState(() => _notificationsEnabled = v),
                      ),
                      _buildToggleItem(
                        icon: Icons.access_time_outlined,
                        label: 'Ежедневные напоминания',
                        value: _dailyReminders,
                        onChanged: (v) => setState(() => _dailyReminders = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'ДОВЕРЕННЫЙ КОНТАКТ',
                    children: [
                      _buildTrustedContactCard(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    title: 'ПОДДЕРЖКА',
                    children: [
                      _buildSettingsItem(
                        icon: Icons.info_outline,
                        label: 'О приложении',
                        subtitle: 'Версия 1.0.0',
                        onTap: () => _showAboutDialog(context),
                      ),
                      _buildSettingsItem(
                        icon: Icons.help_outline,
                        label: 'Помощь',
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildLogoutButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Text(
      'Настройки',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.foreground,
      ),
    );
  }

  Widget _buildProfileCard(User? user) {
    final displayName = user?.name ?? 'Пользователь';
    final displayEmail = user?.email ?? 'Не авторизован';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.subtleBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.citrusOrange, AppColors.citrusAmber],
              ),
            ),
            child: Center(
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.background,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  displayEmail,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedForeground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustedContactCard() {
    final isEditing = _editingContactId != null;
    final isCreating = _editingContactId == '';

    return Column(
      children: [
        // Форма редактирования/создания
        if (isEditing || isCreating)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCreating
                      ? 'Новый доверенный контакт'
                      : 'Редактировать контакт',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _trustedNameController,
                  decoration: InputDecoration(
                    labelText: 'Имя',
                    hintText: 'Мама, Друг и т.д.',
                    filled: true,
                    fillColor: AppColors.surface2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _trustedPhoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [PhoneInputFormatter()],
                  decoration: InputDecoration(
                    labelText: 'Номер телефона',
                    hintText: '+7 (___) ___-__-__',
                    filled: true,
                    fillColor: AppColors.surface2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveTrustedContact,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.citrusGreen,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Сохранить', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _cancelEditing,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Отмена'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // Список контактов
        if (_trustedContacts.isEmpty && !isEditing && !isCreating)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _trustedNameController.clear();
                _trustedPhoneController.clear();
                setState(() => _editingContactId = '');
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Icon(Icons.person_add_outlined, color: AppColors.citrusOrange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Добавить доверенный контакт',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.foreground,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Для отправки SOS-сообщений',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.add, color: AppColors.citrusOrange, size: 20),
                  ],
                ),
              ),
            ),
          ),

        ..._trustedContacts.map((contact) {
          final isActive = _editingContactId == contact['id'] && _editingContactId!.isNotEmpty;
          return Material(
            color: isActive ? AppColors.surface2 : Colors.transparent,
            child: InkWell(
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.favorite, color: AppColors.destructive, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contact['name']?.isNotEmpty == true
                                ? contact['name']
                                : 'Контакт',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.foreground,
                            ),
                          ),
                          Text(
                            _formatPhoneForDisplay(contact['phone']),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () => _editContact(contact),
                      color: AppColors.mutedForeground,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: () => _deleteContact(contact['id']),
                      color: AppColors.destructive,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        // Кнопка добавления если есть контакты и не редактируем
        if (_trustedContacts.isNotEmpty && !isEditing && !isCreating)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _trustedNameController.clear();
                _trustedPhoneController.clear();
                setState(() => _editingContactId = '');
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.add, color: AppColors.citrusOrange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Добавить ещё',
                      style: TextStyle(
                        fontSize: 13,
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
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: AppColors.mutedForeground,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface1,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.subtleBorder),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSelector() {
    return ListenableBuilder(
      listenable: ThemeService(),
      builder: (context, _) {
        final isDark = ThemeService().isDarkMode;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.palette_outlined, color: AppColors.mutedForeground, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Тема',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.foreground,
                      ),
                    ),
                    Text(
                      isDark ? 'Тёмная' : 'Светлая',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('☀️')),
                  ButtonSegment(value: 1, label: Text('🌙')),
                ],
                selected: {isDark ? 1 : 0},
                onSelectionChanged: (selected) {
                  ThemeService().toggleTheme(selected.first == 1);
                },
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  backgroundColor: AppColors.surface2,
                  selectedBackgroundColor: AppColors.citrusOrange.withOpacity(0.2),
                  foregroundColor: AppColors.foreground,
                  selectedForegroundColor: AppColors.citrusOrange,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.mutedForeground, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.foreground,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.citrusOrange,
            inactiveThumbColor: AppColors.mutedForeground,
            inactiveTrackColor: AppColors.surface3,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String label,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: AppColors.mutedForeground, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.foreground,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.mutedForeground, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.destructive.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.destructive.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLogoutDialog(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout, color: AppColors.destructive, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Выйти из аккаунта',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.destructive,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.destructive.withOpacity(0.3)),
        ),
        icon: Icon(Icons.logout, color: AppColors.destructive, size: 32),
        title: const Text(
          'Выйти из аккаунта?',
          style: TextStyle(color: AppColors.foreground, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Вы будете перенаправлены на страницу входа. Все несохранённые данные будут потеряны.',
          style: TextStyle(color: AppColors.mutedForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена', style: TextStyle(color: AppColors.mutedForeground)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(const AuthLogout());
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.destructive,
            ),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadTrustedContacts() async {
    try {
      final headers = await _headers(context);
      debugPrint('Loading trusted contacts from: ${ApiConfig.baseUrl}/trusted-contacts');
      debugPrint('Headers: $headers');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/trusted-contacts'),
        headers: headers,
      );
      debugPrint('Response status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _trustedContacts = data.cast<Map<String, dynamic>>();
          });
          debugPrint('Loaded ${_trustedContacts.length} trusted contacts');
        }
      } else {
        debugPrint('Failed to load trusted contacts: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error loading trusted contacts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки контактов: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveTrustedContact() async {
    final phone = PhoneInputFormatter.extractDigits(_trustedPhoneController.text);
    debugPrint('=== Save trusted contact ===');
    debugPrint('Phone (digits): $phone');
    debugPrint('Name: ${_trustedNameController.text}');
    debugPrint('Editing ID: $_editingContactId');
    debugPrint('URL: ${ApiConfig.baseUrl}/trusted-contacts');
    if (phone.isEmpty) {
      debugPrint('Phone is empty, aborting');
      return;
    }

    final body = jsonEncode({
      'name': _trustedNameController.text.trim(),
      'phone': phone,
    });
    debugPrint('Request body: $body');

    try {
      final headers = await _headers(context);
      debugPrint('Headers: $headers');
      if (_editingContactId != null && _editingContactId!.isNotEmpty) {
        // Редактирование существующего
        debugPrint('Method: PUT -> /trusted-contacts/$_editingContactId');
        final resp = await http.put(
          Uri.parse('${ApiConfig.baseUrl}/trusted-contacts/$_editingContactId'),
          headers: headers,
          body: body,
        );
        debugPrint('PUT response: ${resp.statusCode} ${resp.body}');
      } else {
        // Создание нового (_editingContactId == '')
        debugPrint('Method: POST -> /trusted-contacts');
        final resp = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/trusted-contacts'),
          headers: headers,
          body: body,
        );
        debugPrint('POST response: ${resp.statusCode} ${resp.body}');
      }
      setState(() {
        _editingContactId = null;
        _trustedNameController.clear();
        _trustedPhoneController.clear();
      });
      await _loadTrustedContacts();
    } catch (e) {
      debugPrint('Error saving trusted contact: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка сохранения: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editContact(Map<String, dynamic> contact) {
    setState(() {
      _editingContactId = contact['id'];
      _trustedNameController.text = contact['name'] ?? '';
      _trustedPhoneController.text = _formatPhoneForDisplay(contact['phone']);
    });
  }

  Future<void> _deleteContact(String id) async {
    try {
      final headers = await _headers(context);
      await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/trusted-contacts/$id'),
        headers: headers,
      );
      setState(() {
        if (_editingContactId == id) {
          _editingContactId = null;
          _trustedNameController.clear();
          _trustedPhoneController.clear();
        }
      });
      await _loadTrustedContacts();
    } catch (e) {
      debugPrint('Error deleting trusted contact: $e');
    }
  }

  void _cancelEditing() {
    setState(() {
      _editingContactId = null;
      _trustedNameController.clear();
      _trustedPhoneController.clear();
    });
  }

  String _formatPhoneForDisplay(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 11 && digits.startsWith('7')) {
      return '+7 (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7, 9)}-${digits.substring(9)}';
    }
    return phone;
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info, color: AppColors.citrusOrange),
            SizedBox(width: 8),
            Text('О приложении', style: TextStyle(color: AppColors.foreground)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Цитрус — персональный помощник ментального здоровья',
              style: TextStyle(color: AppColors.foreground, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              'Версия: 1.0.0 (Beta)\n\nПриложение включает:\n• Трекер настроения\n• Трекер сна\n• Календарь событий\n• ИИ-чат\n• Упражнения и медитации\n• Аналитику',
              style: TextStyle(color: AppColors.mutedForeground, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть', style: TextStyle(color: AppColors.citrusOrange)),
          ),
        ],
      ),
    );
  }
}
