import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../pages/documents/data/sample_documents.dart';

/// Simple in-memory repository that uploads a PDF to the backend and stores
/// the parsed result as a `SampleDocument`-compatible object for display.
class ApiConfig {
  /// Resolves a sensible default base URL depending on environment.
  /// Overridden to a fixed Wi‑Fi IP as requested.
  static String get baseUrl {
    return 'http://192.168.31.67:8000';
  }
}

class ParsedDocumentsRepository {
  ParsedDocumentsRepository({required this.baseUrl});

  final String baseUrl; // e.g., http://localhost:8000

  /// List of documents parsed in this session.
  final List<SampleDocument> _uploadedDocs = [];

  List<SampleDocument> get uploadedDocs => List.unmodifiable(_uploadedDocs);

  Future<List<Map<String, dynamic>>> fetchDocuments() async {
    final uri = Uri.parse('$baseUrl/api/documents/');
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw HttpException('List failed (${res.statusCode}): ${res.body}');
    }
    final Map<String, dynamic> data = json.decode(res.body) as Map<String, dynamic>;
    final List<dynamic> results = (data['results'] ?? []) as List<dynamic>;
    return results.cast<Map<String, dynamic>>();
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
}


