import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/analysis_mock.dart';
import '../../repositories/chat_repository.dart';
import '../../services/api_exception.dart';
import '../../theme/app_theme.dart';

class _ChatBubbleMsg {
  const _ChatBubbleMsg({
    required this.id,
    required this.text,
    required this.isUser,
    this.citedClauses = const [],
  });

  final String id;
  final String text;
  final bool isUser;
  final List<String> citedClauses;
}

/// Chat with Document — live ChatRepository session.
class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.result});

  final AnalysisResult result;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _repo = ChatRepository();
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<_ChatBubbleMsg> _messages = [];
  String? _sessionId;
  bool _sending = false;
  bool _ready = false;
  String? _initError;

  static const _prompts = <String>[
    'What are the biggest risks?',
    'Explain the lock-in period',
    'Who does this contract favor?',
    'What happens if I leave early?',
  ];

  AnalysisResult get r => widget.result;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final docId = r.documentId;
    if (docId == null) {
      setState(() {
        _initError = 'This analysis is missing a document id. Re-open from Documents.';
        _ready = false;
      });
      return;
    }
    try {
      final sid = await _repo.createSession(docId);
      if (!mounted) return;
      setState(() {
        _sessionId = sid;
        _ready = true;
        _messages.add(
          _ChatBubbleMsg(
            id: 's1',
            text:
                'I’ve reviewed “${r.documentTitle}”. Ask about risks, parties, dates, or any clause.',
            isUser: false,
          ),
        );
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _initError = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _initError = e.toString());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  List<String> _parseCitations(dynamic raw) {
    if (raw is! List) return [];
    return raw.map((e) {
      if (e is Map) {
        final m = Map<String, dynamic>.from(e);
        final title = m['clauseTitle'] ?? m['title'] ?? m['clauseNumber'];
        final snippet = m['snippet'] ?? m['text'] ?? m['originalText'];
        if (title != null && snippet != null) {
          return '$title: $snippet';
        }
        return (title ?? snippet ?? e).toString();
      }
      return e.toString();
    }).toList();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    final docId = r.documentId;
    if (text.isEmpty || _sending || docId == null || !_ready) return;

    setState(() {
      _sending = true;
      _messages.add(
        _ChatBubbleMsg(
          id: 'u${_messages.length}',
          text: text,
          isUser: true,
        ),
      );
      _controller.clear();
    });
    _scrollToEnd();

    try {
      final res = await _repo.sendMessage(
        documentId: docId,
        message: text,
        sessionId: _sessionId,
      );
      if (!mounted) return;
      final msg = res['message'];
      String reply;
      List<String> cites = [];
      if (msg is Map) {
        final m = Map<String, dynamic>.from(msg);
        reply = (m['content'] ?? m['message'] ?? m['text'] ?? '').toString();
        cites = _parseCitations(m['citedClauses']);
        final sid = res['sessionId']?.toString();
        if (sid != null && sid.isNotEmpty) _sessionId = sid;
      } else {
        reply = (res['reply'] ?? res['content'] ?? res['message'] ?? '')
            .toString();
        cites = _parseCitations(res['citedClauses']);
      }
      if (reply.isEmpty) reply = 'No response from assistant.';
      setState(() {
        _messages.add(
          _ChatBubbleMsg(
            id: 'a${_messages.length}',
            text: reply,
            isUser: false,
            citedClauses: cites,
          ),
        );
        _sending = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatBubbleMsg(
            id: 'e${_messages.length}',
            text: e.message,
            isUser: false,
          ),
        );
        _sending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatBubbleMsg(
            id: 'e${_messages.length}',
            text: e.toString(),
            isUser: false,
          ),
        );
        _sending = false;
      });
    }
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chat',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            Text(
              r.documentTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.mute,
              ),
            ),
          ],
        ),
      ),
      body: _initError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _initError!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(color: AppColors.mute),
                ),
              ),
            )
          : !_ready
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.rule),
                        ),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final p in _prompts) ...[
                              ActionChip(
                                label: Text(
                                  p,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ink,
                                  ),
                                ),
                                backgroundColor: AppColors.surface,
                                side: const BorderSide(color: AppColors.rule),
                                onPressed: _sending ? null : () => _send(p),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) {
                          return _Bubble(message: _messages[i]);
                        },
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          border: Border(
                            top: BorderSide(color: AppColors.rule),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _send(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: AppColors.ink,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Ask about this document…',
                                  hintStyle: GoogleFonts.plusJakartaSans(
                                    color: AppColors.mute,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.chip,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadii.pill),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadii.pill),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadii.pill),
                                    borderSide: const BorderSide(
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Material(
                              color: AppColors.ink,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: _sending ? null : () => _send(),
                                child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: _sending
                                      ? const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.surface,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.send_rounded,
                                          color: AppColors.surface,
                                          size: 22,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final _ChatBubbleMsg message;

  @override
  Widget build(BuildContext context) {
    final user = message.isUser;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: user ? AppColors.ink : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(user ? 16 : 4),
            bottomRight: Radius.circular(user ? 4 : 16),
          ),
          border: user ? null : Border.all(color: AppColors.rule),
          boxShadow: user ? null : AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                height: 1.45,
                color: user ? AppColors.surface : AppColors.ink,
              ),
            ),
            if (!user && message.citedClauses.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Cited clauses',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mute,
                ),
              ),
              const SizedBox(height: 6),
              for (final c in message.citedClauses)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.chip,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      c,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        height: 1.35,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
