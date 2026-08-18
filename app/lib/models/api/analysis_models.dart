class AnalysisBundle {
  const AnalysisBundle({
    required this.status,
    this.analysis,
    this.clauses = const [],
    this.riskItems = const [],
    this.deadlines = const [],
    this.documentTitle,
  });

  final String status;
  final Map<String, dynamic>? analysis;
  final List<Map<String, dynamic>> clauses;
  final List<Map<String, dynamic>> riskItems;
  final List<Map<String, dynamic>> deadlines;
  final String? documentTitle;

  factory AnalysisBundle.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> listOf(dynamic v) {
      if (v is! List) return [];
      return v
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    return AnalysisBundle(
      status: json['status'] as String? ?? 'pending',
      analysis: json['analysis'] is Map<String, dynamic>
          ? json['analysis'] as Map<String, dynamic>
          : null,
      clauses: listOf(json['clauses']),
      riskItems: listOf(json['riskItems'] ?? json['risk_items']),
      deadlines: listOf(json['deadlines']),
      documentTitle: json['documentTitle'] as String? ??
          json['originalName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'analysis': analysis,
      'clauses': clauses,
      'riskItems': riskItems,
      'deadlines': deadlines,
      'documentTitle': documentTitle,
    };
  }

  bool get hasAnalysis => analysis != null;
}
