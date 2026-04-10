import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _dailyReminders = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.foreground),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    '\u041D\u0430\u0441\u0442\u0440\u043E\u0439\u043A\u0438',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.foreground),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildProfileCard(),
              const SizedBox(height: 24),
              _buildSettingsGroup(
                title: '\u0410\u041A\u041A\u0410\u0423\u041D\u0422',
                items: [
                  _buildSettingsItem(icon: Icons.person_outline, label: '\u041F\u0440\u043E\u0444\u0438\u043B\u044C', onTap: () {}),
                  _buildSettingsItem(
                    icon: Icons.notifications_none,
                    label: '\u0423\u0432\u0435\u0434\u043E\u043C\u043B\u0435\u043D\u0438\u044F',
                    trailing: _buildNotificationToggle(),
                    onTap: null,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSettingsGroup(
                title: '\u041F\u0420\u0418\u041B\u041E\u0416\u0415\u041D\u0418\u0415',
                items: [
                  _buildSettingsItem(icon: Icons.palette_outlined, label: '\u0422\u0435\u043C\u0430', onTap: _showNotificationsModal),
                  _buildSettingsItem(icon: Icons.devices, label: '\u041A\u043E\u043D\u0442\u0435\u043D\u0442', onTap: () {}),
                ],
              ),
              const SizedBox(height: 20),
              _buildSettingsGroup(
                title: '\u0421\u0422\u0410\u0422\u044C\u0418',
                items: [
                  _buildSettingsItem(icon: Icons.article_outlined, label: '\u0421\u043E\u0437\u0434\u0430\u0442\u044C \u0441\u0442\u0430\u0442\u044C\u044E', onTap: _showArticleModal),
                ],
              ),
              const SizedBox(height: 20),
              _buildSettingsGroup(
                title: '\u041F\u041E\u0414\u0414\u0415\u0420\u0416\u041A\u0410',
                items: [
                  _buildSettingsItem(icon: Icons.info_outline, label: '\u041E \u043F\u0440\u0438\u043B\u043E\u0436\u0435\u043D\u0438\u0438', onTap: () {}),
                  _buildSettingsItem(icon: Icons.help_outline, label: '\u041F\u043E\u043C\u043E\u0449\u044C', onTap: () {}),
                ],
              ),
              const SizedBox(height: 24),
              _buildLogoutButton(),
              const SizedBox(height: 24),
              _buildAppVersion(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
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
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.citrusOrange, AppColors.citrusAmber],
              ),
            ),
            child: const Center(child: Text('\u{1F464}', style: TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '\u0421\u0442\u0443\u0434\u0435\u043D\u0442',
                  style: TextStyle(color: AppColors.foreground, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                const Text(
                  'student@citrus.app',
                  style: TextStyle(color: AppColors.mutedForeground, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.moodExcellent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        '\u0410\u043A\u0442\u0438\u0432\u0435\u043D',
                        style: TextStyle(color: Color(0xFF4ADE80), fontSize: 10, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '\u{1F525} 7 \u0434\u043D\u0435\u0439',
                      style: TextStyle(color: AppColors.citrusOrange, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit_outlined, color: AppColors.mutedForeground, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.dimForeground,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface1,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.subtleBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: items.asMap().entries.map((entry) {
              return Column(
                children: [
                  entry.value,
                  if (entry.key < items.length - 1)
                    Divider(height: 1, color: Colors.white.withOpacity(0.05)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String label,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.citrusOrange.withOpacity(0.12),
                ),
                child: Icon(icon, color: AppColors.citrusOrange, size: 16),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: AppColors.foreground, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              trailing ?? const Icon(Icons.chevron_right, color: AppColors.mutedForeground, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationToggle() {
    return SizedBox(
      width: 44,
      height: 24,
      child: Switch(
        value: _notificationsEnabled,
        onChanged: (value) => setState(() => _notificationsEnabled = value),
        activeColor: Colors.white,
        activeTrackColor: AppColors.citrusOrange,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: Colors.white.withOpacity(0.1),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _showLogoutDialog,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.destructive.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.destructive.withOpacity(0.25)),
        ),
        child: const Text(
          '\u0412\u044B\u0439\u0442\u0438 \u0438\u0437 \u0430\u043A\u043A\u0430\u0443\u043D\u0442\u0430',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.destructive,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildAppVersion() {
    return const Center(
      child: Column(
        children: [
          Text(
            '\u0426\u0438\u0442\u0440\u0443\u0441 v1.0.0',
            style: TextStyle(color: AppColors.dimForeground, fontSize: 12),
          ),
          SizedBox(height: 4),
          Text(
            '\u041C\u043E\u043D\u0438\u0442\u043E\u0440\u0438\u043D\u0433 \u043C\u0435\u043D\u0442\u0430\u043B\u044C\u043D\u043E\u0433\u043E \u0437\u0434\u043E\u0440\u043E\u0432\u044C\u044F',
            style: TextStyle(color: AppColors.dimForeground, fontSize: 11),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('\u0412\u044B\u0445\u043E\u0434', style: TextStyle(color: AppColors.foreground)),
        content: const Text('\u0412\u044B \u0443\u0432\u0435\u0440\u0435\u043D\u044B, \u0447\u0442\u043E \u0445\u043E\u0442\u0438\u0442\u0435 \u0432\u044B\u0439\u0442\u0438?', style: TextStyle(color: AppColors.mutedForeground)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('\u041E\u0442\u043C\u0435\u043D\u0430', style: TextStyle(color: AppColors.citrusOrange)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(backgroundColor: AppColors.destructive),
            child: const Text('\u0412\u044B\u0439\u0442\u0438'),
          ),
        ],
      ),
    );
  }

  void _showNotificationsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface1,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: Color(0xFF2A2830))),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.dimForeground,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                '\u0423\u0432\u0435\u0434\u043E\u043C\u043B\u0435\u043D\u0438\u044F',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.foreground),
              ),
              const SizedBox(height: 20),
              _buildSwitchRow(
                label: '\u041E\u0441\u043D\u043E\u0432\u043D\u044B\u0435 \u0443\u0432\u0435\u0434\u043E\u043C\u043B\u0435\u043D\u0438\u044F',
                value: _notificationsEnabled,
                onChanged: (v) => setModalState(() => _notificationsEnabled = v),
              ),
              _buildSwitchRow(
                label: '\u0415\u0436\u0435\u0434\u043D\u0435\u0432\u043D\u044B\u0435 \u043D\u0430\u043F\u043E\u043C\u0438\u043D\u0430\u043D\u0438\u044F',
                value: _dailyReminders,
                onChanged: (v) => setModalState(() => _dailyReminders = v),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {});
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.citrusOrange,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('\u0421\u043E\u0445\u0440\u0430\u043D\u0438\u0442\u044C', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchRow({required String label, required bool value, required ValueChanged<bool> onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.foreground, fontSize: 14)),
          SizedBox(
            width: 44,
            height: 24,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: AppColors.citrusOrange,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.white.withOpacity(0.1),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  void _showArticleModal() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Color(0xFF2A2830))),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.dimForeground,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              '\u041D\u043E\u0432\u0430\u044F \u0441\u0442\u0430\u0442\u044C\u044F',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.foreground),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: titleController,
              style: const TextStyle(color: AppColors.foreground),
              decoration: InputDecoration(
                labelText: '\u0417\u0430\u0433\u043E\u043B\u043E\u0432\u043E\u043A',
                labelStyle: const TextStyle(color: AppColors.mutedForeground),
                filled: true,
                fillColor: AppColors.surface2,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              style: const TextStyle(color: AppColors.foreground),
              minLines: 4,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: '\u0421\u043E\u0434\u0435\u0440\u0436\u0430\u043D\u0438\u0435',
                labelStyle: const TextStyle(color: AppColors.mutedForeground),
                filled: true,
                fillColor: AppColors.surface2,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.citrusOrange, AppColors.citrusAmber]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('\u041E\u043F\u0443\u0431\u043B\u0438\u043A\u043E\u0432\u0430\u0442\u044C', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
