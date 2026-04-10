import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class _PhotoCard {
  final String emoji;
  final String title;
  final String date;
  final Color color;
  final List<Color> gradientColors;
  bool isLiked;

  _PhotoCard({
    required this.emoji,
    required this.title,
    required this.date,
    required this.color,
    required this.gradientColors,
    this.isLiked = false,
  });
}

class PhotoGalleryScreen extends StatefulWidget {
  const PhotoGalleryScreen({super.key});

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  final List<_PhotoCard> _photos = [
    _PhotoCard(
      emoji: '\u{1F393}',
      title: '\u041F\u043E\u043B\u0443\u0447\u0435\u043D\u0438\u0435 \u0434\u0438\u043F\u043B\u043E\u043C\u0430',
      date: '15 \u0438\u044E\u043D\u044F 2025',
      color: const Color(0xFF6366F1),
      gradientColors: [const Color(0xFF2563EB), const Color(0xFF9333EA)],
    ),
    _PhotoCard(
      emoji: '\u{1F389}',
      title: '\u0414\u0435\u043D\u044C \u0440\u043E\u0436\u0434\u0435\u043D\u0438\u044F',
      date: '3 \u043C\u0430\u0440\u0442\u0430 2025',
      color: AppColors.citrusRed,
      gradientColors: [const Color(0xFFEC4899), const Color(0xFFF43F5E)],
    ),
    _PhotoCard(
      emoji: '\u{1F3D6}\u{FE0F}',
      title: '\u041B\u0435\u0442\u043D\u0438\u0439 \u043E\u0442\u0434\u044B\u0445',
      date: '20 \u0438\u044E\u043B\u044F 2025',
      color: const Color(0xFF2EC4B6),
      gradientColors: [const Color(0xFF06B6D4), const Color(0xFF14B8A6)],
    ),
    _PhotoCard(
      emoji: '\u{1F384}',
      title: '\u041D\u043E\u0432\u044B\u0439 \u0433\u043E\u0434',
      date: '31 \u0434\u0435\u043A\u0430\u0431\u0440\u044F 2024',
      color: const Color(0xFF2A9D8F),
      gradientColors: [const Color(0xFF22C55E), const Color(0xFF10B981)],
    ),
    _PhotoCard(
      emoji: '\u{1F468}\u200D\u{1F469}\u200D\u{1F467}',
      title: '\u0421\u0435\u043C\u0435\u0439\u043D\u044B\u0439 \u0443\u0436\u0438\u043D',
      date: '10 \u044F\u043D\u0432\u0430\u0440\u044F 2025',
      color: AppColors.citrusOrange,
      gradientColors: [const Color(0xFFF97316), const Color(0xFFF59E0B)],
    ),
    _PhotoCard(
      emoji: '\u{1F415}',
      title: '\u0412\u0441\u0442\u0440\u0435\u0447\u0430 \u0441 \u0434\u0440\u0443\u0433\u043E\u043C',
      date: '5 \u0444\u0435\u0432\u0440\u0430\u043B\u044F 2025',
      color: AppColors.citrusAmber,
      gradientColors: [const Color(0xFFEAB308), const Color(0xFFF97316)],
    ),
  ];

  void _toggleLike(int index) {
    setState(() => _photos[index].isLiked = !_photos[index].isLiked);
  }

