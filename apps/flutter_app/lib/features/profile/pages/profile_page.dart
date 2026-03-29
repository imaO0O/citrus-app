import 'package:flutter/material.dart';
import '../../../core/utils/theme_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          IconButton(
            icon: Icon(themeService.isDarkMode ? Icons.dark_mode : Icons.light_mode),
            onPressed: () {
              themeService.toggleTheme(!themeService.isDarkMode);
            },
            tooltip: themeService.isDarkMode ? 'Светлая тема' : 'Тёмная тема',
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildThemeCard(context, themeService),
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
            leading: const Icon(Icons.bedtime_outlined),
            title: const Text('Трекер сна'),
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
  }

  Widget _buildThemeCard(BuildContext context, ThemeService themeService) {
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
                  themeService.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  size: 32,
                  color: themeService.isDarkMode ? Colors.amber : Colors.orange,
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
            SwitchListTile(
              title: const Text('Тёмная тема'),
              subtitle: Text(
                themeService.isDarkMode ? 'Включена' : 'Выключена',
              ),
              value: themeService.isDarkMode,
              onChanged: (value) {
                themeService.toggleTheme(value);
              },
              secondary: Icon(
                themeService.isDarkMode ? Icons.check_circle : Icons.circle_outlined,
                color: themeService.isDarkMode ? Colors.green : Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Выберите удобный режим отображения приложения',
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
}
