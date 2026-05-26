import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:just_audio/just_audio.dart';
import '../core/theme/app_colors.dart';
import '../core/services/casino_coins_service.dart';
import '../core/services/exercise_tracker_service.dart';
import '../core/config/api_config.dart';
import '../core/utils/app_size.dart';

class ExerciseItem {
  final String id;
  final String icon;
  final String title;
  final String description;
  final String duration;
  final String difficulty;
  final String type;
  final String category;
  final List<String> steps;
  final Color color;
  final int durationSeconds;
  final String? videoUrl;
  final String? videoEmbedUrl;
  final String? audioUrl;
  final String? audioTitle;
  final String? audioEmbedUrl;
  // Для дыхательных упражнений
  final List<int>? phaseDurations; // длительность каждой фазы (сек)
  final bool cycles; // повторять цикл фаз
  final List<Color>? phaseColors; // цвет для каждой фазы
  final List<double>? phaseScales; // масштаб круга для каждой фазы
  final List<String>? phaseLabels; // короткие названия фаз для круга

  ExerciseItem({
    required this.id,
    required this.icon,
    required this.title,
    required this.description,
    required this.duration,
    required this.difficulty,
    required this.type,
    required this.category,
    required this.steps,
    this.color = AppColors.citrusOrange,
    required this.durationSeconds,
    this.videoUrl,
    this.videoEmbedUrl,
    this.audioUrl,
    this.audioTitle,
    this.audioEmbedUrl,
    this.phaseDurations,
    this.cycles = false,
    this.phaseColors,
    this.phaseScales,
    this.phaseLabels,
  });
}

const _categories = ['Все', 'Дыхание', 'Видео', 'Аудио'];

