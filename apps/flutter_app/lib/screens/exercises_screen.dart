import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:just_audio/just_audio.dart';
import '../core/theme/app_colors.dart';
import '../core/services/exercise_tracker_service.dart';
import '../core/config/api_config.dart';

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

  const ExerciseItem({
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

const _exercises = [
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
    phaseDurations: const [4, 4, 4, 4],
    phaseLabels: ['Вдох', 'Задержка', 'Выдох', 'Задержка'],
    phaseColors: const [
      Color(0xFF8BC34A), // Вдох — зелёный (рост, энергия)
      Color(0xFFFFD93D), // Задержка — жёлтый (внимание)
      Color(0xFF74B9FF), // Выдох — голубой (расслабление)
      Color(0xFFFFD93D), // Задержка — жёлтый
    ],
    phaseScales: const [
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
    phaseDurations: const [4, 7, 8],
    phaseLabels: ['Вдох', 'Задержка', 'Выдох'],
    phaseColors: const [
      Color(0xFF9C88FF), // Вдох — фиолетовый (спокойствие)
      Color(0xFFFFD93D), // Задержка — жёлтый
      Color(0xFF74B9FF), // Выдох — голубой (глубокое расслабление)
    ],
    phaseScales: const [
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
    phaseDurations: const [2, 2],
    phaseLabels: ['Вдох', 'Выдох'],
    phaseColors: const [
      Color(0xFFFF8C42), // Вдох — оранжевый (энергия)
      Color(0xFF5A5468), // Выдох — тёмный (освобождение)
    ],
    phaseScales: const [
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
    phaseDurations: const [5, 5],
    phaseLabels: ['Вдох', 'Выдох'],
    phaseColors: const [
      Color(0xFF00CEC9), // Вдох — бирюзовый (свежесть)
      Color(0xFF74B9FF), // Выдох — голубой (расслабление)
    ],
    phaseScales: const [
      1.0,  // Вдох — полный
      0.6,  // Выдох — пустой
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
  const ExercisesScreen({super.key});

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
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Text(
                    'Упражнения',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.foreground),
                  ),
                ),
                _buildQuickStartCard(),
                SizedBox(height: 16),
                _buildCategoryChips(),
                SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 80),
                    itemCount: _filteredExercises.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
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
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.citrusPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
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
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.foreground),
                ),
                SizedBox(height: 4),
                Text(
                  'Начните с дыхательного упражнения',
                  style: TextStyle(fontSize: 12, color: AppColors.mutedForeground),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              if (_filteredExercises.isNotEmpty) _showExerciseDetail(_filteredExercises.first);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.citrusPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.citrusPurple.withOpacity(0.3)),
              ),
              child: const Text(
                'Начать',
                style: TextStyle(color: AppColors.citrusPurple, fontSize: 13, fontWeight: FontWeight.w600),
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
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.citrusOrange.withOpacity(0.15) : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? AppColors.citrusOrange : AppColors.mutedForeground,
                  fontSize: 12,
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(16),
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
                    Text(exercise.icon, style: const TextStyle(fontSize: 32)),
                    if (exercise.type == 'Видео')
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.citrusOrange,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow, size: 12, color: Colors.white),
                        ),
                      )
                    else if (exercise.type == 'Аудио')
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.citrusPurple,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.headphones, size: 12, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              exercise.title,
                              style: TextStyle(color: AppColors.foreground, fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: exercise.color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              exercise.type,
                              style: TextStyle(color: exercise.color, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        exercise.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                      ),
                      SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _showExerciseDetail(exercise),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: exercise.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            exercise.type == 'Видео' ? '▶ Смотреть' :
                            exercise.type == 'Аудио' ? '🎧 Слушать' : 'Открыть',
                            style: TextStyle(color: exercise.color, fontSize: 12, fontWeight: FontWeight.w600),
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
  const VideoExerciseScreen({super.key, required this.exercise});

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
            setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
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
          style: TextStyle(color: AppColors.foreground, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser, color: AppColors.citrusOrange),
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
                  const Center(
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.exercise.description,
                    style: TextStyle(color: AppColors.mutedForeground, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Шаги выполнения',
                    style: TextStyle(
                      color: AppColors.foreground,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.exercise.steps.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
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
                                    style: const TextStyle(
                                      color: AppColors.citrusOrange,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.exercise.steps[index],
                                  style: TextStyle(
                                    color: AppColors.mutedForeground,
                                    fontSize: 13,
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
  const AudioExerciseScreen({super.key, required this.exercise});

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
    final pos = _position - const Duration(seconds: 10);
    await _audioPlayer.seek(pos < Duration.zero ? Duration.zero : pos);
  }

  Future<void> _seekForward() async {
    final pos = _position + const Duration(seconds: 10);
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
          style: TextStyle(color: AppColors.foreground, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (!_isSearching && _isLoaded)
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.citrusOrange),
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
                  SizedBox(height: 16),
                  Text('Поиск аудио...', style: TextStyle(color: AppColors.mutedForeground)),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: AppColors.destructive),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.mutedForeground)),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isSearching = true;
                            _error = null;
                          });
                          _searchAndPlay();
                        },
                        child: const Text('Повторить'),
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
                          child: Text(widget.exercise.icon, style: const TextStyle(fontSize: 72)),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        '${_fmt(_position)} / ${_fmt(_duration)}',
                        style: TextStyle(color: AppColors.foreground, fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 40),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.replay_10, size: 40),
                            color: AppColors.mutedForeground,
                            onPressed: _seekBack,
                          ),
                          const SizedBox(width: 24),
                          GestureDetector(
                            onTap: _isCompleted ? _restart : (_isPlaying ? _stop : _play),
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: _isCompleted
                                      ? [AppColors.citrusGreen, const Color(0xFF6BCB77)]
                                      : _isPlaying
                                          ? [AppColors.destructive, const Color(0xFFE74C3C)]
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
                          const SizedBox(width: 24),
                          IconButton(
                            icon: const Icon(Icons.forward_10, size: 40),
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
  const ExerciseDetailSheet({super.key, required this.exercise});

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
  Duration _animationDuration = const Duration(milliseconds: 1000);
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
            duration: const Duration(milliseconds: 500),
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
            duration: const Duration(milliseconds: 500),
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
      _animationDuration = const Duration(milliseconds: 1000);
      _updateCurrentStep();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
        ExerciseTrackerService().recordExercise(widget.exercise.id);
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
      _animationDuration = const Duration(milliseconds: 1000);
    });
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: AppColors.subtleBorder, width: 1)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.dimForeground,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              if (isBreathing) ...[
                // === ЭКРАН ДЫХАТЕЛЬНОГО УПРАЖНЕНИЯ ===
                Expanded(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Заголовок
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(widget.exercise.icon, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          Text(
                            widget.exercise.title,
                            style: TextStyle(
                              color: AppColors.foreground,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.exercise.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.mutedForeground, fontSize: 13),
                      ),
                      const SizedBox(height: 24),

                      // Анимированный круг дыхания (как в Антистресс)
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Пульсирующие внешние кольца
                          TweenAnimationBuilder<double>(
                            key: ValueKey('outer_ring_${_currentStepIndex}_$_isRunning'),
                            duration: _animationDuration,
                            curve: Curves.easeInOutCubic,
                            tween: Tween(begin: _isRunning ? 0.6 : 0.8, end: _targetScale),
                            builder: (context, scale, _) {
                              return Container(
                                width: 200 * scale,
                                height: 200 * scale,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _currentPhaseColor.withOpacity(0.2 * scale),
                                    width: 2,
                                  ),
                                ),
                              );
                            },
                          ),

                          // Второе пульсирующее кольцо
                          TweenAnimationBuilder<double>(
                            key: ValueKey('second_ring_${_currentStepIndex}_$_isRunning'),
                            duration: _animationDuration + const Duration(milliseconds: 200),
                            curve: Curves.easeInOutCubic,
                            tween: Tween(begin: _isRunning ? 0.6 : 0.8, end: _targetScale),
                            builder: (context, scale, _) {
                              return Container(
                                width: 220 * scale,
                                height: 220 * scale,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _currentPhaseColor.withOpacity(0.1 * scale),
                                    width: 1.5,
                                  ),
                                ),
                              );
                            },
                          ),

                          // Плавное внешнее свечение
                          TweenAnimationBuilder<double>(
                            key: ValueKey('glow_${_currentStepIndex}_$_isRunning'),
                            duration: _animationDuration,
                            curve: Curves.easeInOutCubic,
                            tween: Tween(begin: _isRunning ? 0.6 : 0.8, end: _targetScale),
                            builder: (context, scale, _) {
                              return Container(
                                width: 170 * scale,
                                height: 170 * scale,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _currentPhaseColor.withOpacity(0.25 * scale),
                                      blurRadius: 50 * scale,
                                      spreadRadius: 6 * scale,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          // Основной круг с градиентом
                          TweenAnimationBuilder<double>(
                            key: ValueKey('main_circle_${_currentStepIndex}_$_isRunning'),
                            duration: _animationDuration,
                            curve: Curves.easeInOutCubic,
                            tween: Tween(begin: _isRunning ? 0.6 : 0.8, end: _targetScale),
                            builder: (context, scale, _) {
                              return Container(
                                width: 150 * scale,
                                height: 150 * scale,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      _currentPhaseColor.withOpacity(0.4 * scale),
                                      _currentPhaseColor.withOpacity(0.2 * scale),
                                      _currentPhaseColor.withOpacity(0.05),
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                  ),
                                  border: Border.all(
                                    color: _currentPhaseColor.withOpacity(_isRunning ? 0.6 : 0.2),
                                    width: 3,
                                  ),
                                  boxShadow: _isRunning
                                      ? [
                                          BoxShadow(
                                            color: _currentPhaseColor.withOpacity(0.35 * scale),
                                            blurRadius: 25 * scale,
                                            spreadRadius: 4 * scale,
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Center(
                                  child: AnimatedDefaultTextStyle(
                                    duration: _animationDuration > const Duration(milliseconds: 500)
                                        ? _animationDuration - const Duration(milliseconds: 400)
                                        : const Duration(milliseconds: 200),
                                    curve: Curves.easeInOutCubic,
                                    style: TextStyle(
                                      color: _isFinished
                                          ? AppColors.citrusGreen
                                          : _currentPhaseColor,
                                      fontSize: _isFinished ? 48 : (_isRunning ? 22 : 48),
                                      fontWeight: FontWeight.w800,
                                    ),
                                    child: Text(
                                      _isFinished
                                          ? '✓'
                                          : _isRunning
                                              ? _phaseText
                                              : widget.exercise.icon,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Таймер
                      Text(
                        _isRunning || _isFinished
                            ? _formatTime(_remainingSeconds)
                            : widget.exercise.duration,
                        style: TextStyle(
                          color: AppColors.foreground,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                      
                      const SizedBox(height: 16),

                      // Список шагов с выделением текущего
                      if (widget.exercise.steps.isNotEmpty) ...[
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 40),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _currentPhaseColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _currentPhaseColor.withOpacity(0.15),
                              width: 1,
                            ),
                          ),
                          child: ListView.builder(
                            controller: _stepsScrollController,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: widget.exercise.steps.length,
                            itemBuilder: (context, index) {
                              final isActive = index == _currentStepIndex && _isRunning;
                              final isCompleted = index < _currentStepIndex && _isRunning;
                              
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOutCubic,
                                margin: EdgeInsets.only(bottom: index < widget.exercise.steps.length - 1 ? 8 : 0),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? _currentPhaseColor.withOpacity(0.15)
                                      : (isCompleted
                                          ? AppColors.citrusGreen.withOpacity(0.08)
                                          : Colors.transparent),
                                  borderRadius: BorderRadius.circular(10),
                                  border: isActive
                                      ? Border.all(color: _currentPhaseColor.withOpacity(0.3), width: 1.5)
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    // Индикатор
                                    Container(
                                      width: 24,
                                      height: 24,
                                      margin: const EdgeInsets.only(right: 10),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isActive
                                            ? _currentPhaseColor
                                            : (isCompleted
                                                ? AppColors.citrusGreen.withOpacity(0.3)
                                                : AppColors.mutedForeground.withOpacity(0.2)),
                                        border: isActive
                                            ? Border.all(color: _currentPhaseColor, width: 2)
                                            : null,
                                        boxShadow: isActive
                                            ? [
                                                BoxShadow(
                                                  color: _currentPhaseColor.withOpacity(0.4),
                                                  blurRadius: 8,
                                                  spreadRadius: 1,
                                                ),
                                              ]
                                            : [],
                                      ),
                                      child: Center(
                                        child: isCompleted
                                            ? const Icon(Icons.check, size: 14, color: AppColors.citrusGreen)
                                            : (isActive
                                                ? Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : Text(
                                                    '${index + 1}',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppColors.mutedForeground.withOpacity(0.5),
                                                    ),
                                                  )),
                                      ),
                                    ),
                                    // Текст шага
                                    Expanded(
                                      child: Text(
                                        widget.exercise.steps[index],
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                          color: isActive
                                              ? _currentPhaseColor
                                              : (isCompleted
                                                  ? AppColors.citrusGreen.withOpacity(0.8)
                                                  : AppColors.mutedForeground),
                                        ),
                                      ),
                                    ),
                                    // Длительность фазы
                                    if (widget.exercise.phaseDurations != null && 
                                        index < widget.exercise.phaseDurations!.length)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? _currentPhaseColor.withOpacity(0.15)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${widget.exercise.phaseDurations![index]}с',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                                            color: isActive
                                                ? _currentPhaseColor
                                                : AppColors.mutedForeground,
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
                      
                      const SizedBox(height: 20),

                      // Кнопки управления
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: _isRunning ? _stopTimer : _startTimer,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOutCubic,
                              width: 160,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: !_isRunning
                                    ? LinearGradient(
                                        colors: [color, color.withOpacity(0.85)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: _isRunning ? AppColors.surface2 : null,
                                borderRadius: BorderRadius.circular(18),
                                border: _isRunning
                                    ? Border.all(color: color.withOpacity(0.4), width: 1.5)
                                    : null,
                                boxShadow: !_isRunning
                                    ? [
                                        BoxShadow(
                                          color: color.withOpacity(0.5),
                                          blurRadius: 24,
                                          offset: const Offset(0, 8),
                                        ),
                                        BoxShadow(
                                          color: color.withOpacity(0.3),
                                          blurRadius: 40,
                                          offset: const Offset(0, 12),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Text(
                                _isRunning ? '⏸ Стоп' : (_isFinished ? '🔄 Заново' : '▶ Старт'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _isRunning ? color : AppColors.background,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Сообщение о завершении
                      if (_isFinished) ...[
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutBack,
                          margin: const EdgeInsets.symmetric(horizontal: 40),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.citrusGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.citrusGreen.withOpacity(0.3), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.citrusGreen.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_outline, color: AppColors.citrusGreen, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Отличная работа! 🎉',
                                style: TextStyle(
                                  color: AppColors.citrusGreen,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ] else ...[
                // === ЭКРАН ДЛЯ ВИДЕО/АУДИО/ОБЫЧНЫХ УПРАЖНЕНИЙ ===
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      Row(
                        children: [
                          Text(widget.exercise.icon, style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.exercise.title,
                              style: TextStyle(
                                color: AppColors.foreground,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
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
                            child: Text(widget.exercise.icon, style: const TextStyle(fontSize: 56)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          _isRunning || _isFinished ? _formatTime(_remainingSeconds) : widget.exercise.title,
                          style: TextStyle(
                            color: AppColors.foreground,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (_phaseText.isNotEmpty && _isRunning) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            _phaseText,
                            style: TextStyle(
                              color: color,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Text(
                        'Шаги выполнения',
                        style: TextStyle(
                          color: AppColors.foreground,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...widget.exercise.steps.asMap().entries.map((entry) {
                        final index = entry.key;
                        final step = entry.value;
                        final isCurrentStep = _isRunning && index == _currentStepIndex;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
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
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  step,
                                  style: TextStyle(
                                    color: isCurrentStep ? color : AppColors.mutedForeground,
                                    fontSize: 13,
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
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.citrusGreen.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle, color: AppColors.citrusGreen, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Отличная работа!',
                                style: TextStyle(
                                  color: AppColors.citrusGreen,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _isRunning ? _stopTimer : _startTimer,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  gradient: _isRunning
                                      ? null
                                      : const LinearGradient(
                                          colors: [AppColors.citrusOrange, AppColors.citrusAmber],
                                        ),
                                  color: _isRunning ? AppColors.surface2 : null,
                                  borderRadius: BorderRadius.circular(12),
                                  border: _isRunning
                                      ? Border.all(color: AppColors.citrusOrange.withOpacity(0.3))
                                      : null,
                                  boxShadow: _isRunning
                                      ? null
                                      : [
                                          BoxShadow(
                                            color: AppColors.citrusOrange.withOpacity(0.3),
                                            blurRadius: 16,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                ),
                                child: Text(
                                  _isRunning ? 'Стоп' : 'Старт',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _isRunning ? AppColors.citrusOrange : AppColors.background,
                                    fontSize: 15,
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
