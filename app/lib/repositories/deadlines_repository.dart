import '../services/api_client.dart';

class DeadlinesRepository {
  DeadlinesRepository({ApiClient? client})
      : _api = client ?? ApiClient.instance;

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> list({bool? completed}) {
    return _api.get(
      '/api/deadlines',
      query: {
        if (completed != null) 'completed': completed,
      },
      parse: _asList,
    );
  }

  Future<List<Map<String, dynamic>>> upcoming() {
    return _api.get('/api/deadlines/upcoming', parse: _asList);
  }

  Future<List<Map<String, dynamic>>> forDocument(int documentId) {
    return _api.get('/api/deadlines/document/$documentId', parse: _asList);
  }

  Future<void> complete(int id) async {
    await _api.put('/api/deadlines/$id/complete');
  }

  Future<void> dismiss(int id) async {
    await _api.put('/api/deadlines/$id/dismiss');
  }

  Future<void> updateReminders(int id, Map<String, dynamic> body) async {
    await _api.put('/api/deadlines/$id/reminders', data: body);
  }

  Future<String?> exportIcsText(List<int> ids) async {
    final data = await _api.post(
      '/api/deadlines/export/ics?json=1',
      data: {'deadlineIds': ids},
      parse: (d) => d,
    );
    if (data is Map && data['ics'] is String) return data['ics'] as String;
    if (data is String) return data;
    return null;
  }

  Future<List<int>> exportIcs(List<int> ids) async {
    await exportIcsText(ids);
    return ids;
  }

  Future<dynamic> exportIcsRaw(List<int> ids) => exportIcsText(ids);

  List<Map<String, dynamic>> _asList(dynamic d) {
    if (d is Map && d['deadlines'] is List) {
      return (d['deadlines'] as List)
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
    return [];
  }
}
