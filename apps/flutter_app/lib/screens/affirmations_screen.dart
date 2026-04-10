import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class _AffirmationData {
  final String emoji;
  final String text;
  final Color color;

  const _AffirmationData({required this.emoji, required this.text, required this.color});
}

const _categories = ['Все', 'Уверенность', 'Спокойствие', 'Сила', 'Любовь'];

const _allAffirmations = [
  _AffirmationData(emoji: '🌟', text: 'Я достоин любви и уважения', color: Color(0xFFFFB347)),
  _AffirmationData(emoji: '🌱', text: 'Каждый день я становлюсь лучше', color: AppColors.moodExcellent),
  _AffirmationData(emoji: '💪', text: 'Я справлюсь с любыми трудностями', color: AppColors.citrusOrange),
  _AffirmationData(emoji: '❤️', text: 'Мои чувства важны', color: AppColors.citrusRed),
  _AffirmationData(emoji: '🏆', text: 'Я горжусь своими достижениями', color: AppColors.citrusYellow),
  _AffirmationData(emoji: '✨', text: 'У меня есть всё для успеха', color: Color(0xFFC084FC)),
  _AffirmationData(emoji: '🦋', text: 'Я принимаю себя', color: Color(0xFFA78BFA)),
  _AffirmationData(emoji: '☀️', text: 'Сегодня я выбираю позитив', color: AppColors.citrusYellow),
  _AffirmationData(emoji: '🧠', text: 'Мой ум ясный', color: Color(0xFFA78BFA)),
  _AffirmationData(emoji: '🌸', text: 'Я заслуживаю отдыха', color: AppColors.moodExcellent),
];

class AffirmationsScreen extends StatefulWidget {
  const AffirmationsScreen({super.key});

  @override
  State<AffirmationsScreen> createState() => _AffirmationsScreenState();
}

class _AffirmationsScreenState extends State<AffirmationsScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  final Set<int> _favorites = {};
  String _selectedCategory = 'Все';

  List<_AffirmationData> get _filteredAffirmations {
    if (_selectedCategory == 'Все') return _allAffirmations;
    return _allAffirmations;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    if (index >= 0 && index < _filteredAffirmations.length) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _toggleFavorite(int index) {
    setState(() {
      if (_favorites.contains(index)) {
        _favorites.remove(index);
      } else {
        _favorites.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Аффирмации',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 16),
                _buildCategoryPills(),
                const SizedBox(height: 16),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _currentIndex = index),
                    itemCount: _filteredAffirmations.length,
                    itemBuilder: (context, index) {
                      final affirmation = _filteredAffirmations[index];
                      return _buildMainCard(affirmation, index);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _buildPageIndicator(),
                const SizedBox(height: 16),
                _buildActionButtons(),
                if (_favorites.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildFavoritesSection(),
                ],
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPills() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
                _currentIndex = 0;
                _pageController.jumpToPage(0);
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.citrusOrange.withOpacity(0.15) : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? AppColors.citrusOrange : AppColors.mutedForeground,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainCard(_AffirmationData affirmation, int index) {
    final isFavorite = _favorites.contains(index);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [affirmation.color.withOpacity(0.15), affirmation.color.withOpacity(0.05)],
        ),
        border: Border.all(color: affirmation.color.withOpacity(0.2)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [affirmation.color.withOpacity(0.25), affirmation.color.withOpacity(0)],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(affirmation.emoji, style: const TextStyle(fontSize: 64)),
                const SizedBox(height: 24),
                Text(
                  '"${affirmation.text}"',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                    height: 1.4,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  '${index + 1} / ${_filteredAffirmations.length}',
                  style: TextStyle(fontSize: 12, color: AppColors.foreground.withOpacity(0.5)),
                ),
              ],
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: GestureDetector(
              onTap: () => _goToPage(index - 1),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.chevron_left_rounded, color: AppColors.foreground, size: 20),
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: () => _goToPage(index + 1),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.chevron_right_rounded, color: AppColors.foreground, size: 20),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: GestureDetector(
              onTap: () => _toggleFavorite(index),
              child: Icon(
                isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFavorite ? affirmation.color : AppColors.mutedForeground,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _filteredAffirmations.length,
        (index) {
          final currentColor = _filteredAffirmations[_currentIndex].color;
          final isSelected = _currentIndex == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: isSelected ? 16 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: isSelected ? currentColor : Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => _toggleFavorite(_currentIndex),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.favorite_border_rounded, color: AppColors.mutedForeground, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () {
            final next = (_currentIndex + 1) % _filteredAffirmations.length;
            _goToPage(next);
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.citrusOrange, AppColors.citrusAmber]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.citrusOrange.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () {},
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.share_rounded, color: AppColors.mutedForeground, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesSection() {
    if (_favorites.isEmpty) return const SizedBox.shrink();
    final favoriteList = _favorites.toList()..sort();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.subtleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ИЗБРАННОЕ',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.4,
              color: AppColors.dimForeground,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: favoriteList.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final affirmation = _filteredAffirmations[favoriteList[index]];
                return GestureDetector(
                  onTap: () => _goToPage(favoriteList[index]),
                  child: Container(
                    width: 56,
                    decoration: BoxDecoration(
                      color: affirmation.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: affirmation.color.withOpacity(0.2)),
                    ),
                    child: Center(
                      child: Text(affirmation.emoji, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
