import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

final Set<String> _registeredViewTypes = <String>{};

/// Встраивает внешнюю страницу (VK / Rutube embed) через HTML <iframe> на вебе.
/// Используется вместо webview_flutter, у которого нет web-реализации.
Widget buildWebIframe(String url) {
  final viewType = 'citrus-iframe-${url.hashCode}';
  if (!_registeredViewTypes.contains(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final iframe = html.IFrameElement()
        ..src = url
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allowFullscreen = true;
      return iframe;
    });
    _registeredViewTypes.add(viewType);
  }
  return HtmlElementView(viewType: viewType);
}
