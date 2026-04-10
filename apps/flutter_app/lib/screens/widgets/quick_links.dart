import 'package:flutter/material.dart';

class QuickLinks extends StatelessWidget {
  final VoidCallback onExerciseTap;
  final VoidCallback onChatTap;
  final VoidCallback onDiaryTap;
  final VoidCallback onSleepTap;

  const QuickLinks({
    super.key,
    required this.onExerciseTap,
    required this.onChatTap,
    required this.onDiaryTap,
    required this.onSleepTap,
  });

  @override
  Widget build(BuildContext context) {
    final links = [
      _QuickLinkItem(
        icon: '🌬️',
        label: 'Дыхание',
        onTap: onExerciseTap,
      ),
      _QuickLinkItem(
        icon: '🤖',
        label: 'ИИ Чат',
        onTap: onChatTap,
      ),
      _QuickLinkItem(
        icon: '📝',
        label: 'Дневник',
        onTap: onDiaryTap,
      ),
      _QuickLinkItem(
        icon: '🌙',
        label: 'Сон',
        onTap: onSleepTap,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: links
            .map((link) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: link,
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _QuickLinkItem extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _QuickLinkItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color.fromRGBO(255, 255, 255, 0.05),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Color(0xFF8A8298),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
