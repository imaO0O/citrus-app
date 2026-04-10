import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class _Message {
  final String text;
  final bool isUser;
  final String time;

  const _Message({required this.text, required this.isUser, required this.time});
}

const _suggestions = [
  '\u041A\u0430\u043A \u0443\u043B\u0443\u0447\u0448\u0438\u0442\u044C \u043D\u0430\u0441\u0442\u0440\u043E\u0435\u043D\u0438\u0435?',
  '\u041F\u043E\u043C\u043E\u0433\u0438 \u0441 \u0442\u0440\u0435\u0432\u043E\u0433\u043E\u0439',
  '\u0414\u0430\u0439 \u0441\u043E\u0432\u0435\u0442 \u043D\u0430 \u0441\u0435\u0433\u043E\u0434\u043D\u044F',
  '\u0420\u0430\u0441\u0441\u043A\u0430\u0436\u0438 \u043E \u0434\u044B\u0445\u0430\u043D\u0438\u0438',
];

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  final List<_Message> _messages = [];
  bool _isTyping = false;
  bool _diaryAttached = false;

  void _sendMessage({String? text}) {
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

    Timer(const Duration(seconds: 1, milliseconds: 500), () {
      if (!mounted) return;
      final responses = [
        '\u0421\u043F\u0430\u0441\u0438\u0431\u043E \u0437\u0430 \u0434\u043E\u0432\u0435\u0440\u0438\u0435. \u042F \u0437\u0434\u0435\u0441\u044C, \u0447\u0442\u043E\u0431\u044B \u043F\u043E\u043C\u043E\u0447\u044C \u0442\u0435\u0431\u0435. \u0414\u0430\u0432\u0430\u0439 \u0440\u0430\u0437\u0431\u0435\u0440\u0451\u043C\u0441\u044F \u0432\u043C\u0435\u0441\u0442\u0435.',
        '\u042F \u043F\u043E\u043D\u0438\u043C\u0430\u044E \u0442\u0432\u043E\u0438 \u0447\u0443\u0432\u0441\u0442\u0432\u0430. \u041F\u043E\u043F\u0440\u043E\u0431\u0443\u0439 \u0441\u0434\u0435\u043B\u0430\u0442\u044C \u0433\u043B\u0443\u0431\u043E\u043A\u0438\u0439 \u0432\u0434\u043E\u0445 \u0438 \u0432\u044B\u0434\u043E\u0445. \u0422\u044B \u0441\u043F\u0440\u0430\u0432\u043B\u044F\u0435\u0448\u044C\u0441\u044F!',
        '\u042D\u0442\u043E \u043E\u0447\u0435\u043D\u044C \u0432\u0430\u0436\u043D\u043E \u2014 \u043E\u0442\u0441\u043B\u0435\u0436\u0438\u0432\u0430\u0442\u044C \u0441\u0432\u043E\u0451 \u0441\u043E\u0441\u0442\u043E\u044F\u043D\u0438\u0435. \u041F\u0440\u043E\u0434\u043E\u043B\u0436\u0430\u0439 \u0432 \u0442\u043E\u043C \u0436\u0435 \u0434\u0443\u0445\u0435! \uD83D\uDFE0',
        '\u0414\u044B\u0445\u0430\u0442\u0435\u043B\u044C\u043D\u044B\u0435 \u0443\u043F\u0440\u0430\u0436\u043D\u0435\u043D\u0438\u044F \u2014 \u043E\u0442\u043B\u0438\u0447\u043D\u044B\u0439 \u0441\u043F\u043E\u0441\u043E\u0431 \u0441\u043D\u044F\u0442\u044C \u043D\u0430\u043F\u0440\u044F\u0436\u0435\u043D\u0438\u0435. \u041F\u043E\u043F\u0440\u043E\u0431\u0443\u0439 \u0442\u0435\u0445\u043D\u0438\u043A\u0443 4-4-4: \u0432\u0434\u043E\u0445 4\u0441, \u0437\u0430\u0434\u0435\u0440\u0436\u043A\u0430 4\u0441, \u0432\u044B\u0434\u043E\u0445 4\u0441.',
        '\u041E\u0442\u043B\u0438\u0447\u043D\u044B\u0439 \u0432\u043E\u043F\u0440\u043E\u0441! \u041D\u0430\u0447\u043D\u0438 \u0441 \u043D\u0435\u0431\u043E\u043B\u044C\u0448\u043E\u0433\u043E: \u0437\u0430\u043F\u0438\u0448\u0438 \u0442\u0440\u0438 \u0432\u0435\u0449\u0438, \u0437\u0430 \u043A\u043E\u0442\u043E\u0440\u044B\u0435 \u0442\u044B \u0431\u043B\u0430\u0433\u043E\u0434\u0430\u0440\u0435\u043D \u0441\u0435\u0433\u043E\u0434\u043D\u044F.',
      ];
      setState(() {
        final now = DateTime.now();
        final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        _messages.add(
          _Message(
            text: responses[_messages.length % responses.length],
            isUser: false,
            time: time,
          ),
        );
        _isTyping = false;
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
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
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isTyping) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.surface2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.citrusOrange, AppColors.citrusAmber],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.citrusOrange.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(child: Text('\u{1F34A}', style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '\u0418\u0418-\u0410\u0441\u0441\u0438\u0441\u0442\u0435\u043D\u0442 \u0426\u0438\u0442\u0440\u0443\u0441',
                  style: TextStyle(
                    color: AppColors.foreground,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _PulsingDot(),
                    const SizedBox(width: 6),
                    const Text(
                      '\u0412\u0441\u0435\u0433\u0434\u0430 \u043E\u043D\u043B\u0430\u0439\u043D',
                      style: TextStyle(color: Color(0xFF4ADE80), fontSize: 12),
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
      padding: const EdgeInsets.only(top: 8),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 280),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: isUser
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.citrusOrange, AppColors.citrusAmber],
                  )
                : null,
            color: isUser ? null : AppColors.surface1,
            borderRadius: BorderRadius.circular(16),
            border: isUser ? null : Border.all(color: Colors.white.withOpacity(0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isUser)
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text('\u{1F34A}', style: TextStyle(fontSize: 16)),
                ),
              Text(
                msg.text,
                style: TextStyle(
                  color: isUser ? Colors.white : AppColors.foreground,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                msg.time,
                style: TextStyle(
                  color: (isUser ? Colors.white : AppColors.mutedForeground).withOpacity(0.5),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions.map((hint) {
              return GestureDetector(
                onTap: () => _sendMessage(text: hint),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.citrusOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.citrusOrange.withOpacity(0.2)),
                  ),
                  child: Text(
                    hint,
                    style: const TextStyle(color: AppColors.citrusOrange, fontSize: 12),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              setState(() => _diaryAttached = true);
              _sendMessage(text: '\u0417\u0430\u0433\u0440\u0443\u0436\u0430\u044E \u0434\u043D\u0435\u0432\u043D\u0438\u043A \u0434\u043B\u044F \u0430\u043D\u0430\u043B\u0438\u0437\u0430');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.citrusPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.citrusPurple.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.upload_file, color: AppColors.citrusPurple, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    '\u0417\u0430\u0433\u0440\u0443\u0437\u0438\u0442\u044C \u0434\u043D\u0435\u0432\u043D\u0438\u043A \u0434\u043B\u044F \u0430\u043D\u0430\u043B\u0438\u0437\u0430',
                    style: TextStyle(color: AppColors.citrusPurple, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    final hasText = _controller.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.surface2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: const TextStyle(color: AppColors.foreground),
              maxLines: 4,
              minLines: 1,
              decoration: InputDecoration(
                hintText: '\u0412\u0432\u0435\u0434\u0438\u0442\u0435 \u0441\u043E\u043E\u0431\u0449\u0435\u043D\u0438\u0435...',
                hintStyle: TextStyle(color: AppColors.mutedForeground.withOpacity(0.5)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.surface3),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.surface3),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.citrusOrange, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: hasText ? _sendMessage : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: hasText
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.citrusOrange, AppColors.citrusAmber],
                      )
                    : null,
                color: hasText ? null : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                boxShadow: hasText
                    ? [
                        BoxShadow(
                          color: AppColors.citrusOrange.withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
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
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

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
      duration: const Duration(milliseconds: 600),
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface1,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('\u{1F34A}', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
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
                if (i < 2) const SizedBox(width: 4),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

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
      duration: const Duration(milliseconds: 1200),
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
            decoration: const BoxDecoration(
              color: Color(0xFF4ADE80),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
