import 'package:flutter/widgets.dart';

/// Адаптивные размеры приложения.
///
/// Единый масштаб по ШИРИНЕ экрана (база 390pt — iPhone 14), мягко ограниченный
/// диапазоном, чтобы вёрстка не раздувалась на десктопе/планшете и не сжималась
/// на телефоне в браузере. Высоту обрабатывает прокрутка экранов, а не масштаб —
/// поэтому `s()`, `w()`, `h()` используют ОДИН и тот же коэффициент (без перекосов
/// по осям, которые раньше ломали раскладку на нестандартных экранах).
///
/// Логика одинакова для web и Android.
class AppSize {
  static const double _baseWidth = 390;

  /// Максимальная «расчётная» ширина контента. На более широких экранах
  /// (десктоп, планшет) приложение показывается колонкой по центру — см. обёртку
  /// в `main.dart`. Это же значение используется и для центрирующего ConstrainedBox.
  static const double maxContentWidth = 480;

  /// Единый множитель для всех размеров (s/w/h).
  static double scale = 1.0;

  /// Системный масштаб текста, ограниченный, чтобы крупный шрифт не ломал вёрстку.
  static double textScale = 1.0;

  /// Размер окна и безопасные отступы (вырезы/чёлка) — на случай ручной адаптации.
  static Size screen = Size.zero;
  static EdgeInsets safe = EdgeInsets.zero;

  // Обратная совместимость: исторически были отдельные scaleW/scaleH.
  // Теперь они равны единому scale (без искажений по осям).
  static double get scaleW => scale;
  static double get scaleH => scale;

  /// Вызывать один раз при запуске приложения (в builder MaterialApp).
  static void init(BuildContext context) {
    final mq = MediaQuery.of(context);
    screen = mq.size;
    safe = mq.padding;
    // Ширину для расчёта масштаба ограничиваем сверху телефонной (maxContentWidth):
    // на широких экранах приложение всё равно колонка по центру.
    final contentWidth = screen.width.clamp(320.0, maxContentWidth).toDouble();
    // Единый масштаб по ширине, мягко зажатый — без раздувания и сжатия.
    scale = (contentWidth / _baseWidth).clamp(0.80, 1.30).toDouble();
    // Уважаем системный масштаб текста, но не даём ему сломать вёрстку.
    textScale = mq.textScaler.scale(1.0).clamp(0.9, 1.3).toDouble();
  }

  /// Масштабировать размер (ширина/высота/padding/fontSize/borderRadius).
  static double s(double value) => value * scale;

  /// Сохранены для совместимости — используют тот же единый масштаб, что и [s].
  static double w(double value) => value * scale;
  static double h(double value) => value * scale;

  /// EdgeInsets с масштабированием.
  static EdgeInsets padding(double all) => EdgeInsets.all(s(all));
  static EdgeInsets paddingH(double horizontal, double vertical) =>
      EdgeInsets.symmetric(horizontal: s(horizontal), vertical: s(vertical));
  static EdgeInsets paddingOnly({
    double left = 0, double top = 0, double right = 0, double bottom = 0,
  }) => EdgeInsets.only(
    left: s(left), top: s(top), right: s(right), bottom: s(bottom),
  );

  /// SizedBox с масштабированием.
  static SizedBox gap(double size) => SizedBox(width: s(size), height: s(size));
  static SizedBox gapW(double width) => SizedBox(width: s(width));
  static SizedBox gapH(double height) => SizedBox(height: s(height));

  /// BorderRadius с масштабированием.
  static BorderRadius radius(double r) => BorderRadius.circular(s(r));
}
