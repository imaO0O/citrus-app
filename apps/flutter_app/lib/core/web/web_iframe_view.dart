// Условный импорт: на web подключается реализация с <iframe>,
// на мобильных платформах — заглушка (dart:html в Android/iOS не попадает).
export 'web_iframe_stub.dart' if (dart.library.html) 'web_iframe_web.dart';
