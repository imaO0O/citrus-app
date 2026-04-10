import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class _AffirmationData {
  final String emoji;
  final String text;
  final Color color;

  const _AffirmationData({required this.emoji, required this.text, required this.color});
}

const _categories = ['\u0412\u0441\u0435', '\u0423\u0432\u0435\u0440\u0435\u043D\u043D\u043E\u0441\u0442\u044C', '\u0421\u043F\u043E\u043A\u043E\u0439\u0441\u0442\u0432\u0438\u0435', '\u0421\u0438\u043B\u0430', '\u041B\u044E\u0431\u043E\u0432\u044C'];

const _allAffirmations = [
  _AffirmationData(emoji: '\u{1F31F}', text: '\u042F \u0434\u043E\u0441\u0442\u043E\u0438\u043D \u043B\u044E\u0431\u0432\u0438 \u0438 \u0443\u0432\u0430\u0436\u0435\u043D\u0438\u044F', color: Color(0xFFFFB347)),
  _AffirmationData(emoji: '\u{1F331}', text: '\u041A\u0430\u0436\u0434\u044B\u0439 \u0434\u0435\u043D\u044C \u044F \u0441\u0442\u0430\u043D\u043E\u0432\u043B\u044E\u0441\u044C \u043B\u0443\u0447\u0448\u0435', color: AppColors.moodExcellent),
  _AffirmationData(emoji: '\u{1F4AA}', text: '\u042F \u0441\u043F\u0440\u0430\u0432\u043B\u044E\u0441\u044C \u0441 \u043B\u044E\u0431\u044B\u043C\u0438 \u0442\u0440\u0443\u0434\u043D\u043E\u0441\u0442\u044F\u043C\u0438', color: AppColors.citrusOrange),
  _AffirmationData(emoji: '\u2764\u{FE0F}', text: '\u041C\u043E\u0438 \u0447\u0443\u0432\u0441\u0442\u0432\u0430 \u0432\u0430\u0436\u043D\u044B', color: AppColors.citrusRed),
  _AffirmationData(emoji: '\u{1F3C6}', text: '\u042F \u0433\u043E\u0440\u0436\u0443\u0441\u044C \u0441\u0432\u043E\u0438\u043C\u0438 \u0434\u043E\u0441\u0442\u0438\u0436\u0435\u043D\u0438\u044F\u043C\u0438', color: AppColors.citrusYellow),
  _AffirmationData(emoji: '\u2728', text: '\u0423 \u043C\u0435\u043D\u044F \u0435\u0441\u0442\u044C \u0432\u0441\u0451 \u0434\u043B\u044F \u0443\u0441\u043F\u0435\u0445\u0430', color: Color(0xFFC084FC)),
  _AffirmationData(emoji: '\u{1F98B}', text: '\u042F \u043F\u0440\u0438\u043D\u0438\u043C\u0430\u044E \u0441\u0435\u0431\u044F', color: Color(0xFFA78BFA)),
  _AffirmationData(emoji: '\u2600\u{FE0F}', text: '\u0421\u0435\u0433\u043E\u0434\u043D\u044F \u044F \u0432\u044B\u0431\u0438\u0440\u0430\u044E \u043F\u043E\u0437\u0438\u0442\u0438\u0432', color: AppColors.citrusYellow),
  _AffirmationData(emoji: '\u{1F9E0}', text: '\u041C\u043E\u0439 \u0443\u043C \u044F\u0441\u043D\u044B\u0439', color: Color(0xFFA78BFA)),
  _AffirmationData(emoji: '\u{1F338}', text: '\u042F \u0437\u0430\u0441\u043B\u0443\u0436\u0438\u0432\u0430\u044E \u043E\u0442\u0434\u044B\u0445\u0430', color: AppColors.moodExcellent),
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
  String _selectedCategory = '\u0412\u0441\u0435';

  List<_AffirmationData> get _filteredAffirmations {
    if (_selectedCategory == '\u0412\u0441\u0435') return _allAffirmations;
    // Simple category filtering for demo
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
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '\u0410\u0444\u0444\u0438\u0440\u043C\u0430\u0446\u0438\u0438',
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
                const SizedBox(height: 20),
                _buildActionButtons(),
                if (_favorites.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildFavoritesSection(),
                ],
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
                  '\u201C${affirmation.text}\u201D',
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
    final isLast = _currentIndex == _filteredAffirmations.length - 1;
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
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildFavoritesSection() {
    final favoriteList = _favorites.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            '\u0418\u0417\u0411\u0420\u0410\u041D\u041D\u041E\u0415',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.4,
              color: AppColors.dimForeground,
            ),
          ),
        ),
        ...favoriteList.map((index) {
          final affirmation = _filteredAffirmations[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.subtleBorder),
            ),
            child: Row(
              children: [
                Text(affirmation.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    affirmation.text,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.foreground),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _toggleFavorite(index),
                  child: Icon(Icons.favorite_rounded, color: affirmation.color, size: 20),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
