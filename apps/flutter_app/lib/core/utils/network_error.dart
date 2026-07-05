/// Преобразует технические сетевые ошибки в понятные пользователю сообщения.
///
/// Работает на всех платформах (web/Android/iOS): тип ошибки определяется
/// по тексту, потому что, например, SocketException недоступен на web,
/// а браузер кидает «Failed to fetch».
String friendlyError(Object error, {String fallback = 'Произошла ошибка. Попробуйте ещё раз.'}) {
  final text = error.toString();
  if (text.contains('SocketException') ||
      text.contains('ClientException') ||
      text.contains('Failed to fetch') ||
      text.contains('Connection refused') ||
      text.contains('Connection reset') ||
      text.contains('Network is unreachable') ||
      text.contains('Connection timed out') ||
      text.contains('TimeoutException')) {
    return 'Нет соединения с сервером. Проверьте интернет и попробуйте ещё раз.';
  }
  if (text.contains('401') || text.contains('Unauthorized')) {
    return 'Сессия истекла. Войдите в аккаунт заново.';
  }
  if (text.contains('500') || text.contains('502') || text.contains('503')) {
    return 'Сервер временно недоступен. Попробуйте позже.';
  }
  return fallback;
}
