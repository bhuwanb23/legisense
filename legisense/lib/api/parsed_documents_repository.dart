import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import '../pages/documents/data/sample_documents.dart';

/// Simple in-memory repository that uploads a PDF to the backend and stores
/// the parsed result as a `SampleDocument`-compatible object for display.
class ApiConfig {
  /// Resolves a sensible default base URL depending on environment.
  /// Overridden to localhost for local testing.
  static String get baseUrl {
    return 'http://localhost:8000';
  }
}

class ParsedDocumentsRepository {
  ParsedDocumentsRepository({required this.baseUrl});

  final String baseUrl; // e.g., http://localhost:8000

  /// List of documents parsed in this session.
  final List<SampleDocument> _uploadedDocs = [];

  List<SampleDocument> get uploadedDocs => List.unmodifiable(_uploadedDocs);

  /// Test method to verify API connectivity
  Future<bool> testConnection() async {
    try {
      final uri = Uri.parse('$baseUrl/api/documents/');
      print('DEBUG: Testing connection to: $uri');
      final res = await http.get(uri);
      print('DEBUG: Test response status: ${res.statusCode}');
      return res.statusCode == 200;
    } catch (e) {
      print('DEBUG: Connection test failed: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchDocuments() async {
    try {
      final uri = Uri.parse('$baseUrl/api/documents/');
      print('DEBUG: Fetching documents from: $uri');
      final res = await http.get(uri);
      print('DEBUG: Response status: ${res.statusCode}');
      print('DEBUG: Response body: ${res.body}');
      
      if (res.statusCode != 200) {
        throw HttpException('List failed (${res.statusCode}): ${res.body}');
      }
      final Map<String, dynamic> data = json.decode(res.body) as Map<String, dynamic>;
      final List<dynamic> results = (data['results'] ?? []) as List<dynamic>;
      print('DEBUG: Parsed ${results.length} documents');
      return results.cast<Map<String, dynamic>>();
    } catch (e) {
      print('DEBUG: Error in fetchDocuments: $e');
      rethrow;
    }
  }

  Future<SampleDocument> fetchDocumentDetail(int id) async {
    final uri = Uri.parse('$baseUrl/api/documents/$id/');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw HttpException('Detail failed (${res.statusCode}): ${res.body}');
    }
    final Map<String, dynamic> data = json.decode(res.body) as Map<String, dynamic>;
    final String title = (data['file_name'] ?? 'Document').toString();
    final int numPages = (data['num_pages'] ?? 0) as int;
    // analysis_available is returned for UI chips; currently unused here.
    final List<dynamic> pages = (data['pages'] ?? []) as List<dynamic>;
    final List<String> textBlocks = pages
        .map((e) => (e as Map<String, dynamic>)['text']?.toString() ?? '')
        .where((t) => t.isNotEmpty)
        .toList(growable: false);

    return SampleDocument(
      id: 'server-$id',
      title: title,
      meta: 'PDF • $numPages page${numPages == 1 ? '' : 's'}',
      ext: 'pdf',
      tldr: '',
      textBlocks: textBlocks,
      imageUrls: const [],
      insights: const [],
    );
  }

  Future<Map<String, dynamic>> fetchAnalysis(int id) async {
    final uri = Uri.parse('$baseUrl/api/documents/$id/analysis/');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw HttpException('Analysis failed (${res.statusCode}): ${res.body}');
    }
    final Map<String, dynamic> data = json.decode(res.body) as Map<String, dynamic>;
    // Handle pending/failed statuses gracefully
    final status = (data['status'] ?? 'success').toString();
    if (status != 'success') {
      throw HttpException(status == 'pending' ? 'Analysis pending' : 'Analysis unavailable: ${data['error'] ?? status}');
    }
    final Map<String, dynamic> analysis = (data['analysis'] ?? {}) as Map<String, dynamic>;
    return analysis;
  }

  // Removed continuous polling to prevent repeated calls

  /// Uploads a PDF file to Django parser endpoint and returns a SampleDocument.
  ///
  /// The Django endpoint is expected to return JSON like:
  /// {
  ///   "file": "path-or-name",
  ///   "num_pages": 3,
  ///   "pages": [{"page_number": 1, "text": "..."}, ...],
  ///   "full_text": "..."
  /// }
  Future<SampleDocument> uploadAndParsePdf({required File pdfFile}) async {
    final uri = Uri.parse('$baseUrl/api/parse-pdf/');

    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', pdfFile.path));

    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Upload failed (${response.statusCode}): ${response.body}');
    }

    final Map<String, dynamic> data = json.decode(response.body) as Map<String, dynamic>;
    final int serverId = (data['id'] ?? 0) as int;
    // Prefer server-returned original filename; fallback to picked file name
    final String title = (data['file_name'] ?? pdfFile.path.split(Platform.pathSeparator).last).toString();
    final int numPages = (data['num_pages'] ?? 0) as int;
    final List<dynamic> pages = (data['pages'] ?? []) as List<dynamic>;