final _exercises = [
  // === САМЫЕ ПОПУЛЯРНЫЕ ДЫХАТЕЛЬНЫЕ УПРАЖНЕНИЯ ===

  // 1. Квадратное дыхание — Navy SEALs, фокус и концентрация
  ExerciseItem(
    id: 'box_breathing',
    icon: '⬜',
    title: 'Квадратное дыхание',
    description: 'Техника 4-4-4-4. Используют Navy SEALs для контроля в стрессе',
    duration: '5 мин',
    difficulty: 'Легко',
    type: 'Дыхание',
    category: 'Дыхание',
    color: AppColors.citrusGreen,
    steps: [
      'Вдох через нос',
      'Задержка дыхания',
      'Выдох через рот',
      'Задержка дыхания',
    ],
    durationSeconds: 300,
    phaseDurations: [4, 4, 4, 4],
    phaseLabels: ['Вдох', 'Задержка', 'Выдох', 'Задержка'],
    phaseColors: [
      Color(0xFF8BC34A), // Вдох — зелёный (рост, энергия)
      Color(0xFFFFD93D), // Задержка — жёлтый (внимание)
      Color(0xFF74B9FF), // Выдох — голубой (расслабление)
      Color(0xFFFFD93D), // Задержка — жёлтый
    ],
    phaseScales: [
      1.0,  // Вдох — круг полный
      1.0,  // Задержка — круг полный, замирание
      0.6,  // Выдох — круг пустой
      0.6,  // Задержка — круг пустой, замирание
    ],
    cycles: true,
  ),

  // 2. Дыхание 4-7-8 — для сна и глубокого расслабления (доктор Вейл)
  ExerciseItem(
    id: 'relax_breathing',
    icon: '🌙',
    title: 'Дыхание 4-7-8',
    description: 'Метод доктора Вейла. Лучшее упражнение для сна и снятия тревоги',
    duration: '5 мин',
    difficulty: 'Средне',
    type: 'Дыхание',
    category: 'Дыхание',
    color: Color(0xFF9C88FF),
    steps: [
      'Вдох через нос',
      'Задержка дыхания',
      'Медленный выдох через рот',
    ],
    durationSeconds: 300,
    phaseDurations: [4, 7, 8],
    phaseLabels: ['Вдох', 'Задержка', 'Выдох'],
    phaseColors: [
      Color(0xFF9C88FF), // Вдох — фиолетовый (спокойствие)
      Color(0xFFFFD93D), // Задержка — жёлтый
      Color(0xFF74B9FF), // Выдох — голубой (глубокое расслабление)
    ],
    phaseScales: [
      1.0,  // Вдох — полный
      1.0,  // Задержка — полный, замирание
      0.6,  // Выдох — пустой (долгий)
    ],
    cycles: true,
  ),

  // 3. Метод Вима Хофа — энергия и бодрость
  ExerciseItem(
    id: 'wimhof_breathing',
    icon: '❄️',
    title: 'Дыхание Вима Хофа',
    description: 'Мощная техника для энергии, иммунитета и ясности ума',
    duration: '5 мин',
    difficulty: 'Сложно',
    type: 'Дыхание',
    category: 'Дыхание',
    color: AppColors.citrusOrange,
    steps: [
      'Глубокий мощный вдох',
      'Полный выдох',
    ],
    durationSeconds: 300,
    phaseDurations: [2, 2],
    phaseLabels: ['Вдох', 'Выдох'],
    phaseColors: [
      Color(0xFFFF8C42), // Вдох — оранжевый (энергия)
      Color(0xFF5A5468), // Выдох — тёмный (освобождение)
    ],
    phaseScales: [
      1.0,  // Вдох — полный
      0.5,  // Выдох — пустой
    ],
    cycles: true,
  ),

  // 4. Диафрагмальное дыхание — основа, снятие напряжения
  ExerciseItem(
    id: 'diaphragm_breathing',
    icon: '🫁',
    title: 'Дыхание животом',
    description: 'Базовая техника диафрагмы. Снижает кортизол и давление',
    duration: '7 мин',
    difficulty: 'Легко',
    type: 'Дыхание',
    category: 'Дыхание',
    color: Color(0xFF00CEC9),
    steps: [
      'Глубокий вдох животом',
      'Медленный выдох',
    ],
    durationSeconds: 420,
    phaseDurations: [5, 5],
    phaseLabels: ['Вдох', 'Выдох'],
    phaseColors: [
      Color(0xFF00CEC9), // Вдох — бирюзовый (свежесть)
      Color(0xFF74B9FF), // Выдох — голубой (расслабление)
    ],
    phaseScales: [
      1.0,  // Вдох — полный
      0.6,  // Выдох — пустой
    ],
    cycles: true,
  ),

  // 5. Кохерентное дыхание — баланс нервной системы
  ExerciseItem(
    id: 'coherent_breathing',
    icon: '🧘',
    title: 'Кохерентное дыхание',
    description: 'Ритм 5-5. Синхронизирует сердце и мозг для гармонии',
    duration: '5 мин',
    difficulty: 'Легко',
    type: 'Дыхание',
    category: 'Дыхание',
    color: Color(0xFF9B59B6),
    steps: [
      'Плавный вдох через нос',
      'Мягкий выдох через нос',
    ],
    durationSeconds: 300,
    phaseDurations: [5, 5],
    phaseLabels: ['Вдох', 'Выдох'],
    phaseColors: [
      Color(0xFF9B59B6), // Вдох — фиолетовый (баланс)
      Color(0xFFBB8FCE), // Выдох — светло-фиолетовый
    ],
    phaseScales: [
      1.0,  // Вдох — полный
      0.6,  // Выдох — пустой
    ],
    cycles: true,
  ),

  // 6. Энергетическое дыхание — бодрость
  ExerciseItem(
    id: 'energy_breathing',
    icon: '⚡',
    title: 'Энергия за 3 минуты',
    description: 'Техника 6-2-6. Быстро взбодрит и наполнит силой',
    duration: '3 мин',
    difficulty: 'Средне',
    type: 'Дыхание',
    category: 'Дыхание',
    color: Color(0xFFFF6B6B),
    steps: [
      'Глубокий активный вдох',
      'Короткая задержка',
      'Мощный выдох',
    ],
    durationSeconds: 180,
    phaseDurations: [6, 2, 6],
    phaseLabels: ['Вдох', 'Задержка', 'Выдох'],
    phaseColors: [
      Color(0xFFFF6B6B), // Вдох — красный (энергия)
      Color(0xFFFFD93D), // Задержка — жёлтый
      Color(0xFF74B9FF), // Выдох — голубой
    ],
    phaseScales: [
      1.0,  // Вдох — полный
      1.0,  // Задержка — полный
      0.5,  // Выдох — пустой
    ],
    cycles: true,
  ),

  // 7. Дыхание перед сном — глубокое расслабление
  ExerciseItem(
    id: 'sleep_breathing',
    icon: '🌙',
    title: 'Подготовка ко сну',
    description: 'Техника 4-8. Медленный выдох активирует парасимпатику',
    duration: '5 мин',
    difficulty: 'Легко',
    type: 'Дыхание',
    category: 'Дыхание',
    color: Color(0xFF5DADE2),
    steps: [
      'Спокойный вдох',
      'Длинный медленный выдох',
    ],
    durationSeconds: 300,
    phaseDurations: [4, 8],
    phaseLabels: ['Вдох', 'Выдох'],
    phaseColors: [
      Color(0xFF5DADE2), // Вдох — голубой (ночное небо)
      Color(0xFF2C3E50), // Выдох — тёмно-синий (сон)
    ],
    phaseScales: [
      1.0,  // Вдох — полный
      0.5,  // Выдох — пустой (медленный)
    ],
    cycles: true,
  ),

  // === ВИДЕО УПРАЖНЕНИЯ ===
  ExerciseItem(
    id: 'video_breathing_guided',
    icon: '🎬',
    title: 'Дыхательная медитация с гидом',
    description: 'Управляемая дыхательная медитация для начинающих',
    duration: '10 мин',
    difficulty: 'Легко',
    type: 'Видео',
    category: 'Видео',
    color: AppColors.citrusOrange,
    videoUrl: 'https://vk.com/video-224098011_456239907',
    videoEmbedUrl: 'https://vk.com/video_ext.php?oid=-224098011&id=456239907&hd=2',
    steps: [
      'Сядьте или лягте удобно',
      'Следуйте подсказкам в видео',
      'Дышите в показанном ритме',
      'Сосредоточьтесь на ощущениях',
      'Мягко завершите практику',
    ],
    durationSeconds: 600,
  ),
  ExerciseItem(
    id: 'video_body_scan',
    icon: '🎬',
    title: 'Шавасана — расслабление тела',
    description: 'Медитация сканирования тела для глубокого расслабления',
    duration: '15 мин',
    difficulty: 'Легко',
    type: 'Видео',
    category: 'Видео',
    color: Color(0xFF74B9FF),
    videoUrl: 'https://vk.com/video-27408214_456239760',
    videoEmbedUrl: 'https://vk.com/video_ext.php?oid=-27408214&id=456239760&hd=2',
    steps: [
      'Лягте на спину, руки вдоль тела',
      'Следуйте голосу в видео',
      'Перемещайте внимание от стоп к макушке',
      'Замечайте ощущения без оценки',
      'Расслабьтесь полностью к концу',
    ],
    durationSeconds: 900,
  ),
  ExerciseItem(
    id: 'video_meditation_relax',
    icon: '🎬',
    title: 'Медитация от стресса',
    description: 'Управляемая медитация для восстановления нервной системы',
    duration: '20 мин',
    difficulty: 'Легко',
    type: 'Видео',
    category: 'Видео',
    color: Color(0xFFFD79A8),
    videoUrl: 'https://vk.com/video-211495377_456239108',
    videoEmbedUrl: 'https://vk.com/video_ext.php?oid=-211495377&id=456239108&hd=2',
    steps: [
      'Подготовьте тихое удобное место',
      'Сядьте или лягте, закройте глаза',
      'Следуйте подсказкам гида',
      'Дышите глубоко и ровно',
      'Позвольте себе полностью расслабиться',
    ],
    durationSeconds: 1200,
  ),
  ExerciseItem(
    id: 'video_nature_sounds',
    icon: '🎬',
    title: 'Звуки леса',
    description: 'Видео с звуками природы для релаксации и сна',
    duration: '30 мин',
    difficulty: 'Легко',
    type: 'Видео',
    category: 'Видео',
    color: AppColors.citrusGreen,
    videoUrl: 'https://rutube.ru/video/7d00a214d5ed9f96ee136201ffa37618/',
    videoEmbedUrl: 'https://rutube.ru/play/embed/7d00a214d5ed9f96ee136201ffa37618/',
    steps: [
      'Устройтесь удобно',
      'Включите видео на полный экран',
      'Слушайте звуки природы',
      'Представьте, что вы в лесу',
      'Позвольте себе расслабиться',
    ],
    durationSeconds: 1800,
  ),

  // === АУДИО УПРАЖНЕНИЯ ===
  ExerciseItem(
    id: 'audio_rain_sounds',
    icon: '🌧️',
    title: 'Звуки дождя',
    description: 'Успокаивающие звуки дождя для медитации и сна',
    duration: '~3 мин',
    difficulty: 'Легко',
    type: 'Аудио',
    category: 'Аудио',
    color: Color(0xFF74B9FF),
    audioUrl: 'https://archive.org/download/rain_sounds_nature_202101/rain_sounds_nature_202101.mp3',
    audioTitle: 'Звуки дождя',
    steps: [
      'Найдите удобное положение',
      'Нажмите ▶ для воспроизведения',
      'Закройте глаза и слушайте',
      'Сосредоточьтесь на звуках дождя',
      'Позвольте мыслям свободно течь',
    ],
    durationSeconds: 180,
  ),
  ExerciseItem(
    id: 'audio_ocean_waves',
    icon: '🌊',
    title: 'Океанские волны',
    description: 'Ритмичные звуки океана для расслабления',
    duration: '~5 мин',
    difficulty: 'Легко',
    type: 'Аудио',
    category: 'Аудио',
    color: Color(0xFF00CEC9),
    audioUrl: 'https://archive.org/download/ocean_waves_relax_2020/ocean_waves_relax_2020.mp3',
    audioTitle: 'Океанские волны',
    steps: [
      'Лягте или сядьте удобно',
      'Нажмите ▶ для воспроизведения',
      'Дышите в ритме волн',
      'Представьте морской бриз',
      'Погрузитесь в спокойствие',
    ],
    durationSeconds: 300,
  ),
  ExerciseItem(
    id: 'audio_forest_sounds',
    icon: '🌲',
    title: 'Звуки леса',
    description: 'Пение птиц и шелест листьев для заземления',
    duration: '~5 мин',
    difficulty: 'Легко',
    type: 'Аудио',
    category: 'Аудио',
    color: AppColors.citrusGreen,
    audioUrl: 'https://archive.org/download/forest_birds_nature_2019/forest_birds_nature_2019.mp3',
    audioTitle: 'Звуки леса',
    steps: [
      'Устройтесь в тихом месте',
      'Нажмите ▶ для воспроизведения',
      'Представьте себя в лесу',
      'Слушайте пение птиц',
      'Ощутите спокойствие природы',
    ],
    durationSeconds: 300,
  ),
  ExerciseItem(
    id: 'audio_meditation_calm',
    icon: '🎵',
    title: 'Музыка для медитации',
    description: 'Расслабляющая мелодия для практики осознанности',
    duration: '~10 мин',
    difficulty: 'Легко',
    type: 'Аудио',
    category: 'Аудио',
    color: AppColors.citrusPurple,
    audioUrl: 'https://archive.org/download/peaceful-meditation-music/peaceful-meditation-music.mp3',
    audioTitle: 'Музыка для медитации',
    steps: [
      'Сядьте в тихом месте',
      'Нажмите ▶ для воспроизведения',
      'Дышите глубоко и ровно',
      'Позвольте музыке вести вас',
      'Мягко возвращайте внимание к дыханию',
    ],
    durationSeconds: 600,
  ),
  ExerciseItem(
    id: 'audio_binaural_relax',
    icon: '🔔',
    title: 'Медитационный гонг',
    description: 'Мягкий звук гонга для расслабления и концентрации',
    duration: '~3 мин',
    difficulty: 'Легко',
    type: 'Аудио',
    category: 'Аудио',
    color: Color(0xFF9C88FF),
    audioUrl: 'https://archive.org/download/meditation-gong-sound/meditation-gong-sound.mp3',
    audioTitle: 'Медитационный гонг',
    steps: [
      'Наденьте наушники',
      'Лягте удобно',
      'Нажмите ▶ для воспроизведения',
      'Позвольте звукам воздействовать на вас',
      'Не мешайте естественному расслаблению',
    ],
    durationSeconds: 180,
  ),
];

