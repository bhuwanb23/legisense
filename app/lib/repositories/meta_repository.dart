import '../services/api_client.dart';

class MetaRepository {
  MetaRepository({ApiClient? client}) : _api = client ?? ApiClient.instance;

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> countries() {
    return _api.get(
      '/api/jurisdictions/countries',
      parse: (d) {
        final list = d is Map ? d['countries'] ?? d : d;
        if (list is! List) return <Map<String, dynamic>>[];
        return list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      },
    );
  }

  Future<List<Map<String, dynamic>>> states(String countryCode) {
    return _api.get(
      '/api/jurisdictions/$countryCode/states',
      parse: (d) {
        final list = d is Map ? d['states'] ?? d : d;
        if (list is! List) return <Map<String, dynamic>>[];
        return list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      },
    );
  }

  Future<List<Map<String, dynamic>>> languages() {
    return _api.get(
      '/api/languages/supported',
      parse: (d) {
        final list = d is Map ? d['languages'] ?? d : d;
        if (list is! List) return <Map<String, dynamic>>[];
        return list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      },
    );
  }
}
