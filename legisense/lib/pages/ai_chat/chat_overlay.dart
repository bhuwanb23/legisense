import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../api/parsed_documents_repository.dart';

class ChatOverlay extends StatefulWidget {
  const ChatOverlay({super.key});

  @override
  State<ChatOverlay> createState() => _ChatOverlayState();
}

class _ChatOverlayState extends State<ChatOverlay> with TickerProviderStateMixin {
  bool _isOpen = false;
  final List<_ChatMessage> _messages = <_ChatMessage>[
    const _ChatMessage(
      role: _ChatRole.assistant,
      text:
          'I am Legisense AI. I specialize in legal documents, compliance, and jurisdiction-related questions. I will answer clearly and honestly, and I will note when laws can vary by jurisdiction. How can I help you today?',
    ),
  ];
  final TextEditingController _textController = TextEditingController();
  late final AnimationController _panelController;
  late final Animation<double> _panelScale;
  AnimationController? _pulseController;
  Animation<double> _pulse = const AlwaysStoppedAnimation<double>(0);
  bool _hasUnread = false;
  bool _isSending = false;
  Animation<Offset> _panelOffset = const AlwaysStoppedAnimation<Offset>(Offset.zero);

  @override
  void initState() {
    super.initState();
    _panelController = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _panelScale = CurvedAnimation(parent: _panelController, curve: Curves.easeOutCubic);
    _panelOffset = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _panelController, curve: Curves.easeOutCubic));
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _textController.dispose();
    _panelController.dispose();
    _pulseController?.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _panelController.forward();
        _hasUnread = false;
      } else {
        _panelController.reverse();
      }
    });
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(role: _ChatRole.user, text: text));
      _textController.clear();
    });
    _sendToBackend(text);
  }

  Future<void> _sendToBackend(String text) async {
    try {
      setState(() {
        _isSending = true;
      });
      final repo = ParsedDocumentsRepository(baseUrl: ApiConfig.baseUrl);
      final reply = await repo.sendChatPrompt(text);
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(role: _ChatRole.assistant, text: reply.isEmpty ? '...' : reply));
        _isSending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(role: _ChatRole.assistant, text: 'Error: $e'));
        _isSending = false;
        if (!_isOpen) _hasUnread = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    // Sit above BottomNavBar (~75) with extra spacing and safe area inset
    final bottomPadding = 75.0 + 20.0 + bottomInset;
    // Lift the chat panel slightly higher than the toggle to avoid any overlap
    final panelBottomPadding = bottomPadding + 22.0;
    final rightPadding = 16.0;
    return Stack(
      children: [
        // Panel wrapped with IgnorePointer so background remains interactive when closed
        Positioned(
          right: rightPadding,
          bottom: panelBottomPadding,
          child: IgnorePointer(
            ignoring: !_isOpen,
            child: FadeTransition(
              opacity: _panelScale,
              child: SlideTransition(
                position: _panelOffset,
                child: ScaleTransition(
                  scale: _panelScale,
                  alignment: Alignment.bottomRight,
                  child: Material(
                    elevation: 18,
                    borderRadius: BorderRadius.circular(18),
                    clipBehavior: Clip.antiAlias,
                    color: Colors.transparent,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 420,
                        minWidth: 300,
                        maxHeight: 520,
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: BackdropFilter(
                                filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface.withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 24,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 360,
                            height: 420,
                            child: Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                                    border: Border(
                                      bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  child: Row(
                                    children: [
                                      Icon(Icons.chat_bubble_rounded, color: theme.colorScheme.primary),
                                      const SizedBox(width: 8),
                                      Text('AI Chat', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    reverse: true,
                                    itemCount: _messages.length + (_isSending ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (_isSending && index == 0) {
                                        return const _TypingBubble();
                                      }
                                      final adjIndex = _isSending ? index - 1 : index;
                                      final msg = _messages[_messages.length - 1 - adjIndex];
                                      final isUser = msg.role == _ChatRole.user;
                                      final gradient = isUser
                                          ? const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFFA78BFA)])
                                          : const LinearGradient(colors: [Color(0xFFE5E7EB), Color(0xFFF5F6F8)]);
                                      final textColor = isUser ? Colors.white : theme.colorScheme.onSurface;
                                      return Align(
                                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(vertical: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(14),
                                            gradient: gradient,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.06),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            msg.text,
                                            style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                SafeArea(
                                  top: false,
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(10, 8, 32, 20),
                                    decoration: BoxDecoration(
                                      border: Border(top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.12))),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _textController,
                                            minLines: 1,
                                            maxLines: 4,
                                            decoration: const InputDecoration(
                                              hintText: 'Type a message...',
                                              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                                              isDense: true,
                                            ),
                                            onSubmitted: (_) => _isSending ? null : _handleSend(),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          tooltip: 'Send',
                                          onPressed: _isSending ? null : _handleSend,
                                          icon: _isSending
                                              ? SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                                                  ),
                                                )
                                              : const Icon(Icons.send_rounded),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Toggle button always clickable - beautiful gradient pill with glow and pulse
        Positioned(
          right: rightPadding,
          bottom: bottomPadding,
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              final scale = _isOpen ? 1.0 : 0.98 + (_pulse.value * 0.02);
              return Transform.scale(
                scale: scale,
                alignment: Alignment.center,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Material(
                      color: Colors.transparent,
                      elevation: 0,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(28),
                        onTap: _toggle,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _isOpen
                                  ? const [Color(0xFFEF4444), Color(0xFFF97316)]
                                  : const [Color(0xFF3B82F6), Color(0xFFA78BFA)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_isOpen
                                        ? const Color(0xFFF97316)
                                        : const Color(0xFF3B82F6))
                                    .withValues(alpha: 0.35),
                                blurRadius: 22,
                                spreadRadius: 1,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                                child: Icon(
                                  _isOpen ? Icons.close_rounded : Icons.chat_bubble_rounded,
                                  key: ValueKey(_isOpen),
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
                                child: _isOpen
                                    ? const SizedBox.shrink()
                                    : const Text(
                                        'Chat',
                                        key: ValueKey('Chat'),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_hasUnread && !_isOpen)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(color: Color(0x66EF4444), blurRadius: 8),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
      
    );
  }
}

enum _ChatRole { user, assistant }

class _ChatMessage {
  final _ChatRole role;
  final String text;
  const _ChatMessage({required this.role, required this.text});
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _dots;

  @override
  void initState() {
    super.initState();
    _dots = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() {
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(colors: [Color(0xFFE5E7EB), Color(0xFFF5F6F8)]),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: AnimatedBuilder(
          animation: _dots,
          builder: (context, _) {
            final v = _dots.value;
            int active = (v * 3).floor() % 3; // 0,1,2 cycling
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final on = i <= active;
                return Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: on ? theme.colorScheme.onSurface.withValues(alpha: 0.7) : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}


