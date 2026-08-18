import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/api/analysis_models.dart';
import '../models/api/document_models.dart';

/// Local cache of the last-seen documents and analyses so past results stay
/// viewable without a network connection (F36 offline mode).
class OfflineCache {
  OfflineCache._();

  static const _docsKey = 'offline_documents_v1';
  static const _analysisPrefix = 'offline_analysis_v1_';
  static const _docsSyncedKey = 'offline_documents_synced_at';

  static Future<SharedPreferences> get _prefs async =>
      SharedPreferences.getInstance();

  /// True when the failure looks like a connectivity problem (no HTTP status).
  static bool isNetworkFailure(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('socket') ||
        message.contains('connection') ||
        message.contains('failed host') ||
        message.contains('network') ||
        message.contains('timed out') ||
        message.contains('timeout');
  }

  /* ------------------------------ Documents ------------------------------ */

  static Future<void> saveDocuments(List<ApiDocument> docs) async {
    final prefs = await _prefs;
    final json = jsonEncode(docs.map((d) => d.toJson()).toList());
    await prefs.setString(_docsKey, json);
    await prefs.setString(_docsSyncedKey, DateTime.now().toIso8601String());
  }

  static Future<List<ApiDocument>> cachedDocuments() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_docsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map>()
          .map((e) => ApiDocument.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<DateTime?> documentsSyncedAt() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_docsSyncedKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  /* ------------------------------- Analysis ------------------------------ */

  static Future<void> saveAnalysis(int documentId, AnalysisBundle bundle) async {
    final prefs = await _prefs;
    await prefs.setString(
      '$_analysisPrefix$documentId',
      jsonEncode(bundle.toJson()),
    );
  }

  static Future<AnalysisBundle?> cachedAnalysis(int documentId) async {
    final prefs = await _prefs;
    final raw = prefs.getString('$_analysisPrefix$documentId');
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return AnalysisBundle.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}