class ExercisesScreen extends StatefulWidget {
  ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  String _selectedCategory = 'Все';

  List<ExerciseItem> get _filteredExercises {
    if (_selectedCategory == 'Все') return _exercises;
    return _exercises.where((e) => e.category == _selectedCategory).toList();
  }

  void _showExerciseDetail(ExerciseItem exercise) {
    if (exercise.type == 'Видео' && exercise.videoEmbedUrl != null) {
      _openVideo(exercise);
    } else if (exercise.type == 'Аудио' && exercise.audioUrl != null) {
      _playAudio(exercise);
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ExerciseDetailSheet(exercise: exercise),
      );
    }
  }

  void _openVideo(ExerciseItem exercise) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoExerciseScreen(exercise: exercise),
      ),
    );
  }

  void _playAudio(ExerciseItem exercise) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AudioExerciseScreen(exercise: exercise),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Text(
                    'Упражнения',
                    style: TextStyle(fontSize: AppSize.s(24), fontWeight: FontWeight.w700, color: AppColors.foreground),
                  ),
                ),
                _buildQuickStartCard(),
                AppSize.gapH(16),
                _buildCategoryChips(),
                AppSize.gapH(16),
                Expanded(
                  child: ListView.builder(
                    padding: AppSize.paddingH(20, 0).copyWith(bottom: 80),
                    itemCount: _filteredExercises.length,
                    itemBuilder: (context, index) => Padding(
                      padding: AppSize.paddingOnly(bottom: 12),
                      child: _buildExerciseCard(_filteredExercises[index]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStartCard() {
    return Container(
      margin: AppSize.paddingH(20, 0),
      padding: AppSize.padding(16),
      decoration: BoxDecoration(
        color: AppColors.citrusPurple.withOpacity(0.1),
        borderRadius: AppSize.radius(16),
        border: Border.all(color: AppColors.citrusPurple.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Нужна помощь прямо сейчас?',
                  style: TextStyle(fontSize: AppSize.s(15), fontWeight: FontWeight.w600, color: AppColors.foreground),
                ),
                AppSize.gapH(4),
                Text(
                  'Начните с дыхательного упражнения',
                  style: TextStyle(fontSize: AppSize.s(12), color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),
          AppSize.gapW(12),
          GestureDetector(
            onTap: () {
              if (_filteredExercises.isNotEmpty) _showExerciseDetail(_filteredExercises.first);
            },
            child: Container(
              padding: AppSize.paddingH(20, 10),
              decoration: BoxDecoration(
                color: AppColors.citrusPurple.withOpacity(0.2),
                borderRadius: AppSize.radius(10),
                border: Border.all(color: AppColors.citrusPurple.withOpacity(0.3)),
              ),
              child: Text(
                'Начать',
                style: TextStyle(color: AppColors.citrusPurple, fontSize: AppSize.s(13), fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSize.paddingH(20, 0),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => AppSize.gapW(8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: Container(
              padding: AppSize.paddingH(16, 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.citrusOrange.withOpacity(0.15) : Colors.white.withOpacity(0.06),
                borderRadius: AppSize.radius(20),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? AppColors.citrusOrange : AppColors.mutedForeground,
                  fontSize: AppSize.s(12),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExerciseCard(ExerciseItem exercise) {
    return GestureDetector(
      onTap: () => _showExerciseDetail(exercise),
      child: Container(
        padding: AppSize.padding(16),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: AppSize.radius(16),
          border: Border.all(color: AppColors.subtleBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(exercise.icon, style: TextStyle(fontSize: AppSize.s(32))),
                    if (exercise.type == 'Видео')
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: AppSize.padding(2),
                          decoration: BoxDecoration(
                            color: AppColors.citrusOrange,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.play_arrow, size: 12, color: Colors.white),
                        ),
                      )
                    else if (exercise.type == 'Аудио')
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: AppSize.padding(2),
                          decoration: BoxDecoration(
                            color: AppColors.citrusPurple,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.headphones, size: 12, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                AppSize.gapW(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              exercise.title,
                              style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(15), fontWeight: FontWeight.w600),
                            ),
                          ),
                          Container(
                            padding: AppSize.paddingH(8, 2),
                            decoration: BoxDecoration(
                              color: exercise.color.withOpacity(0.15),
                              borderRadius: AppSize.radius(6),
                            ),
                            child: Text(
                              exercise.type,
                              style: TextStyle(color: exercise.color, fontSize: AppSize.s(10), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      AppSize.gapH(4),
                      Text(
                        exercise.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(12)),
                      ),
                      AppSize.gapH(8),
                      GestureDetector(
                        onTap: () => _showExerciseDetail(exercise),
                        child: Container(
                          padding: AppSize.paddingH(14, 7),
                          decoration: BoxDecoration(
                            color: exercise.color.withOpacity(0.15),
                            borderRadius: AppSize.radius(8),
                          ),
                          child: Text(
                            exercise.type == 'Видео' ? '▶ Смотреть' :
                            exercise.type == 'Аудио' ? '🎧 Слушать' : 'Открыть',
                            style: TextStyle(color: exercise.color, fontSize: AppSize.s(12), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Экран для видео упражнений с WebView (RuTube, VK Video)
class VideoExerciseScreen extends StatefulWidget {
  final ExerciseItem exercise;
  VideoExerciseScreen({super.key, required this.exercise});

  @override
  State<VideoExerciseScreen> createState() => _VideoExerciseScreenState();
}

class _VideoExerciseScreenState extends State<VideoExerciseScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.exercise.videoEmbedUrl!));
  }

  void _openInBrowser() async {
    final url = Uri.parse(widget.exercise.videoUrl!);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.foreground),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.exercise.title,
          style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(16), fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.open_in_browser, color: AppColors.citrusOrange),
            onPressed: _openInBrowser,
          ),
        ],
      ),
      body: Column(
        children: [
          // Видео плеер
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.citrusOrange),
                    ),
                  ),
              ],
            ),
          ),
          // Информация
          Expanded(
            flex: 2,
            child: Container(
              padding: AppSize.padding(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.exercise.description,
                    style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(14)),
                  ),
                  AppSize.gapH(16),
                  Text(
                    'Шаги выполнения',
                    style: TextStyle(
                      color: AppColors.foreground,
                      fontSize: AppSize.s(16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  AppSize.gapH(12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.exercise.steps.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: AppSize.paddingOnly(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: AppColors.citrusOrange.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: AppColors.citrusOrange,
                                      fontSize: AppSize.s(12),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              AppSize.gapW(12),
                              Expanded(
                                child: Text(
                                  widget.exercise.steps[index],
                                  style: TextStyle(
                                    color: AppColors.mutedForeground,
                                    fontSize: AppSize.s(13),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Экран для аудио упражнений - Freesound API
class AudioExerciseScreen extends StatefulWidget {
  final ExerciseItem exercise;
  AudioExerciseScreen({super.key, required this.exercise});

  @override
  State<AudioExerciseScreen> createState() => _AudioExerciseScreenState();
}

class _AudioExerciseScreenState extends State<AudioExerciseScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  bool _isLoaded = false;
  bool _isSearching = true;
  bool _isCompleted = false;
  String? _error;
  StreamSubscription? _durationSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _playerStateSub;

  @override
  void initState() {
    super.initState();
    _searchAndPlay();
  }

  void _setupListeners() {
    _cancelListeners();

    _durationSub = _audioPlayer.durationStream.listen((d) {
      if (d != null) setState(() => _duration = d);
    });

    _positionSub = _audioPlayer.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    });

    _playerStateSub = _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;

      setState(() {
        _isPlaying = state.playing;
        _isLoaded = true;
        _isSearching = false;
      });

      // Трек закончился — НЕ запускаем заново, ждём нажатия кнопки
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _isCompleted = true;
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  void _cancelListeners() {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _playerStateSub?.cancel();
  }

  Future<void> _searchAndPlay() async {
    setState(() {
      _isSearching = true;
      _error = null;
      _isCompleted = false;
    });

    try {
      final queries = {
        'audio_rain_sounds': 'rain sounds nature water',
        'audio_ocean_waves': 'ocean waves sea water nature',
        'audio_forest_sounds': 'forest birds nature sounds',
        'audio_meditation_calm': 'ambient meditation peaceful music',
        'audio_binaural_relax': 'singing bowl meditation gong sound',
      };

      final query = queries[widget.exercise.id] ?? 'nature sounds meditation';
      final mp3Url = await _searchFreesound(query);

      if (mp3Url == null) throw Exception('Аудио не найдено на Freesound');

      await _audioPlayer.setUrl(mp3Url);
      _setupListeners();
      await _audioPlayer.play();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _error = 'Ошибка: $e';
        });
      }
    }
  }

  /// Поиск через Freesound API
  Future<String?> _searchFreesound(String query) async {
    final apiKey = ApiConfig.freesoundApiKey;
    if (apiKey == 'YOUR_FREESOUND_API_KEY') {
      throw Exception('API ключ Freesound не настроен');
    }

    final searchUrl = '${ApiConfig.freesoundBaseUrl}/search/text/'
        '?query=$query'
        '&fields=id,name,previews,license'
        '&filter=type:(wav OR mp3)'
        '&sort=downloads_desc'
        '&page_size=10'
        '&token=$apiKey';

    final resp = await http.get(Uri.parse(searchUrl));
    if (resp.statusCode != 200) throw Exception('Ошибка Freesound API: ${resp.statusCode}');

    final data = jsonDecode(resp.body);
    final results = data['results'] as List?;
    if (results == null || results.isEmpty) return null;

    for (final sound in results) {
      final previews = sound['previews'] as Map<String, dynamic>?;
      if (previews != null) {
        final hqMp3 = previews['preview-hq-mp3'] as String?;
        if (hqMp3 != null && hqMp3.isNotEmpty) return hqMp3;

        final lqMp3 = previews['preview-lq-mp3'] as String?;
        if (lqMp3 != null && lqMp3.isNotEmpty) return lqMp3;
      }
    }

    return null;
  }

  Future<void> _refreshAudio() async {
    if (!mounted) return;

    // Полностью останавливаем плеер
    await _audioPlayer.stop();
    _cancelListeners();

    if (!mounted) return;
    setState(() {
      _isSearching = true;
      _isLoaded = false;
      _error = null;
      _position = Duration.zero;
      _duration = Duration.zero;
      _isCompleted = false;
      _isPlaying = false;
    });

    try {
      final mp3Url = await _searchFreesoundRandom();

      if (mp3Url == null) throw Exception('Аудио не найдено на Freesound');

      await _audioPlayer.setUrl(mp3Url);
      _setupListeners();

      if (mounted) {
        await _audioPlayer.play();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _error = 'Ошибка: $e';
        });
      }
    }
  }

  /// Ищем случайное аудио через Freesound API
  Future<String?> _searchFreesoundRandom() async {
    final apiKey = ApiConfig.freesoundApiKey;
    if (apiKey == 'YOUR_FREESOUND_API_KEY') {
      throw Exception('API ключ Freesound не настроен');
    }

    final queries = {
      'audio_rain_sounds': 'rain sounds nature water',
      'audio_ocean_waves': 'ocean waves sea water nature',
      'audio_forest_sounds': 'forest birds nature sounds',
      'audio_meditation_calm': 'ambient meditation peaceful music',
      'audio_binaural_relax': 'singing bowl meditation gong sound',
    };

    final query = queries[widget.exercise.id] ?? 'nature sounds meditation';

    // Случайная страница для разных результатов при обновлении
    final randomPage = 1 + (DateTime.now().millisecondsSinceEpoch % 5);

    final searchUrl = '${ApiConfig.freesoundBaseUrl}/search/text/'
        '?query=$query'
        '&fields=id,name,previews,license'
        '&filter=type:(wav OR mp3)'
        '&sort=random'
        '&page=$randomPage'
        '&page_size=15'
        '&token=$apiKey';

    final resp = await http.get(Uri.parse(searchUrl));
    if (resp.statusCode != 200) throw Exception('Ошибка Freesound API: ${resp.statusCode}');

    final data = jsonDecode(resp.body);
    final results = data['results'] as List?;
    if (results == null || results.isEmpty) return null;

    for (final sound in results) {
      final previews = sound['previews'] as Map<String, dynamic>?;
      if (previews != null) {
        final hqMp3 = previews['preview-hq-mp3'] as String?;
        if (hqMp3 != null && hqMp3.isNotEmpty) return hqMp3;

        final lqMp3 = previews['preview-lq-mp3'] as String?;
        if (lqMp3 != null && lqMp3.isNotEmpty) return lqMp3;
      }
    }

    return null;
  }

  Future<void> _play() async {
    if (_isCompleted) {
      await _audioPlayer.seek(Duration.zero);
    }
    setState(() {
      _isCompleted = false;
    });
    await _audioPlayer.play();
  }

  Future<void> _stop() async {
    await _audioPlayer.stop();
    setState(() {
      _position = Duration.zero;
      _isPlaying = false;
    });
  }

  Future<void> _restart() async {
    setState(() {
      _isCompleted = false;
      _position = Duration.zero;
    });
    await _audioPlayer.seek(Duration.zero);
    await _audioPlayer.play();
  }

  Future<void> _seekBack() async {
    final pos = _position - Duration(seconds: 10);
    await _audioPlayer.seek(pos < Duration.zero ? Duration.zero : pos);
  }

  Future<void> _seekForward() async {
    final pos = _position + Duration(seconds: 10);
    await _audioPlayer.seek(pos > _duration ? _duration : pos);
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes)}:${two(d.inSeconds.remainder(60))}';
  }

  @override
  void dispose() {
    _cancelListeners();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.foreground),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.exercise.audioTitle ?? widget.exercise.title,
          style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(16), fontWeight: FontWeight.w600),
        ),
        actions: [
          if (!_isSearching && _isLoaded)
            IconButton(
              icon: Icon(Icons.refresh, color: AppColors.citrusOrange),
              onPressed: _refreshAudio,
              tooltip: 'Найти другое аудио',
            ),
        ],
      ),
      body: _isSearching
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.citrusOrange)),
                  AppSize.gapH(16),
                  Text('Поиск аудио...', style: TextStyle(color: AppColors.mutedForeground)),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: AppColors.destructive),
                      AppSize.gapH(16),
                      Padding(
                        padding: AppSize.paddingH(32, 0),
                        child: Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.mutedForeground)),
                      ),
                      AppSize.gapH(16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isSearching = true;
                            _error = null;
                          });
                          _searchAndPlay();
                        },
                        child: Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            widget.exercise.color.withOpacity(0.3),
                            widget.exercise.color.withOpacity(0.1),
                          ]),
                          boxShadow: [
                            BoxShadow(
                              color: widget.exercise.color.withOpacity(0.3),
                              blurRadius: 50,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(widget.exercise.icon, style: TextStyle(fontSize: AppSize.s(72))),
                        ),
                      ),
                      AppSize.gapH(40),
                      Text(
                        '${_fmt(_position)} / ${_fmt(_duration)}',
                        style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(20), fontWeight: FontWeight.w600),
                      ),
                      AppSize.gapH(40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.replay_10, size: 40),
                            color: AppColors.mutedForeground,
                            onPressed: _seekBack,
                          ),
                          AppSize.gapW(24),
                          GestureDetector(
                            onTap: _isCompleted ? _restart : (_isPlaying ? _stop : _play),
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: _isCompleted
                                      ? [AppColors.citrusGreen, Color(0xFF6BCB77)]
                                      : _isPlaying
                                          ? [AppColors.destructive, Color(0xFFE74C3C)]
                                          : [AppColors.citrusOrange, AppColors.citrusAmber],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isCompleted
                                            ? AppColors.citrusGreen
                                            : _isPlaying
                                                ? AppColors.destructive
                                                : AppColors.citrusOrange)
                                        .withOpacity(0.4),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isCompleted ? Icons.replay : (_isPlaying ? Icons.stop : Icons.play_arrow),
                                size: 60,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          AppSize.gapW(24),
                          IconButton(
                            icon: Icon(Icons.forward_10, size: 40),
                            color: AppColors.mutedForeground,
                            onPressed: _seekForward,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}

