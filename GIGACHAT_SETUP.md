# Настройка GigaChat AI для чата

Этот документ описывает шаги для подключения GigaChat API к вашему чату в приложении Citrus.

## 1. Получение API ключа GigaChat

### Шаг 1: Регистрация в GigaChat Developers
1. Перейдите на [https://developers.sber.ru/gigachat](https://developers.sber.ru/gigachat)
2. Нажмите "Регистрация" и создайте аккаунт (или войдите через Сбер ID)

### Шаг 2: Создание проекта
1. После входа в личный кабинет, перейдите в раздел "Проекты"
2. Нажмите "Создать проект"
3. Заполните информацию о проекте (название, описание)
4. Выберите нужный вам API (GigaChat API)

### Шаг 3: Получение учетных данных
1. В настройках проекта найдите раздел "Учетные данные" или "Credentials"
2. Скопируйте:
   - **Client ID** (идентификатор клиента)
   - **Client Secret** (секрет клиента)

> **Важно:** Храните эти данные в секрете! Не коммитьте их в Git!

## 2. Настройка backend (dart_frog)

### Шаг 1: Установка переменных окружения

Создайте файл `.env` в директории `apps/dart_frog_backend/` со следующим содержимым:

```env
GIGACHAT_CLIENT_ID=ваш_client_id_сюда
GIGACHAT_CLIENT_SECRET=ваш_client_secret_сюда
```

Или установите переменные окружения в вашей ОС:

**Windows (PowerShell):**
```powershell
$env:GIGACHAT_CLIENT_ID="ваш_client_id"
$env:GIGACHAT_CLIENT_SECRET="ваш_client_secret"
```

**Linux/macOS:**
```bash
export GIGACHAT_CLIENT_ID="ваш_client_id"
export GIGACHAT_CLIENT_SECRET="ваш_client_secret"
```

### Шаг 2: Запуск backend

```bash
cd apps/dart_frog_backend
dart pub get
dart run server.dart
```

При успешной инициализации вы увидите в логах:
```
GigaChat service initialized!
```

## 3. Настройка Flutter клиента

### Шаг 1: Указание URL backend

Откройте файл `apps/flutter_app/lib/screens/chat_screen.dart` и найдите строку:

```dart
_chatApiClient = ChatApiClient(
  baseUrl: 'http://localhost:8080', // Измените на ваш адрес
  token: null, // TODO: Добавить токен авторизации, если требуется
);
```

Замените `http://localhost:8080` на актуальный URL вашего dart_frog_backend.

> **Примечание:** 
> - Для локальной разработки на Android эмуляторе используйте `http://10.0.2.2:8080`
> - Для iOS симулятора используйте `http://localhost:8080`
> - Для физического устройства используйте IP адрес вашего компьютера в локальной сети

### Шаг 2: Добавление токена авторизации (опционально)

Если ваш backend требует авторизацию, получите токен после логина и передайте его:

```dart
_chatApiClient = ChatApiClient(
  baseUrl: 'http://localhost:8080',
  token: 'ваш_jwt_token', // Получите после авторизации
);
```

## 4. Тестирование

### Проверка работы backend

Вы можете протестировать endpoint через curl или Postman:

```bash
curl -X POST http://localhost:8080/chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Привет! Как дела?",
    "temperature": 0.7,
    "max_tokens": 1024
  }'
```

Ожидаемый ответ:
```json
{
  "response": "Привет! Я Цитрус, твой AI-ассистент для ментального здоровья. Как я могу помочь тебе сегодня?",
  "timestamp": "2026-04-13T..."
}
```

### Проверка работы Flutter приложения

1. Запустите backend
2. Запустите Flutter приложение:
```bash
cd apps/flutter_app
flutter pub get
flutter run
```

3. Откройте экран чата
4. Отправьте сообщение
5. Вы должны получить ответ от GigaChat AI

## 5. Решение проблем

### Ошибка: "GigaChat service is not configured"

**Причина:** Не установлены переменные окружения `GIGACHAT_CLIENT_ID` и `GIGACHAT_CLIENT_SECRET`

**Решение:**
1. Проверьте, что переменные окружения установлены
2. Перезапустите backend
3. Проверьте логи - должно быть "GigaChat service initialized!"

### Ошибка: "Failed to get access token"

**Причина:** Неверные Client ID или Client Secret

**Решение:**
1. Проверьте правильность введенных учетных данных
2. Убедитесь, что проект активен в личном кабинете GigaChat
3. Проверьте, что у вас есть доступ к GigaChat API PERS

### Ошибка подключения во Flutter

**Причина:** Неправильный URL backend или backend не запущен

**Решение:**
1. Убедитесь, что dart_frog_backend запущен
2. Проверьте URL в `ChatApiClient`
3. Для Android эмулятора используйте `10.0.2.2` вместо `localhost`
4. Проверьте firewall и сетевые настройки

## 6. Дополнительные настройки

### Выбор модели

GigaChat API поддерживает несколько моделей:

| Модель | Значение | Описание |
|--------|----------|----------|
| **GigaChat** | `gigachat` | Базовая модель, оптимальна для большинства задач (по умолчанию) |
| **GigaChat Pro** | `giga_chat_pro` | Продвинутая модель для более сложных задач |
| **GigaChat Max** | `giga_chat_max` | Максимальная модель для самых сложных задач |

Для выбора модели в backend используйте параметр `model`:

```dart
// В server.dart можно добавить параметр model в запросе
final response = await _gigachatService!.chat(
  message,
  model: GigaChatModel.gigaChatPro, // или GigaChatModel.gigaChatMax
  temperature: temperature,
  maxTokens: maxTokens,
);
```

### Температура (temperature)

Параметр `temperature` контролирует креативность ответов AI:
- `0.0-0.3` - более точные и детерминированные ответы
- `0.5-0.7` - сбалансированные ответы (по умолчанию)
- `0.8-1.0` - более креативные и разнообразные ответы

### Максимальное количество токенов (max_tokens)

Параметр `max_tokens` контролирует максимальную длину ответа:
- `256-512` - короткие ответы
- `1024` - средние ответы (по умолчанию)
- `2048+` - длинные развернутые ответы

### System Prompt

Вы можете настроить personality AI через параметр `system_prompt`:

```dart
final response = await _chatApiClient.sendMessage(
  message: userMessage,
  systemPrompt: 'Твой собственный текст personality для AI',
);
```

## 7. Безопасность

⚠️ **ВАЖНО:**
- Никогда не коммитьте `.env` файлы с секретами в Git
- В production используйте безопасное хранение секретов
- Рассмотрите использование серверного прокси для дополнительной безопасности
- Регулярно обновляйте API ключи

## 8. Архитектура

```
┌─────────────┐         ┌──────────────────┐         ┌──────────────┐
│   Flutter   │  HTTP   │  dart_frog       │  HTTP   │   GigaChat   │
│   Client    │ ──────> │  Backend         │ ──────> │   API        │
│             │ <────── │  /chat endpoint  │ <────── │   (Сбер)     │
└─────────────┘         └──────────────────┘         └──────────────┘
```

Поток данных:
1. Пользователь отправляет сообщение во Flutter
2. Flutter отправляет POST запрос на `/chat` backend
3. Backend получает токен GigaChat (кэширует его)
4. Backend отправляет сообщение в GigaChat API
5. GigaChat возвращает ответ
6. Backend возвращает ответ Flutter клиенту
7. Flutter отображает ответ пользователю

## 9. Технические детали

### Формат запроса авторизации GigaChat

Наш сервис использует правильный формат запроса согласно официальной документации:

```bash
curl -L -X POST 'https://ngw.devices.sberbank.ru:9443/api/v2/oauth' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -H 'Accept: application/json' \
  -H 'RqUID: <uuid4>' \
  -H 'Authorization: Basic <base64(clientId:clientSecret)>' \
  --data-urlencode 'scope=GIGACHAT_API_PERS'
```

Где:
- **RqUID** — уникальный идентификатор запроса в формате UUID4 (генерируется автоматически)
- **Authorization** — ключ авторизации в формате Basic Auth (base64 от `clientId:clientSecret`)
- **scope** — версия API (`GIGACHAT_API_PERS` для физических лиц)

### Формат запроса чата

```bash
curl -X POST 'https://gigachat.devices.sberbank.ru/api/v1/chat/completions' \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer <access_token>' \
  -d '{
    "model": "GigaChat",
    "messages": [
      {"role": "system", "content": "Ты полезный ассистент"},
      {"role": "user", "content": "Привет!"}
    ],
    "temperature": 0.7,
    "max_tokens": 1024
  }'
```

## 10. Файлы проекта

### Backend:
- `apps/dart_frog_backend/lib/services/gigachat_service.dart` - сервис для работы с GigaChat API
- `apps/dart_frog_backend/server.dart` - endpoint `/chat`

### Frontend:
- `apps/flutter_app/lib/services/chat_api_client.dart` - HTTP клиент для общения с backend
- `apps/flutter_app/lib/screens/chat_screen.dart` - UI экрана чата

## Поддержка

При возникновении проблем:
1. Проверьте логи backend
2. Проверьте логи Flutter приложения
3. Убедитесь, что все зависимости установлены (`dart pub get` и `flutter pub get`)
4. Проверьте документацию GigaChat: https://developers.sber.ru/docs/ru/gigachat
