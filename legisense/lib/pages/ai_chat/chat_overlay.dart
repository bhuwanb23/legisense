import 'package:flutter/material.dart';
import '../../api/parsed_documents_repository.dart';

class ChatOverlay extends StatefulWidget {
  const ChatOverlay({super.key});

  @override
  State<ChatOverlay> createState() => _ChatOverlayState();
}

class _ChatOverlayState extends State<ChatOverlay> with TickerProviderStateMixin {
  bool _isOpen = false;
  final List<_ChatMessage> _messages = <_ChatMessage>[
    const _ChatMessage(role: _ChatRole.assistant, text: 'Hi! How can I help you with legal documents?'),
  ];
  final TextEditingController _textController = TextEditingController();
  late final AnimationController _panelController;
  late final Animation<double> _panelScale;
  AnimationController? _pulseController;
  Animation<double> _pulse = const AlwaysStoppedAnimation<double>(0);
  bool _hasUnread = false;

  @override
  void initState() {
    super.initState();
    _panelController = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _panelScale = CurvedAnimation(parent: _panelController, curve: Curves.easeOutCubic);
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
      final repo = ParsedDocumentsRepository(baseUrl: ApiConfig.baseUrl);
      final reply = await repo.sendChatPrompt(text);
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(role: _ChatRole.assistant, text: reply.isEmpty ? '...' : reply));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(role: _ChatRole.assistant, text: 'Error: $e'));
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
    final rightPadding = 16.0;
    return Stack(
      children: [
        // Panel wrapped with IgnorePointer so background remains interactive when closed
        Positioned(
          right: rightPadding,
          bottom: bottomPadding,
          child: IgnorePointer(
            ignoring: !_isOpen,
            child: FadeTransition(
              opacity: _panelScale,
              child: ScaleTransition(
                scale: _panelScale,
                alignment: Alignment.bottomRight,
                child: Material(
                  elevation: 16,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  color: theme.colorScheme.surface,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 420,
                      minWidth: 300,
                      maxHeight: 520,
                    ),
                    child: SizedBox(
                      width: 360,
                      height: 420,
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.08),
                              border: Border(
                                bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.12)),
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
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                final msg = _messages[_messages.length - 1 - index];
                                final isUser = msg.role == _ChatRole.user;
                                final bubbleColor = isUser
                                    ? theme.colorScheme.primary.withOpacity(0.12)
                                    : theme.colorScheme.surfaceVariant.withOpacity(0.6);
                                return Align(
                                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: bubbleColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: theme.colorScheme.outline.withOpacity(0.08)),
                                    ),
                                    child: Text(
                                      msg.text,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          SafeArea(
                            top: false,
                            child: Container(
                              // Extra right and bottom padding to avoid overlap with floating toggle
                              padding: const EdgeInsets.fromLTRB(10, 8, 24, 16),
                              decoration: BoxDecoration(
                                border: Border(top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.12))),
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
                                      onSubmitted: (_) => _handleSend(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    tooltip: 'Send',
                                    onPressed: _handleSend,
                                    icon: const Icon(Icons.send_rounded),
                                  ),
                                ],
                              ),
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
                                    .withOpacity(0.35),
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


