import '../services/api_client.dart';

class ChatRepository {
  ChatRepository({ApiClient? client}) : _api = client ?? ApiClient.instance;

  final ApiClient _api;

  Future<String> createSession(int documentId) async {
    final data = await _api.post(
      '/api/chat/$documentId/session',
      parse: (d) => Map<String, dynamic>.from(d as Map),
    );
    return data['sessionId']?.toString() ?? data['id']?.toString() ?? '';
  }

  Future<Map<String, dynamic>> sendMessage({
    required int documentId,
    required String message,
    String? sessionId,
  }) {
    return _api.post(
      '/api/chat/$documentId/message',
      data: {
        'message': message,
        if (sessionId != null && sessionId.isNotEmpty) 'sessionId': sessionId,
      },
      parse: (d) => Map<String, dynamic>.from(d as Map),
    );
  }

  Future<List<Map<String, dynamic>>> history(
    int documentId, {
    String? sessionId,
    int page = 1,
    int limit = 50,
  }) {
    return _api.get(
      '/api/chat/$documentId/history',
      query: {
        'page': page,
        'limit': limit,
        if (sessionId != null) 'sessionId': sessionId,
      },
      parse: (d) {
        if (d is Map && d['messages'] is List) {
          return (d['messages'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        if (d is List) {
          return d
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        return <Map<String, dynamic>>[];
      },
    );
  }
}
