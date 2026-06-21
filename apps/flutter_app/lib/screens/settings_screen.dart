import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import '../core/theme/app_colors.dart';
import '../core/utils/theme_service.dart';
import '../core/utils/phone_formatter.dart';
import '../core/config/api_config.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../core/repository/auth_repository.dart';
import '../features/notifications/pages/notifications_page.dart';
import 'help_screen.dart';
import 'lock/pin_screen.dart';
import '../core/utils/app_size.dart';
import '../core/utils/network_error.dart';
import '../core/services/pin_service.dart';

class SettingsScreen extends StatefulWidget {
  SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<Map<String, dynamic>> _trustedContacts = [];
  String? _editingContactId;
  final TextEditingController _trustedNameController = TextEditingController();
  final TextEditingController _trustedPhoneController = TextEditingController();

  // Редактирование профиля
  bool _isEditingProfile = false;
  bool _isSavingProfile = false;
  bool _isUploadingAvatar = false;
  final TextEditingController _profileNameController = TextEditingController();
  final TextEditingController _profilePhoneController = TextEditingController();
  String? _profileAvatarUrl;

  String? _token;
  bool _pinOn = false;

  Future<void> _loadPin() async {
    final on = await PinService().isEnabled();
    if (mounted) setState(() => _pinOn = on);
  }

