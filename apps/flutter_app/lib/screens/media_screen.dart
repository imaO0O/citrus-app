import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/app_size.dart';

class MediaScreen extends StatefulWidget {
  MediaScreen({super.key});

  @override
  State<MediaScreen> createState() => _MediaScreenState();
}

class _MediaScreenState extends State<MediaScreen> with SingleTickerProviderStateMixin {
  String? _playingTrackId;
  String? _playingCategory;
  late AnimationController _equalizerController;

  final List<String> _categories = [
    '\u0412\u0441\u0435', '\u0421\u043E\u043D', '\u0421\u0442\u0440\u0435\u0441\u0441', '\u0422\u0440\u0435\u0432\u043E\u0433\u0430', '\u0424\u043E\u043A\u0443\u0441', '\u042D\u043D\u0435\u0440\u0433\u0438\u044F', '\u041F\u043E\u043A\u043E\u0439',
  ];
  String _selectedCategory = '\u0412\u0441\u0435';

  final List<Map<String, dynamic>> _videos = [
    {'id': 'v1', 'icon': '\u{1F319}', 'title': '\u041C\u0435\u0434\u0438\u0442\u0430\u0446\u0438\u044F \u0434\u043B\u044F \u0441\u043D\u0430', 'duration': '15 \u043C\u0438\u043D', 'color': AppColors.citrusPurple},
    {'id': 'v2', 'icon': '\u{1F32C}\u{FE0F}', 'title': '\u0414\u044B\u0445\u0430\u0442\u0435\u043B\u044C\u043D\u044B\u0435 \u0443\u043F\u0440\u0430\u0436\u043D\u0435\u043D\u0438\u044F', 'duration': '10 \u043C\u0438\u043D', 'color': Color(0xFF42A5F5)},
    {'id': 'v3', 'icon': '\u{1F9D8}', 'title': '\u0419\u043E\u0433\u0430', 'duration': '20 \u043C\u0438\u043D', 'color': Color(0xFF66BB6A)},
    {'id': 'v4', 'icon': '\u2728', 'title': '\u041F\u0440\u043E\u0433\u0440\u0435\u0441\u0441\u0438\u0432\u043D\u0430\u044F \u0440\u0435\u043B\u0430\u043A\u0441\u0430\u0446\u0438\u044F', 'duration': '12 \u043C\u0438\u043D', 'color': Color(0xFFFFB74D)},
    {'id': 'v5', 'icon': '\u2600\u{FE0F}', 'title': '\u0423\u0442\u0440\u0435\u043D\u043D\u044F\u044F \u043C\u0435\u0434\u0438\u0442\u0430\u0446\u0438\u044F', 'duration': '8 \u043C\u0438\u043D', 'color': Color(0xFFFFA726)},
    {'id': 'v6', 'icon': '\u{1F3DD}\u{FE0F}', 'title': '\u0412\u0438\u0437\u0443\u0430\u043B\u0438\u0437\u0430\u0446\u0438\u044F', 'duration': '18 \u043C\u0438\u043D', 'color': Color(0xFFAB47BC)},
  ];

  final List<Map<String, dynamic>> _audios = [
    {'id': 'a1', 'icon': '\u{1F332}', 'title': '\u0417\u0432\u0443\u043A\u0438 \u043F\u0440\u0438\u0440\u043E\u0434\u044B', 'duration': '30 \u043C\u0438\u043D', 'color': Color(0xFF66BB6A)},
    {'id': 'a2', 'icon': '\u{1F30A}', 'title': '\u0411\u0435\u043B\u044B\u0439 \u0448\u0443\u043C', 'duration': '45 \u043C\u0438\u043D', 'color': Color(0xFF42A5F5)},
    {'id': 'a3', 'icon': '\u{1F3B5}', 'title': '\u0423\u0441\u043F\u043E\u043A\u0430\u0438\u0432\u0430\u044E\u0449\u0430\u044F \u043C\u0443\u0437\u044B\u043A\u0430', 'duration': '25 \u043C\u0438\u043D', 'color': AppColors.citrusPurple},
    {'id': 'a4', 'icon': '\u26C8\u{FE0F}', 'title': '\u0414\u043E\u0436\u0434\u044C \u0438 \u0433\u0440\u043E\u043C', 'duration': '40 \u043C\u0438\u043D', 'color': Color(0xFF8D6E63)},
    {'id': 'a5', 'icon': '\u{1F99C}', 'title': '\u041F\u0435\u043D\u0438\u0435 \u043F\u0442\u0438\u0446', 'duration': '35 \u043C\u0438\u043D', 'color': Color(0xFFFFA726)},
  ];

