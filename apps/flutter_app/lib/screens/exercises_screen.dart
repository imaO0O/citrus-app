import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:just_audio/just_audio.dart';
import '../core/theme/app_colors.dart';

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
  final String? audioEmbedUrl; // Яндекс Музыка embed iframe

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
  });
}

const _categories = ['Все', 'Дыхание', 'Расслабление', 'Фокус', 'Энергия', 'Видео', 'Аудио'];

const _exercises = [
  // Дыхательные упражнения
  ExerciseItem(
    id: 'box_breathing',
    icon: '🌬️',
    title: 'Квадратное дыхание',
    description: 'Техника 4-4-4-4 для снятия стресса и улучшения концентрации',
    duration: '5 мин',
    difficulty: 'Легко',
    type: 'Дыхание',
    category: 'Дыхание',
    color: AppColors.citrusGreen,
    steps: [
      'Вдохните через нос на 4 счёта',
      'Задержите дыхание на 4 счёта',
      'Выдохните через рот на 4 счёта',
      'Задержите дыхание на 4 счёта',
      'Повторяйте цикл 5 минут',
    ],
    durationSeconds: 300,
  ),
  // Расслабление
  ExerciseItem(
    id: 'progressive_relaxation',
    icon: '🧘',
    title: 'Прогрессивная релаксация',
    description: 'Последовательное напряжение и расслабление мышц тела',
    duration: '10 мин',
    difficulty: 'Средне',
    type: 'Расслабление',
    category: 'Расслабление',
    color: Color(0xFF9C88FF),
    steps: [
      'Напрягите мышцы ног на 5 секунд, затем расслабьте',
      'Перейдите к икрам, бёдрам, животу',
      'Напрягите руки и плечи',
      'Сожмите и расслабьте мышцы лица',
      'Почувствуйте разницу между напряжением и расслаблением',
    ],
    durationSeconds: 600,
  ),
  ExerciseItem(
    id: 'visualization',
    icon: '🌊',
    title: 'Визуализация',
    description: 'Погрузитесь в спокойное мысленное путешествие',
    duration: '8 мин',
    difficulty: 'Легко',
    type: 'Расслабление',
    category: 'Расслабление',
    color: Color(0xFF74B9FF),
    steps: [
      'Закройте глаза и сделайте глубокий вдох',
      'Представьте спокойное место — пляж, лес или горы',
      'Ощутите звуки, запахи и ощущения этого места',
      'Позвольте себе полностью погрузиться',
      'Медленно вернитесь в настоящее',
    ],
    durationSeconds: 480,
  ),
  // Фокус
  ExerciseItem(
    id: 'morning_meditation',
    icon: '🌅',
    title: 'Утренняя медитация',
    description: 'Начните день с осознанности и спокойствия',
    duration: '7 мин',
    difficulty: 'Легко',
    type: 'Фокус',
    category: 'Фокус',
    color: Color(0xFFFFEAA7),
    steps: [
      'Сядьте удобно с прямой спиной',
      'Сосредоточьтесь на дыхании',
      'Наблюдайте за мыслями без оценки',
      'Мягко возвращайте внимание к дыханию',
      'Начните день с ясным умом',
    ],
    durationSeconds: 420,
  ),
  // Энергия
  ExerciseItem(
    id: 'yoga_beginners',
    icon: '🧘',
    title: 'Йога для начинающих',
    description: 'Простые позы для гибкости и равновесия',
    duration: '15 мин',
    difficulty: 'Средне',
    type: 'Энергия',
    category: 'Энергия',
    color: Color(0xFFFD79A8),
    steps: [
      'Встаньте прямо, ноги на ширине плеч',
      'Медленно поднимите руки вверх',
      'Наклонитесь вперёд, почувствуйте растяжение',
      'Выполните позу кошки и коровы',
      'Двигайтесь плавно, дышите глубоко',
    ],
    durationSeconds: 900,
  ),
  ExerciseItem(
    id: 'technique_54321',
    icon: '⚡',
    title: 'Техника 5-4-3-2-1',
    description: 'Заземление через органы чувств для снятия тревоги',
    duration: '3 мин',
    difficulty: 'Легко',
    type: 'Фокус',
    category: 'Фокус',
    color: Color(0xFF00CEC9),
    steps: [
      'Найдите 5 вещей, которые вы видите',
      'Найдите 4 вещи, которые можно потрогать',
      'Обратите внимание на 3 вещи, которые вы слышите',
      'Найдите 2 вещи, которые можно понюхать',
      'Найдите 1 вещь, которую можно попробовать на вкус',
    ],
    durationSeconds: 180,
  ),
  
  // === ВИДЕО УПРАЖНЕНИЯ (RuTube и VK Video) ===
  ExerciseItem(
    id: 'video_breathing_guided',
    icon: '🎬',
    title: 'Дыхательная медитация с гидом',
    description: 'Видео с управляемой дыхательной медитацией для начинающих',
    duration: '10 мин',
    difficulty: 'Легко',
    type: 'Видео',
    category: 'Видео',
    color: AppColors.citrusOrange,
    videoUrl: 'https://vk.com/video-224098011_456239907',
    videoEmbedUrl: 'https://vk.com/video_ext.php?oid=-224098011&id=456239907&hd=2',
    steps: [
      'Найдите удобное положение сидя или лёжа',
      'Следуйте инструкциям в видео',
      'Дышите в ритме, показанном на экране',
      'Сосредоточьтесь на ощущениях в теле',
      'Завершите упражнение мягко',
    ],
    durationSeconds: 600,
  ),
  ExerciseItem(
    id: 'video_body_scan',
    icon: '🎬',
    title: 'Шавасана - медитация расслабления',
    description: 'Видео медитация для глубокого расслабления тела',
    duration: '15 мин',
    difficulty: 'Легко',
    type: 'Видео',
    category: 'Видео',
    color: Color(0xFF74B9FF),
    videoUrl: 'https://vk.com/video-27408214_456239760',
    videoEmbedUrl: 'https://vk.com/video_ext.php?oid=-27408214&id=456239760&hd=2',
    steps: [
      'Лягте удобно на спину',
      'Следуйте голосу в видео',
      'Перемещайте внимание по частям тела',
      'Осознавайте ощущения без оценки',
      'Расслабьтесь полностью к концу упражнения',
    ],
    durationSeconds: 900,
  ),
  ExerciseItem(
    id: 'video_meditation_relax',
    icon: '🎬',
    title: 'Медитация для снятия стресса',
    description: 'Управляемая медитация для восстановления нервной системы',
    duration: '20 мин',
    difficulty: 'Легко',
    type: 'Видео',
    category: 'Видео',
    color: Color(0xFFFD79A8),
    videoUrl: 'https://vk.com/video-211495377_456239108',
    videoEmbedUrl: 'https://vk.com/video_ext.php?oid=-211495377&id=456239108&hd=2',
    steps: [
      'Подготовьте тихое место',
      'Сядьте или лягте удобно',
      'Следуйте инструкциям гида',
      'Дышите глубоко и ровно',
      'Позвольте себе расслабиться',
    ],
    durationSeconds: 1200,
  ),
  ExerciseItem(
    id: 'video_nature_sounds',
    icon: '🎬',
    title: 'Звуки природы для медитации',
    description: 'Видео с звуками леса для релаксации и сна',
    duration: '30 мин',
    difficulty: 'Легко',
    type: 'Видео',
    category: 'Видео',
    color: AppColors.citrusGreen,
    videoUrl: 'https://rutube.ru/video/7d00a214d5ed9f96ee136201ffa37618/',
    videoEmbedUrl: 'https://rutube.ru/play/embed/7d00a214d5ed9f96ee136201ffa37618/',
    steps: [
      'Устройтесь удобно',
      'Включите видео на полном экране',
      'Слушайте звуки природы',
      'Представьте, что вы в лесу',
      'Позвольте себе расслабиться',
    ],
    durationSeconds: 1800,
  ),
  
  // === АУДИО УПРАЖНЕНИЯ (Archive.org - бесплатно, без VPN, работает) ===
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
      'Нажмите "Играть" для воспроизведения',
      'Закройте глаза и слушайте',
      'Сосредоточьтесь на звуках дождя',
      'Позвольте мыслям течь свободно',
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
      'Нажмите "Играть" для воспроизведения',
      'Слушайте ритм волн',
      'Дышите в такт океану',
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
      'Устройтесь в удобном месте',
      'Нажмите "Играть" для воспроизведения',
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
    description: 'Расслабляющая музыка для практики осознанности',
    duration: '~10 мин',
    difficulty: 'Легко',
    type: 'Аудио',
    category: 'Аудио',
    color: AppColors.citrusPurple,
    audioUrl: 'https://archive.org/download/peaceful-meditation-music/peaceful-meditation-music.mp3',
    audioTitle: 'Музыка для медитации',
    steps: [
      'Сядьте в тихом месте',
      'Нажмите "Играть" для воспроизведения',
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
      'Обязательно используйте наушники',
      'Лягте удобно',
      'Нажмите "Играть" для воспроизведения',
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
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Text(
                    'Упражнения',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.foreground),
                  ),
                ),
                _buildQuickStartCard(),
                const SizedBox(height: 16),
                _buildCategoryChips(),
                const SizedBox(height: 16),
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
          const Expanded(
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
          const SizedBox(width: 12),
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
        separatorBuilder: (_, __) => const SizedBox(width: 8),
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
                              style: const TextStyle(color: AppColors.foreground, fontSize: 15, fontWeight: FontWeight.w600),
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
                      const SizedBox(height: 4),
                      Text(
                        exercise.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.mutedForeground, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(exercise.duration, style: const TextStyle(color: AppColors.dimForeground, fontSize: 11)),
                const SizedBox(width: 10),
                Text(exercise.difficulty, style: const TextStyle(color: AppColors.dimForeground, fontSize: 11)),
                const Spacer(),
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
          icon: const Icon(Icons.arrow_back, color: AppColors.foreground),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.exercise.title,
          style: const TextStyle(color: AppColors.foreground, fontSize: 16, fontWeight: FontWeight.w600),
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
                    style: const TextStyle(color: AppColors.mutedForeground, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '⏱ ${widget.exercise.duration}',
                        style: const TextStyle(color: AppColors.dimForeground, fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '📊 ${widget.exercise.difficulty}',
                        style: const TextStyle(color: AppColors.dimForeground, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
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
                                  style: const TextStyle(
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

// Экран для аудио упражнений - Archive.org API
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
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchAndPlay();
  }

  Future<void> _searchAndPlay() async {
    try {
      // Ключевые слова для каждого упражнения
      final queries = {
        'audio_rain_sounds': 'rain sounds nature water',
        'audio_ocean_waves': 'ocean waves sea water nature',
        'audio_forest_sounds': 'forest birds nature sounds',
        'audio_meditation_calm': 'ambient meditation peaceful music',
        'audio_binaural_relax': 'singing bowl meditation gong sound',
      };

      final query = queries[widget.exercise.id] ?? 'nature sounds meditation';

      // Поиск через Archive.org
      final searchUrl = 'https://archive.org/advancedsearch.php'
          '?q=$query+mediatype:audio'
          '&fl[]=identifier,title'
          '&sort[]=-downloads'
          '&rows=10'
          '&output=json';

      final searchResp = await http.get(Uri.parse(searchUrl));
      if (searchResp.statusCode != 200) throw Exception('Search failed');

      final searchData = jsonDecode(searchResp.body);
      final docs = searchData['response']['docs'] as List;
      if (docs.isEmpty) throw Exception('Аудио не найдено');

      // Фильтруем результаты — исключаем речь
      String? mp3Url;
      for (final doc in docs) {
        final identifier = doc['identifier'] as String?;
        final title = (doc['title'] as String?)?.toLowerCase() ?? '';

        // Пропускаем файлы с речью
        if (_containsSpeech(title)) continue;
        if (identifier == null) continue;

        // Получаем metadata и ищем аудио файл
        final metadataUrl = 'https://archive.org/metadata/$identifier';
        final metaResp = await http.get(Uri.parse(metadataUrl));
        if (metaResp.statusCode != 200) continue;

        final metaData = jsonDecode(metaResp.body);
        mp3Url = _findAudioFile(metaData, identifier);
        if (mp3Url != null) break;
      }

      if (mp3Url == null) throw Exception('Подходящие аудио файлы не найдены');

      // Загружаем и воспроизводим
      await _audioPlayer.setUrl(mp3Url);

      _audioPlayer.durationStream.listen((d) {
        if (d != null) setState(() => _duration = d);
      });

      _audioPlayer.positionStream.listen((p) {
        setState(() => _position = p);
      });

      _audioPlayer.playerStateStream.listen((state) {
        setState(() {
          _isPlaying = state.playing;
          _isLoaded = true;
          _isSearching = false;
        });
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _error = 'Ошибка: $e';
      });
    }
  }

  bool _containsSpeech(String title) {
    final speechWords = [
      'podcast', 'interview', 'talk', 'speech', 'audiobook',
      'reading', 'librivox', 'story', 'lecture', 'sermon',
      'radio', 'news', 'discussion', 'debate', 'comedy',
      'spoken', 'word', 'narration', 'narrated', 'voice'
    ];
    return speechWords.any((word) => title.contains(word));
  }

  String? _findAudioFile(Map<String, dynamic> metaData, String identifier) {
    final files = metaData['files'] as List?;
    if (files == null) return null;

    final title = (metaData['metadata']['title'] as String?)?.toLowerCase() ?? '';
    if (_containsSpeech(title)) return null;

    // Ищем MP3
    for (final file in files) {
      final name = file['name'] as String?;
      if (name != null && name.endsWith('.mp3')) {
        // Пропускаем большие файлы (> 50MB) — скорее всего аудиокниги
        final sizeStr = file['size']?.toString();
        if (sizeStr != null) {
          final size = int.tryParse(sizeStr);
          if (size != null && size > 50 * 1024 * 1024) continue;
        }
        return 'https://archive.org/download/$identifier/$name';
      }
    }

    // Или OGG
    for (final file in files) {
      final name = file['name'] as String?;
      if (name != null && name.endsWith('.ogg')) {
        final sizeStr = file['size']?.toString();
        if (sizeStr != null) {
          final size = int.tryParse(sizeStr);
          if (size != null && size > 50 * 1024 * 1024) continue;
        }
        return 'https://archive.org/download/$identifier/$name';
      }
    }

    return null;
  }

  Future<void> _play() async => await _audioPlayer.play();

  Future<void> _stop() async {
    await _audioPlayer.stop();
    setState(() => _position = Duration.zero);
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
          icon: const Icon(Icons.arrow_back, color: AppColors.foreground),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.exercise.audioTitle ?? widget.exercise.title,
          style: const TextStyle(color: AppColors.foreground, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (!_isSearching && _isLoaded)
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.citrusOrange),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                  _isLoaded = false;
                  _error = null;
                  _position = Duration.zero;
                  _duration = Duration.zero;
                });
                _audioPlayer.stop();
                _searchAndPlay();
              },
              tooltip: 'Найти другое аудио',
            ),
        ],
      ),
      body: _isSearching
          ? const Center(
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
                        child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mutedForeground)),
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
                        style: const TextStyle(color: AppColors.foreground, fontSize: 20, fontWeight: FontWeight.w600),
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
                            onTap: _isPlaying ? _stop : _play,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: _isPlaying
                                      ? [AppColors.destructive, const Color(0xFFE74C3C)]
                                      : [AppColors.citrusOrange, AppColors.citrusAmber],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isPlaying ? AppColors.destructive : AppColors.citrusOrange).withOpacity(0.4),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isPlaying ? Icons.stop : Icons.play_arrow,
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