  Future<void> _togglePin(bool value) async {
    if (value) {
      // Включение — установка нового PIN
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const PinScreen(setup: true, canCancel: true)),
      );
      if (ok == true && mounted) setState(() => _pinOn = true);
    } else {
      // Отключение — подтверждаем текущим PIN
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const PinScreen(setup: false, canCancel: true)),
      );
      if (ok == true) {
        await PinService().disable();
        if (mounted) setState(() => _pinOn = false);
      }
    }
  }

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getToken(context).then((_) => _loadTrustedContacts());
    });
    _loadPin();
  }

  @override
  void dispose() {
    _trustedNameController.dispose();
    _trustedPhoneController.dispose();
    _profileNameController.dispose();
    _profilePhoneController.dispose();
    super.dispose();
  }

  // === Профиль: начать редактирование ===
  void _startEditingProfile(User? user) {
    setState(() {
      _isEditingProfile = true;
      _profileNameController.text = user?.name ?? '';
      _profilePhoneController.text = (user?.phone != null && user!.phone!.isNotEmpty)
          ? _formatPhoneForDisplay(user.phone!)
          : '';
      _profileAvatarUrl = user?.avatarUrl;
    });
  }

  void _cancelEditingProfile() {
    setState(() {
      _isEditingProfile = false;
      _profileNameController.clear();
      _profilePhoneController.clear();
    });
  }

  Future<void> _saveProfile() async {
    setState(() => _isSavingProfile = true);

    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) return;

      final token = authState.user.token;
      final authRepository = context.read<AuthRepository>();

      final name = _profileNameController.text.trim();
      final phone = PhoneInputFormatter.extractDigits(_profilePhoneController.text);

      await authRepository.apiService.updateProfile(
        token,
        name: name,
        phone: phone.isEmpty ? null : phone,
      );

      final updatedUser = User(
        id: authState.user.id,
        email: authState.user.email,
        name: name.isEmpty ? null : name,
        themeId: authState.user.themeId,
        avatarUrl: _profileAvatarUrl,
        phone: phone.isEmpty ? null : phone,
        token: authState.user.token,
      );

      if (!mounted) return;
      context.read<AuthBloc>().add(AuthProfileUpdated(updatedUser));

      setState(() => _isEditingProfile = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Профиль обновлён'),
            backgroundColor: AppColors.citrusGreen,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка обновления профиля: $e'),
            backgroundColor: AppColors.destructive,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (image == null) return;

    setState(() => _isUploadingAvatar = true);

    try {
      if (!mounted) return;
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) return;

      final token = authState.user.token;
      final authRepository = context.read<AuthRepository>();
      final fileBytes = await image.readAsBytes();

      final avatarUrl = await authRepository.apiService.uploadAvatar(
        token,
        image.path,
        fileBytes,
        image.name,
      );

      final updatedUser = User(
        id: authState.user.id,
        email: authState.user.email,
        name: authState.user.name,
        themeId: authState.user.themeId,
        avatarUrl: avatarUrl,
        phone: authState.user.phone,
        token: authState.user.token,
      );

      if (!mounted) return;
      context.read<AuthBloc>().add(AuthProfileUpdated(updatedUser));

      setState(() => _profileAvatarUrl = avatarUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Аватар обновлён'),
            backgroundColor: AppColors.citrusGreen,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error uploading avatar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки аватара: $e'),
            backgroundColor: AppColors.destructive,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  String _formatPhoneForDisplay(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 11 && digits.startsWith('7')) {
      return '+7 (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7, 9)}-${digits.substring(9)}';
    }
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  AppSize.gapH(20),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final user = state is AuthAuthenticated ? state.user : null;
                      return _buildProfileSection(user);
                    },
                  ),
                  AppSize.gapH(24),
                  _buildSection(
                    title: 'ПРИЛОЖЕНИЕ',
                    children: [
                      _buildThemeSelector(),
                      _buildSettingsItem(
                        icon: Icons.notifications_outlined,
                        label: 'Настройка уведомлений',
                        subtitle: 'Календарь, сон, настроение, дневник',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => NotificationsPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  AppSize.gapH(24),
                  _buildSection(
                    title: 'ДОВЕРЕННЫЙ КОНТАКТ',
                    children: [
                      _buildTrustedContactCard(),
                    ],
                  ),
                  AppSize.gapH(24),
                  _buildSection(
                    title: 'ДАННЫЕ И ПРИВАТНОСТЬ',
                    children: [
                      _buildToggleItem(
                        icon: Icons.lock_outline,
                        label: 'Блокировка PIN-кодом',
                        value: _pinOn,
                        onChanged: _togglePin,
                      ),
                      _buildSettingsItem(
                        icon: Icons.download_outlined,
                        label: 'Экспорт моих данных',
                        subtitle: 'Все записи одним JSON в буфер обмена',
                        onTap: _exportMyData,
                      ),
                      _buildSettingsItem(
                        icon: Icons.delete_forever_outlined,
                        label: 'Удалить аккаунт',
                        subtitle: 'Безвозвратно удалить все данные',
                        onTap: _confirmDeleteAccount,
                      ),
                    ],
                  ),
                  AppSize.gapH(24),
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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => HelpScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                  AppSize.gapH(32),
                  _buildLogoutButton(),
                  AppSize.gapH(20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Экспорт всех данных пользователя: JSON копируется в буфер обмена
  Future<void> _exportMyData() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final token = authState.user.token;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Готовим экспорт данных...')),
    );

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/user/data-export'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final pretty = const JsonEncoder.withIndent('  ')
          .convert(jsonDecode(utf8.decode(response.bodyBytes)));
      await Clipboard.setData(ClipboardData(text: pretty));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Данные скопированы в буфер обмена (JSON)'),
          backgroundColor: AppColors.citrusGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e, fallback: 'Не удалось выполнить экспорт данных.')),
          backgroundColor: AppColors.destructive,
        ),
      );
    }
  }

  /// Удаление аккаунта со всеми данными (с подтверждением)
  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface1,
        shape: RoundedRectangleBorder(
          borderRadius: AppSize.radius(16),
          side: BorderSide(color: AppColors.destructive.withValues(alpha: 0.3)),
        ),
        title: Text('Удалить аккаунт?', style: TextStyle(color: AppColors.foreground)),
        content: Text(
          'Будут безвозвратно удалены все ваши данные: настроение, сон, дневник, '
          'календарь, фото, результаты тестов и история чата. '
          'Это действие нельзя отменить.',
          style: TextStyle(color: AppColors.mutedForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Отмена', style: TextStyle(color: AppColors.mutedForeground)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.destructive),
            child: Text('Удалить навсегда'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final token = authState.user.token;

    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/user/account'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Аккаунт и все данные удалены'),
          backgroundColor: Colors.orange,
        ),
      );
      context.read<AuthBloc>().add(AuthLogout());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyError(e, fallback: 'Не удалось удалить аккаунт.')),
          backgroundColor: AppColors.destructive,
        ),
      );
    }
  }

  Widget _buildHeader() {
    return Text(
      'Настройки',
      style: TextStyle(
        fontSize: AppSize.s(24),
        fontWeight: FontWeight.w700,
        color: AppColors.foreground,
      ),
    );
  }

  // === Секция профиля (просмотр / редактирование) ===
  Widget _buildProfileSection(User? user) {
    final displayName = user?.name ?? 'Пользователь';
    final displayEmail = user?.email ?? 'Не авторизован';
    final avatarUrl = _isEditingProfile ? _profileAvatarUrl : user?.avatarUrl;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: AppSize.radius(16),
        border: Border.all(color: AppColors.subtleBorder),
      ),
      child: Column(
        children: [
          // Шапка профиля: аватар + имя + email
          Padding(
            padding: AppSize.padding(16),
            child: Row(
              children: [
                _buildAvatar(avatarUrl, displayName),
                AppSize.gapW(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: AppSize.s(16),
                          fontWeight: FontWeight.w600,
                          color: AppColors.foreground,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      AppSize.gapH(2),
                      Text(
                        displayEmail,
                        style: TextStyle(
                          fontSize: AppSize.s(12),
                          color: AppColors.mutedForeground,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!_isEditingProfile)
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: AppColors.citrusOrange, size: 20),
                    onPressed: () => _startEditingProfile(user),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
              ],
            ),
          ),

          // Форма редактирования профиля
          if (_isEditingProfile) ...[
            Divider(height: 1, color: AppColors.subtleBorder),
            Padding(
              padding: AppSize.padding(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Аватар с кнопкой смены
                  Center(
                    child: GestureDetector(
                      onTap: _isUploadingAvatar ? null : _pickAvatar,
                      child: Stack(
                        children: [
                          _buildAvatar(avatarUrl, _profileNameController.text, size: 90),
                          if (_isUploadingAvatar)
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black54,
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.citrusOrange,
                                  strokeWidth: 3,
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.citrusOrange,
                                border: Border.all(color: AppColors.surface1, width: 2),
                              ),
                              child: Icon(Icons.camera_alt, color: Colors.white, size: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppSize.gapH(20),
                  // Имя
                  Text(
                    'Имя',
                    style: TextStyle(
                      fontSize: AppSize.s(12),
                      fontWeight: FontWeight.w600,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  AppSize.gapH(6),
                  TextField(
                    controller: _profileNameController,
                    decoration: InputDecoration(
                      hintText: 'Введите ваше имя',
                      filled: true,
                      fillColor: AppColors.surface2,
                      border: OutlineInputBorder(
                        borderRadius: AppSize.radius(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: AppSize.paddingH(12, 10),
                      isDense: true,
                      prefixIcon: Icon(Icons.person_outline, color: AppColors.mutedForeground, size: 18),
                    ),
                    style: TextStyle(fontSize: AppSize.s(14), color: AppColors.foreground),
                  ),
                  AppSize.gapH(12),
                  // Телефон
                  Text(
                    'Телефон',
                    style: TextStyle(
                      fontSize: AppSize.s(12),
                      fontWeight: FontWeight.w600,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  AppSize.gapH(6),
                  TextField(
                    controller: _profilePhoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [PhoneInputFormatter()],
                    decoration: InputDecoration(
                      hintText: '+7 (___) ___-__-__',
                      filled: true,
                      fillColor: AppColors.surface2,
                      border: OutlineInputBorder(
                        borderRadius: AppSize.radius(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: AppSize.paddingH(12, 10),
                      isDense: true,
                      prefixIcon: Icon(Icons.phone_outlined, color: AppColors.mutedForeground, size: 18),
                    ),
                    style: TextStyle(fontSize: AppSize.s(14), color: AppColors.foreground),
                  ),
                  AppSize.gapH(16),
                  // Кнопки
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSavingProfile ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.citrusGreen,
                            disabledBackgroundColor: AppColors.citrusGreen.withValues(alpha: 0.5),
                            padding: AppSize.paddingH(0, 10),
                            shape: RoundedRectangleBorder(borderRadius: AppSize.radius(10)),
                          ),
                          child: _isSavingProfile
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text('Сохранить', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      AppSize.gapW(8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _cancelEditingProfile,
                          style: OutlinedButton.styleFrom(
                            padding: AppSize.paddingH(0, 10),
                            shape: RoundedRectangleBorder(borderRadius: AppSize.radius(10)),
                          ),
                          child: Text('Отмена'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl, String displayName, {double size = 56}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: avatarUrl == null
            ? LinearGradient(
                colors: [AppColors.citrusOrange, AppColors.citrusAmber],
              )
            : null,
        image: avatarUrl != null
            ? DecorationImage(
                image: CachedNetworkImageProvider(avatarUrl),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: avatarUrl == null
          ? Center(
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: size * 0.43,
                  fontWeight: FontWeight.bold,
                  color: AppColors.background,
                ),
              ),
            )
          : null,
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
            padding: AppSize.padding(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCreating
                      ? 'Новый доверенный контакт'
                      : 'Редактировать контакт',
                  style: TextStyle(
                    fontSize: AppSize.s(13),
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
                AppSize.gapH(12),
                TextField(
                  controller: _trustedNameController,
                  decoration: InputDecoration(
                    labelText: 'Имя',
                    hintText: 'Мама, Друг и т.д.',
                    filled: true,
                    fillColor: AppColors.surface2,
                    border: OutlineInputBorder(
                      borderRadius: AppSize.radius(12),
                    ),
                    contentPadding: AppSize.paddingH(12, 10),
                    isDense: true,
                  ),
                ),
                AppSize.gapH(8),
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
                      borderRadius: AppSize.radius(12),
                    ),
                    contentPadding: AppSize.paddingH(12, 10),
                    isDense: true,
                  ),
                ),
                AppSize.gapH(12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveTrustedContact,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.citrusGreen,
                          padding: AppSize.paddingH(0, 10),
                          shape: RoundedRectangleBorder(borderRadius: AppSize.radius(10)),
                        ),
                        child: Text('Сохранить', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    AppSize.gapW(8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _cancelEditing,
                        style: OutlinedButton.styleFrom(
                          padding: AppSize.paddingH(0, 10),
                          shape: RoundedRectangleBorder(borderRadius: AppSize.radius(10)),
                        ),
                        child: Text('Отмена'),
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
              borderRadius: AppSize.radius(16),
              child: Padding(
                padding: AppSize.paddingH(16, 16),
                child: Row(
                  children: [
                    Icon(Icons.person_add_outlined, color: AppColors.citrusOrange, size: 20),
                    AppSize.gapW(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Добавить доверенный контакт',
                            style: TextStyle(
                              fontSize: AppSize.s(14),
                              fontWeight: FontWeight.w500,
                              color: AppColors.foreground,
                            ),
                          ),
                          AppSize.gapH(2),
                          Text(
                            'Для отправки SOS-сообщений',
                            style: TextStyle(
                              fontSize: AppSize.s(12),
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
                padding: AppSize.paddingH(16, 12),
                child: Row(
                  children: [
                    Icon(Icons.favorite, color: AppColors.destructive, size: 18),
                    AppSize.gapW(10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contact['name']?.isNotEmpty == true
                                ? contact['name']
                                : 'Контакт',
                            style: TextStyle(
                              fontSize: AppSize.s(14),
                              fontWeight: FontWeight.w600,
                              color: AppColors.foreground,
                            ),
                          ),
                          Text(
                            _formatPhoneForDisplay(contact['phone']),
                            style: TextStyle(
                              fontSize: AppSize.s(12),
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, size: 18),
                      onPressed: () => _editContact(contact),
                      color: AppColors.mutedForeground,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                    AppSize.gapW(12),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 18),
                      onPressed: () => _deleteContact(contact['id']),
                      color: AppColors.destructive,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
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
                padding: AppSize.paddingH(16, 12),
                child: Row(
                  children: [
                    Icon(Icons.add, color: AppColors.citrusOrange, size: 20),
                    AppSize.gapW(8),
                    Text(
                      'Добавить ещё',
                      style: TextStyle(
                        fontSize: AppSize.s(13),
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
          padding: AppSize.paddingOnly(bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: AppSize.s(11),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: AppColors.mutedForeground,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface1,
            borderRadius: AppSize.radius(16),
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
          padding: AppSize.paddingH(16, 12),
          child: Row(
            children: [
              Icon(Icons.palette_outlined, color: AppColors.mutedForeground, size: 20),
              AppSize.gapW(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Тема',
                      style: TextStyle(
                        fontSize: AppSize.s(14),
                        fontWeight: FontWeight.w500,
                        color: AppColors.foreground,
                      ),
                    ),
                    Text(
                      isDark ? 'Тёмная' : 'Светлая',
                      style: TextStyle(
                        fontSize: AppSize.s(12),
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              SegmentedButton<int>(
                segments: [
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
                  selectedBackgroundColor: AppColors.citrusOrange.withValues(alpha: 0.2),
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
      padding: AppSize.paddingH(16, 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.mutedForeground, size: 20),
          AppSize.gapW(12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppSize.s(14),
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
        borderRadius: AppSize.radius(16),
        child: Padding(
          padding: AppSize.paddingH(16, 12),
          child: Row(
            children: [
              Icon(icon, color: AppColors.mutedForeground, size: 20),
              AppSize.gapW(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
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
        color: AppColors.destructive.withValues(alpha: 0.1),
        borderRadius: AppSize.radius(16),
        border: Border.all(color: AppColors.destructive.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLogoutDialog(context),
          borderRadius: AppSize.radius(16),
          child: Padding(
            padding: AppSize.paddingH(0, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout, color: AppColors.destructive, size: 20),
                AppSize.gapW(8),
                Text(
                  'Выйти из аккаунта',
                  style: TextStyle(
                    fontSize: AppSize.s(15),
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
          borderRadius: AppSize.radius(16),
          side: BorderSide(color: AppColors.destructive.withValues(alpha: 0.3)),
        ),
        icon: Icon(Icons.logout, color: AppColors.destructive, size: 32),
        title: Text(
          'Выйти из аккаунта?',
          style: TextStyle(color: AppColors.foreground, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Вы будете перенаправлены на страницу входа. Все несохранённые данные будут потеряны.',
          style: TextStyle(color: AppColors.mutedForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Отмена', style: TextStyle(color: AppColors.mutedForeground)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(AuthLogout());
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.destructive,
            ),
            child: Text('Выйти'),
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

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface1,
        shape: RoundedRectangleBorder(borderRadius: AppSize.radius(16)),
        title: Row(
          children: [
            Icon(Icons.info, color: AppColors.citrusOrange),
            AppSize.gapW(8),
            Text('О приложении', style: TextStyle(color: AppColors.foreground)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Цитрус — персональный помощник ментального здоровья',
              style: TextStyle(color: AppColors.foreground, fontWeight: FontWeight.w500),
            ),
            AppSize.gapH(8),
            Text(
              'Версия: 1.0.0 (Beta)\n\nПриложение включает:\n• Трекер настроения\n• Трекер сна\n• Календарь событий\n• ИИ-чат\n• Упражнения и медитации\n• Аналитику',
              style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(13)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Закрыть', style: TextStyle(color: AppColors.citrusOrange)),
          ),
        ],
      ),
    );
  }
}
