import 'package:dio/dio.dart';

import '../services/api_client.dart';

/// API access for the post-launch feature set:
/// favorites, share links, clause annotations, playbook rules,
/// one-click better version, document comparison, and templates.
class FeaturesRepository {
  FeaturesRepository({ApiClient? client})
      : _api = client ?? ApiClient.instance;

  final ApiClient _api;

  /* ------------------------------ Favorites ------------------------------ */

  Future<void> setFavorite(int documentId, bool isFavorite) async {
    await _api.put(
      '/api/documents/$documentId/favorite',
      data: {'isFavorite': isFavorite},
    );
  }

  Future<Map<String, dynamic>> favoriteDocuments() async {
    return _api.get(
      '/api/documents?favorites=1&limit=100',
      parse: (d) => Map<String, dynamic>.from(d as Map),
    );
  }

  /* ----------------------------- Share links ----------------------------- */

  Future<Map<String, dynamic>> createShareLink(int documentId) {
    return _api.post(
      '/api/documents/$documentId/share',
      data: {},
      parse: (d) => Map<String, dynamic>.from(d as Map),
    );
  }

  Future<void> revokeShareLink(int documentId) async {
    await _api.delete('/api/documents/$documentId/share');
  }

  Future<Map<String, dynamic>> getSharedAnalysis(String token) {
    return _api.get(
      '/api/shared/$token',
      parse: (d) => Map<String, dynamic>.from(d as Map),
    );
  }

  /* ------------------------------- Notes --------------------------------- */

  Future<List<Map<String, dynamic>>> listNotes(int documentId) {
    return _api.get(
      '/api/documents/$documentId/notes',
      parse: (d) {
        if (d is Map && d['notes'] is List) {
          return (d['notes'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        return <Map<String, dynamic>>[];
      },
    );
  }

  Future<Map<String, dynamic>> addNote({
    required int documentId,
    required int clauseId,
    required String note,
  }) {
    return _api.post(
      '/api/documents/$documentId/clauses/$clauseId/notes',
      data: {'note': note},
      parse: (d) => Map<String, dynamic>.from(d as Map),
    );
  }

  Future<Map<String, dynamic>> updateNote({
    required int noteId,
    required String note,
  }) {
    return _api.put(
      '/api/notes/$noteId',
      data: {'note': note},
      parse: (d) => Map<String, dynamic>.from(d as Map),
    );
  }

  Future<void> deleteNote(int noteId) async {
    await _api.delete('/api/notes/$noteId');
  }

  /* ------------------------------ Playbook ------------------------------- */

  Future<List<Map<String, dynamic>>> playbookRules() {
    return _api.get(
      '/api/playbook/rules',
      parse: (d) {
        if (d is Map && d['rules'] is List) {
          return (d['rules'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        return <Map<String, dynamic>>[];
      },
    );
  }

  Future<Map<String, dynamic>> addPlaybookRule({
    required String ruleText,
    String category = 'general',
  }) {
    return _api.post(
      '/api/playbook/rules',
      data: {'ruleText': ruleText, 'category': category},
      parse: (d) => Map<String, dynamic>.from(d as Map),
    );
  }

  Future<Map<String, dynamic>> updatePlaybookRule({
    required int id,
    String? ruleText,
    String? category,
    bool? isActive,
  }) {
    return _api.put(
      '/api/playbook/rules/$id',
      data: {
        if (ruleText != null) 'ruleText': ruleText,
        if (category != null) 'category': category,
        if (isActive != null) 'isActive': isActive,
      },
      parse: (d) => Map<String, dynamic>.from(d as Map),
    );
  }

  Future<void> deletePlaybookRule(int id) async {
    await _api.delete('/api/playbook/rules/$id');
  }

  /* --------------------------- Better version ---------------------------- */

  Future<Map<String, dynamic>> betterVersion(int documentId) {
    return _api.post(
      '/api/analysis/$documentId/better-version',
      data: {},
      options: Options(
        receiveTimeout: const Duration(minutes: 5),
      ),
      parse: (d) => Map<String, dynamic>.from(d as Map),
    );
  }

  /* -------------------------------- Compare ------------------------------ */

  Future<Map<String, dynamic>> compareDocuments({
    required int documentIdA,
    required int documentIdB,
  }) {
    return _api.post(
      '/api/analysis/compare',
      data: {'documentIdA': documentIdA, 'documentIdB': documentIdB},
      parse: (d) => Map<String, dynamic>.from(d as Map),
    );
  }

  /* ------------------------------- Templates ----------------------------- */

  Future<List<Map<String, dynamic>>> templates() {
    return _api.get(
      '/api/analysis/templates',
      parse: (d) {
        if (d is Map && d['templates'] is List) {
          return (d['templates'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        return <Map<String, dynamic>>[];
      },
    );
  }
}
