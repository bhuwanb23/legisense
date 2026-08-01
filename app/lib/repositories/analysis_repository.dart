import '../services/api_client.dart';
import 'package:dio/dio.dart';

class AnalysisRepository {
  AnalysisRepository({ApiClient? client}) : _api = client ?? ApiClient.instance;

  final ApiClient _api;

  Future<Map<String, dynamic>> start(int documentId, {Map<String, dynamic>? body}) {
    return _api.post(
      '/api/analysis/start/$documentId',
      data: body ?? {},
      parse: (d) => Map<String, dynamic>.from(d as Map? ?? {}),
    );
  }

  Future<Map<String, dynamic>> riskDashboard(int documentId) {
    return _api.get(
      '/api/analysis/$documentId/risk-dashboard',
      parse: (d) => Map<String, dynamic>.from(d as Map),
    );
  }

  Future<Map<String, dynamic>> risks(int documentId) {
    return _api.get(
      '/api/analysis/$documentId/risks',
      parse: (d) => Map<String, dynamic>.from(d as Map),
    );
  }

  Future<Map<String, dynamic>> plainEnglish(int documentId) {
    return _api.get(
      '/api/analysis/$documentId/plain-english',
      parse: (d) => Map<String, dynamic>.from(d as Map),
    );
  }

  Future<Map<String, dynamic>> jurisdictionFlags(int documentId) {
    return _api.get(
      '/api/analysis/$documentId/jurisdiction-flags',
      parse: (d) => Map<String, dynamic>.from(d as Map),
    );
  }

  Future<Map<String, dynamic>> stateConflicts(int documentId) {
    return _api.get(
      '/api/analysis/$documentId/state-conflicts',
      parse: (d) => Map<String, dynamic>.from(d as Map),
    );
  }

  Future<Map<String, dynamic>> flaggedClauses(int documentId) {
    return _api.get(
      '/api/analysis/$documentId/flagged-clauses',
      parse: (d) => Map<String, dynamic>.from(d as Map),
    );
  }

  Future<Map<String, dynamic>> missingClauses(int documentId) {
    return _api.get(
      '/api/analysis/$documentId/missing-clauses',
      parse: (d) => Map<String, dynamic>.from(d as Map),
    );
  }

  Future<Map<String, dynamic>> counterClauses(int documentId) {
    return _api.get(
      '/api/analysis/$documentId/counter-clauses',
      parse: (d) => Map<String, dynamic>.from(d as Map),
    );
  }

  Future<Map<String, dynamic>> classify(int documentId) {
    return _api.get(
      '/api/analysis/$documentId/classify',
      parse: (d) => Map<String, dynamic>.from(d as Map),
    );
  }

  Future<Map<String, dynamic>> confirmType(int documentId, String type) {
    return _api.post(
      '/api/analysis/$documentId/confirm-type',
      data: {'type': type},
      parse: (d) => Map<String, dynamic>.from(d as Map),
    );
  }

  Future<Map<String, dynamic>> glossary(String term) {
    return _api.post(
      '/api/analysis/glossary',
      data: {'term': term},
      parse: (d) => Map<String, dynamic>.from(d as Map),
    );
  }

  Future<Map<String, dynamic>> rewritePlainEnglish(
    int documentId, {
    required String readingLevel,
  }) {
    return _api.post(
      '/api/analysis/$documentId/plain-english/rewrite',
      data: {'readingLevel': readingLevel},
      options: Options(
        receiveTimeout: const Duration(minutes: 5),
      ),
      parse: (d) => Map<String, dynamic>.from(d as Map),
    );
  }

  Future<void> riskFeedback({
    required int documentId,
    required int clauseId,
    required String feedbackType,
    String? note,
  }) async {
    await _api.post(
      '/api/analysis/$documentId/clauses/$clauseId/risk-feedback',
      data: {
        'feedback_type': feedbackType,
        if (note != null) 'note': note,
      },
    );
  }

  Future<void> markCounterUsed({
    required int documentId,
    required int clauseId,
  }) async {
    await _api.post(
      '/api/analysis/$documentId/clauses/$clauseId/counter-used',
    );
  }
}