  @override
  void initState() {
    super.initState();
    _equalizerController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    )..repeat();
  }

  @override
  void dispose() {
    _equalizerController.dispose();
    super.dispose();
  }

  void _toggleTrack(String trackId) {
    setState(() {
      if (_playingTrackId == trackId) {
        _playingTrackId = null;
        _playingCategory = null;
      } else {
        _playingTrackId = trackId;
        _playingCategory = _videos.any((v) => v['id'] == trackId) ? 'video' : 'audio';
      }
    });
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
              children: [
                if (_playingTrackId != null) _buildMiniPlayer(),
                _buildCategoryChips(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 80),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('\u0412\u0438\u0434\u0435\u043E'),
                        AppSize.gapH(12),
                        _buildVideoGrid(),
                        AppSize.gapH(24),
                        _buildSectionTitle('\u0410\u0443\u0434\u0438\u043E'),
                        AppSize.gapH(12),
                        _buildAudioList(),
                      ],
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

  Widget _buildMiniPlayer() {
    final allTracks = [..._videos, ..._audios];
    final track = allTracks.firstWhere(
      (t) => t['id'] == _playingTrackId,
      orElse: () => {'color': AppColors.citrusOrange},
    );
    final color = track['color'] as Color;

    return Container(
      margin: AppSize.padding(16),
      padding: AppSize.padding(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.12), color.withOpacity(0.06)],
        ),
        border: Border.all(color: color.withOpacity(0.2)),
        borderRadius: AppSize.radius(16),
      ),
      child: Row(
        children: [
          _buildEqualizer(color: color),
          AppSize.gapW(12),
          Expanded(
            child: Text(
              track['title'] as String,
              style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(14), fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () => _toggleTrack(_playingTrackId!),
            child: Icon(Icons.pause, color: AppColors.citrusOrange, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildEqualizer({Color? color}) {
    final barColor = color ?? AppColors.citrusOrange;
    return SizedBox(
      width: 24,
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(4, (index) {
          return AnimatedBuilder(
            animation: _equalizerController,
            builder: (context, child) {
              final progress = _equalizerController.value;
              final delay = index * 0.15;
              final value = ((progress + delay) % 1.0);
              final height = 8 + value * 12;
              return Container(
                width: 4,
                height: height,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: AppSize.radius(2),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppSize.paddingH(20, 8),
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
                borderRadius: AppSize.radius(999),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? AppColors.citrusOrange : AppColors.mutedForeground,
                  fontSize: AppSize.s(12),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.foreground,
        fontSize: AppSize.s(20),
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildVideoGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemCount: _videos.length,
      itemBuilder: (context, index) {
        final video = _videos[index];
        final isPlaying = _playingTrackId == video['id'];
        final color = video['color'] as Color;

        return GestureDetector(
          onTap: () => _toggleTrack(video['id'] as String),
          child: Container(
            decoration: BoxDecoration(
              gradient: isPlaying
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color.withOpacity(0.15), color.withOpacity(0.06)],
                    )
                  : null,
              color: isPlaying ? null : AppColors.surface1,
              border: Border.all(
                color: isPlaying ? color.withOpacity(0.25) : AppColors.subtleBorder,
                width: 1,
              ),
              borderRadius: AppSize.radius(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(video['icon'] as String, style: TextStyle(fontSize: AppSize.s(32))),
                AppSize.gapH(8),
                Padding(
                  padding: AppSize.paddingH(8, 0),
                  child: Text(
                    video['title'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(13), fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AppSize.gapH(4),
                Text(video['duration'] as String, style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(12))),
                if (isPlaying) ...[
                  AppSize.gapH(8),
                  SizedBox(width: AppSize.w(20), height: 16, child: _buildEqualizer(color: color)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAudioList() {
    return Column(
      children: _audios.map((audio) {
        final isPlaying = _playingTrackId == audio['id'];
        final color = audio['color'] as Color;

        return GestureDetector(
          onTap: () => _toggleTrack(audio['id'] as String),
          child: Container(
            margin: AppSize.paddingOnly(bottom: 8),
            padding: AppSize.padding(12),
            decoration: BoxDecoration(
              gradient: isPlaying
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color.withOpacity(0.15), color.withOpacity(0.06)],
                    )
                  : null,
              color: isPlaying ? null : AppColors.surface1,
              border: Border.all(
                color: isPlaying ? color.withOpacity(0.25) : AppColors.subtleBorder,
                width: 1,
              ),
              borderRadius: AppSize.radius(12),
            ),
            child: Row(
              children: [
                Text(audio['icon'] as String, style: TextStyle(fontSize: AppSize.s(24))),
                AppSize.gapW(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        audio['title'] as String,
                        style: TextStyle(color: AppColors.foreground, fontSize: AppSize.s(14), fontWeight: FontWeight.w500),
                      ),
                      AppSize.gapH(4),
                      Text(audio['duration'] as String, style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(12))),
                    ],
                  ),
                ),
                if (isPlaying) ...[
                  _buildEqualizer(color: color),
                  AppSize.gapW(8),
                  Icon(Icons.pause, color: AppColors.citrusOrange, size: 24),
                ] else
                  Icon(Icons.play_arrow, color: AppColors.mutedForeground, size: 24),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
