import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Локальные пользовательские настройки статей: избранное, отметка «прочитано»,
/// размер шрифта читалки. Хранится на устройстве (без бэкенда).
class ArticlePrefsService {
  static const _storage = FlutterSecureStorage();
  static const _kFav = 'article_favorites';
  static const _kRead = 'article_read';
  static const _kFont = 'article_font_scale';

  Future<Set<String>> _getSet(String key) async {
    final raw = await _storage.read(key: key);
    if (raw == null || raw.isEmpty) return <String>{};
    return raw.split(',').where((e) => e.isNotEmpty).toSet();
  }

  Future<void> _saveSet(String key, Set<String> set) =>
      _storage.write(key: key, value: set.join(','));

  Future<Set<String>> getFavorites() => _getSet(_kFav);

  Future<Set<String>> getRead() => _getSet(_kRead);

  /// Переключает избранное, возвращает новое состояние (true = в избранном).
  Future<bool> toggleFavorite(String id) async {
    final set = await getFavorites();
    final nowFav = !set.contains(id);
    if (nowFav) {
      set.add(id);
    } else {
      set.remove(id);
    }
    await _saveSet(_kFav, set);
    return nowFav;
  }

  Future<void> markRead(String id) async {
    final set = await getRead();
    if (set.add(id)) await _saveSet(_kRead, set);
  }

  Future<double> getFontScale() async {
    final raw = await _storage.read(key: _kFont);
    final v = double.tryParse(raw ?? '') ?? 1.0;
    return v.clamp(0.85, 1.6);
  }

  Future<void> setFontScale(double v) =>
      _storage.write(key: _kFont, value: v.toStringAsFixed(2));
}