    final List<String> textBlocks = pages
        .map((e) => (e as Map<String, dynamic>)['text']?.toString() ?? '')
        .where((t) => t.isNotEmpty)
        .toList(growable: false);

    final SampleDocument doc = SampleDocument(
      id: serverId > 0 ? 'server-$serverId' : 'uploaded-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      meta: 'PDF • $numPages page${numPages == 1 ? '' : 's'} • just now',
      ext: 'pdf',
      tldr: '',
      textBlocks: textBlocks,
      imageUrls: const [],
      insights: const [],
    );

    _uploadedDocs.insert(0, doc);
    // Optionally keep a tiny local index to server id / fileUrl if needed later
    // (not displayed right now)
    return doc;
  }

  /// Trigger server-side simulation generation and persistence.
  /// Returns a map with at least { "status": "ok", "session_id": int } on success.
  Future<Map<String, dynamic>> simulateDocument({required int id}) async {
    final uri = Uri.parse('$baseUrl/api/documents/$id/simulate/');
    final res = await http.post(uri, headers: {"Content-Type": "application/json"});
    if (res.statusCode != 200) {
      throw HttpException('Simulate failed (${res.statusCode}): ${res.body}');
    }
    final Map<String, dynamic> data = json.decode(res.body) as Map<String, dynamic>;
    return data;
  }

  /// Fetch simulation data by session ID.
  /// Returns a map with simulation session and related data.
  Future<Map<String, dynamic>> fetchSimulationData({required int sessionId}) async {
    final uri = Uri.parse('$baseUrl/api/simulations/$sessionId/');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw HttpException('Simulation fetch failed (${res.statusCode}): ${res.body}');
    }
    final Map<String, dynamic> data = json.decode(res.body) as Map<String, dynamic>;
    return data;
  }

  /// Check if a document has existing simulations.
  /// Returns a map with simulation count and latest session info.
  Future<Map<String, dynamic>> checkDocumentSimulations({required int documentId}) async {
    final uri = Uri.parse('$baseUrl/api/documents/$documentId/simulations/');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw HttpException('Simulation check failed (${res.statusCode}): ${res.body}');
    }
    final Map<String, dynamic> data = json.decode(res.body) as Map<String, dynamic>;
    return data;
  }

  /// Translate a document to a specific language.
  /// Returns a map with translation status and metadata.
  Future<Map<String, dynamic>> translateDocument({
    required int documentId,
    required String language,
  }) async {
    final uri = Uri.parse('$baseUrl/api/documents/$documentId/translate/');
    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: json.encode({"language": language}),
    );
    if (res.statusCode != 200) {
      throw HttpException('Translation failed (${res.statusCode}): ${res.body}');
    }
    final Map<String, dynamic> data = json.decode(res.body) as Map<String, dynamic>;
    return data;
  }

  /// Get translated document content.
  /// Returns a map with translated document data.
  Future<Map<String, dynamic>> getTranslatedDocument({
    required int documentId,
    required String language,
  }) async {
    final uri = Uri.parse('$baseUrl/api/documents/$documentId/translations/$language/');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw HttpException('Translation fetch failed (${res.statusCode}): ${res.body}');
    }
    final Map<String, dynamic> data = json.decode(res.body) as Map<String, dynamic>;
    return data;
  }

  /// List all available translations for a document.
  /// Returns a map with available translations.
  Future<Map<String, dynamic>> listDocumentTranslations({required int documentId}) async {
    final uri = Uri.parse('$baseUrl/api/documents/$documentId/translations/');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw HttpException('Translation list failed (${res.statusCode}): ${res.body}');
    }
    final Map<String, dynamic> data = json.decode(res.body) as Map<String, dynamic>;
    return data;
  }

  /// Fetch document analysis with optional language translation.
  /// If language is provided and not 'en', will fetch translated content.
  Future<Map<String, dynamic>> fetchAnalysisWithLanguage({
    required int documentId,
    String language = 'en',
  }) async {
    Map<String, dynamic> data;
    if (language == 'en') {
      // Fetch original analysis
      data = await fetchAnalysis(documentId);
    } else {
      // First get the analysis to extract the analysis ID
      final analysisResponse = await http.get(Uri.parse('$baseUrl/api/documents/$documentId/analysis/'));
      if (analysisResponse.statusCode != 200) {
        throw Exception('Failed to fetch analysis: ${analysisResponse.statusCode}');
      }
      final analysisData = json.decode(analysisResponse.body) as Map<String, dynamic>;
      // If still pending/failed, bubble up early
      final status = (analysisData['status'] ?? 'success').toString();
      if (status != 'success') {
        throw HttpException(status == 'pending' ? 'Analysis pending' : 'Analysis unavailable: ${analysisData['error'] ?? status}');
      }
      final analysisId = analysisData['id'] as int?;
      
      if (analysisId == null) {
        throw Exception('Analysis ID not found in analysis data');
      }
      
      // Try to fetch translated analysis
      try {
        final uri = Uri.parse('$baseUrl/api/analysis/$analysisId/translations/$language/');
        final response = await http.get(uri);
        if (response.statusCode == 200) {
          final responseData = json.decode(response.body) as Map<String, dynamic>;
          data = responseData['analysis'];
        } else {
          throw Exception('Failed to fetch translation: ${response.statusCode}');
        }
      } catch (e) {
        // If translation doesn't exist, try to create it
        try {
          final translateUri = Uri.parse('$baseUrl/api/analysis/$analysisId/translate/');
          final translateResponse = await http.post(
            translateUri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'language': language}),
          );
          if (translateResponse.statusCode == 200) {
            final fetchUri = Uri.parse('$baseUrl/api/analysis/$analysisId/translations/$language/');
            final fetchResponse = await http.get(fetchUri);
            if (fetchResponse.statusCode == 200) {
              final responseData = json.decode(fetchResponse.body) as Map<String, dynamic>;
              data = responseData['analysis'];
            } else {
              throw Exception('Failed to fetch created translation: ${fetchResponse.statusCode}');
            }
          } else {
            throw Exception('Failed to create translation: ${translateResponse.statusCode}');
          }
        } catch (translationError) {
          // Fallback to original analysis if translation fails
          developer.log('Analysis translation failed, falling back to original: $translationError', name: 'ParsedDocumentsRepository');
          data = analysisData['analysis'] as Map<String, dynamic>;
        }
      }
    }
    return data;
  }

  Future<SampleDocument> fetchDocumentDetailWithLanguage({
    required int id,
    String language = 'en',
  }) async {
    Map<String, dynamic> data;
    if (language == 'en') {
      // Fetch original document
      final originalDoc = await fetchDocumentDetail(id);
      data = {
        'file_name': originalDoc.title,
        'num_pages': originalDoc.textBlocks.length,
        'pages': originalDoc.textBlocks.map((text) => {'text': text}).toList(),
        'full_text': originalDoc.textBlocks.join('\n'),
      };
    } else {
      // Try to fetch translated document
      try {
        data = await getTranslatedDocument(documentId: id, language: language);
      } catch (e) {
        // If translation doesn't exist, try to create it
        try {
          await translateDocument(documentId: id, language: language);
          data = await getTranslatedDocument(documentId: id, language: language);
        } catch (translationError) {
          // Fallback to original document if translation fails
          developer.log('Translation failed, falling back to original: $translationError', name: 'ParsedDocumentsRepository');
          final originalDoc = await fetchDocumentDetail(id);
          data = {
            'file_name': originalDoc.title,
            'num_pages': originalDoc.textBlocks.length,
            'pages': originalDoc.textBlocks.map((text) => {'text': text}).toList(),
            'full_text': originalDoc.textBlocks.join('\n'),
          };
        }
      }
    }

    final String title = (data['file_name'] ?? 'Document').toString();
    final int numPages = (data['num_pages'] ?? 0) as int;
    final List<dynamic> pages = (data['pages'] ?? []) as List<dynamic>;
    final List<String> textBlocks = pages
        .map((e) => (e as Map<String, dynamic>)['text']?.toString() ?? '')
        .where((t) => t.isNotEmpty)
        .toList(growable: false);

    return SampleDocument(
      id: 'server-$id',
      title: title,
      meta: 'PDF • $numPages page${numPages == 1 ? '' : 's'}',
      ext: 'pdf',
      tldr: '',
      textBlocks: textBlocks,
      imageUrls: const [],
      insights: const [],
    );
  }

  // Simulation Translation Methods

  /// Translate simulation data to a specific language
  Future<Map<String, dynamic>> translateSimulation({
    required int sessionId,
    required String language,
  }) async {
    final uri = Uri.parse('$baseUrl/api/simulations/$sessionId/translate/');
    developer.log('📡 Translating simulation: $uri with language $language', name: 'ParsedDocumentsRepository');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'language': language}),
    );
    developer.log('📡 Translation response: ${res.statusCode} - ${res.body}', name: 'ParsedDocumentsRepository');
    if (res.statusCode != 200) {
      throw HttpException('Simulation translation failed (${res.statusCode}): ${res.body}');
    }
    return json.decode(res.body) as Map<String, dynamic>;
  }

  /// Get translated simulation data for a specific language
  Future<Map<String, dynamic>> getTranslatedSimulation({
    required int sessionId,
    required String language,
  }) async {
    final uri = Uri.parse('$baseUrl/api/simulations/$sessionId/translations/$language/');
    developer.log('📡 Getting translated simulation: $uri', name: 'ParsedDocumentsRepository');
    final res = await http.get(uri);
    developer.log('📡 Get translation response: ${res.statusCode} - ${res.body.substring(0, res.body.length > 200 ? 200 : res.body.length)}...', name: 'ParsedDocumentsRepository');
    if (res.statusCode != 200) {
      throw HttpException('Get simulation translation failed (${res.statusCode}): ${res.body}');
    }
    return json.decode(res.body) as Map<String, dynamic>;
  }

  /// List all available translations for a simulation session
  Future<List<String>> listSimulationTranslations({required int sessionId}) async {
    final uri = Uri.parse('$baseUrl/api/simulations/$sessionId/translations/');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw HttpException('List simulation translations failed (${res.statusCode}): ${res.body}');
    }
    final Map<String, dynamic> data = json.decode(res.body) as Map<String, dynamic>;
    final List<dynamic> languages = (data['available_languages'] ?? []) as List<dynamic>;
    return languages.map((lang) => (lang as Map<String, dynamic>)['language'] as String).toList();
  }

  /// Fetch simulation data with language support
  Future<Map<String, dynamic>> fetchSimulationWithLanguage({
    required int sessionId,
    required String language,
  }) async {
    developer.log('🔄 fetchSimulationWithLanguage: sessionId=$sessionId, language=$language', name: 'ParsedDocumentsRepository');
    
    if (language == 'en') {
      // For English, we might need to fetch from the original simulation endpoint
      // This would depend on your existing simulation API structure
      final uri = Uri.parse('$baseUrl/api/simulations/$sessionId/');
      developer.log('📡 Fetching original simulation from: $uri', name: 'ParsedDocumentsRepository');
      final res = await http.get(uri);
      if (res.statusCode != 200) {
        throw HttpException('Get simulation failed (${res.statusCode}): ${res.body}');
      }
      return json.decode(res.body) as Map<String, dynamic>;
    } else {
      // Always trigger/ensure translation, then poll until fully translated before returning
      try {
        developer.log('📡 Ensuring translation is triggered for $language', name: 'ParsedDocumentsRepository');
        await translateSimulation(sessionId: sessionId, language: language);
      } catch (e) {
        developer.log('⚠️ translateSimulation returned non-blocking/exists: $e', name: 'ParsedDocumentsRepository');
      }

      Map<String, dynamic> last = {};
      for (int attempt = 1; attempt <= 25; attempt++) {
        final data = await getTranslatedSimulation(sessionId: sessionId, language: language);
        last = data;
        if (_isTranslatedSimulation(data, language)) {
          developer.log('✅ Translated data confirmed on attempt $attempt', name: 'ParsedDocumentsRepository');
          return data;
        }
        await Future.delayed(const Duration(milliseconds: 900));
      }
      developer.log('⏱️ Translation not confirmed in time; returning last response', name: 'ParsedDocumentsRepository');
      return last;
    }
  }

  bool _isTranslatedSimulation(Map<String, dynamic> data, String language) {
    if (language == 'en') return true;
    try {
      final session = data['session'] as Map<String, dynamic>?;
      final title = session?['title']?.toString() ?? '';
      // Check some likely-translated fields for non-ascii characters
      final narratives = (data['narratives'] as List?)?.cast<dynamic>() ?? const [];
      final risks = (data['risk_alerts'] as List?)?.cast<dynamic>() ?? const [];
      final samples = <String>[
        if (title.isNotEmpty) title,
        if (narratives.isNotEmpty) ((narratives.first as Map)['title']?.toString() ?? ''),
        if (narratives.isNotEmpty) ((narratives.first as Map)['narrative']?.toString() ?? ''),
        if (risks.isNotEmpty) ((risks.first as Map)['message']?.toString() ?? ''),
      ].where((s) => s.isNotEmpty).toList();
      if (samples.isEmpty) return false;
      // If any sample has non-ASCII, consider translated for Indic scripts
      for (final s in samples) {
        if (s.codeUnits.any((u) => u > 127)) return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // --- Gemini Chat ---
  Future<String> sendChatPrompt(String prompt, {String model = 'gemini-2.0-flash', String language = 'en'}) async {
    final uri = Uri.parse('$baseUrl/api/chat/gemini/');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'prompt': prompt,
        'model': model,
        'language': language,
        // You can pass thinking_budget: 0 to disable thinking if desired
      }),
    );
    if (res.statusCode != 200) {
      throw HttpException('Chat failed (${res.statusCode}): ${res.body}');
    }
    final Map<String, dynamic> data = json.decode(res.body) as Map<String, dynamic>;
    return (data['text'] ?? '').toString();
  }
}


