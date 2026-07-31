import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../mappers/analysis_mapper.dart';
import '../../repositories/notifications_repository.dart';
import '../../services/api_exception.dart';
import '../../theme/app_theme.dart';
import '../../widgets/home/app_page_header.dart';
import '../analysis/analysis_loader_page.dart';

class _NotifItem {
  const _NotifItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timeLabel,
    required this.createdAt,
    required this.unread,
    this.documentId,
  });

  final int id;
  final String type;
  final String title;
  final String body;
  final String timeLabel;
  final DateTime? createdAt;
  final bool unread;
  final int? documentId;
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _repo = NotificationsRepository();
  String _filter = 'all'; // all | unread
  List<_NotifItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  _NotifItem _map(Map<String, dynamic> raw) {
    final id = (raw['id'] as num?)?.toInt() ?? 0;
    final title = raw['title']?.toString() ?? 'Notification';
    final type = (raw['type'] ?? 'tip').toString();
    final rawBody = (raw['body'] ?? raw['message'] ?? '').toString();
    final body = _friendlyBody(type, title, rawBody);
    final createdRaw = raw['createdAt']?.toString();
    final created = DateTime.tryParse(createdRaw ?? '');
    final isRead = raw['isRead'] == true || raw['isRead'] == 1;
    final unread = raw['unread'] == true
        ? true
        : raw.containsKey('isRead')
            ? !isRead
            : true;
    final docRaw = raw['documentId'] ?? raw['docId'];
    final documentId = docRaw is num
        ? docRaw.toInt()
        : int.tryParse(docRaw?.toString() ?? '');
    return _NotifItem(
      id: id,
      type: type,
      title: title,
      body: body,
      timeLabel: AnalysisMapper.relativeDate(createdRaw),
      createdAt: created,
      unread: unread,
      documentId: documentId,
    );
  }

  /// Hide stack traces / Zod dumps — keep a short human message.
  String _friendlyBody(String type, String title, String body) {
    final t = type.toLowerCase();
    if (t.contains('fail') || title.toLowerCase().contains('fail')) {
      final cut = RegExp(r'failed:\s*', caseSensitive: false).firstMatch(body);
      if (cut != null) {
        final before = body.substring(0, cut.start).trim();
        if (before.isNotEmpty) {
          return before.endsWith('.')
              ? '$before Tap to retry.'
              : '$before. Tap to retry.';
        }
      }
      if (body.contains('AI analysis failed') ||
          body.contains('invalid_type') ||
          body.contains('INTERNAL_ERROR') ||
          body.contains('Expected') ||
          body.length > 160) {
        return 'We couldn’t finish analyzing this document. Tap to retry.';
      }
    }
    if (body.length > 140) {
      return '${body.substring(0, 137).trim()}…';
    }
    return body;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _repo.list();
      if (!mounted) return;
      setState(() {
        _items = result.items.map(_map).toList();
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<_NotifItem> get _visible {
    if (_filter == 'unread') {
      return _items.where((n) => n.unread).toList();
    }
    return _items;
  }

  Future<void> _markAllRead() async {
    try {
      await _repo.markAllRead();
      if (!mounted) return;
      setState(() {
        _items = _items
            .map(
              (n) => _NotifItem(
                id: n.id,
                type: n.type,
                title: n.title,
                body: n.body,
                timeLabel: n.timeLabel,
                createdAt: n.createdAt,
                unread: false,
                documentId: n.documentId,
              ),
            )
            .toList();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _markRead(_NotifItem n) async {
    if (!n.unread) return;
    try {
      await _repo.markRead(n.id);
      if (!mounted) return;
      setState(() {
        _items = _items
            .map(
              (x) => x.id == n.id
                  ? _NotifItem(
                      id: x.id,
                      type: x.type,
                      title: x.title,
                      body: x.body,
                      timeLabel: x.timeLabel,
                      createdAt: x.createdAt,
                      unread: false,
                      documentId: x.documentId,
                    )
                  : x,
            )
            .toList();
      });
    } catch (_) {}
  }

  Future<void> _open(_NotifItem n) async {
    await _markRead(n);
    if (!mounted) return;
    if (n.documentId != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AnalysisLoaderPage(documentId: n.documentId!),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(n.body, style: GoogleFonts.plusJakartaSans()),
        backgroundColor: AppColors.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  ({IconData icon, Color tint, Color fg}) _style(String type) {
    final t = type.toLowerCase();
    if (t.contains('fail') || t.contains('error')) {
      return (
        icon: Icons.error_outline_rounded,
        tint: AppColors.riskHighBg,
        fg: AppColors.riskHigh,
      );
    }
    if (t.contains('deadline')) {
      return (
        icon: Icons.event_outlined,
        tint: AppColors.riskMediumBg,
        fg: AppColors.riskMedium,
      );
    }
    if (t.contains('analysis') || t.contains('ready')) {
      return (
        icon: Icons.fact_check_outlined,
        tint: AppColors.chip,
        fg: AppColors.ink,
      );
    }
    return (
      icon: Icons.lightbulb_outline_rounded,
      tint: const Color(0xFFE8F5E9),
      fg: AppColors.riskLow,
    );
  }

  String _groupKey(_NotifItem n) {
    final dt = n.createdAt;
    if (dt == null) return 'earlier';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'today';
    if (diff == 1) return 'yesterday';
    return 'earlier';
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final today = visible.where((n) => _groupKey(n) == 'today').toList();
    final yesterday =
        visible.where((n) => _groupKey(n) == 'yesterday').toList();
    final earlier = visible.where((n) => _groupKey(n) == 'earlier').toList();

    return ColoredBox(
      color: AppColors.bg,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(
              title: 'Notifications',
              subtitle: 'Deadlines, analysis, and tips',
              trailing: AppHeaderIconButton(
                icon: Icons.done_all_rounded,
                onTap: _markAllRead,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _filter == 'all',
                    onTap: () => setState(() => _filter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Unread',
                    selected: _filter == 'unread',
                    onTap: () => setState(() => _filter = 'unread'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _markAllRead,
                    child: Text(
                      'Mark all as read',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _error!,
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.mute,
                                ),
                              ),
                              TextButton(
                                onPressed: _load,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : visible.isEmpty
                          ? Center(
                              child: Text(
                                'No notifications',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.mute,
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView(
                                padding:
                                    const EdgeInsets.fromLTRB(24, 12, 24, 110),
                                children: [
                                  if (today.isNotEmpty) ...[
                                    _SectionLabel('Today'),
                                    ...today.map(_card),
                                  ],
                                  if (yesterday.isNotEmpty) ...[
                                    _SectionLabel('Yesterday'),
                                    ...yesterday.map(_card),
                                  ],
                                  if (earlier.isNotEmpty) ...[
                                    _SectionLabel('Earlier'),
                                    ...earlier.map(_card),
                                  ],
                                ],
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(_NotifItem n) {
    final style = _style(n.type);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: () => _open(n),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.md),
              boxShadow: AppShadows.soft,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: style.tint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(style.icon, color: style.fg, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              n.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          if (n.unread)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(left: 6),
                              decoration: const BoxDecoration(
                                color: AppColors.ink,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        n.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          height: 1.4,
                          color: AppColors.mute,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        n.timeLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.mute.withValues(alpha: 0.8),
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
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          boxShadow: selected ? null : AppShadows.soft,
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.surface : AppColors.mute,
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
    );
  }
}
