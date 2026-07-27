import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class SocialConnections extends StatelessWidget {
  const SocialConnections({super.key, this.connections = const []});

  final List<SocialConnection> connections;

  @override
  Widget build(BuildContext context) {
    if (connections.isEmpty) return const SizedBox.shrink();
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.people_alt, color: AppTheme.primaryBlue, size: 18),
                SizedBox(width: 8),
                Text('Connections', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
              ],
            ),
            const SizedBox(height: 12),
            ...connections.map((c) => _ConnectionTile(conn: c)),
          ],
        ),
      ),
    );
  }
}

class SocialConnection {
  final String name;
  final String role;
  final String avatarUrl;
  final bool online;

  const SocialConnection({required this.name, required this.role, this.avatarUrl = '', this.online = false});
}

class _ConnectionTile extends StatelessWidget {
  const _ConnectionTile({required this.conn});

  final SocialConnection conn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(radius: 16, backgroundColor: const Color(0xFFE5E7EB), child: Text(_initials(conn.name), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF374151)))),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(width: 8, height: 8, decoration: BoxDecoration(color: conn.online ? AppTheme.successGreen : Colors.grey, shape: BoxShape.circle)),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(conn.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
              const SizedBox(height: 2),
              Text(conn.role, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
            ]),
          ),
          TextButton(onPressed: () {}, child: const Text('Message')),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty) return parts.first[0].toUpperCase();
    return 'U';
  }
}


