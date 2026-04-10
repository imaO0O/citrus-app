import 'package:flutter/material.dart';
import 'settings_screen.dart';
import 'analytics_screen.dart';
import 'sleep_tracker_screen.dart';
import 'tests_screen.dart';
import 'exercises_screen.dart';
import 'media_screen.dart';
import 'affirmations_screen.dart';
import 'photo_gallery_screen.dart';
import 'toy_screen.dart';
import 'sos_screen.dart';

const _kBackground = Color(0xFF111111);
const _kSurface1 = Color(0xFF131320);
const _kSurface2 = Color(0xFF1A1A2A);
const _kForeground = Color(0xFFEDE8E0);
const _kPrimary = Color(0xFFFF8C42);
const _kMuted = Color(0xFF8A8298);
const _kMutedDeep = Color(0xFF6B6578);

class _FeatureItem {
  final String emoji;
  final String title;
  final String description;
  final Widget? screen;

  const _FeatureItem({
    required this.emoji,
    required this.title,
    required this.description,
    this.screen,
  });
}

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  void _openFeature(BuildContext context, _FeatureItem feature) {
    if (feature.screen != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => feature.screen!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Stack(
          children: [
            Container(color: Colors.black.withOpacity(0.6)),
            Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  decoration: const BoxDecoration(
                    color: _kBackground,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    border: Border(
                      top: BorderSide(color: Colors.white10, width: 1),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'ДОПОЛНИТЕЛЬНО',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: _kMutedDeep,
                          ),
                        ),
                      ),
                      const _FeatureGrid(onTap: _openFeature),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  final void Function(BuildContext, _FeatureItem) onTap;

  const _FeatureGrid({required this.onTap});

  List<_FeatureItem> get _features => [
    const _FeatureItem(
      emoji: '📈',
      title: 'Аналитика',
      description: 'Статистика и графики',
      screen: AnalyticsScreen(),
    ),
    const _FeatureItem(
      emoji: '🌙',
      title: 'Трекер сна',
      description: 'Качество сна',
      screen: SleepTrackerScreen(),
    ),
    const _FeatureItem(
      emoji: '🧪',
      title: 'Тесты',
      description: 'Психологические тесты',
      screen: TestsScreen(),
    ),
    const _FeatureItem(
      emoji: '🧘',
      title: 'Упражнения',
      description: 'Дыхание и релакс',
      screen: ExercisesScreen(),
    ),
    const _FeatureItem(
      emoji: '🎵',
      title: 'Медиа',
      description: 'Медитации',
      screen: MediaScreen(),
    ),
    const _FeatureItem(
      emoji: '💫',
      title: 'Аффирмации',
      description: 'Позитивные установки',
      screen: AffirmationsScreen(),
    ),
    const _FeatureItem(
      emoji: '📸',
      title: 'Галерея',
      description: 'Счастливые моменты',
      screen: PhotoGalleryScreen(),
    ),
    const _FeatureItem(
      emoji: '🎮',
      title: 'Антистресс',
      description: 'Игры',
      screen: ToyScreen(),
    ),
    const _FeatureItem(
      emoji: '⚙️',
      title: 'Настройки',
      description: 'Профиль',
      screen: SettingsScreen(),
    ),
    const _FeatureItem(
      emoji: '🆘',
      title: 'SOS',
      description: 'Экстренная помощь',
      screen: SOScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: _features.length,
      itemBuilder: (context, index) {
        final feature = _features[index];
        final isActive = feature.screen != null;

        return GestureDetector(
          onTap: () => onTap(context, feature),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive
                  ? _kPrimary.withOpacity(0.15)
                  : Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive
                    ? _kPrimary.withOpacity(0.35)
                    : Colors.white.withOpacity(0.06),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(feature.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 8),
                Text(
                  feature.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _kForeground,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  feature.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _kMutedDeep,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