  void _openPhotoDetail(int index) {
    final photo = _photos[index];
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: photo.gradientColors,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(32),
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Center(child: Text(photo.emoji, style: const TextStyle(fontSize: 72))),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _toggleLike(index),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            photo.isLiked ? Icons.favorite : Icons.favorite_border,
                            color: photo.isLiked ? AppColors.citrusRed : AppColors.foreground,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.surface1,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      photo.title,
                      style: const TextStyle(
                        color: AppColors.foreground,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(photo.date, style: const TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surface2,
                          foregroundColor: AppColors.foreground,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('\u0417\u0430\u043A\u0440\u044B\u0442\u044C'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAddMomentModal() {
    final emojis = ['\u{1F393}', '\u{1F389}', '\u{1F3D6}\u{FE0F}', '\u{1F384}', '\u{1F468}\u200D\u{1F469}\u200D\u{1F467}', '\u{1F415}', '\u{1F381}', '\u2708\u{FE0F}', '\u{1F3B8}', '\u{1F3C6}', '\u{1F305}', '\u{1F38A}'];
    String? selectedEmoji;
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: AppColors.surface1,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '\u0414\u043E\u0431\u0430\u0432\u0438\u0442\u044C \u043C\u043E\u043C\u0435\u043D\u0442',
                      style: TextStyle(color: AppColors.foreground, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.mutedForeground),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('\u0412\u044B\u0431\u0435\u0440\u0438\u0442\u0435 \u0438\u043A\u043E\u043D\u043A\u0443', style: TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: emojis.length,
                  itemBuilder: (context, index) {
                    final emoji = emojis[index];
                    final isSelected = selectedEmoji == emoji;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedEmoji = emoji),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.surface2 : AppColors.surface1,
                          border: Border.all(
                            color: isSelected ? AppColors.citrusOrange.withOpacity(0.5) : AppColors.subtleBorder,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: AppColors.foreground),
                  decoration: InputDecoration(
                    labelText: '\u041D\u0430\u0437\u0432\u0430\u043D\u0438\u0435',
                    labelStyle: const TextStyle(color: AppColors.mutedForeground),
                    filled: true,
                    fillColor: AppColors.surface2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.citrusOrange, AppColors.citrusAmber]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        if (selectedEmoji != null && titleController.text.isNotEmpty) {
                          setState(() {
                            _photos.add(_PhotoCard(
                              emoji: selectedEmoji!,
                              title: titleController.text,
                              date: '\u0421\u0435\u0433\u043E\u0434\u043D\u044F',
                              color: AppColors.citrusOrange,
                              gradientColors: [AppColors.citrusOrange, AppColors.citrusAmber],
                            ));
                          });
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        '\u0421\u043E\u0445\u0440\u0430\u043D\u0438\u0442\u044C \u043C\u043E\u043C\u0435\u043D\u0442',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
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

  @override
  Widget build(BuildContext context) {
    final likedCount = _photos.where((p) => p.isLiked).length;

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '\u0413\u0430\u043B\u0435\u0440\u0435\u044F \u043C\u043E\u043C\u0435\u043D\u0442\u043E\u0432',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.foreground),
                    ),
                    GestureDetector(
                      onTap: _openAddMomentModal,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.citrusOrange, AppColors.citrusAmber]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Dopamine card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.citrusRed.withOpacity(0.12), AppColors.citrusOrange.withOpacity(0.08)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.citrusRed.withOpacity(0.2)),
                  ),
                  child: const Text(
                    '\u0414\u043E\u0444\u0430\u043C\u0438\u043D\n\u041A\u0430\u0436\u0434\u044B\u0439 \u0441\u0447\u0430\u0441\u0442\u043B\u0438\u0432\u044B\u0439 \u043C\u043E\u043C\u0435\u043D\u0442 \u0437\u0430\u0441\u043B\u0443\u0436\u0438\u0432\u0430\u0435\u0442 \u0431\u044B\u0442\u044C \u0441\u043E\u0445\u0440\u0430\u043D\u0451\u043D\u043D\u044B\u043C.',
                    style: TextStyle(color: AppColors.foreground, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.favorite, color: AppColors.citrusRed, size: 16),
                    const SizedBox(width: 4),
                    Text('$likedCount \u043B\u044E\u0431\u0438\u043C\u044B\u0445 \u043C\u043E\u043C\u0435\u043D\u0442\u043E\u0432', style: const TextStyle(color: AppColors.mutedForeground, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _photos.length,
                    itemBuilder: (context, index) {
                      final photo = _photos[index];
                      return GestureDetector(
                        onTap: () => _openPhotoDetail(index),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface1,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.subtleBorder),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: Stack(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: photo.gradientColors,
                                        ),
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                      ),
                                      child: Center(child: Text(photo.emoji, style: const TextStyle(fontSize: 48))),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () => _toggleLike(index),
                                        child: Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.4),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            photo.isLiked ? Icons.favorite : Icons.favorite_border,
                                            color: photo.isLiked ? AppColors.citrusRed : AppColors.foreground,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: photo.color,
                                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      photo.title,
                                      style: const TextStyle(color: AppColors.foreground, fontSize: 13, fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(photo.date, style: const TextStyle(color: AppColors.mutedForeground, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.citrusOrange, AppColors.citrusAmber]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: _openAddMomentModal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        '\u0414\u043E\u0431\u0430\u0432\u0438\u0442\u044C \u043C\u043E\u043C\u0435\u043D\u0442',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
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
}
