import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/mood.dart';

class MoodLog extends StatelessWidget {
  final List<MoodLogEntry> entries;

  const MoodLog({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Сегодня',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFFEDE8E0),
            ),
          ),
          const SizedBox(height: 8),
          ...entries.map(_buildEntry),
        ],
      ),
    );
  }

  Widget _buildEntry(MoodLogEntry entry) {
    final mood = Mood.all.firstWhere((m) => m.id == entry.moodId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color.fromRGBO(255, 255, 255, 0.05),
          ),
        ),
        child: Row(
          children: [
            Text(mood.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mood.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFEDE8E0),
                ),
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: mood.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: mood.glow,
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              DateFormat('HH:mm').format(entry.timestamp),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF5A5468),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
