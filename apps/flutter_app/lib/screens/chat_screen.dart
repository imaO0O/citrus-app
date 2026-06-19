import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../services/chat_api_client.dart';
import '../services/analytics_loader.dart';
import '../services/diary_loader.dart';
import '../core/config/api_config.dart';
import '../core/repository/mood_repository.dart';
import '../core/repository/diary_repository.dart';
import '../core/repository/sleep_repository.dart';
import '../core/services/storage_service.dart';
import '../core/utils/app_size.dart';

class _Message {
  final String text;
  final bool isUser;
  final String time;

  _Message({required this.text, required this.isUser, required this.time});
}

const _suggestions = [
  '\u041A\u0430\u043A \u0443\u043B\u0443\u0447\u0448\u0438\u0442\u044C \u043D\u0430\u0441\u0442\u0440\u043E\u0435\u043D\u0438\u0435?',
  '\u041F\u043E\u043C\u043E\u0433\u0438 \u0441 \u0442\u0440\u0435\u0432\u043E\u0433\u043E\u0439',
  '\u0414\u0430\u0439 \u0441\u043E\u0432\u0435\u0442 \u043D\u0430 \u0441\u0435\u0433\u043E\u0434\u043D\u044F',
  '\u0420\u0430\u0441\u0441\u043A\u0430\u0436\u0438 \u043E \u0434\u044B\u0445\u0430\u043D\u0438\u0438',
];

class ChatScreen extends StatefulWidget {
  ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  final List<_Message> _messages = [];
  bool _isTyping = false;
  bool _isLoadingAnalytics = false;
  bool _isLoadingDiary = false;

  // API клиент для общения с backend
  // TODO: Заменить URL на актуальный адрес вашего dart_frog_backend
  late final ChatApiClient _chatApiClient;

  @override
  void initState() {
    super.initState();
    // Инициализация API клиента с токеном
    _initChatApiClient();
  }

  /// Инициализировать ChatApiClient с токеном авторизации
  Future<void> _initChatApiClient() async {
    final storage = StorageService();
    final token = await storage.getString('auth_token');
    
    _chatApiClient = ChatApiClient(
      baseUrl: ApiConfig.baseUrl,
      token: token,
    );
  }