class _ExerciseDetailSheetState extends State<ExerciseDetailSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  Timer? _timer;
  int _remainingSeconds = 0;
  int _currentCycle = 0;
  String _phaseText = '';
  bool _isRunning = false;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.exercise.durationSeconds;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.exercise.id == 'box_breathing') {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
      _phaseText = 'Вдох...';
    });

    if (widget.exercise.id == 'box_breathing') {
      _startBreathingCycle();
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
          if (widget.exercise.id == 'box_breathing') {
            final cyclePos = _currentCycle % 4;
            _phaseText = cyclePos == 0 ? 'Вдох...'
                : cyclePos == 1 ? 'Задержка...'
                : cyclePos == 2 ? 'Выдох...'
                : 'Задержка...';
          }
        });
      } else {
        _timer?.cancel();
        setState(() {
          _isRunning = false;
          _isFinished = true;
          _phaseText = 'Упражнение завершено!';
        });
        _animationController.stop();
      }
    });
  }

  void _startBreathingCycle() {
    Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_isRunning || _isFinished) {
        timer.cancel();
        return;
      }
      setState(() => _currentCycle++);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = widget.exercise.durationSeconds;
      _currentCycle = 0;
      _phaseText = '';
      _isFinished = false;
    });
    if (widget.exercise.id == 'box_breathing') {
      _animationController.reset();
      _animationController.repeat(reverse: true);
    }
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isBreathingExercise = widget.exercise.id == 'box_breathing';
    final color = widget.exercise.color;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: Color(0xFF2A2830), width: 1)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.dimForeground,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
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
                            style: const TextStyle(
                              color: AppColors.foreground,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (isBreathingExercise)
                      Center(
                        child: AnimatedBuilder(
                          animation: _scaleAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _scaleAnimation.value,
                              child: Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      AppColors.citrusGreen.withOpacity(0.4),
                                      AppColors.citrusGreen.withOpacity(0.1),
                                      AppColors.citrusGreen.withOpacity(0.05),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.citrusGreen.withOpacity(0.3),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    _isRunning ? _phaseText : '🌬️',
                                    style: TextStyle(
                                      color: AppColors.citrusGreen,
                                      fontSize: _isRunning ? 16 : 48,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    else
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
                        _isRunning || _isFinished ? _formatTime(_remainingSeconds) : widget.exercise.duration,
                        style: const TextStyle(
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
                            color: AppColors.citrusGreen,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    const Text(
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
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
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
                                step,
                                style: const TextStyle(
                                  color: AppColors.mutedForeground,
                                  fontSize: 13,
                                  height: 1.5,
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
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: AppColors.citrusGreen, size: 20),
                            SizedBox(width: 8),
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
          ),
        );
      },
    );
  }
}
