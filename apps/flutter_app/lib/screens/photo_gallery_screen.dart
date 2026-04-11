import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/repository/memory_photo_repository.dart';
import '../models/memory_photo.dart';

class PhotoGalleryScreen extends StatefulWidget {
  const PhotoGalleryScreen({super.key});

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  final ImagePicker _picker = ImagePicker();
  List<MemoryPhoto> _photos = [];
  bool _isLoading = true;
  bool _isUploading = false;
  bool _showFavoritesOnly = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = context.read<MemoryPhotoRepository>();
      final photos = await repo.getPhotos();
      setState(() {
        _photos = photos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite(MemoryPhoto photo) async {
    try {
      final repo = context.read<MemoryPhotoRepository>();
      final newFavorite = await repo.toggleFavorite(photo.id);
      setState(() {
        final index = _photos.indexWhere((p) => p.id == photo.id);
        if (index != -1) {
          _photos[index] = MemoryPhoto(
            id: photo.id,
            userId: photo.userId,
            imageUrl: photo.imageUrl,
            caption: photo.caption,
            photoDate: photo.photoDate,
            isFavorite: newFavorite,
            createdAt: photo.createdAt,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.destructive),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      // Показать диалог для caption
      final caption = await _showCaptionDialog();

      final repo = context.read<MemoryPhotoRepository>();
      await repo.uploadPhoto(
        imageFile: File(image.path),
        caption: caption,
        photoDate: DateTime.now(),
      );

      setState(() => _isUploading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Фото загружено'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadPhotos();
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки: $e'),
            backgroundColor: AppColors.destructive,
          ),
        );
      }
    }
  }

  Future<String?> _showCaptionDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.citrusOrange.withOpacity(0.2)),
        ),
        title: const Text(
          'Добавить описание',
          style: TextStyle(color: AppColors.foreground),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.foreground),
          decoration: InputDecoration(
            hintText: 'Название момента (необязательно)',
            hintStyle: const TextStyle(color: AppColors.mutedForeground),
            filled: true,
            fillColor: AppColors.surface2,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: const Text('Пропустить', style: TextStyle(color: AppColors.mutedForeground)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: FilledButton.styleFrom(backgroundColor: AppColors.citrusOrange),
            child: const Text('Далее'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeletePhoto(MemoryPhoto photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.destructive.withOpacity(0.3)),
        ),
        title: const Text('Удалить момент?', style: TextStyle(color: AppColors.foreground)),
        content: Text(
          photo.caption ?? 'Момент от ${DateFormat('dd.MM.yyyy').format(photo.createdAt)}',
          style: const TextStyle(color: AppColors.mutedForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена', style: TextStyle(color: AppColors.mutedForeground)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.destructive),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repo = context.read<MemoryPhotoRepository>();
      await repo.deletePhoto(photo.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Момент удалён'), backgroundColor: Colors.green),
        );
        await _loadPhotos();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления: $e'), backgroundColor: AppColors.destructive),
        );
      }
    }
  }

  void _openPhotoDetail(MemoryPhoto photo) {
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
              // Изображение
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 350),
                decoration: const BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: CachedNetworkImage(
                    imageUrl: photo.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: AppColors.citrusOrange),
                    ),
                    errorWidget: (context, url, error) => Container(
                      padding: const EdgeInsets.all(32),
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 64, color: AppColors.mutedForeground),
                      ),
                    ),
                  ),
                ),
              ),
              // Информация
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
                    if (photo.caption != null && photo.caption!.isNotEmpty) ...[
                      Text(
                        photo.caption!,
                        style: const TextStyle(
                          color: AppColors.foreground,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      DateFormat('dd MMMM yyyy', 'ru_RU').format(photo.createdAt),
                      style: const TextStyle(color: AppColors.mutedForeground, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.surface2,
                              foregroundColor: AppColors.foreground,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Закрыть'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete, color: AppColors.destructive),
                          onPressed: () {
                            Navigator.pop(context);
                            _confirmDeletePhoto(photo);
                          },
                        ),
                      ],
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

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Добавить момент',
                style: TextStyle(
                  color: AppColors.foreground,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.citrusOrange),
              title: const Text('Выбрать из галереи', style: TextStyle(color: AppColors.foreground)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.citrusOrange),
              title: const Text('Сделать фото', style: TextStyle(color: AppColors.foreground)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedPhotos = _showFavoritesOnly
        ? _photos.where((p) => p.isFavorite).toList()
        : _photos;
    final favoriteCount = _photos.where((p) => p.isFavorite).length;

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
                // Заголовок
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Галерея моментов',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.foreground),
                    ),
                    Row(
                      children: [
                        // Фильтр избранное
                        GestureDetector(
                          onTap: () => setState(() => _showFavoritesOnly = !_showFavoritesOnly),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _showFavoritesOnly
                                  ? AppColors.citrusRed.withOpacity(0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _showFavoritesOnly
                                    ? AppColors.citrusRed.withOpacity(0.5)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Icon(
                              _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
                              color: _showFavoritesOnly
                                  ? AppColors.citrusRed
                                  : AppColors.mutedForeground,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Кнопка добавить
                        GestureDetector(
                          onTap: _isUploading ? null : _showUploadOptions,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [AppColors.citrusOrange, AppColors.citrusAmber]),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: _isUploading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.add, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Мотивационная карточка
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
                    'Дофамин\nКаждый счастливый момент заслуживает быть сохранённым.',
                    style: TextStyle(color: AppColors.foreground, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 12),
                // Счётчик
                Row(
                  children: [
                    const Icon(Icons.photo, color: AppColors.citrusOrange, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${_photos.length} моментов',
                      style: const TextStyle(color: AppColors.mutedForeground, fontSize: 13),
                    ),
                    if (favoriteCount > 0) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.favorite, color: AppColors.citrusRed, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '$favoriteCount избранных',
                        style: const TextStyle(color: AppColors.mutedForeground, fontSize: 13),
                      ),
                    ],
                    if (_showFavoritesOnly) ...[
                      const SizedBox(width: 12),
                      Text(
                        '(показаны избранные)',
                        style: const TextStyle(color: AppColors.citrusRed, fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                // Сетка фото
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.citrusOrange))
                      : _error != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline, size: 48, color: AppColors.destructive),
                                  const SizedBox(height: 8),
                                  Text(_error!, style: const TextStyle(color: AppColors.mutedForeground)),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _loadPhotos,
                                    child: const Text('Повторить'),
                                  ),
                                ],
                              ),
                            )
                          : _photos.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.photo_library, size: 64, color: AppColors.dimForeground),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Пока нет моментов',
                                        style: TextStyle(color: AppColors.mutedForeground),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Нажмите + чтобы добавить фото',
                                        style: TextStyle(color: AppColors.dimForeground, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                )
                              : GridView.builder(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 0.85,
                                  ),
                                  itemCount: displayedPhotos.length,
                                  itemBuilder: (context, index) {
                                    final photo = displayedPhotos[index];
                                    return GestureDetector(
                                      onTap: () => _openPhotoDetail(photo),
                                      onLongPress: () {
                                        HapticFeedback.mediumImpact();
                                        _confirmDeletePhoto(photo);
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.surface1,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: AppColors.subtleBorder),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Изображение
                                            Expanded(
                                              child: Stack(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                                    child: CachedNetworkImage(
                                                      imageUrl: photo.imageUrl,
                                                      width: double.infinity,
                                                      fit: BoxFit.cover,
                                                      placeholder: (context, url) => Container(
                                                        color: AppColors.surface2,
                                                        child: const Center(
                                                          child: CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: AppColors.citrusOrange,
                                                          ),
                                                        ),
                                                      ),
                                                      errorWidget: (context, url, error) => Container(
                                                        color: AppColors.surface2,
                                                        child: const Center(
                                                          child: Icon(
                                                            Icons.broken_image,
                                                            size: 48,
                                                            color: AppColors.mutedForeground,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  // Кнопка избранного
                                                  Positioned(
                                                    top: 8,
                                                    right: 8,
                                                    child: GestureDetector(
                                                      onTap: () => _toggleFavorite(photo),
                                                      child: Container(
                                                        width: 28,
                                                        height: 28,
                                                        decoration: BoxDecoration(
                                                          color: Colors.black.withOpacity(0.4),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: Icon(
                                                          photo.isFavorite ? Icons.favorite : Icons.favorite_border,
                                                          color: photo.isFavorite
                                                              ? AppColors.citrusRed
                                                              : AppColors.foreground,
                                                          size: 14,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Описание
                                            if (photo.caption != null && photo.caption!.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.all(8),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      photo.caption!,
                                                      style: const TextStyle(
                                                        color: AppColors.foreground,
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      DateFormat('dd.MM.yyyy').format(photo.createdAt),
                                                      style: const TextStyle(
                                                        color: AppColors.mutedForeground,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            else
                                              Padding(
                                                padding: const EdgeInsets.all(8),
                                                child: Text(
                                                  DateFormat('dd.MM.yyyy').format(photo.createdAt),
                                                  style: const TextStyle(
                                                    color: AppColors.mutedForeground,
                                                    fontSize: 11,
                                                  ),
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
                // Кнопка добавления
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.citrusOrange, AppColors.citrusAmber]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _showUploadOptions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: AppColors.background,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isUploading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background),
                            )
                          : const Text(
                              'Добавить момент',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
