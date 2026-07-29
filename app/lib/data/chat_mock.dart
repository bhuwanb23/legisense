import 'analysis_mock.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    this.timestamp,
  });

  final String id;
  final String text;
  final bool isUser;
  final DateTime? timestamp;
}

/// Seeded Q&A + keyword replies for Chat-with-Document.
abstract final class ChatMock {
  static const suggestedPrompts = <String>[
    'What are the biggest risks?',
    'Explain the lock-in period',
    'Who does this contract favor?',
    'What happens if I leave early?',
  ];

  static List<ChatMessage> seed(AnalysisResult result) {
    return [
      ChatMessage(
        id: 's1',
        text:
            'I’ve reviewed “${result.documentTitle}”. Ask about risks, parties, dates, or any clause.',
        isUser: false,
      ),
      const ChatMessage(
        id: 's2',
        text: 'What should I watch out for first?',
        isUser: true,
      ),
      ChatMessage(
        id: 's3',
        text:
            'Start with termination and lock-in. Score is ${result.riskScore}/100 — ${result.biasSummary.toLowerCase()}.',
        isUser: false,
      ),
    ];
  }

  static String replyFor(String prompt, AnalysisResult result) {
    final q = prompt.toLowerCase();

    if (q.contains('risk') || q.contains('biggest') || q.contains('watch')) {
      final highs = result.clauses
          .where((c) => c.risk == AnalysisRiskLevel.high)
          .take(3)
          .map((c) => '• ${c.title}: ${c.plainEnglish}')
          .join('\n');
      return 'Highest-risk areas in this ${result.documentType}:\n$highs';
    }

    if (q.contains('lock') || q.contains('early') || q.contains('leave')) {
      final lock = result.clauses.where(
        (c) => c.title.toLowerCase().contains('lock'),
      );
      if (lock.isNotEmpty) {
        return lock.first.plainEnglish;
      }
      return 'Early exit during the lock-in can cost up to 2 months’ rent in this mock lease.';
    }

    if (q.contains('favor') || q.contains('bias') || q.contains('landlord')) {
      return result.biasSummary;
    }

    if (q.contains('party') || q.contains('who') || q.contains('parties')) {
      final lines = result.parties
          .map((p) => '• ${p.name} (${p.role})')
          .join('\n');
      return 'Parties on this document:\n$lines';
    }

    if (q.contains('date') || q.contains('deadline') || q.contains('when')) {
      final lines = result.criticalDates
          .map((d) => '• ${d.label}: ${d.value}')
          .join('\n');
      return 'Key dates:\n$lines';
    }

    if (q.contains('deposit') || q.contains('security')) {
      final dep = result.clauses.where(
        (c) => c.title.toLowerCase().contains('deposit'),
      );
      if (dep.isNotEmpty) return dep.first.plainEnglish;
    }

    if (q.contains('summary') || q.contains('overview')) {
      return result.overview;
    }

    return 'Based on “${result.documentTitle}” (risk ${result.riskScore}): '
        '${result.overview.split('.').first}. '
        'Try asking about risks, lock-in, parties, or key dates.';
  }
}
