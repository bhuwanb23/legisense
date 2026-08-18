import '../data/analysis_mock.dart';
import '../data/dashboard_mock.dart';
import '../models/api/analysis_models.dart';
import '../models/api/document_models.dart';

abstract final class AnalysisMapper {
  static String typeEmoji(String? type) {
    final t = (type ?? '').toLowerCase();
    if (t.contains('nda')) return '🔒';
    if (t.contains('lease') || t.contains('rent')) return '🏠';
    if (t.contains('employ')) return '💼';
    if (t.contains('loan')) return '💳';
    if (t.contains('insurance')) return '🛡️';
    if (t.contains('sale') || t.contains('deed')) return '📜';
    return '📄';
  }

  static String typeLabel(String? type) {
    if (type == null || type.isEmpty) return 'Document';
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  static AnalysisRiskLevel riskFromString(String? v) {
    switch ((v ?? '').toLowerCase()) {
      case 'high':
        return AnalysisRiskLevel.high;
      case 'medium':
        return AnalysisRiskLevel.medium;
      case 'missing':
        return AnalysisRiskLevel.missing;
      default:
        return AnalysisRiskLevel.low;
    }
  }

  static DocRisk docRiskFromString(String? v) {
    switch ((v ?? '').toLowerCase()) {
      case 'high':
        return DocRisk.high;
      case 'medium':
        return DocRisk.medium;
      default:
        return DocRisk.low;
    }
  }

  static String relativeDate(String? iso) {
    if (iso == null || iso.isEmpty) return 'Recently';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  static MockDocument toMockDocument(ApiDocument doc) {
    final type = doc.documentType ?? doc.fileFormat ?? 'document';
    return MockDocument(
      id: doc.id.toString(),
      title: doc.originalName,
      typeId: type.toLowerCase().replaceAll(' ', '_'),
      typeLabel: typeLabel(type),
      risk: docRiskFromString(doc.riskLevel),
      relativeDate: relativeDate(doc.createdAt),
      riskScore: doc.overallRiskScore ?? 0,
      daysAgo: _daysAgo(doc.createdAt),
      processingStatus: doc.processingStatus,
      fileSize: doc.fileSize,
      isFavorite: doc.isFavorite,
    );
  }

  /// Apply a translate API snapshot onto an existing [AnalysisResult].
  static AnalysisResult applyTranslation(
    AnalysisResult result,
    Map<String, dynamic> snapshot,
  ) {
    final lang = snapshot['language']?.toString();
    final summary = snapshot['summary']?.toString();
    final rawClauses = snapshot['clauses'];
    final byId = <String, Map<String, dynamic>>{};
    if (rawClauses is List) {
      for (final item in rawClauses.whereType<Map>()) {
        final m = Map<String, dynamic>.from(item);
        final id = (m['id'] ?? '').toString();
        if (id.isNotEmpty) byId[id] = m;
      }
    }

    final clauses = result.clauses.map((c) {
      final t = byId[c.id];
      if (t == null) return c;
      final plain = t['plainEnglishText']?.toString();
      if (plain == null || plain.isEmpty) return c;
      return c.copyWith(plainEnglish: plain);
    }).toList();

    return result.copyWith(
      overview: (summary != null && summary.isNotEmpty) ? summary : null,
      clauses: clauses,
      displayLanguage: lang,
    );
  }

  static int _daysAgo(String? iso) {
    final dt = DateTime.tryParse(iso ?? '');
    if (dt == null) return 0;
    return DateTime.now().difference(dt).inDays;
  }

  static AnalysisResult fromBundle(
    AnalysisBundle bundle, {
    required int documentId,
    String? documentTitle,
  }) {
    final a = bundle.analysis ?? {};
    final title = documentTitle ??
        bundle.documentTitle ??
        a['documentTitle'] as String? ??
        'Document';
    final type = a['documentType'] as String? ?? 'Document';
    final score = (a['overallRiskScore'] as num?)?.toInt() ?? 0;
    final fairness = (a['fairnessScore'] as num?)?.toInt();
    final riskLevel = a['riskLevel'] as String?;
    final favors = a['favorsParty'] as String? ?? '';
    final summary = a['summary'] as String? ?? 'Analysis complete.';

    final parties = _parseParties(a['keyParties']);
    final dates = _parseDates(a['criticalDates']);
    final breaches = _parseBreaches(a['breachScenarios']);
    final clauses = bundle.clauses.map(_clause).toList();

    final high = clauses.where((c) => c.risk == AnalysisRiskLevel.high).length;
    final med =
        clauses.where((c) => c.risk == AnalysisRiskLevel.medium).length;
    final low = clauses.where((c) => c.risk == AnalysisRiskLevel.low).length;

    final missingRaw = a['missingClauses'];
    var missingCount = 0;
    if (missingRaw is List) missingCount = missingRaw.length;

    final categories = <RiskCategory>[];
    final byCat = <String, List<AnalysisClause>>{};
    for (final c in clauses) {
      for (final cat in c.categories) {
        byCat.putIfAbsent(cat, () => []).add(c);
      }
    }

    // Build a lookup of recommendation per risk_type from the backend risk_items
    final recByType = <String, String?>{};
    for (final ri in bundle.riskItems) {
      final t = ri['riskType']?.toString() ?? '';
      if (t.isNotEmpty && !recByType.containsKey(t)) {
        recByType[t] = ri['recommendation']?.toString();
      }
    }

    var i = 0;
    for (final entry in byCat.entries) {
      final worst = entry.value.map((c) => c.risk).fold(
            AnalysisRiskLevel.low,
            (a, b) => a.index >= b.index ? a : b,
          );
      final count = entry.value.length;
      final catKey = entry.key.toLowerCase();
      final highCount = entry.value
          .where((c) => c.risk == AnalysisRiskLevel.high)
          .length;
      final summaryDesc = _buildCategorySummary(
        entry.key,
        count,
        highCount,
        worst,
      );
      categories.add(
        RiskCategory(
          id: 'rc$i',
          title: entry.key,
          level: worst,
          summary: summaryDesc,
          clauseIds: entry.value.map((c) => c.id).toList(),
          recommendation: recByType[catKey],
        ),
      );
      i++;
    }

    return AnalysisResult(
      documentId: documentId,
      documentTitle: title,
      documentType: typeLabel(type),
      typeEmoji: typeEmoji(type),
      pageCount: 1,
      partyCount: parties.length,
      analyzedLabel: 'Just now',
      riskScore: score,
      fairnessScore: fairness,
      riskLevelLabel: riskLevel,
      biasSummary: favors.isEmpty
          ? 'Balanced overall'
          : 'This agreement favors $favors',
      overview: summary,
      parties: parties,
      durationLabel: dates.isNotEmpty ? dates.first.value : '—',
      keyDatesCount: dates.length,
      criticalDates: dates,
      breachScenarios: breaches,
      clauses: clauses,
      riskCategories: categories,
      highRiskCount: high,
      mediumRiskCount: med,
      lowRiskCount: low,
      missingCount: missingCount,
    );
  }

  static AnalysisClause _clause(Map<String, dynamic> c) {
    final cats = <String>[];
    final cat = c['riskCategory'] as String?;
    if (cat != null && cat.isNotEmpty) cats.add(cat);
    final terms = c['keyLegalTerms'];
    if (terms is List) {
      for (final t in terms) {
        if (t != null) cats.add(t.toString());
      }
    }
    if (cats.isEmpty) cats.add('General');

    return AnalysisClause(
      id: (c['id'] ?? c['clauseNumber'] ?? '').toString(),
      number: (c['clauseNumber'] as num?)?.toInt() ?? 0,
      title: c['clauseTitle'] as String? ?? 'Clause',
      risk: riskFromString(c['riskLevel'] as String?),
      originalText: c['originalText'] as String? ?? '',
      plainEnglish: c['plainEnglishText'] as String? ??
          c['plainEnglish'] as String? ??
          '',
      categories: cats,
    );
  }

  static List<AnalysisParty> _parseParties(dynamic raw) {
    if (raw is String) {
      try {
        // ignore: unnecessary_cast
        raw = raw; // may already be parsed by backend
      } catch (_) {}
    }
    if (raw is! List) return [];
    return raw.whereType<Map>().map((p) {
      final m = Map<String, dynamic>.from(p);
      final obs = m['obligations'] ?? m['obligations_summary'];
      List<String> list = [];
      if (obs is List) {
        list = obs.map((e) => e.toString()).toList();
      } else if (obs is String && obs.isNotEmpty) {
        list = [obs];
      }
      return AnalysisParty(
        name: m['name'] as String? ?? 'Party',
        role: m['role'] as String? ?? m['type'] as String? ?? '',
        obligations: list,
      );
    }).toList();
  }

  static List<AnalysisDateRow> _parseDates(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<Map>().map((d) {
      final m = Map<String, dynamic>.from(d);
      return AnalysisDateRow(
        label: m['label'] as String? ?? 'Date',
        value: (m['date'] ?? m['value'] ?? '').toString(),
      );
    }).toList();
  }

  static String _buildCategorySummary(
    String category,
    int count,
    int highRiskCount,
    AnalysisRiskLevel worst,
  ) {
    final catLabel = category
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
    final worstLabel = switch (worst) {
      AnalysisRiskLevel.high => 'high risk',
      AnalysisRiskLevel.medium => 'moderate risk',
      AnalysisRiskLevel.low => 'low risk',
      AnalysisRiskLevel.missing => 'unknown risk',
    };
    if (count == 1) {
      return '$catLabel: 1 clause at $worstLabel.';
    }
    if (highRiskCount > 0) {
      return '$catLabel: $count clauses, $highRiskCount high-risk. Review carefully.';
    }
    return '$catLabel: $count clauses at $worstLabel.';
  }

  static List<String> _parseBreaches(dynamic raw) {
    if (raw is String && raw.isNotEmpty) {
      // Often stored as JSON string
      if (raw.startsWith('[')) {
        try {
          // lightweight: split by quotes content — fallback to single
          return [raw];
        } catch (_) {
          return [raw];
        }
      }
      return [raw];
    }
    if (raw is List) {
      return raw.map((e) {
        if (e is Map) {
          return (e['scenario'] ?? e['title'] ?? e.toString()).toString();
        }
        return e.toString();
      }).toList();
    }
    return [];
  }
}

abstract final class DashboardFilters {
  static const filters = DashboardMock.filters;
}