  Future<void> _loadAnalytics() async {
    if (_isLoadingAnalytics) return;

    setState(() {
      _isLoadingAnalytics = true;
    });

    try {
      final moodRepo = context.read<MoodRepository>();
      final sleepRepo = context.read<SleepRepository>();
      final analyticsLoader = AnalyticsLoaderService(
        moodRepo: moodRepo,
        sleepRepo: sleepRepo,
      );

      // Получаем токен из хранилища
      final storage = StorageService();
      final token = await storage.getString('auth_token') ?? '';

      // Загружаем аналитику за последние 30 дней
      final analyticsText = await analyticsLoader.loadAndFormatAnalytics(
        token: token,
        userId: moodRepo.userId,
        startDate: DateTime.now().subtract(Duration(days: 30)),
      );

      if (!mounted) return;

      // Отправляем аналитику в чат
      await _sendMessage(text: analyticsText);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки аналитики: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAnalytics = false;
        });
      }
    }
  }

  Future<void> _showDiarySelectionDialog() async {
    if (_isLoadingDiary) return;

    setState(() {
      _isLoadingDiary = true;
    });

    try {
      final diaryRepo = context.read<DiaryRepository>();
      final diaryLoader = DiaryLoaderService(diaryRepo: diaryRepo);

      // Загружаем записи за последние 30 дней
      final entries = await diaryLoader.loadDiaryEntries(
        startDate: DateTime.now().subtract(Duration(days: 30)),
      );

      if (!mounted) return;

      if (entries.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Нет записей дневника за последний месяц'),
            backgroundColor: AppColors.citrusOrange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Показываем диалог выбора записей
      final selectedEntries = await showDialog<List<DiaryEntry>>(
        context: context,
        builder: (context) => _DiarySelectionDialog(entries: entries),
      );

      if (selectedEntries != null && selectedEntries.isNotEmpty && mounted) {
        final formattedText = diaryLoader.formatSelectedEntries(selectedEntries);
        await _sendMessage(text: formattedText);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки дневника: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDiary = false;
        });
      }
    }
  }

  Future<void> _sendMessage({String? text}) async {
    final msgText = (text ?? _controller.text).trim();
    if (msgText.isEmpty) return;

    setState(() {
      final now = DateTime.now();
      final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      _messages.add(_Message(text: msgText, isUser: true, time: time));
      _controller.clear();
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      // Получаем ответ от GigaChat через backend
      final aiResponse = await _chatApiClient.sendMessage(
        message: msgText,
        systemPrompt: 'Ты полезный ассистент по имени Цитрус. Ты помогаешь пользователям следить за своим ментальным здоровьем, даёшь советы по улучшению настроения, борьбе с тревогой и поддержанию хорошего эмоционального состояния. Отвечай дружелюбно и поддерживающе.',
      );

      if (!mounted) return;

      setState(() {
        final now = DateTime.now();
        final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        _messages.add(_Message(text: aiResponse, isUser: false, time: time));
        _isTyping = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        final now = DateTime.now();
        final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        _messages.add(
          _Message(
            text: 'Извините, произошла ошибка при получении ответа от AI. Попробуйте ещё раз.',
            isUser: false,
            time: time,
          ),
        );
        _isTyping = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasMessages = _messages.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isTyping) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: AppSize.paddingOnly(top: 8),
                            child: _TypingIndicator(),
                          ),
                        );
                      }
                      final msg = _messages[index];
                      return _buildMessageBubble(msg);
                    },
                  ),
                ),
                if (!hasMessages) _buildSuggestions(),
                _buildInputField(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: AppSize.padding(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.surface2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.citrusOrange, AppColors.citrusAmber],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.citrusOrange.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(child: Text('\u{1F34A}', style: TextStyle(fontSize: AppSize.s(20)))),
          ),
          AppSize.gapW(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\u0418\u0418-\u0410\u0441\u0441\u0438\u0441\u0442\u0435\u043D\u0442 \u0426\u0438\u0442\u0440\u0443\u0441',
                  style: TextStyle(
                    color: AppColors.foreground,
                    fontWeight: FontWeight.w600,
                    fontSize: AppSize.s(15),
                  ),
                ),
                AppSize.gapH(2),
                Row(
                  children: [
                    _PulsingDot(),
                    AppSize.gapW(6),
                    Text(
                      '\u0412\u0441\u0435\u0433\u0434\u0430 \u043E\u043D\u043B\u0430\u0439\u043D',
                      style: TextStyle(color: Color(0xFF4ADE80), fontSize: AppSize.s(12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.auto_awesome, color: AppColors.citrusAmber, size: 20),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_Message msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: AppSize.paddingOnly(top: 8),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: () {
            Clipboard.setData(ClipboardData(text: msg.text));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Сообщение скопировано'),
                duration: Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.citrusOrange,
              ),
            );
          },
          child: Container(
            constraints: BoxConstraints(maxWidth: 280),
            padding: AppSize.padding(12),
            decoration: BoxDecoration(
              gradient: isUser
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.citrusOrange, AppColors.citrusAmber],
                    )
                  : null,
              color: isUser ? null : AppColors.surface1,
              borderRadius: AppSize.radius(16),
              border: isUser ? null : Border.all(color: Colors.white.withValues(alpha: 0.06)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isUser)
                      Padding(
                        padding: AppSize.paddingOnly(right: 4),
                        child: Text('\u{1F34A}', style: TextStyle(fontSize: AppSize.s(16))),
                      ),
                    if (!isUser)
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: msg.text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Сообщение скопировано'),
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppColors.citrusOrange,
                            ),
                          );
                        },
                        child: Icon(
                          Icons.copy_rounded,
                          size: 14,
                          color: (isUser ? Colors.white : AppColors.mutedForeground).withValues(alpha: 0.5),
                        ),
                      ),
                    Spacer(),
                    Text(
                      msg.time,
                      style: TextStyle(
                        color: (isUser ? Colors.white : AppColors.mutedForeground).withValues(alpha: 0.5),
                        fontSize: AppSize.s(10),
                      ),
                    ),
                  ],
                ),
                AppSize.gapH(4),
                isUser
                    ? Text(
                        msg.text,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: AppSize.s(14),
                          height: 1.5,
                        ),
                      )
                    : MarkdownBody(
                        data: msg.text,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(
                            color: AppColors.foreground,
                            fontSize: AppSize.s(14),
                            height: 1.5,
                          ),
                          strong: TextStyle(
                            color: AppColors.foreground,
                            fontWeight: FontWeight.bold,
                            fontSize: AppSize.s(14),
                          ),
                          em: TextStyle(
                            color: AppColors.foreground,
                            fontStyle: FontStyle.italic,
                            fontSize: AppSize.s(14),
                          ),
                          listBullet: TextStyle(
                            color: AppColors.foreground,
                            fontSize: AppSize.s(14),
                          ),
                          blockquote: TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: AppSize.s(13),
                            fontStyle: FontStyle.italic,
                          ),
                          code: TextStyle(
                            color: AppColors.citrusAmber,
                            fontSize: AppSize.s(13),
                            fontFamily: 'monospace',
                          ),
                          h1: TextStyle(
                            color: AppColors.foreground,
                            fontWeight: FontWeight.bold,
                            fontSize: AppSize.s(18),
                          ),
                          h2: TextStyle(
                            color: AppColors.foreground,
                            fontWeight: FontWeight.bold,
                            fontSize: AppSize.s(16),
                          ),
                          h3: TextStyle(
                            color: AppColors.foreground,
                            fontWeight: FontWeight.bold,
                            fontSize: AppSize.s(15),
                          ),
                        ),
                        selectable: true,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _suggestions.map((hint) {
          return GestureDetector(
            onTap: () => _sendMessage(text: hint),
            child: Container(
              padding: AppSize.paddingH(14, 8),
              decoration: BoxDecoration(
                color: AppColors.citrusOrange.withValues(alpha: 0.1),
                borderRadius: AppSize.radius(999),
                border: Border.all(color: AppColors.citrusOrange.withValues(alpha: 0.2)),
              ),
              child: Text(
                hint,
                style: TextStyle(color: AppColors.citrusOrange, fontSize: AppSize.s(12)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputField() {
    final hasText = _controller.text.trim().isNotEmpty;

    return Container(
      padding: AppSize.padding(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.surface2)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: TextStyle(color: AppColors.foreground),
                  maxLines: 4,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: '\u0412\u0432\u0435\u0434\u0438\u0442\u0435 \u0441\u043E\u043E\u0431\u0449\u0435\u043D\u0438\u0435...',
                    hintStyle: TextStyle(color: AppColors.mutedForeground.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.04),
                    border: OutlineInputBorder(
                      borderRadius: AppSize.radius(16),
                      borderSide: BorderSide(color: AppColors.surface3),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppSize.radius(16),
                      borderSide: BorderSide(color: AppColors.surface3),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppSize.radius(16),
                      borderSide: BorderSide(color: AppColors.citrusOrange, width: 1.5),
                    ),
                    contentPadding: AppSize.paddingH(16, 12),
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              AppSize.gapW(8),
              GestureDetector(
                onTap: hasText ? _sendMessage : null,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: hasText
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.citrusOrange, AppColors.citrusAmber],
                          )
                        : null,
                    color: hasText ? null : Colors.white.withValues(alpha: 0.06),
                    borderRadius: AppSize.radius(12),
                    boxShadow: hasText
                        ? [
                            BoxShadow(
                              color: AppColors.citrusOrange.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    color: hasText ? Colors.white : AppColors.mutedForeground,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          AppSize.gapH(8),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildAnalyticsButton(),
                AppSize.gapW(8),
                _buildDiaryButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsButton() {
    return GestureDetector(
      onTap: _isLoadingAnalytics ? null : _loadAnalytics,
      child: Container(
        padding: AppSize.paddingH(12, 8),
        decoration: BoxDecoration(
          color: AppColors.citrusPurple.withValues(alpha: _isLoadingAnalytics ? 0.05 : 0.1),
          borderRadius: AppSize.radius(999),
          border: Border.all(color: AppColors.citrusPurple.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoadingAnalytics)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.citrusPurple),
                ),
              )
            else
              Icon(Icons.analytics_outlined, color: AppColors.citrusPurple, size: 14),
            AppSize.gapW(6),
            Text(
              _isLoadingAnalytics ? 'Загрузка...' : 'Аналитика',
              style: TextStyle(color: AppColors.citrusPurple, fontSize: AppSize.s(12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiaryButton() {
    return GestureDetector(
      onTap: _isLoadingDiary ? null : _showDiarySelectionDialog,
      child: Container(
        padding: AppSize.paddingH(12, 8),
        decoration: BoxDecoration(
          color: AppColors.citrusAmber.withValues(alpha: _isLoadingDiary ? 0.05 : 0.1),
          borderRadius: AppSize.radius(999),
          border: Border.all(color: AppColors.citrusAmber.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoadingDiary)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.citrusAmber),
                ),
              )
            else
              Icon(Icons.menu_book_rounded, color: AppColors.citrusAmber, size: 14),
            AppSize.gapW(6),
            Text(
              _isLoadingDiary ? 'Загрузка...' : 'Дневник',
              style: TextStyle(color: AppColors.citrusAmber, fontSize: AppSize.s(12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: AppSize.padding(12),
          decoration: BoxDecoration(
            color: AppColors.surface1,
            borderRadius: AppSize.radius(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('\u{1F34A}', style: TextStyle(fontSize: AppSize.s(16))),
              AppSize.gapW(8),
              for (int i = 0; i < 3; i++) ...[
                Transform.scale(
                  scale: 0.6 + 0.4 * ((0.5 + 0.5 * math.sin((_controller.value * 2 * math.pi + i * 0.8)))).clamp(0.0, 1.0),
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppColors.citrusOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                if (i < 2) AppSize.gapW(4),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PulsingDot extends StatefulWidget {
  _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: Color(0xFF4ADE80),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

class _DiarySelectionDialog extends StatefulWidget {
  final List<DiaryEntry> entries;

  _DiarySelectionDialog({required this.entries});

  @override
  State<_DiarySelectionDialog> createState() => _DiarySelectionDialogState();
}

class _DiarySelectionDialogState extends State<_DiarySelectionDialog> {
  final Set<String> _selectedIds = {};

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedIds.length == widget.entries.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(widget.entries.map((e) => e.id));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final moodEmojis = ['😄', '🙂', '😐', '😟', '😢', '😞'];

    return Dialog(
      backgroundColor: AppColors.surface1,
      shape: RoundedRectangleBorder(borderRadius: AppSize.radius(16)),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxWidth: 400, maxHeight: 500),
        padding: AppSize.padding(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Выберите записи',
                    style: TextStyle(
                      fontSize: AppSize.s(18),
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: _selectAll,
                      child: Text(
                        _selectedIds.length == widget.entries.length ? 'Снять все' : 'Выбрать все',
                        style: TextStyle(color: AppColors.citrusOrange, fontSize: AppSize.s(12)),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                      color: AppColors.mutedForeground,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            AppSize.gapH(8),
            Text(
              '${_selectedIds.length} из ${widget.entries.length} записей выбрано',
              style: TextStyle(color: AppColors.mutedForeground, fontSize: AppSize.s(12)),
            ),
            AppSize.gapH(12),
            Expanded(
              child: ListView.separated(
                itemCount: widget.entries.length,
                separatorBuilder: (context, index) => AppSize.gapH(8),
                itemBuilder: (context, index) {
                  final entry = widget.entries[index];
                  final isSelected = _selectedIds.contains(entry.id);
                  final dateStr = DateFormat('dd.MM.yyyy').format(entry.entryDate);

                  return GestureDetector(
                    onTap: () => _toggleSelection(entry.id),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      padding: AppSize.padding(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.citrusOrange.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.04),
                        borderRadius: AppSize.radius(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.citrusOrange
                              : Colors.white.withValues(alpha: 0.06),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle : Icons.circle_outlined,
                            color: isSelected ? AppColors.citrusOrange : AppColors.mutedForeground,
                            size: 20,
                          ),
                          AppSize.gapW(8),
                          if (entry.moodValue != null)
                            Text(moodEmojis[entry.moodValue!.clamp(0, 5)], style: TextStyle(fontSize: AppSize.s(18))),
                          if (entry.moodValue != null) AppSize.gapW(8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    fontSize: AppSize.s(11),
                                    color: AppColors.mutedForeground,
                                  ),
                                ),
                                AppSize.gapH(2),
                                Text(
                                  entry.content.length > 50
                                      ? '${entry.content.substring(0, 50)}...'
                                      : entry.content,
                                  style: TextStyle(
                                    fontSize: AppSize.s(13),
                                    color: AppColors.foreground,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
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
            AppSize.gapH(12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selectedIds.isEmpty
                    ? null
                    : () {
                        final selected = widget.entries
                            .where((e) => _selectedIds.contains(e.id))
                            .toList();
                        Navigator.pop(context, selected);
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.citrusOrange,
                  padding: AppSize.paddingH(0, 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppSize.radius(12),
                  ),
                ),
                child: Text(
                  'Отправить ${_selectedIds.length} ${_selectedIds.length == 1 ? 'запись' : 'записей'} в чат',
                  style: TextStyle(fontSize: AppSize.s(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
