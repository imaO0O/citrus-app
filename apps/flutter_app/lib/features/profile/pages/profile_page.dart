import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/repository/auth_repository.dart' as auth_repo;
import '../../../core/repository/auth_repository.dart';
import '../../../core/utils/theme_service.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/profile_bloc.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<auth_repo.Theme> _themes = [];
  auth_repo.Theme? _currentTheme;

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(LoadProfile());
    _loadThemes();
  }

  Future<void> _loadThemes() async {
    try {
      final authRepository = context.read<AuthRepository>();
      final themes = await authRepository.apiService.getThemes();
      setState(() {
        _themes = themes;
      });
    } catch (e) {
      print('Ошибка загрузки тем: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService();

    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        auth_repo.User? user;
        if (state is ProfileLoaded) {
          user = state.user;
          // Находим текущую тему пользователя
          if (user?.themeId != null && _themes.isNotEmpty) {
            _currentTheme = _themes.firstWhere(
              (t) => t.id == user!.themeId,
              orElse: () => _themes.first,
            );
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Профиль'),
          ),
          body: ListView(
            children: [
              _buildUserInfoCard(user),
              _buildThemeCard(context),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.article_outlined),
                title: const Text('Настройка предпочтений по статьям'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Настройка уведомлений'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('Выгрузка аналитики'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.psychology_outlined),
                title: const Text('Тесты (подходящий отдых)'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Создать кастомную статью'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeCard(BuildContext context) {
    final authRepository = context.read<AuthRepository>();
    final authBloc = context.read<AuthBloc>();
    final user = authBloc.state is AuthAuthenticated
        ? (authBloc.state as AuthAuthenticated).user
        : null;
    final themeService = ThemeService();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _currentTheme?.isDark ?? false ? Icons.dark_mode : Icons.light_mode,
                  size: 32,
                  color: _currentTheme != null
                      ? Color(int.parse(_currentTheme!.primaryColor.replaceFirst('#', '0xFF')))
                      : Colors.blue,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Тема оформления',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _currentTheme?.id,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Выберите тему',
              ),
              items: _themes.map((theme) {
                return DropdownMenuItem<String>(
                  value: theme.id,
                  child: Row(
                    children: [
                      Icon(
                        theme.isDark ? Icons.dark_mode : Icons.light_mode,
                        color: Color(int.parse(theme.primaryColor.replaceFirst('#', '0xFF'))),
                      ),
                      const SizedBox(width: 8),
                      Text(theme.name),
                    ],
                  ),
                );
              }).cast<DropdownMenuItem<String>>().toList(),
              onChanged: user != null ? (String? newThemeId) async {
                if (newThemeId == null) return;

                try {
                  await authRepository.apiService.updateTheme(user.token, newThemeId);

                  // Применяем тему
                  final selectedTheme = _themes.firstWhere((t) => t.id == newThemeId);
                  themeService.toggleTheme(selectedTheme.isDark);

                  // Обновляем тему пользователя в BLoC
                  final updatedUser = User(
                    id: user.id,
                    email: user.email,
                    name: user.name,
                    themeId: newThemeId,
                    token: user.token,
                  );
                  context.read<AuthBloc>().add(AuthThemeChanged(updatedUser));

                  // Обновляем локальное состояние
                  if (mounted) {
                    setState(() {
                      _currentTheme = selectedTheme;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Тема применена'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Ошибка: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } : null,
            ),
            const SizedBox(height: 8),
            Text(
              'Выберите удобный стиль отображения приложения',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(dynamic user) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue[100],
                  child: Icon(Icons.person, size: 30, color: Colors.blue[700]),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Пользователь',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Выход'),
                      content: const Text('Вы уверены, что хотите выйти?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Отмена'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            context.read<AuthBloc>().add(const AuthLogout());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Выйти'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Выйти из аккаунта',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
