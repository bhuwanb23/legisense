import '../services/api_client.dart';

class NotificationsRepository {
  NotificationsRepository({ApiClient? client})
      : _api = client ?? ApiClient.instance;

  final ApiClient _api;

  Future<({List<Map<String, dynamic>> items, int unreadCount})> list() async {
    final data = await _api.get(
      '/api/notifications',
      parse: (d) => Map<String, dynamic>.from(d as Map),
    );
    final items = (data['notifications'] as List? ?? data['items'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final unread = (data['unreadCount'] as num?)?.toInt() ?? 0;
    return (items: items, unreadCount: unread);
  }

  Future<void> markRead(int id) async {
    await _api.put('/api/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _api.put('/api/notifications/read-all');
  }
}
