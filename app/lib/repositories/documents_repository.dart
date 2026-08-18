import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../models/api/analysis_models.dart';
import '../models/api/document_models.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';

class DocumentsRepository {
  DocumentsRepository({ApiClient? client}) : _api = client ?? ApiClient.instance;

  final ApiClient _api;

  Future<List<ApiDocument>> list({
    int page = 1,
    int limit = 50,
    String? status,
  }) async {
    return _api.get(
      '/api/documents',
      query: {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status,
      },
      parse: (d) {
        if (d is Map && d['documents'] is List) {
          return (d['documents'] as List)
              .whereType<Map>()
              .map((e) => ApiDocument.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
        if (d is List) {
          return d
              .whereType<Map>()
              .map((e) => ApiDocument.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
        return <ApiDocument>[];
      },
    );
  }

  Future<ApiDocument> getById(int id) async {
    return _api.get(
      '/api/documents/$id',
      parse: (d) => ApiDocument.fromJson(d as Map<String, dynamic>),
    );
  }

  Future<DocumentStatus> getStatus(int id) async {
    return _api.get(
      '/api/documents/$id/status',
      parse: (d) => DocumentStatus.fromJson(d as Map<String, dynamic>),
    );
  }

  Future<AnalysisBundle> getAnalysis(int id) async {
    return _api.get(
      '/api/documents/$id/analysis',
      parse: (d) => AnalysisBundle.fromJson(d as Map<String, dynamic>),
    );
  }

  /// Blocking extract + LLM analysis. Long timeout for local Ollama.
  Future<AnalysisBundle> process(int id) async {
    return _api.post(
      '/api/documents/$id/process',
      options: Options(
        receiveTimeout: const Duration(minutes: 10),
        sendTimeout: const Duration(minutes: 2),
      ),
      parse: (d) => AnalysisBundle.fromJson(d as Map<String, dynamic>),
    );
  }

  Future<void> delete(int id) async {
    await _api.delete('/api/documents/$id');
  }

  Future<UploadResult> uploadFile({
    required String filename,
    required Uint8List bytes,
    String sourceType = 'file',
    String? title,
    String? countryCode,
    String? stateCode,
    String? typeHint,
  }) async {
    final form = FormData.fromMap({
      'sourceType': sourceType,
      if (title != null) 'title': title,
      if (countryCode != null) 'countryCode': countryCode,
      if (stateCode != null) 'stateCode': stateCode,
      if (typeHint != null) 'typeHint': typeHint,
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    return _api.postMultipart(
      '/api/documents/upload',
      formData: form,
      parse: (d) => UploadResult.fromJson(d as Map<String, dynamic>),
    );
  }

  Future<UploadResult> uploadPaste({
    required String text,
    String? title,
    String? countryCode,
    String? stateCode,
    String? typeHint,
  }) async {
    final form = FormData.fromMap({
      'sourceType': 'paste',
      'text': text,
      if (title != null) 'title': title,
      if (countryCode != null) 'countryCode': countryCode,
      if (stateCode != null) 'stateCode': stateCode,
      if (typeHint != null) 'typeHint': typeHint,
    });
    return _api.postMultipart(
      '/api/documents/upload',
      formData: form,
      parse: (d) => UploadResult.fromJson(d as Map<String, dynamic>),
    );
  }

  Future<UploadResult> uploadUrl({
    required String url,
    String? title,
    String? countryCode,
    String? stateCode,
    String? typeHint,
  }) async {
    final form = FormData.fromMap({
      'sourceType': 'url',
      'url': url,
      if (title != null) 'title': title,
      if (countryCode != null) 'countryCode': countryCode,
      if (stateCode != null) 'stateCode': stateCode,
      if (typeHint != null) 'typeHint': typeHint,
    });
    return _api.postMultipart(
      '/api/documents/upload',
      formData: form,
      parse: (d) => UploadResult.fromJson(d as Map<String, dynamic>),
    );
  }

  Future<Map<String, dynamic>> translate(
    int id, {
    required String targetLanguage,
  }) async {
    return _api.post(
      '/api/documents/$id/translate',
      data: {'targetLanguage': targetLanguage},
      parse: (d) => Map<String, dynamic>.from(d as Map),
    );
  }

  /// Downloads export bytes (pdf/docx). Returns file bytes + suggested name.
  Future<({Uint8List bytes, String filename, String mime})> exportReport(
    int id, {
    String format = 'pdf',
  }) async {
    try {
      final res = await _api.dio.get<List<int>>(
        '/api/documents/$id/export',
        queryParameters: {'format': format},
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(minutes: 2),
        ),
      );
      final bytes = Uint8List.fromList(res.data ?? const []);
      final mime = format == 'docx'
          ? 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
          : 'application/pdf';
      final filename = 'legisense-report-$id.$format';
      return (bytes: bytes, filename: filename, mime: mime);
    } on DioException catch (e) {
      throw ApiException(
        message: e.message ?? 'Export failed',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
