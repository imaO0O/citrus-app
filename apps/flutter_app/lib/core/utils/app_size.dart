import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';

/// Адаптивные размеры — масштабирование относительно базового экрана (390pt — iPhone 14)
class AppSize {
  static const double _baseWidth = 390;
  static const double _baseHeight = 844;

  static late double scaleW;
  static late double scaleH;
  static late double scale; // min(scaleW, scaleH) — безопасный масштаб

  /// Вызывать один раз при запуске приложения (в builder MaterialApp или в первом экране)
  static void init(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (kIsWeb) {
      // На web вьюпорт переменный: на телефоне высоту «съедает» адресная строка,
      // на десктопе окно намного шире телефона. Поэтому используем единый масштаб
      // по ширине, ограниченной телефонной (_baseWidth), — это убирает раздувание
      // горизонтальных отступов на ПК и сжатие по высоте на телефоне.
      final effectiveWidth = size.width < _baseWidth ? size.width : _baseWidth;
      final webScale = effectiveWidth / _baseWidth;
      scaleW = webScale;
      scaleH = webScale;
      scale = webScale;
      return;
    }
    scaleW = size.width / _baseWidth;
    scaleH = size.height / _baseHeight;
    scale = scaleW < scaleH ? scaleW : scaleH;
  }

  /// Масштабировать размер (ширина/высота/padding/fontSize/borderRadius)
  /// Используется для большинства размеров
  static double s(double value) => value * scale;

  /// Масштабировать по ширине (для горизонтальных отступов, ширин виджетов)
  static double w(double value) => value * scaleW;

  /// Масштабировать по высоте (для вертикальных отступов, высот виджетов)
  static double h(double value) => value * scaleH;

  /// EdgeInsets с масштабированием
  static EdgeInsets padding(double all) => EdgeInsets.all(s(all));
  static EdgeInsets paddingH(double horizontal, double vertical) =>
      EdgeInsets.symmetric(horizontal: w(horizontal), vertical: h(vertical));
  static EdgeInsets paddingOnly({
    double left = 0, double top = 0, double right = 0, double bottom = 0,
  }) => EdgeInsets.only(
    left: w(left), top: h(top), right: w(right), bottom: h(bottom),
  );

  /// SizedBox с масштабированием
  static SizedBox gap(double size) => SizedBox(width: s(size), height: s(size));
  static SizedBox gapW(double width) => SizedBox(width: w(width));
  static SizedBox gapH(double height) => SizedBox(height: h(height));

  /// BorderRadius с масштабированием
  static BorderRadius radius(double r) => BorderRadius.circular(s(r));
}
