import 'package:flutter/widgets.dart';

/// Заглушка для мобильных платформ (Android/iOS).
/// На вебе вместо неё подключается [web_iframe_web.dart] с реальным <iframe>.
/// На мобильных видео показывается через webview_flutter, поэтому сюда
/// исполнение не доходит.
Widget buildWebIframe(String url) => const SizedBox.shrink();
