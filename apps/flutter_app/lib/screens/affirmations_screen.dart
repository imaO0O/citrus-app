import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/affirmations_service.dart';

const _categories = ['Все', 'Уверенность', 'Спокойствие', 'Сила', 'Любовь'];

class AffirmationsScreen extends StatefulWidget {
  const AffirmationsScreen({super.key});

  @override
  State<AffirmationsScreen> createState() => _AffirmationsScreenState();
}

class _AffirmationsScreenState extends State<AffirmationsScreen> {
  late PageController _pageController;
  final Set<int> _favorites = {};
  String _selectedCategory = 'Все';

  final AffirmationsService _service = AffirmationsService();
  List<Affirmation> _affirmations = [];
  bool _isLoading = true;
  bool _isGenerating = false;

  List<Affirmation> get _filteredAffirmations {
    if (_selectedCategory == 'Все') return _affirmations;
    return _affirmations.where((a) => a.category == _selectedCategory).toList();
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadAffirmations();
  }

  Future<void> _loadAffirmations() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    final affirmations = await _service.getCachedAffirmations();
    
    if (mounted) {
      setState(() {
        _affirmations = affirmations;
        _isLoading = false;
      });
    }
    
    // Проверяем, нужно ли обновить (раз в день)
    final shouldRefresh = await _service.shouldRefresh();
    if (shouldRefresh && mounted) {
      _generateAffirmations();
    }
  }

  Future<void> _generateAffirmations() async {
    if (_isGenerating) return;
    
    setState(() => _isGenerating = true);
    
    try {
      final newAffirmations = await _service.generateAffirmations(
        category: _selectedCategory,
      );
      
      if (mounted) {
        setState(() {
          _affirmations = newAffirmations;
          _isGenerating = false;
        });
        _pageController.jumpToPage(0);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка генерации: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildCategoryPills(),
                  const SizedBox(height: 16),
                  _buildContent(),
                  const SizedBox(height: 16),
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
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Аффирмации',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.foreground,
          ),
        ),
        if (_isGenerating)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.citrusOrange),
            ),
          )
        else
          IconButton(
            onPressed: _generateAffirmations,
            icon: Icon(Icons.auto_awesome, color: AppColors.citrusOrange),
            tooltip: 'Сгенерировать новые (AI)',
          ),
      ],
    );
  }

  Widget _buildContent() {
    return SizedBox(
      height: 320,
      child: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.citrusOrange),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Загрузка аффирмаций...',
                    style: TextStyle(color: AppColors.mutedForeground),
                  ),
                ],
              ),
            )
          : _filteredAffirmations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.format_quote,
                        size: 64,
                        color: AppColors.mutedForeground.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Нет аффирмаций в этой категории',
                        style: TextStyle(color: AppColors.mutedForeground),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _generateAffirmations,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Сгенерировать (AI)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.citrusOrange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : PageView.builder(
                  controller: _pageController,
                  itemCount: _filteredAffirmations.length,
                  itemBuilder: (context, index) {
                    final affirmation = _filteredAffirmations[index];
                    return _buildMainCard(affirmation, index);
                  },
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
              });
              _pageController.jumpToPage(0);
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

  Widget _buildMainCard(Affirmation affirmation, int index) {
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
            padding: const EdgeInsets.all(24),
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(affirmation.emoji, style: const TextStyle(fontSize: 56)),
                    const SizedBox(height: 16),
                    Text(
                      '"${affirmation.text}"',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: affirmation.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        affirmation.category,
                        style: TextStyle(
                          fontSize: 11,
                          color: affirmation.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
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
          Text(
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
                final favIndex = favoriteList[index];
                if (favIndex >= _filteredAffirmations.length) {
                  return const SizedBox.shrink();
                }
                final affirmation = _filteredAffirmations[favIndex];
                return GestureDetector(
                  onTap: () => _goToPage(favIndex),
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