class ExerciseDetailSheet extends StatefulWidget {
  final ExerciseItem exercise;
  ExerciseDetailSheet({super.key, required this.exercise});

  @override
  State<ExerciseDetailSheet> createState() => _ExerciseDetailSheetState();
}

class _ExerciseDetailSheetState extends State<ExerciseDetailSheet> {
  Timer? _timer;
  int _remainingSeconds = 0;
  String _phaseText = '';
  int _currentStepIndex = 0;
  Color _currentPhaseColor = AppColors.citrusGreen;
  double _targetScale = 0.8;
  Duration _animationDuration = Duration(milliseconds: 1000);
  bool _isRunning = false;
  bool _isFinished = false;
  ScrollController? _stepsScrollController;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.exercise.durationSeconds;
    _currentPhaseColor = widget.exercise.color;
    _stepsScrollController = ScrollController();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stepsScrollController?.dispose();
    super.dispose();
  }

  /// Рассчитываем текущий шаг на основе прошедшего времени
  void _updateCurrentStep() {
    final steps = widget.exercise.steps;
    if (steps.isEmpty) return;

    final elapsed = widget.exercise.durationSeconds - _remainingSeconds;
    final phaseDurations = widget.exercise.phaseDurations;

    if (phaseDurations != null && phaseDurations.isNotEmpty) {
      final totalCycle = phaseDurations.fold<int>(0, (a, b) => a + b);
      final elapsedInCycle = elapsed % totalCycle;

      int accumulated = 0;
      int newStepIndex = 0;
      for (int i = 0; i < phaseDurations.length; i++) {
        accumulated += phaseDurations[i];
        if (elapsedInCycle < accumulated) {
          newStepIndex = i;
          break;
        }
      }

      if (newStepIndex != _currentStepIndex) {
        _currentStepIndex = newStepIndex;

        final phaseLabels = widget.exercise.phaseLabels;
        if (phaseLabels != null && _currentStepIndex < phaseLabels.length) {
          _phaseText = phaseLabels[_currentStepIndex];
        } else {
          _phaseText = widget.exercise.steps[_currentStepIndex];
        }

        final phaseColors = widget.exercise.phaseColors;
        final phaseScales = widget.exercise.phaseScales;

        if (phaseColors != null && _currentStepIndex < phaseColors.length) {
          _currentPhaseColor = phaseColors[_currentStepIndex];
        }
        if (phaseScales != null && _currentStepIndex < phaseScales.length) {
          _targetScale = phaseScales[_currentStepIndex];
        }

        // Устанавливаем длительность анимации равной длительности фазы
        if (phaseDurations != null && _currentStepIndex < phaseDurations.length) {
          _animationDuration = Duration(seconds: phaseDurations[_currentStepIndex]);
        }

        // Автопрокрутка к текущему шагу
        if (_stepsScrollController?.hasClients == true) {
          _stepsScrollController!.animateTo(
            _currentStepIndex * 60.0,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOutCubic,
          );
        }
      }
    } else {
      final stepDuration = widget.exercise.durationSeconds ~/ steps.length;
      final newStepIndex = (elapsed ~/ stepDuration).clamp(0, steps.length - 1);
      if (newStepIndex != _currentStepIndex) {
        _currentStepIndex = newStepIndex;
        
        final phaseLabels = widget.exercise.phaseLabels;
        if (phaseLabels != null && _currentStepIndex < phaseLabels.length) {
          _phaseText = phaseLabels[_currentStepIndex];
        } else {
          _phaseText = widget.exercise.steps[_currentStepIndex];
        }

        // Автопрокрутка к текущему шагу
        if (_stepsScrollController?.hasClients == true) {
          _stepsScrollController!.animateTo(
            _currentStepIndex * 60.0,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOutCubic,
          );
        }
      }
    }
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
      _currentStepIndex = 0;
      _animationDuration = Duration(milliseconds: 1000);
      _updateCurrentStep();
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
          _updateCurrentStep();
        });
      } else {
        _timer?.cancel();
        setState(() {
          _isRunning = false;
          _isFinished = true;
          _phaseText = 'Упражнение завершено!';
        });
        // Сохраняем выполненное упражнение
        ExerciseTrackerService().recordExercise(
          widget.exercise.id,
          exerciseType: widget.exercise.type,
          title: widget.exercise.title,
          durationMinutes: widget.exercise.durationSeconds ~/ 60,
          difficultyLevel: widget.exercise.difficulty == 'Легко' ? 1 : widget.exercise.difficulty == 'Средне' ? 2 : 3,
        );
        // Начисляем монеты за задание
        CasinoCoinsService().completeQuest('exercise');
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = widget.exercise.durationSeconds;
      _currentStepIndex = 0;
      _phaseText = '';
      _isFinished = false;
      _currentPhaseColor = widget.exercise.color;
      _targetScale = 0.8;
      _animationDuration = Duration(milliseconds: 1000);
    });
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Получает оставшиеся секунды текущей фазы
  int _getCurrentPhaseRemainingSeconds() {
    final phaseDurations = widget.exercise.phaseDurations;
    if (phaseDurations == null || phaseDurations.isEmpty) return 0;
    
    final elapsed = widget.exercise.durationSeconds - _remainingSeconds;
    final totalCycle = phaseDurations.fold<int>(0, (a, b) => a + b);
    final elapsedInCycle = elapsed % totalCycle;
    
    int accumulated = 0;
    for (int i = 0; i < phaseDurations.length; i++) {
      accumulated += phaseDurations[i];
      if (elapsedInCycle < accumulated) {
        return accumulated - elapsedInCycle;
      }
    }
    return phaseDurations.last;
  }

  /// Получает прогресс текущей фазы (0.0 - 1.0)
  double _getCurrentPhaseProgress() {
    final phaseDurations = widget.exercise.phaseDurations;
    if (phaseDurations == null || phaseDurations.isEmpty) return 0.0;
    
    final elapsed = widget.exercise.durationSeconds - _remainingSeconds;
    final totalCycle = phaseDurations.fold<int>(0, (a, b) => a + b);
    final elapsedInCycle = elapsed % totalCycle;
    
    int accumulated = 0;
    for (int i = 0; i < phaseDurations.length; i++) {
      final prevAccumulated = accumulated;
      accumulated += phaseDurations[i];
      if (elapsedInCycle < accumulated) {
        final elapsedInPhase = elapsedInCycle - prevAccumulated;
        return elapsedInPhase / phaseDurations[i];
      }
    }
    return 1.0;
  }

  /// Получает иконку для текущей фазы
  IconData _getPhaseIcon() {
    final phaseLabels = widget.exercise.phaseLabels;
    if (phaseLabels == null || _currentStepIndex >= phaseLabels.length) {
      return Icons.air;
    }
    
    final label = phaseLabels[_currentStepIndex].toLowerCase();
    if (label.contains('вдох')) return Icons.arrow_upward;
    if (label.contains('выдох')) return Icons.arrow_downward;
    if (label.contains('задержка') || label.contains('пауза')) return Icons.pause;
    return Icons.air;
  }

  @override
  Widget build(BuildContext context) {
    final isBreathing = widget.exercise.phaseDurations != null && widget.exercise.phaseDurations!.isNotEmpty;
    final color = widget.exercise.color;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: AppColors.subtleBorder, width: 1)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: AppSize.paddingOnly(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.dimForeground,
                  borderRadius: AppSize.radius(2),
                ),
              ),

              if (isBreathing) ...[
                // === НОВЫЙ ЭКРАН ДЫХАТЕЛЬНОГО УПРАЖНЕНИЯ ===
                Expanded(
                  child: SingleChildScrollView(
                    padding: AppSize.paddingH(24, 0),
                    child: Column(
                      children: [
                        AppSize.gapH(24),

                        // Индикаторы фаз (точки)
                        if (widget.exercise.phaseLabels != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              widget.exercise.phaseLabels!.length,
                              (index) {
                                final isActive = index == _currentStepIndex && _isRunning;
                                final isCompleted = index < _currentStepIndex && _isRunning;
                                final phaseColor = widget.exercise.phaseColors != null && 
                                    index < widget.exercise.phaseColors!.length
                                    ? widget.exercise.phaseColors![index]
                                    : color;
                                
                                return AnimatedContainer(
                                  duration: Duration(milliseconds: 400),
                                  curve: Curves.easeInOutCubic,
                                  margin: AppSize.paddingH(6, 0),
                                  width: isActive ? 32 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? phaseColor 
                                        : (isCompleted
                                            ? phaseColor.withOpacity(0.4)
                                            : AppColors.mutedForeground.withOpacity(0.2)),
                                    borderRadius: AppSize.radius(4),
                                  ),
                                );
                              },
                            ),
                          ),
                        
                        AppSize.gapH(16),

                        // Название текущей фазы
                        AnimatedSwitcher(
                          duration: Duration(milliseconds: 500),
                          child: Text(
                            _isFinished 
                                ? 'Готово!'
                                : _isRunning 
                                    ? _phaseText 
                                    : 'Начните дыхание',
                            key: ValueKey(_phaseText),
                            style: TextStyle(
                              color: _isFinished 
                                  ? AppColors.citrusGreen
                                  : _isRunning 
                                      ? _currentPhaseColor 
                                      : AppColors.foreground,
                              fontSize: AppSize.s(28),
                              fontWeight: FontWeight.w300,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        
                        AppSize.gapH(8),
                        
                        // Подсказка
                        Text(
                          _isRunning && !_isFinished
                              ? '${_getCurrentPhaseRemainingSeconds()} секунд'
                              : widget.exercise.description,
                          style: TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: AppSize.s(14),
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        AppSize.gapH(32),

                        // Главный круг дыхания
                        SizedBox(
                          width: 280,
                          height: 280,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Внешнее свечение (blur)
                              TweenAnimationBuilder<double>(
                                duration: _animationDuration,
                                curve: Curves.easeInOutSine,
                                tween: Tween(end: _targetScale),
                                builder: (context, scale, _) {
                                  return Container(
                                    width: 240 * scale,
                                    height: 240 * scale,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          _currentPhaseColor.withOpacity(0.3),
                                          _currentPhaseColor.withOpacity(0.0),
                                        ],
                                        stops: [0.0, 1.0],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              
                              // Кольцо прогресса
                              TweenAnimationBuilder<double>(
                                duration: _animationDuration,
                                curve: Curves.easeInOutSine,
                                tween: Tween(end: _targetScale),
                                builder: (context, scale, _) {
                                  return Container(
                                    width: 200 * scale,
                                    height: 200 * scale,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _currentPhaseColor.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // Основной круг
                              TweenAnimationBuilder<double>(
                                duration: _animationDuration,
                                curve: Curves.easeInOutSine,
                                tween: Tween(end: _targetScale),
                                builder: (context, scale, _) {
                                  return Container(
                                    width: 180 * scale,
                                    height: 180 * scale,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          _currentPhaseColor.withOpacity(0.9),
                                          _currentPhaseColor.withOpacity(0.5),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _currentPhaseColor.withOpacity(0.4),
                                          blurRadius: 40,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Icon(
                                        _getPhaseIcon(),
                                        color: Colors.white,
                                        size: 48,
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // Иконка в центре (статичная)
                              if (!_isRunning)
                                Container(
                                  width: 180,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.surface1,
                                    border: Border.all(
                                      color: color.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      widget.exercise.icon,
                                      style: TextStyle(fontSize: AppSize.s(64)),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        AppSize.gapH(32),

                        // Общий таймер
                        Text(
                          _formatTime(_remainingSeconds),
                          style: TextStyle(
                            color: AppColors.foreground.withOpacity(0.6),
                            fontSize: AppSize.s(18),
                            fontWeight: FontWeight.w500,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),

                        AppSize.gapH(32),

                        // Кнопка управления
                        GestureDetector(
                          onTap: _isRunning ? _stopTimer : _startTimer,
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            width: 200,
                            height: 56,
                            decoration: BoxDecoration(
                              color: _isFinished 
                                  ? AppColors.citrusGreen
                                  : _isRunning 
                                      ? Colors.transparent 
                                      : color,
                              borderRadius: AppSize.radius(28),
                              border: _isRunning && !_isFinished
                                  ? Border.all(color: color, width: 2)
                                  : null,
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isFinished 
                                        ? Icons.replay
                                        : _isRunning 
                                            ? Icons.stop 
                                            : Icons.play_arrow,
                                    color: _isRunning && !_isFinished ? color : Colors.white,
                                    size: 24,
                                  ),
                                  AppSize.gapW(8),
                                  Text(
                                    _isFinished 
                                        ? 'Заново'
                                        : _isRunning 
                                            ? 'Стоп' 
                                            : 'Начать',
                                    style: TextStyle(
                                      color: _isRunning && !_isFinished ? color : Colors.white,
                                      fontSize: AppSize.s(16),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        AppSize.gapH(24),

                        // Карточка с шагами (компактная)
                        if (widget.exercise.steps.isNotEmpty && !_isFinished)
                          Container(
                            padding: AppSize.padding(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface1,
                              borderRadius: AppSize.radius(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Последовательность',
                                  style: TextStyle(
                                    color: AppColors.mutedForeground,
                                    fontSize: AppSize.s(12),
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                AppSize.gapH(12),
                                Row(
                                  children: List.generate(
                                    widget.exercise.steps.length * 2 - 1,
                                    (index) {
                                      if (index.isOdd) {
                                        return Padding(
                                          padding: AppSize.paddingH(8, 0),
                                          child: Icon(
                                            Icons.arrow_forward_ios,
                                            size: 12,
                                            color: AppColors.mutedForeground.withOpacity(0.3),
                                          ),
                                        );
                                      }
                                      final stepIndex = index ~/ 2;
                                      final isActive = stepIndex == _currentStepIndex && _isRunning;
                                      final stepColor = widget.exercise.phaseColors != null && 
                                          stepIndex < widget.exercise.phaseColors!.length
                                          ? widget.exercise.phaseColors![stepIndex]
                                          : color;
                                      
                                      return Expanded(
                                        child: Container(
                                          padding: AppSize.paddingH(4, 8),
                                          decoration: BoxDecoration(
                                            color: isActive 
                                                ? stepColor.withOpacity(0.15)
                                                : Colors.transparent,
                                            borderRadius: AppSize.radius(8),
                                            border: isActive
                                                ? Border.all(color: stepColor.withOpacity(0.3))
                                                : null,
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                widget.exercise.steps[stepIndex],
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: isActive ? stepColor : AppColors.mutedForeground,
                                                  fontSize: AppSize.s(11),
                                                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                                ),
                                              ),
                                              if (widget.exercise.phaseDurations != null && 
                                                  stepIndex < widget.exercise.phaseDurations!.length)
                                                Text(
                                                  '${widget.exercise.phaseDurations![stepIndex]}с',
                                                  style: TextStyle(
                                                    color: isActive 
                                                        ? stepColor.withOpacity(0.7)
                                                        : AppColors.mutedForeground.withOpacity(0.5),
                                                    fontSize: AppSize.s(10),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Сообщение о завершении
                        if (_isFinished)
                          Container(
                            padding: AppSize.paddingH(24, 16),
                            decoration: BoxDecoration(
                              color: AppColors.citrusGreen.withOpacity(0.1),
                              borderRadius: AppSize.radius(16),
                              border: Border.all(
                                color: AppColors.citrusGreen.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: AppColors.citrusGreen,
                                  size: 20,
                                ),
                                AppSize.gapW(8),
                                Text(
                                  'Упражнение завершено',
                                  style: TextStyle(
                                    color: AppColors.citrusGreen,
                                    fontSize: AppSize.s(14),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        AppSize.gapH(24),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // === ЭКРАН ДЛЯ ВИДЕО/АУДИО/ОБЫЧНЫХ УПРАЖНЕНИЙ ===
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: AppSize.padding(20),
                    children: [
                      Row(
                        children: [
                          Text(widget.exercise.icon, style: TextStyle(fontSize: AppSize.s(28))),
                          AppSize.gapW(12),
                          Expanded(
                            child: Text(
                              widget.exercise.title,
                              style: TextStyle(
                                color: AppColors.foreground,
                                fontSize: AppSize.s(18),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      AppSize.gapH(20),
                      Center(
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: color.withOpacity(0.3)),
                          ),
                          child: Center(
                            child: Text(widget.exercise.icon, style: TextStyle(fontSize: AppSize.s(56))),
                          ),
                        ),
                      ),
                      AppSize.gapH(20),
                      Center(
                        child: Text(
                          _isRunning || _isFinished ? _formatTime(_remainingSeconds) : widget.exercise.title,
                          style: TextStyle(
                            color: AppColors.foreground,
                            fontSize: AppSize.s(32),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (_phaseText.isNotEmpty && _isRunning) ...[
                        AppSize.gapH(8),
                        Center(
                          child: Text(
                            _phaseText,
                            style: TextStyle(
                              color: color,
                              fontSize: AppSize.s(15),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                      AppSize.gapH(20),
                      Text(
                        'Шаги выполнения',
                        style: TextStyle(
                          color: AppColors.foreground,
                          fontSize: AppSize.s(16),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      AppSize.gapH(12),
                      ...widget.exercise.steps.asMap().entries.map((entry) {
                        final index = entry.key;
                        final step = entry.value;
                        final isCurrentStep = _isRunning && index == _currentStepIndex;
                        return Padding(
                          padding: AppSize.paddingOnly(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isCurrentStep ? color : AppColors.citrusOrange.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: isCurrentStep ? Colors.white : AppColors.citrusOrange,
                                      fontSize: AppSize.s(12),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              AppSize.gapW(12),
                              Expanded(
                                child: Text(
                                  step,
                                  style: TextStyle(
                                    color: isCurrentStep ? color : AppColors.mutedForeground,
                                    fontSize: AppSize.s(13),
                                    height: 1.5,
                                    fontWeight: isCurrentStep ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (_isFinished) ...[
                        AppSize.gapH(16),
                        Container(
                          padding: AppSize.paddingH(16, 10),
                          decoration: BoxDecoration(
                            color: AppColors.citrusGreen.withOpacity(0.15),
                            borderRadius: AppSize.radius(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: AppColors.citrusGreen, size: 20),
                              AppSize.gapW(8),
                              Text(
                                'Отличная работа!',
                                style: TextStyle(
                                  color: AppColors.citrusGreen,
                                  fontSize: AppSize.s(14),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppSize.gapH(12),
                      ],
                      AppSize.gapH(16),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _isRunning ? _stopTimer : _startTimer,
                              child: Container(
                                padding: AppSize.paddingH(0, 14),
                                decoration: BoxDecoration(
                                  gradient: _isRunning
                                      ? null
                                      : LinearGradient(
                                          colors: [AppColors.citrusOrange, AppColors.citrusAmber],
                                        ),
                                  color: _isRunning ? AppColors.surface2 : null,
                                  borderRadius: AppSize.radius(12),
                                  border: _isRunning
                                      ? Border.all(color: AppColors.citrusOrange.withOpacity(0.3))
                                      : null,
                                  boxShadow: _isRunning
                                      ? null
                                      : [
                                          BoxShadow(
                                            color: AppColors.citrusOrange.withOpacity(0.3),
                                            blurRadius: 16,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                ),
                                child: Text(
                                  _isRunning ? 'Стоп' : 'Старт',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _isRunning ? AppColors.citrusOrange : AppColors.background,
                                    fontSize: AppSize.s(15),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
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
      },
    );
  }
}
