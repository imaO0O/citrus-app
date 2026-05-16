import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/affirmations_service.dart';
import '../core/utils/app_size.dart';

const _categories = ['Все', 'Уверенность', 'Спокойствие', 'Сила', 'Любовь'];

class AffirmationsScreen extends StatefulWidget {
  AffirmationsScreen({super.key});

  @override
  State<AffirmationsScreen> createState() => _AffirmationsScreenState();
}

class _AffirmationsScreenState extends State<AffirmationsScreen> {
  late PageController _pageController;
  final Set<String> _favorites = {}; // храним ID, а не индексы
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
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _toggleFavorite(String id) {
    setState(() {
      if (_favorites.contains(id)) {
        _favorites.remove(id);
      } else {
        _favorites.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  AppSize.gapH(16),
                  _buildCategoryPills(),
                  AppSize.gapH(16),
                  _buildContent(),
                  AppSize.gapH(16),
                  if (_favorites.isNotEmpty) ...[
                    AppSize.gapH(12),
                    _buildFavoritesSection(),
                  ],
                  AppSize.gapH(80),
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
            fontSize: AppSize.s(24),
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
                  AppSize.gapH(16),
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
                      AppSize.gapH(16),
                      Text(
                        'Нет аффирмаций в этой категории',
                        style: TextStyle(color: AppColors.mutedForeground),
                      ),
                      AppSize.gapH(16),
                      ElevatedButton.icon(
                        onPressed: _generateAffirmations,
                        icon: Icon(Icons.auto_awesome),
                        label: Text('Сгенерировать (AI)'),
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
        separatorBuilder: (_, __) => AppSize.gapW(8),
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

  Widget _buildMainCard(Affirmation affirmation, int index) {
    final isFavorite = _favorites.contains(affirmation.id);

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppSize.radius(24),
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
                  stops: [0.0, 0.7],
                ),
              ),
            ),
          ),
          Padding(
            padding: AppSize.padding(24),
            child: Center(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(affirmation.emoji, style: TextStyle(fontSize: AppSize.s(56))),
                    AppSize.gapH(16),
                    Text(
                      '"${affirmation.text}"',
                      style: TextStyle(
                        fontSize: AppSize.s(16),
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    AppSize.gapH(8),
                    Container(
                      padding: AppSize.paddingH(12, 4),
                      decoration: BoxDecoration(
                        color: affirmation.color.withOpacity(0.1),
                        borderRadius: AppSize.radius(12),
                      ),
                      child: Text(
                        affirmation.category,
                        style: TextStyle(
                          fontSize: AppSize.s(11),
                          color: affirmation.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    AppSize.gapH(8),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: GestureDetector(
              onTap: () => _toggleFavorite(affirmation.id),
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
    if (_favorites.isEmpty) return SizedBox.shrink();

    // Находим аффирмации, которые в избранном, по их ID
    final favoriteAffirmations = _affirmations.where((a) => _favorites.contains(a.id)).toList();

    return Container(
      padding: AppSize.padding(12),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: AppSize.radius(16),
        border: Border.all(color: AppColors.subtleBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ИЗБРАННОЕ',
            style: TextStyle(
              fontSize: AppSize.s(10),
              fontWeight: FontWeight.w700,
              letterSpacing: 2.4,
              color: AppColors.dimForeground,
            ),
          ),
          AppSize.gapH(8),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: favoriteAffirmations.length,
              separatorBuilder: (_, __) => AppSize.gapW(8),
              itemBuilder: (context, index) {
                final affirmation = favoriteAffirmations[index];
                final globalIndex = _affirmations.indexOf(affirmation);
                return GestureDetector(
                  onTap: () {
                    // Переключаемся на категорию этой аффирмации и переходим к ней
                    if (_selectedCategory != affirmation.category && _selectedCategory != 'Все') {
                      setState(() => _selectedCategory = affirmation.category);
                    }
                    final filteredIndex = _filteredAffirmations.indexOf(affirmation);
                    if (filteredIndex >= 0) {
                      _goToPage(filteredIndex);
                    }
                  },
                  child: Container(
                    width: 56,
                    decoration: BoxDecoration(
                      color: affirmation.color.withOpacity(0.1),
                      borderRadius: AppSize.radius(12),
                      border: Border.all(color: affirmation.color.withOpacity(0.2)),
                    ),
                    child: Center(
                      child: Text(affirmation.emoji, style: TextStyle(fontSize: AppSize.s(20))),
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
